# As duas portas: a escolha, o 1.2.6 na tela, e a poda

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> to implement this plan task-by-task.

**Goal:** `/` passa a ser a escolha entre as duas versões; `/1.8.7` e `/1.2.6`
são as duas homes; o filtro do 1.2.6 existe, **podado** do que aquele jogo não
tem; e nenhum link já partilhado quebra.

**Architecture:** A app já é cega à versão — provado em 01/10/2026 servindo o
índice do 1.2.6 no lugar do outro: o filtro abriu, construiu as faixas de
preço a partir dos dados, listou as seis classes e desenhou os cards com os
nomes de arma daquele jogo, **sem uma linha alterada**. O que falta não é
generalizar: é **escolher qual índice carregar** e **parar de desenhar o que
não existe**.

**Tech Stack:** Flutter web, Bloc, GetIt. Sem dependência nova.

**Spec:** `docs/superpowers/specs/2026-10-01-duas-versoes-design.md`, com três
decisões do dono tomadas depois dele, em 01/10, que **mandam** onde divergirem:

1. **Só duas cartas no 1.2.6** — o mais barato e o mais caro. *"No momento a
   gente não sabe o que é importante no 1.2.6 para fazer novos filtros"*. O
   recado é que **dá para filtrar**, não um ranking que ninguém pediu.
2. **As rotas levam os pontos** — `/1.8.7` e `/1.2.6`, e o filtro do 1.8.7
   passa a ser `/1.8.7/filtro` com `/filtro` a redirecionar para sempre.
3. **A home de hoje continua a ser a raiz até a tela de escolha existir**, e o
   coletor do 1.2.6 já corre em produção sem nada apontar para ele.

## O que foi medido, e o que isso corta

Sobre os 1.293 personagens colhidos em 01/10:

| No 1.8.7 | No 1.2.6 | Consequência |
|---|---|---|
| cartas equipadas | **0** | sai *Seis cartas S* e *Portal de Nuema* |
| runas | **0** | sai a secção inteira |
| anedotas | **0** | sai a secção e a ordem |
| itens contados | **0** | sai *5 essências*, sai *Itens da mochila* |
| reino celestial | **0** | sai a secção |
| caminho God/Evil | **0** | planeado; falta a âncora — ver abaixo |
| sexo | 824 M / 469 F | **fica** |
| cultivo | 13 valores | **fica** |
| 11 slots, 165 armas distintas | | **fica**, com tabela de nomes própria |

**O caminho não é "não existe": é "não há o que ler".** O 1.8.7 deteta-o por
`Erupção Celestial` contra `Erupção Demoníaca` — nomes de perícia. No 1.2.6 o
painel de perícias traz `data-skill-id="1"`, `"2"`, `"3"` com nível e imagens
numeradas, e **nenhum texto**. `Erup` não aparece em nenhuma das trinta
páginas sondadas.

As pistas que parecem o caminho são **falsos positivos** e são exatamente os
que o `CLAUDE.md` já regista para o 1.8.7: `sage` casa dentro de
*Men**sage**iro*, e `Sagrado`/`Demoníaco` são nomes de item — *Colar do Osso
Sagrado*, *Lorde Demoníaco*.

**O caminho FICA no plano — decisão do dono em 01/10 — e entra assim que
houver sinal.** O que falta é a âncora: dois personagens da mesma classe e do
mesmo nível, um sabidamente God e outro sabidamente Evil. Com esses dois, o
id sai por diferença entre os conjuntos de perícias em segundos, e a deteção
passa a ser por número em vez de por nome.

**O que já foi tentado e não serviu, para ninguém repetir:** procurei um id
que dividisse cada classe ao meio, sobre trinta páginas. Os candidatos
`158`–`161` aparecem em Arqueiro, Feiticeira e Sacerdote — comuns, não de
classe — mas **não são exclusivos**: treze dos trinta têm os quatro ao mesmo
tempo. São quase de certeza perícias de nível alto, e o que separa quem as
tem é o nível, não o caminho. A sondagem também não conseguiu ler o nível
daquelas páginas, então essa hipótese ficou por testar — é um buraco na
medição, não um resultado.

