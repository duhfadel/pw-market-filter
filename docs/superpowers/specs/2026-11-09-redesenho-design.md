# O redesenho de Novembro

Seis telas desenhadas e acordadas com o dono a 08 e 09/11/2026, a partir de
uma referência que ele trouxe: a landing page de um jogo de fantasia, escura,
com um herói a sangrar por trás do texto e ouro no acento.

**A maquete viva está em `scratchpad/maquete/home.html`** e foi publicada como
artefacto durante a conversa. Ela mostra *o quê*; este documento existe para
guardar *o porquê*, que é a metade que não se deduz olhando.

Todos os números aqui foram medidos no índice e na base, com data. Nenhum é
estimativa.

---

## O que o redesenho tem de resolver

O dono nomeou quatro problemas, e escolheu os quatro:

1. **Falta impacto** — a home é correcta e não impressiona.
2. **Não se percebe o que é** — quem chega de um link não sabe o que o site faz.
3. **Parecem sites diferentes** — filtro, Registos, Runas, guias e mapa não
   partilham linguagem.
4. **Não convida a voltar** — nada na página muda de forma que interesse.

E acrescentou dois pedidos que mudam a arrumação, não a pintura: **guias em
todas as versões**, cada uma com os seus, e **uma lista de todos os guias**
independente da versão.

---

## A direcção: cinematográfico sóbrio

Arte de classe a sangrar em ecrã quase cheio, ouro só no que interessa,
tipografia grande, pouco ornamento. Impacto pela foto e pelo espaço, não pela
moldura.

**Foi escolhida contra uma alternativa ornamentada** — molduras entalhadas,
losangos nos separadores, filetes dourados — que é o vocabulário da
referência.

### A restrição que manda em tudo

A referência é a **landing page oficial de um jogo**: logótipo monumental ao
centro, *PLAY NOW*, *SHOP*, *DOWNLOAD*. Ela existe para vender o jogo.

O Portal PW não é o jogo. A The Classic deu **permissão para existir**, não
aval, e o `CLAUDE.md` trata como existencial qualquer coisa que arredonde isso
para «site oficial». Um herói centrado à volta de uma marca grande é
exactamente essa gramática.

**Daí a regra de composição:** a frase vem antes da marca, e a marca fica
pequena no canto. O que se tira da referência é a escuridão, o ouro como
acento único, a arte por trás do texto e a faixa de três itens sob o herói —
nunca a centralidade da marca.

---

## As seis telas

### 1. A raiz deixa de ser torniquete

Hoje `/` é a escolha de versão: três cartas, **148 palavras**, e foi
precisamente esta a página que o AdSense viu como vazia a 31/10.

Passa a ser uma home a sério:

| secção | |
|---|---|
| herói | *As contas que o jogo não faz* |
| apresentação | o que é o mercado de personagens |
| as três versões | como faixa viva, cada uma com o seu número |
| Todos os guias | com etiqueta de versão |
| O canal do Portal PW | banda inteira |
| Novidades | barra fechada com o último recado |
| Streamers amigos | secção própria |

**As versões ocupam o lugar da faixa viva**, e isso é o gesto central: deixa
de haver um clique que não informa. Medido a 08/11 às 21:10 — 1.8.7 com
**2.953** personagens e **197** entrados nesse dia, 1.2.6 com **1.483** e
**110**, e o 1.4.4 esmaecido a dizer que abre a 13 de novembro.

**A apresentação existe porque faltava a premissa.** Sem ela, «2.953 à venda»
é um número sem substantivo — quem chega de um link não sabe que o The Classic
deixa vender o personagem inteiro, com equipamento e cartas, que é a razão de
o site existir.

**A data da coleta aparece em todas as telas que mostram números**, e isto foi
uma falha da primeira maquete: um índice velho parece exactamente igual a um
fresco, e um filtro perfeito sobre dados do mês passado é pior do que filtro
nenhum, porque lê como certo.

#### O que ficou de fora da faixa, e porquê

*No preço mais baixo de sempre* parecia o terceiro número natural. **2.867 de
2.881 pessoas têm esse selo — 99,5%.** Um selo que quase toda a gente tem não
distingue ninguém; é a mesma razão que já reprovou chips do filtro.

#### Sem pílula de Vídeo

A barra da raiz é `Guias · Novidades`. Uma entrada de navegação para uma
secção da mesma página, de um canal sem vídeo nenhum, é promessa a mais.
*Novidades* ganha a dela porque muda sozinha e tem o ponto a avisar. A pílula
de Vídeo entra no dia em que houver vídeos e uma página a listá-los.

#### Guerras fora da raiz

O mapa e os vídeos de guerra são do 1.8.7 — territórios, guildas, aqueles
canais. Numa página que serve as três versões não têm lugar. Voltam à raiz no
dia em que outra versão tiver guerra.

