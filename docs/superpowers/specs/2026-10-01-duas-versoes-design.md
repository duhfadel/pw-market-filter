# Duas versões, duas portas

> Escrito em 01/10/2026, depois de sondar o mercado do 1.2.6 com trinta
> páginas colhidas no ritmo do coletor. Os números aqui são medidos, não
> estimados, e quando a medição desmentiu uma ideia minha isso está escrito.

## O problema

O site é *Portal PW* e fala de um jogo só. `marketplace.theclassic.games`
serve pelo menos dois mercados vivos, e o segundo é grande: **1.308 anúncios
no 1.2.6** contra 1.666 no 1.8.7. Quem joga o clássico não tem ferramenta
nenhuma, e a nossa casa diz no cabeçalho que é do 1.8.7.

Existe ainda um `pw144` que responde **500, não 404** — a rota existe e está
quebrada ou por nascer. Isso é razão para desenhar para **N versões** e não
para duas.

## O que a sondagem mediu, e o que ela matou

Trinta personagens, amostra aleatória de semente fixa, 439 itens com JSON.

**O 1.2.6 é outro jogo, não um 1.8.7 pobre.** Não tem nenhum dos painéis sobre
os quais este site foi construído: zero cartas equipadas, zero runas, zero
anedotas, zero Reino Celestial, zero inventário por sub-aba. São **seis
classes** e **onze slots**, contra dezassete e catorze.

**Os atributos não vêm em tooltip.** No 1.8.7 cada peça imprime
`➜ Nível de Ataque +70` e o parser lê por nome. No 1.2.6 não há linha nenhuma
dessas: os números vivem crus no JSON do `data-item`, em campos do próprio
servidor de jogo.

Frequência, sobre os 439 itens:

| Campo | Em | Serve de filtro? |
|---|---|---|
| `require_level`, `require_class`, `durability`, `item_class` | 100% | não — é metadado |
| `defense` | 52% | **sim** |
| `require_strength` | 51% | talvez |
| `water` · `wood` · `fire` · `metal` · `earth` | 38–45% cada | **sim, e é a melhor** |
| `armor` | 26% | sim |
| `hp_enhance` | 20% | sim |
| `mp_enhance` | 16% | sim |
| `damage_high_min/max`, `attack_speed`, `attack_range` | 12% | **sim** — é a arma |

**Duas ideias minhas morreram na medição, e vale registar as duas.**

A primeira: eu tinha proposto **filtrar por quem forjou a peça**, entusiasmado
por `creator` ser um campo que o 1.8.7 não tem. São **129 forjadores distintos
em 160 peças assinadas** — média de 1,2 peça por nome, maior com cinco, e só
36% das peças são sequer assinadas. Um filtro assim devolve uma pessoa de cada
vez. `creator` fica como **detalhe no card**, nunca como dimensão de busca.

A segunda: eu esperava encontrar lá a escada de patamares que fez este site
existir. **Não existe.** O dano é um contínuo — 24 valores distintos em 30
personagens, de 271 a 1734. Não há "o 70", não há UP5, há uma rampa. Copiar as
seis cartas do 1.8.7 para o 1.2.6 produziria cartas vazias.

**Mas apareceu uma história melhor no lugar.** A correlação de postos entre
preço e dano é **+0,38** — fraca. Medido: **1.034 de dano por 65 TCC** contra
**1.435 por 3.900**. Em 1.8.7 o argumento é *"o mesmo item custa sessenta vezes
mais"*; em 1.2.6 é mais simples e mais forte — **o preço quase não diz nada
sobre o equipamento**, e filtrar por atributo é a única forma de comprar bem.

Trinta personagens é pouco para cravar um coeficiente. O sinal basta para
desenhar em cima; o número **não vai para a tela**.

## As rotas, e por que são assimétricas

```
/              a tela de apresentação
/187           a home do 1.8.7     ← Cartaz e os seis Destaques
/filtro        o filtro do 1.8.7   ← sem prefixo, de propósito
/registros     Títulos             ← idem
/runas         Calculadora         ← idem
/novidades     os recados do site  ← uma só, serve as duas versões
/126           a home do 1.2.6
/126/filtro    o filtro do 1.2.6
```

**As ferramentas do 1.8.7 ficam sem prefixo para sempre.** Não é desleixo: cada
busca do filtro **escreve-se na barra de endereços** e é partilhada no Discord,
e `search_query_url.dart` existe inteiro para que esse link sobreviva a uma
coleta. Prefixar tudo quebraria todos os links já partilhados, de uma vez.
A assimetria é uma decisão com motivo escrito: **1.8.7 é a versão sem prefixo
porque chegou primeiro e porque os links dela já existem.** O 1.2.6 e tudo o
que vier depois levam prefixo.