**Até haver âncora, a secção não se desenha.** Um filtro que devolve nulo
para toda a gente é pior que a ausência dele; e um id adivinhado dividiria o
mercado em dois grupos errados com toda a confiança, que é pior ainda.

## Global Constraints

- **Nenhuma cor inline.** Toda cor é `static const` em `PWColors`; a única
  exceção é `Colors.transparent`.
- **Marcellus desenha algarismos romanos** — seu `0` mal se distingue de `O`.
  `PWTheme.display` é só para títulos e nomes; **nenhum número** cai nele.
  Isto morde duas vezes aqui: o rótulo da versão (`1.8.7`) e as contagens na
  tela de escolha.
- Comentários, docstrings e nomes de teste em **inglês**. Identificadores
  podem ser portugueses. A UI é portuguesa.
- `lib/` nunca importa `dart:io`.
- Nenhuma dependência nova.
- **Roteamento pertence ao `MaterialApp`**, nunca a um `Navigator` aninhado.
- `dart format lib/ test/`; `flutter analyze` termina com `No issues found!`.
- Em `flutter_test` todo glifo é um quadrado do tamanho da fonte: o harness
  **fabrica** overflows que navegador nenhum tem. Nunca encolha um layout para
  calar um — carregue as fontes reais com `FontLoader` num `setUpAll`.
- A suíte está em **603 verde**.

---

### Task 1: A app escolhe qual índice carregar

**Files:**
- Modify: `lib/market/index_repository.dart`
- Modify: `lib/core/di/injection.dart`
- Test: `test/market/index_repository_test.dart`

`IndexRepository.fileName` é hoje a constante `'market_index.json'`. É por
aqui que a app encontra os dados, e é o único lugar que ainda presume uma
versão.

**O que fazer:** o repositório passa a receber a versão e a derivar o arquivo
— `market_index.json` para o 1.8.7 e `market_index_126.json` para o 1.2.6.
**Mantenha o nome do 1.8.7 exatamente como está**: é o arquivo que está no ar
agora, e mudá-lo partiria o site no mesmo deploy.

**O `?t=<millis>` continua**, e não é detalhe: ele é o que impede o navegador
de servir o índice de ontem, e um índice velho é invisível quando acontece.

- [ ] **Step 1: O teste que falha** — que cada versão resolve o seu arquivo, e
que o do 1.8.7 é byte a byte o que era.
- [ ] **Step 2: Rode e veja falhar**
- [ ] **Step 3: A implementação**, incluindo o registo no GetIt.
- [ ] **Step 4: Suíte inteira, analyze, commit**

---

### Task 2: As rotas, e o link antigo que não pode quebrar

**Files:**
- Modify: `lib/main.dart`
- Create: `lib/core/rotas.dart`
- Test: `test/rotas_test.dart`

```
/                    a escolha
/1.8.7               a home do 1.8.7
/1.8.7/filtro        o filtro         ← canónica daqui para a frente
/filtro?...          redireciona      ← links já partilhados, para sempre
/1.8.7/registros     Títulos
/1.8.7/runas         Runas
/1.2.6               a home do 1.2.6
/1.2.6/filtro        o filtro do 1.2.6
/novidades           uma só, serve as duas
```

**Três coisas que o redirecionamento tem de fazer, e falhar em qualquer uma
é pior do que não redirecionar:**

1. **Levar a busca junto.** Um link antigo não é `/filtro` — é
   `/filtro?c=...&ordem=...` com a pesquisa inteira codificada. Chegar ao
   filtro vazio faria a pessoa pensar que a busca deixou de funcionar.
2. **Substituir no histórico, não empilhar.** Senão o botão voltar devolve ao
   link antigo, que redireciona outra vez, e a pessoa fica presa.
3. **Valer para sempre.** Não é migração; é um ponteiro permanente.