### 2. A tela da versão

Herói com a frase do mercado — *Ache o personagem pelo que ele está usando* —
seguido de **O mercado agora** (os três números com o carimbo da coleta), as
seis portas dos Destaques, os guias desta versão e as guerras territoriais.

**O canal do Portal não se repete aqui.** É do site e não desta versão.

### 3. O filtro

Painel à esquerda (*sticky*, por decisão do dono), resultados à direita.

#### O cartão

- **A moldura diz o patamar da arma**, na escada que o projecto já fixou: 80
  vermelho, 70 dourado, 40 roxo, 30 não pinta, defensiva 80 verde.
- **O número nunca é o que se corta.** O nome da arma ellipsiza; o `+70` fica
  preso à direita.
- **Altura fixa por azulejo**, como o `mainAxisExtent` do `GridView` real —
  uma carta sem runas não encolhe, senão a grelha desalinha a cada linha.
- **A tira de equipamento**: catorze encaixes, sem nomes, a mesma gramática da
  tira de runas que já funciona. Medido: **2.177 dos 2.953** vestem as
  catorze, portanto a largura é estável.
- **Os encaixes vazios desenham-se.** Quem veste treze mostra um tracejado — o
  buraco diz *qual* peça falta, e isso é informação.
- **Sem números de refino na tira.** Foram experimentados: catorze algarismos
  de 7 px em fila lêem-se como ruído. O refino que importa — o da arma —
  continua escrito por extenso.
- **As runas ficam redondas** e o equipamento quadrado. Escolhido entre três
  saídas renderizadas lado a lado; separa pela forma sem custar os 12 px de
  altura que um fio custaria em todos os cartões.

#### O hover

Pedido do dono, para a versão web. Hoje **não existe hover nenhum** no cartão
— só um `InkWell` que abre o marketplace.

A bolha mostra **slot, nome com as estrelas, refino e os três maiores
atributos**. O nome nunca aparece sozinho: três armas partilham a palavra
*Dilacerador* e valem 30, 40 e 70.

Nas peças da direita a bolha ancora pelo outro lado, para não sair do cartão.

**Duas armadilhas medidas durante o desenho**, as duas já documentadas e as
duas em que caí:

- **Os nomes dos slots não se adivinham.** A numeração aqui não bate com a do
  cliente padrão. Ler `slot_names.dart`, nunca supor.
- **Não cortar atributos a meio.** O mais longo do mercado tem **80
  caracteres** e cabe; um limite arbitrário fez *«seus ataques têm chance»*
  acabar ali, e isso lê-se como avaria.

### 4. Todos os guias

Oito guias, sete em HTML e o *Multi contas* dentro da app. Filtro por versão
em cima, etiqueta em cada carta, tempo de leitura medido do próprio ficheiro.

**A Saga do Herói não mostra minutos.** Somar as dezoito páginas dava «81 min
de leitura», que ninguém lê e que parece avaria. Diz *17 classes, uma página
cada* — a medida certa para um conjunto, não para um artigo.

### 5. Títulos

Oito colunas porque a janela do jogo tem oito, inclusive no telemóvel.

**`ordem` é o número do encaixe, não a enésima receita.** A aba *Coletar* tem
16 receitas nos encaixes 1–10 e 17–22: os **seis buracos de 11 a 16** são
reais e desenham-se em tracejado, porque é o que segura os ícones seguintes no
lugar.

**`sem_dados` não é o mesmo que zeros.** 27 das 126 receitas ainda não têm
bónus levantado, e um zero ali seria o site afirmar que a receita não dá nada.

**Os totais somam dentro de cada atributo, nunca entre atributos.** Juntar
Atk F com Esquiva faria um número que não é quantidade de nada.

### 6. Novidades

Lista dos recados, com filtro por versão.

**Dois defeitos reais encontrados ao desenhar**, os dois visíveis no site hoje
e nenhum deles bug do código:

- O recado de **29/10** começa com `***1.8.7 adicionamos…` — três asteriscos
  sem fecho. `_tituloPattern` exige a primeira linha inteiramente em negrito,
  logo não vira título e os asteriscos saem literais.
- O de **22/09** usa `*Relíquias e chaves*` e `*Maior fama*`. `_marcacao` só
  conhece `**negrito**` e links; o itálico sai literal.

O site mostra o que foi escrito em vez de engolir em silêncio, e isso é
deliberado. **A correcção é editar no Discord** e chega em cinco minutos sem
deploy.

**A convenção dos marcadores nunca foi usada: zero em sete.** A linha `[1.8.7]`
existe desde 27/10 e o recado de 29/10, dois dias depois, escreveu a versão
dentro do texto. Sem marcador fica vazio, nunca «para todos».

---

