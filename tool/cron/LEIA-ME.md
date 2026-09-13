# O relógio da coleta

O `schedule` das GitHub Actions é melhor esforço, e aqui ele falhou de um jeito
que vale ter medido: pedindo `*/20`, entregou de **45 minutos a 12 horas** entre
26 e 29/08 — sem nenhuma falha, sem nenhum cancelamento, com o repositório
público e minutos ilimitados. O GitHub simplesmente não disparava.

Este Worker tira o relógio das mãos dele. Acorda a cada 30 minutos e pede a
Action pela API.

## O que você precisa fazer uma vez

**1. Criar o token.** Em GitHub → Settings → Developer settings → *Fine-grained
personal access tokens*:

- *Repository access*: **só** `duhfadel/pw-market-filter`
- *Permissions* → Repository → **Actions: Read and write**, e nada mais
- Validade: o mais curto que você aceite renovar (90 dias é razoável)

Esse token dispara essa Action e não faz mais nada. Se vazar, o estrago é
alguém rodar a coleta — chato, não perigoso, e revogável num clique.

**2. Publicar o Worker**, deste diretório:

```
npx wrangler secret put GITHUB_TOKEN     # cola o token quando pedir
npx wrangler deploy
```

**3. Conferir que funcionou**, sem esperar meia hora:

```
npx wrangler tail                        # numa aba, deixa aberto
```

e dispare o cron pelo painel da Cloudflare (Workers → portalpw-cron →
Settings → Trigger Events → *Run*). Uma run nova tem que aparecer em
`gh run list` com evento `workflow_dispatch`.

## A pedra do caminho: o subdomínio

O primeiro `wrangler deploy` sobe o script e **falha ao registrar o cron**:

```
✘ [ERROR] Trigger configuration for "portalpw-cron" was only partially updated:
    Cron schedules:
      - You need a workers.dev subdomain in order to proceed.  [code: 10063]
```

A conta precisa ter um subdomínio `workers.dev` antes de a Cloudflare aceitar
**qualquer** gatilho — inclusive um cron, inclusive com `workers_dev = false`.
Numa conta que nunca abriu a seção Workers, ele não existe.

Resolvido em 29/08 pela API, sem abrir o painel:

```
curl -X PUT -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  --data '{"subdomain":"duhpicheth"}' \
  https://api.cloudflare.com/client/v4/accounts/$CONTA/workers/subdomain
```

O `$TOKEN` é o `oauth_token` que o `wrangler login` grava em
`~/Library/Preferences/.wrangler/config/default.toml`. Depois disso, repetir o
deploy registra o cron.

**Isso não expõe o Worker.** O subdomínio só precisa *existir* na conta; este
Worker continua sem rota, e o cron segue sendo a única porta.

## Quando o token expirar

Ele é o único ponto que apodrece sozinho. No dia em que expirar, o Worker
acorda, leva **401** e o site para de atualizar **em silêncio** — o mesmo
sintoma que trouxe a gente até aqui, com outra causa. É o primeiro lugar a
olhar se a coleta parar sem explicação, e o `wrangler tail` mostra o erro.

Renovar é gerar outro token e repetir só o segredo; o deploy não precisa ser
refeito:

```
npx wrangler secret put GITHUB_TOKEN
```

## Depois que ele estiver de pé

O cron do `publish.yml` vira **reserva**, não relógio principal. Sugestão:
baixar para algo raro — de três em três horas — em vez de apagar. Assim, se o
Worker morrer, o site ainda respira, e a data da coleta na tela é o que
denuncia.

Se você preferir depender só do Worker, apague o bloco `schedule` do workflow.
`push` e `workflow_dispatch` continuam disparando.

## O segundo modo de falha: a fila

Em 13/09 o `schedule` não teve culpa nenhuma — o Worker disparou na hora, como
sempre. A rodada das **04:07 UTC ficou 1h40 esperando uma máquina do GitHub**:
sem runner, sem erro, sem nada vermelho, e o `githubstatus.com` dizendo *All
Systems Operational* o tempo todo.

O estrago vem do `concurrency: group: pages` do workflow, que é o certo a ter:
só uma coleta por vez. A rodada travada segurou a vaga, as das 04:37 e 05:07
foram canceladas ao chegar atrás dela, e o site ficou **duas horas** no mesmo
índice. O conserto à mão foi matar o job morto — no segundo seguinte a rodada
seguinte pegou máquina.

E o pior número disso: **um job na fila só expira sozinho depois de 24 horas.**
Sem alguém reparar, o site passaria um dia parado sem nenhuma run vermelha para
denunciar.

Por isso o Worker agora, **antes de pedir a próxima coleta**, cancela qualquer
rodada que esteja na fila há mais de dez minutos (`destravarFila`). Três coisas
que valem estar escritas:

- **`in_progress` nunca é cancelado.** Uma coleta em andamento está
  trabalhando, e uma recoleta inteira leva ~40 minutos por desenho. Quem a mata
  quando trava de verdade é o `timeout-minutes: 75` do workflow.
- **Dez minutos não pega ninguém são.** Uma coleta normal leva ~3 minutos e a
  fila é instantânea quando há máquina. O que sobra acima de dez minutos é
  rodada esperando em vão, ou rodada presa atrás de uma — e essa o GitHub ia
  cancelar de qualquer jeito na próxima meia hora.
- **Falhar ao ler a fila não cancela o disparo.** No pior caso a fila fica como
  estava, que é exatamente o que acontecia antes deste bloco existir.

O buraco máximo deixa de ser 24 horas e passa a ser trinta minutos.

## O que este Worker não faz

**Não tem endereço público.** `workers_dev = false` no `wrangler.toml` é
deliberado: um endereço que dispara a coleta é um endereço que qualquer um pode
marretar, e cada disparo são ~1000 requisições ao marketplace — que bloqueia o
IP por mais de uma hora quando é maltratado. A única porta é o cron.

**Não faz coleta nenhuma.** Ele só bate na API do GitHub. Toda a lógica
continua em `tool/collect.dart`, rodando no runner, com o estado no cache.

**Não tenta de novo quando falha.** Um disparo perdido custa meia hora e a
próxima tentativa resolve; repetir na hora só arrisca dois runs concorrentes
pelo mesmo grupo de concorrência.
