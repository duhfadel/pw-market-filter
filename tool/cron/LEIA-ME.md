# O relógio da coleta

O `schedule` das GitHub Actions é melhor esforço, e aqui ele falhou de um jeito
que vale ter medido: pedindo `*/20`, entregou de **45 minutos a 12 horas** entre
26 e 29/08 — sem nenhuma falha, sem nenhum cancelamento, com o repositório
público e minutos ilimitados. O GitHub simplesmente não disparava.

Este Worker tira o relógio das mãos dele. Acorda a cada 30 minutos e pede a
Action pela API — alternando entre as duas versões do mercado, uma por
disparo. Ver "O quarto trabalho" abaixo.

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

## O terceiro trabalho: manter o Supabase acordado

O contador do rodapé e os donos dos territórios vivem num projeto Supabase do
plano gratuito, **que é pausado depois de 7 dias sem atividade**. A atividade
vinha inteira dos visitantes — e em setembro o site ficou quatro dias fechado,
ninguém visitou, e o aviso de pausa chegou por e-mail no quarto dia.

Pausado, some o contador e some o mapa: 52 territórios, guildas e brasões.
Despausar pelo painel funciona por 90 dias; passado isso, só resta baixar os
dados.

Por isso o Worker tem **um segundo gatilho, `13 4 * * *`**, que chama
`register_visit()` uma vez por dia. Três coisas que valem estar escritas:

- **Ele é um gatilho separado de propósito.** Se o ping morasse dentro da
  coleta, ele iria a zero junto com ela no dia em que o site fechasse — que é
  exatamente quando ele mais importa. Ao fechar o site, mexe-se só nas duas
  entradas de coleta, `7 * * * *` e `37 * * * *` — as duas juntas, nunca só
  uma: publicar um mercado e esconder o outro não é fechar, é meio fechar.
- **É `register_visit` por decisão do dono, ciente do custo:** soma uma visita
  por dia ao contador, uns 365 por ano. `visit_total()` faria o mesmo serviço
  sem escrever nada, e trocar é uma palavra no `worker.js`.
- **Uma vez por dia contra um limite de sete é folga de sobra.** O que não
  pode é a última chamada bem-sucedida passar de uma semana, então sete falhas
  seguidas e em silêncio são o cenário a temer — elas aparecem no
  `wrangler tail`.

O roteamento entre os dois gatilhos é por `event.cron`, e foi provado antes de
subir com `wrangler dev --test-scheduled` e uma cópia do Worker com a chamada
ao GitHub trocada por um log: o cron da coleta não tocou no Supabase, e o do
Supabase não tocou no GitHub.

## O quarto trabalho: alternar entre as duas versões

Dois mercados, dois horários: `7 * * * *` dispara o 1.8.7 e `37 * * * *`
dispara o 1.2.6. Cada versão refresca de hora em hora; a cadência externa de
disparos continua a mesma de antes, um a cada trinta minutos — só que agora
alternando qual versão sai em cada um, em vez de disparar a mesma versão
quatro vezes por hora.

`publish.yml` ganhou `inputs.server` para receber isso: o `POST` de disparo
carrega `inputs: { server: 'pw187' }` ou `inputs: { server: 'pw126' }`,
escolhido por `SERVIDOR_POR_CRON[event.cron]`. **`CRON_DA_COLETA_187` e
`CRON_DA_COLETA_126` têm de bater, string a string, com as duas entradas de
`crons` no `wrangler.toml`** — a mesma armadilha que já existia com um
horário só, agora em dobro. Deixar um dos dois divergir faz aquele ramo nunca
disparar, caindo calado no keep-alive do Supabase, sem nada no log dizendo
por quê. Por isso o disparo bem-sucedido também loga — `coleta disparada:
pw187` — e não só o recusado: com dois horários, o log é o único lugar que
diz qual dos dois realmente saiu.

**Uma corrida só colhe uma versão, nunca as duas — é o que a permissão
comprou.** Despachar as duas no mesmo disparo dobraria de uma vez a carga
sobre o marketplace deles. A corrida ainda publica o site inteiro: antes de
compilar, `publish.yml` baixa o índice publicado da versão que **não**
colheu e o escreve em `web/` (`dart run tool/collect.dart --carry-forward`,
que reaproveita `_fetchPublishedIndex` — a mesma função que já existia para a
memória de preço). Se esse download falhar, a corrida aborta sem publicar:
publicar sem ele apagaria aquele mercado do site inteiro, não só o deixaria
velho.

**O redisparo depois de uma falha isolada tem de saber qual versão falhou,**
ou perderia a corrida boa que acabou de rodar e repetiria a errada.
`publish.yml` carrega a versão no próprio título da rodada —
`run-name: Coletar e publicar — ${{ inputs.server || 'pw187' }}` — e a API do
GitHub devolve esse texto computado em `display_title`: é o único lugar em
que os `inputs` de um `workflow_dispatch` já disparado voltam legíveis depois
do fato. `servidorDaRodada` lê esse título antes de redisparar; sem isso, a
regra "uma falha isolada, nunca duas seguidas" continuaria certa no *quando*
e errada no *quê*.

## O que este Worker não faz

**Não tem endereço público.** `workers_dev = false` no `wrangler.toml` é
deliberado: um endereço que dispara a coleta é um endereço que qualquer um pode
marretar, e cada disparo são ~1000 requisições ao marketplace — que bloqueia o
IP por mais de uma hora quando é maltratado. A única porta é o cron.

**Não faz coleta nenhuma.** Ele só bate na API do GitHub. Toda a lógica
continua em `tool/collect.dart`, rodando no runner, com o estado no cache.

**Não tenta de novo quando falha.** Isto é sobre o `POST` de disparo em si
falhar — não sobre a coleta falhar depois de disparada, que é o que
`ressuscitarColeta` existe para cobrir. Um disparo perdido custa uma hora
para aquela versão, a próxima vez que o horário dela voltar — meia hora era a
conta de quando havia um horário só para as quatro batidas por hora de uma
única versão — e a próxima tentativa resolve; repetir na hora só arrisca dois
runs concorrentes pelo mesmo grupo de concorrência.