**`/novidades` fica sem prefixo**, e isso é deliberado: ela fala do site, não
de uma versão. Já foi construída sem tocar no `MarketIndex` exatamente por
isto.

- [ ] **Step 1: Os testes que falham** — um por linha da tabela, mais um que
prova que `/filtro?c=10~0~70` chega a `/1.8.7/filtro` **com os parâmetros
intactos**, mais um que prova que não empilha.
- [ ] **Step 2: Rode e veja falhar**
- [ ] **Step 3: A implementação**
- [ ] **Step 4: Confira na barra de endereços de uma build a correr.** Uma
captura de tela não vê este defeito: um `Navigator` aninhado navega perfeito e
nunca muda a URL.
- [ ] **Step 5: Suíte inteira, analyze, `flutter build web`, commit**

---

### Task 3: A tela de escolha

**Files:**
- Create: `lib/features/portas/ui/portas_view.dart`
- Create: `lib/features/portas/domain/versao.dart`
- Test: `test/portas/portas_view_test.dart`

Duas portas. Cada uma mostra, e **só**: o nome da versão, **quantos
personagens estão à venda agora** e **quando foi a última coleta**.

**A contenção é a decisão.** A tela existe para desviar quem ainda não sabe
onde quer ir; **nenhum link da comunidade passa por ela**, porque todos
apontam para uma versão. Quem chega aqui já está no site — não há nada para
vender, só uma pergunta a responder.

**Ela não pode baixar os dois índices para mostrar dois números.** São ~4 MB
cada. O coletor já escreve `web/versoes.json`, minúsculo, uma linha por
versão. A tela lê **só isso**.

Uma versão sem índice aparece **esmaecida e com *em breve***, a mesma regra
que `Tool.isReady` já aplica: a porta mostra a forma do lugar antes de o lugar
existir.

**As `og:` tags da raiz mudam**, e isto é fácil de esquecer: `portalpw.net` é
o link mais partilhado do site e deixa de abrir o mercado. A pré-visualização
no Discord tem de passar a dizer o que o site é — duas versões, dois mercados
— em vez de herdar as do 1.8.7.

- [ ] **Step 1: Os testes que falham** — as duas portas; uma versão sem
índice esmaecida; nenhum número em Marcellus; e que a tela **não** carrega
índice nenhum.
- [ ] **Step 2 a 4:** rode, implemente, verde.
- [ ] **Step 5: Suíte inteira, analyze, commit**

---

### Task 4: A home do 1.2.6, com duas cartas

**Files:**
- Modify: `lib/features/home/domain/destaques.dart`
- Modify: `lib/features/home/ui/home_view.dart`
- Test: `test/home/destaques_126_test.dart`

**Duas cartas, não seis: o mais barato e o mais caro.** Decisão do dono em
01/10. As outras quatro que o índice sugeria — mais arma por TCC, maior dano,
maior defesa, maior resistência ao fogo — **não entram**, porque ninguém sabe
ainda o que importa naquele mercado, e seis cartas afirmando um ranking que
não foi pedido é o site a fingir que entende daquele jogo.

As duas que ficam não pedem conhecimento nenhum: preço é preço.

**A regra das classes distintas continua a valer** e aqui aperta: são seis
classes, não dezassete. Medido em 01/10 com as seis cartas, o Guerreiro ganhou
duas e o rótulo teve de amolecer. Com duas cartas a colisão é menos provável,
mas não impossível — e o amolecimento fica.

**O Cartaz do 1.2.6 usa a mesma arte**: as seis classes daquele jogo são as
clássicas e **todas as seis já estão em `assets/images/classes-verticais/`**.
Conferido um a um em 01/10. Zero arte nova.

- [ ] **Step 1: Os testes que falham** — duas cartas, nunca seis, sobre o
índice real do 1.2.6; as duas de classes distintas; e um mercado vazio
desenha zero cartas sem lançar.
- [ ] **Step 2 a 5:** rode, implemente, verde, commit.

---

### Task 5: A poda — parar de desenhar o que não existe