**`/` deixa de ser a home do 1.8.7, e isso tem um custo que precisa ser dito.**
`portalpw.net` é o link mais partilhado que existe, e hoje ele abre o mercado.
Passa a abrir a escolha. Quem cola o link no Discord deixa de mostrar o Cartaz
na pré-visualização e passa a mostrar a porta. As `og:` tags da raiz têm de ser
reescritas para dizer o que o site é — duas versões, dois mercados, com as duas
contagens — e não herdar as do 1.8.7.

## A tela de apresentação

Duas portas. Cada uma mostra, e **só**: o nome da versão, **quantos
personagens estão à venda agora**, e **quando foi a última coleta**. Sem arte
de classe, sem lista de funcionalidades.

A contenção é deliberada. A tela existe para desviar quem ainda não sabe onde
quer ir; **nenhum link da comunidade passa por ela**, porque todos apontam
para uma versão. Quem chega aqui já está no site — não há nada para vender,
só uma pergunta a responder. Vender duas vezes ao mesmo visitante é como a
home ganhou um menu duplicado.

**Ela não pode baixar os dois índices para mostrar dois números.** São 4 MB
cada. O coletor passa a escrever `web/versoes.json`, um arquivo minúsculo com
uma linha por versão — chave, nome, contagem, data da coleta. A tela lê só
isso.

Uma versão que ainda não tem índice aparece **esmaecida e com *em breve***, a
mesma regra que `Tool.isReady` já aplica no menu: a porta mostra a forma do
lugar antes de o lugar existir.

## O que é partilhado e o que é por versão

**Partilhado, sem uma linha de diferença:** `/novidades` — já construída assim
de propósito e verificada por rastreio de imports; o cabeçalho com as pílulas;
`PWColors` e `PWTheme`; o rodapé, o contador de visitas, a tira de streamers e
o Discord. Nada disso sabe de que jogo se fala.

**Por versão:** o parser de detalhe, o vocabulário de atributos, as cartas de
destaque, os nomes dos slots, a arte das classes, e o índice.

**`slot_names.dart` precisa de tabela própria, e isto é armadilha.** São onze
slots no 1.2.6 contra catorze, e o `CLAUDE.md` já regista que a numeração
daqui **não bate com a do cliente padrão**. Assumir que o slot 10 é a mesma
peça nos dois jogos é exatamente o erro que aquela nota existe para impedir.

## Os atributos do 1.2.6, e de quem são os nomes

No 1.8.7 `MarketIndex.attributes` guarda os nomes **que o jogo imprime**. No
1.2.6 não há nomes — há campos de banco. Então os rótulos passam a ser
**nossos**: `damage_high_max` vira *Dano máximo*, `fire` vira *Resistência ao
fogo*.

Isso é uma diferença de natureza, não de grafia, e tem de estar escrita onde
alguém a leia: **um rótulo nosso pode estar errado de um jeito que um rótulo
do jogo não pode.** A tabela de tradução é código, versionada e com teste, e
cada entrada dela é uma afirmação sobre o que aquele campo significa.

Dois campos ficam **de fora** até alguém confirmar o que são: `item_flag`
(69%) e `item_class` (100%). Mostrar um número sem saber o que ele mede é a
mesma coisa que `Movimento m/seg. +1036831949`, que este repositório já
aprendeu a deixar como está em vez de inventar.

## As cartas do 1.2.6

Seis cartas, como no 1.8.7, mas **feitas das perguntas daquele mercado** — e
nenhuma delas copiada de cá, porque nenhuma teria resposta:

1. **O mais barato** — a entrada do mercado
2. **Mais dano por TCC** — a pechincha, e é o argumento central da versão
3. **A arma mais forte** — o topo
4. **Mais defesa** — a outra metade da build
5. **Maior resistência ao fogo** — uma das cinco; a escolhida roda com a coleta
6. **O mais caro** — e, se a correlação se mantiver, provavelmente não é o mais forte

A regra das **classes distintas** vale aqui tal como lá: a arte é a carta, e
duas cartas da mesma classe são dois retratos iguais lado a lado. Com seis
classes em vez de dezassete a colisão é **muito mais provável**, então o
recuo para o próximo de outra classe vai disparar com frequência — e o rótulo
tem de amolecer junto, como já faz.