## Os guias por versão: a decisão que custa mais se for errada

**A versão é um campo do guia, não um pedaço do endereço.**

`/guias/runas` fica onde está. Cada guia declara a que versões serve — ou
`todas` — e cada versão do site mostra os seus. O *Todos os guias* é
simplesmente não filtrar.

**Porquê, e é a parte a não esquecer:** as 24 páginas de guia foram indexadas
na semana de 02/11, e é disso que depende o pedido de revisão do AdSense.
Mudar para `/1.8.7/guias/runas` moveria 24 endereços recém-indexados no mês em
que o Google está a decidir se o site tem valor — e o GitHub Pages não faz
redirecionamento de servidor.

Medido: os guias de hoje são quase todos de 1.8.7 **sem o dizerem**. A Saga
tem 17 classes e o 1.2.6 tem seis; runas, conduíte, astrolábio e cartas Nuema
são conteúdo de 1.8.7. Só o *Multi contas* serve as três.

---

## Os streamers por versão

Pedido: no 1.8.7 só quem joga 1.8.7, e assim por diante.

**A versão vem do título da transmissão**, ideia do dono e melhor do que um
campo na tabela. A Twitch só diz *Perfect World* e não distingue versão; o
título é reescrito a cada transmissão, portanto quem muda de versão muda
sozinho. Um campo envelheceria em silêncio — e o site só mostra quem está **ao
vivo**, logo o título existe exactamente quando é preciso.

Medido a 09/11: o único canal em directo era o `magraotvv`, com *THE CLASSIC
PW 1.4.4 BETA ABERTO* no título. A regra funciona no caso real, e de passagem
revelou que o beta do 1.4.4 já estava aberto antes do dia 13.

**Sem versão no título, não aparece numa página de versão** — decisão do dono.
Continua na raiz, que não é de versão nenhuma e por isso não afirma nada.

**Decisões minhas, baratas de mudar:** um título que nomeia duas versões conta
como não saber e não entra em nenhuma; o casamento é conservador (as formas
com pontos, e números soltos só com fronteira de palavra) porque **falsos
positivos são o único dano real** — não mostrar alguém custa visibilidade,
mostrá-lo na versão errada é o site a afirmar o que não sabe.

**O título é lido e nunca mostrado.** Está cheio de cupões e emoji, e já tinha
sido deixado de fora do cartão por isso.

---

## O que faz voltar amanhã

**A faixa viva**, e os dados já existem. `firstSeen` e `previousPrice` são
recolhidos desde **30/09** e nunca apareceram na tela.

Medido a 08/11: **197 entraram hoje**, 430 em três dias, 914 em sete; **564
baixaram o preço**, com quedas de −94%, −57% e −33%.

É a única coisa na página que muda sozinha todos os dias.

---

## Fora do redesenho

**O mapa das guerras.** Não é problema de desenho: a máquina está construída —
os 52 territórios desenham-se, a leitura do Supabase funciona, a página é
`noindex` e avisa que é prévia. O que falta são **dados reais e alguém a
mantê-los**. Os donos actuais são `DEMO Chama`, `DEMO Jade` e `DEMO Corvos`, e
a última «conquista» é de **18 de agosto**. Redesenhar seria pintar uma casa
vazia.

Consequência: a secção de guerras na tela do 1.8.7 fica **só com os vídeos**,
que são reais — 49, de 13 canais.

**A calculadora de runas.** Desenhada e depois parada pelo dono, que quer
repensá-la. A tela fica na maquete e fora desta spec.

---

## Por onde começar

Escolhido o caminho incremental: **a home primeiro**, e o resto herda a
linguagem depois.

A primeira fatia de código deve ser o que é pequeno, independente e já está
pago:

1. **A faixa viva do mercado** — dados recolhidos há seis semanas, nunca
   mostrados, e é a resposta ao «não convida a voltar».
2. **Os guias por versão** e a página *Todos os guias* — nenhum endereço mexe.

As duas sobem sozinhas e dão valor antes de o redesenho inteiro existir.

---

## O que fica por decidir

- **O número do 1.2.6 ao lado do 1.8.7** na raiz: 1.483 contra 2.953 é
  honesto, e também diz «o outro é metade».
- **A arte do herói na raiz** é de uma classe de 1.8.7, numa página que serve
  as três versões.
- **A bolha do hover tapa o próprio cartão** enquanto está aberta. Pode ir ao
  lado em vez de por cima.
- **Os streamers aparecem na raiz e na tela da versão.** Duplicação aceite por
  agora.
- **A ordem das secções da raiz** — guias, vídeo, novidades, streamers.
- **O chip *Até 100 TCC* está em 53,9%** e o *Arma de 70* em 46,6%, ambos a
  subir. São decisões de produto, à vista dos números que a suíte agora
  imprime em cada corrida.