**Files:**
- Modify: `lib/features/search/domain/presets.dart`
- Modify: `lib/features/search/ui/search_view.dart` e os seus painéis
- Modify: `lib/market/slot_names.dart`
- Modify: `lib/features/home/ui/widgets/cabecalho.dart`
- Test: `test/search/poda_126_test.dart`

**A regra já existe no site e é a mesma: todo controlo lê as suas opções do
que o mercado tem, e uma secção sem opções não se desenha.** O que falta é
obedecê-la nas famílias que presumem o 1.8.7.

**Os chips.** `weaponQuery` já devolve `null` quando a coleta não tem o
atributo, e por isso um chip de arma some sozinho. Estenda a mesma forma às
outras famílias: *Seis cartas S*, *Portal de Nuema* e *5 essências* têm de
**não existir** no 1.2.6, em vez de existir e achar zero. O `CLAUDE.md` já diz
porquê — um chip que não acha ninguém ensina que o site está partido.

**As secções.** Cartas, runas, anedotas, itens da mochila e reino celestial
somem quando o índice não os tem.

**O caminho sai** enquanto não houver como detetá-lo. Veja a nota no topo:
não se inventa.

**Os onze slots do 1.2.6 precisam de tabela própria, e isto é armadilha.** O
`CLAUDE.md` regista que a numeração daqui **não bate com a do cliente
padrão** — assumir que o slot 10 é a mesma peça nos dois jogos é exatamente o
erro que aquela nota existe para impedir. Medido em 01/10: slot 10 tem 165
itens distintos e é a arma; os outros dez vão de 38 a 102. Nomeie o que os
dados tornam inequívoco e deixe o resto cair no `Slot N` com o item mais
comum, como já se faz.

**E o `1.8.7` cravado** em `cabecalho.dart:172` passa a ser a versão da tela.

- [ ] **Step 1: Os testes que falham** — nenhum chip do 1.2.6 devolve zero;
as secções ausentes não se desenham; o cabeçalho diz a versão certa em cada
tela; e **o 1.8.7 não perde nada** — este é o teste que importa mais, porque
a poda é onde se parte a versão que já está no ar.
- [ ] **Step 2 a 4:** rode, implemente, verde.
- [ ] **Step 5: Suíte inteira, analyze, `flutter build web`, commit**

---

## Pendente do 1.8.7, decidido em 01/10: a carta das relíquias

**A carta *Mais Chaves da Sorte* sai, e no lugar entra a soma das três
relíquias** — Artefato, Arma e Armadura. Decisão do dono: *"estas são as
importantes, as chave da sorte não"*.

**A medição concorda, e por um motivo mais forte que o enunciado.** Sobre os
1.666 personagens de 01/10:

| | Carregam | Mediana | Topo |
|---|---|---|---|
| soma das três relíquias | **1.653 (99%)** | 74 | 595 |
| Chave da Sorte | 875 (53%) | 1 | 3.977 |

A soma das três é uma **escala contínua onde quase toda a gente está**, e por
isso ordena o mercado inteiro. A Chave não: o `CLAUDE.md` já regista que
metade de quem a tem carrega exatamente uma e que 655 dos 875 vivem no
primeiro 1,3% da sua faixa. Isso não é uma escala, é um acumulador — diz mais
sobre quem nunca gastou do que sobre o personagem.

Vencedor de hoje: **Sarsfield**, 595 relíquias (194 + 200 + 201), 700 TCC,
Arqueiro. A repartição quase igual entre as três é sinal de que a soma mede o
que se quer: não é alguém que empilhou uma só.

**Somar as três é legítimo e a regra já está escrita:** atributos somam-se
*dentro* de um atributo, e as três relíquias são a mesma pergunta feita de
três maneiras — é o que a `buscaInicial` já diz ao marcar as três de uma vez.
O que nunca se soma é um atributo a outro, e aqui isso não acontece.

**O selo da carta é a soma, e a nota deve decompô-la.** Um total que ninguém
consegue decompor é um total que ninguém consegue conferir — a mesma razão
pela qual `countedItemNotes` existe.