## O coletor

`tool/collect.dart` ganha `--server`, com `pw187` por padrão. O que muda por
versão: a origem, o prefixo das classes CSS (`pw126-` contra `pw187-`), o
caminho do detalhe e o arquivo de saída.

**O caminho do detalhe é invertido entre as versões, e isto custaria uma hora
a quem não soubesse.** No 1.8.7 a forma canônica é `/pw187/details/<id>` e a
que a listagem usa redireciona. No 1.2.6 é ao contrário: `/pw126/details/<id>`
responde **404** e a forma da listagem, `/details/pw126/<id>`, é a que serve.
Medido nas duas.

O ritmo não muda e não há modo rápido: uma requisição de cada vez, ~3 s, e o
bloqueio sobrevive à corrida.

### Um job só, alternando — e não um por versão

**`publish.yml` ganha um `input` de versão e o Worker alterna**: `pw187` aos
:07, `pw126` aos :37. Cada versão refresca de hora a hora. Dois workflows
separados seriam a escolha óbvia e seriam erro, por três razões em ordem de
custo.

**Um deploy publica o site inteiro, e é isto que decide.** Se a corrida do
126 colheu só o 126, ela ainda assim tem de publicar o índice do 187 — que
não está no repositório, porque é gitignorado. Um deploy "do 126" apagaria o
mercado do 1.8.7 do ar.

A peça que resolve isso **já existe**: a memória do mercado fez o coletor
baixar o índice publicado para comparar preços (`_fetchPublishedIndex`). A
mesma função serve aqui com outro propósito — cada corrida colhe a sua versão
e **arrasta a outra do ar, intacta**, para dentro do deploy. Nada novo a
construir; uma peça existente usada uma segunda vez.

**Dois workflows colidiriam no deploy, e o repositório já pagou por isso.** O
`CLAUDE.md` regista o dia em que um segundo artefato `github-pages` apareceu
e a tentativa seguinte morreu com *"Multiple artifacts named github-pages
were unexpectedly found"*. O grupo de `concurrency` protege dentro de um
workflow; dois, cada um a chamar `upload-pages-artifact` e `deploy-pages`,
colidiriam sempre que se sobrepusessem — e com ~40 minutos cada, sobrepor-se-iam.

**E alternar é o que a permissão comprou.** Fazer as duas coletas em cada
corrida dobraria a carga sobre o site deles de uma vez. *"Não iremos impedir
ou bloquear"* não é aval para isso.

A conta é menor do que parece: **os ~40 minutos são só da primeira passagem.**
Depois `--resume` busca a listagem e só as páginas de quem nunca foi visto —
segundos. Os 1.308 anúncios custam quarenta minutos **uma vez**.

**`CRON_DA_COLETA` passa a ter duas formas de quebrar.** O `worker.js` compara
o horário **string a string** com o `wrangler.toml`, e o próprio arquivo avisa
que deixá-los divergir faz o ramo da coleta nunca disparar, caindo calado no
keep-alive do Supabase. Com dois horários esse risco dobra, e o log tem de
dizer qual versão disparou — um erro que não se vê é o modo de falha que esta
parte do sistema já teve uma vez.

**O re-disparo após falha isolada tem de saber qual versão falhou.** A regra
de hoje — redisparar uma falha isolada, nunca duas seguidas — continua, mas
redisparar a versão errada perderia a corrida boa e repetiria a má.

## Riscos, nomeados

**O 1.2.6 pode não valer o custo**, e a sondagem é o que permite decidir isso
antes de construir: sem patamares, o argumento é mais fraco do que o do 1.8.7,
mesmo sendo real. Se depois de pronto ninguém usar, o custo foi um parser.

**Trinta páginas é amostra pequena.** As frequências são estáveis o bastante
para escolher dimensões; a correlação de +0,38 não é número para publicar.

**Os rótulos de atributo são nossos e podem estar errados.** Um `fire` que
seja resistência e não dano elemental, por exemplo. Cada entrada da tabela é
uma afirmação a confirmar com quem joga.

**A raiz muda de significado**, e com ela a pré-visualização do link mais
partilhado do site.

## O que isto deliberadamente não faz

Não toca no `pw144` enquanto ele responder 500. Não porta cartas, runas,
anedotas nem relíquias para o 1.2.6 — não existem lá. Não unifica os dois
índices num arquivo só: são contratos diferentes, e juntá-los faria cada
versão carregar os campos da outra. E não prefixa as rotas do 1.8.7, pelo
motivo escrito acima.
