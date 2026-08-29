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

## Depois que ele estiver de pé

O cron do `publish.yml` vira **reserva**, não relógio principal. Sugestão:
baixar para algo raro — de três em três horas — em vez de apagar. Assim, se o
Worker morrer, o site ainda respira, e a data da coleta na tela é o que
denuncia.

Se você preferir depender só do Worker, apague o bloco `schedule` do workflow.
`push` e `workflow_dispatch` continuam disparando.

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
