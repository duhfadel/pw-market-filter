# Os Destaques e a barra com gaveta

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> to implement this plan task-by-task.

**Goal:** Trocar a Vitrine de três cards por seis cartas verticais altas — cada
uma respondendo uma pergunta do mercado — e dar peso à barra de Ferramentas,
Guias e Novidades com pílulas que abrem gaveta.

**Architecture:** As artes de classe ganham uma segunda pasta, vertical (480×720),
porque o quadrado de 560 só mostra o busto e a carta alta precisa do corpo. O
domínio novo (`destaques.dart`) escolhe seis personagens, um por categoria, e a
tela desenha seis cartas 2:3 com a arte sangrando e o rótulo no rodapé. O
cabeçalho troca o menu de texto por pílulas com gaveta.

**Tech Stack:** Flutter web, Bloc, GetIt. Sem dependência nova.

**Spec:** `docs/superpowers/specs/2026-09-29-cara-nova-design.md` — esta é a
revisão aprovada pelo dono em 30/09 e 01/10, depois de quatro rodadas de
maquete. O que mudou em relação ao spec: a Vitrine deixa de argumentar "o mesmo
patamar, sessenta vezes o preço" e passa a ser seis portas de entrada.

## Global Constraints

- **Nenhuma cor inline.** Toda cor é `static const` em `PWColors`. A única
  exceção é `Colors.transparent`.
- **Marcellus desenha algarismos romanos** — seu `0` mal se distingue de `O` e
  seu `1` não tem bandeira. `PWTheme.display` é só para títulos e nomes;
  **nenhum número** pode cair nele. Todo preço, contagem e nível fica na Inter.
- Comentários, docstrings e nomes de teste em **inglês**. Identificadores podem
  ser portugueses. A UI é portuguesa.
- `lib/` nunca importa `dart:io`.
- Nenhuma dependência nova.
- `dart format lib/ test/` antes de cada commit.
- `flutter analyze` tem de terminar com `No issues found!`.
- Em `flutter_test` todo glifo é um quadrado do tamanho da fonte, então o
  harness **fabrica** overflows que navegador nenhum tem. Nunca encolha um
  layout para calar um: carregue as fontes reais com `FontLoader` num
  `setUpAll`, como `test/home/cartaz_test.dart` já faz.
- A suíte está em **539 verde**.

---

### Task 1: A arte vertical

**Files:**
- Modify: `pubspec.yaml` (declarar `assets/images/classes-verticais/`)
- Modify: `lib/features/home/domain/arte_da_classe.dart`
- Modify: `lib/features/home/ui/widgets/cartaz.dart`
- Test: `test/home/arte_da_classe_test.dart`

**Interfaces:**
- Produces: `String? arteVerticalDaClasse(String classe)` — caminho da arte
  480×720, `null` para classe sem arte.
- Consumes: o mapa `_classes` que já existe — **esse é o nome real**, e cada
  entrada carrega `.arquivo` (nome sem extensão) e `.magenta`. Não há `_artes`.

Os 17 arquivos **já estão em disco** em `assets/images/classes-verticais/`,
mesmos nomes de arquivo da pasta quadrada. Não os gere.

- [ ] **Step 1: Teste que falha**

```dart
test('every class with square art also has vertical art', () {
  for (final classe in classesComArte) {
    expect(arteVerticalDaClasse(classe), isNotNull, reason: classe);
    expect(arteVerticalDaClasse(classe), contains('classes-verticais'));
  }
});

test('a class nobody has art for draws nothing', () {
  expect(arteVerticalDaClasse('Nenhuma'), isNull);
});
```

- [ ] **Step 2: Rode e veja falhar** — `flutter test test/home/arte_da_classe_test.dart`

- [ ] **Step 3: A implementação**

```dart
/// The tall crop, 480×720, for a card whose art is the card.
///
/// A second folder rather than a second size of the first: the square 560 is a
/// bust, cropped to put the face a fifth from the top, and a 2:3 card filled
/// with it shows a head and no body. These were re-cut from the original
/// phone captures — which is why the two folders can hold the same class under
/// the same file name and still not be the same picture.
String? arteVerticalDaClasse(String classe) {
  final entrada = _classes[classe];
  return entrada == null
      ? null
      : 'assets/images/classes-verticais/${entrada.arquivo}.webp';
}
```

- [ ] **Step 4: Declare no `pubspec.yaml`**, ao lado de `assets/images/classes/`:

```yaml
    - assets/images/classes-verticais/
```

- [ ] **Step 5: O Cartaz passa a usar a vertical.** Em `cartaz.dart`, troque a
chamada de `arteDaClasse` por `arteVerticalDaClasse`, e o `alignment` da
imagem para `Alignment(0, -0.72)` — a arte vertical põe o rosto bem mais alto
que o quadrado, e o `-0.6` atual, pensado para o quadrado, cairia no peito.
Mantenha o `null` desenhando nada, como já faz.

- [ ] **Step 6: Confira em disco** — isto é o que teste nenhum pega:

```bash
for f in andarilho arcano arqueiro atiradora barbaro bardo ceifador \
  espiritualista feiticeira guerreiro mago mercenario mistico paladino \
  retalhador sacerdote tormentador; do
  [ -f "assets/images/classes-verticais/$f.webp" ] || echo "FALTA $f"
done; echo "fim"
```

- [ ] **Step 7: Suíte inteira, analyze, commit**

---

### Task 2: `destaques.dart` — quais seis, e por quê

**Files:**
- Create: `lib/features/home/domain/destaques.dart`
- Test: `test/home/destaques_test.dart`

**Interfaces:**
- Produces: `class Destaque` e `List<Destaque> destaquesDe(MarketIndex index)`.
- Consumes: `runQuery` (`matcher.dart`), `strongWeaponQuery`/`weaponQuery`
  (`presets.dart`), `MarketIndex.countOf`, `MarketIndex.countedItems`.

**As seis categorias, nesta ordem:**

| # | Rótulo | Quem | Moldura | Selo |
|---|---|---|---|---|
| 1 | O mais barato | menor preço do mercado | `gradeColors[0]` | — |
| 2 | Arma de 70 mais barata | menor preço com Nível de Ataque ≥ 70 | `gradeColors[3]` | ARMA 70 |
| 3 | Atq lvl UP5 mais barato | menor preço com Nível de Ataque ≥ 80 | `gradeColors[6]` | ATQ UP5 |
| 4 | Def lvl UP5 mais barato | menor preço com Nível de Defesa ≥ 80 | `defenceTier` | DEF UP5 |
| 5 | O mais caro | maior preço do mercado | `accent` | — |
| 6 | Mais Chaves da Sorte | maior `countOf` de `Chave da Sorte` | `gradeColors[2]` | a contagem |

- [ ] **Step 1: Os testes que falham**

```dart
test('six categories on the real market, all of distinct classes', () {
  final index = lerIndiceReal();          // web/market_index.json
  final seis = destaquesDe(index);

  expect(seis, hasLength(6));
  final classes = seis.map((d) => d.personagem.characterClass).toList();
  expect(classes.toSet(), hasLength(6),
      reason: 'two cards of one class show the same art twice: $classes');
});

test('an empty market draws no cards rather than throwing', () {
  // `MarketIndex` exige server, collectedAt, attributes, items e characters —
  // não existe construtor de um campo só. Escreva um helper `indiceVazio()`.
  expect(destaquesDe(indiceVazio()), isEmpty);
});

test('a category nobody fills is dropped, not faked', () {
  // Nobody at 80: the UP5 cards cannot exist, and the others still do.
  final index = indiceOnde(ataqueMaximo: 70);
  final rotulos = destaquesDe(index).map((d) => d.rotulo);
  expect(rotulos, isNot(contains(contains('Atq lvl UP5'))));
  expect(rotulos, contains(contains('O mais barato')));
});

test('the label softens when a class collision pushes past the true winner', () {
  // Two categories whose real winner is the same person: the second says
  // "dos mais baratos", never "o mais barato", because it no longer is.
  final seis = destaquesDe(indiceComColisao());
  final empurrado = seis.firstWhere((d) => d.rotulo.contains('dos mais'));
  expect(empurrado.rotulo, isNot(contains('o mais')));
});
```

- [ ] **Step 2: Rode e veja falhar**

- [ ] **Step 3: A implementação**

O ponto delicado é a **regra das classes distintas**, e ela é decisão do dono
tomada em 01/10. Escreva-a assim:

```dart
/// One card of the front page's six: a question about the market, already
/// answered by somebody real.
class Destaque {
  const Destaque({
    required this.rotulo,
    required this.personagem,
    required this.nota,
    required this.cor,
    required this.busca,
    this.selo,
  });

  /// What this card answers. Softens from *o mais barato* to *dos mais
  /// baratos* when a class collision pushed it past the true winner — see
  /// [destaquesDe]. A label that still claimed "the cheapest" after moving
  /// off the cheapest would be the card lying about itself.
  final String rotulo;
  final MarketCharacter personagem;

  /// The line under the price, and it must be derivable from this collection.
  final String nota;

  /// The frame, from the game's own rarity palette — the same colours the
  /// results card already paints, so somebody arriving at the filter
  /// recognises them.
  final Color cor;

  /// Where tapping leads. Every card is a door into the filter.
  final SearchQuery busca;

  /// The corner badge. `null` draws none.
  final String? selo;
}

/// The six characters the front page shows, one per question.
///
/// **No two cards may share a class, and that is not a nicety.** The art is
/// the card here, so two cards of one class are two identical pictures side by
/// side — which promises a difference that is not there, the same defect as
/// the pet eggs sharing one sprite. Measured on 2026-09-30: the Arcano was
/// simultaneously the cheapest carrier of a 70 weapon *and* the cheapest
/// carrier of the defensive UP5, so the collision is not hypothetical.
///
/// When a category's true winner is already on screen, the card falls to the
/// next cheapest of a class nobody has used, **and its label softens** — *o
/// mais barato* becomes *dos mais baratos*, because it no longer is the
/// cheapest and a card that says otherwise is lying with a real number
/// beside it. A category with no untaken class left is dropped rather than
/// repeated.
///
/// Empty is an answer: a market with nobody at a tier draws fewer cards, never
/// a hole and never an exception.
List<Destaque> destaquesDe(MarketIndex index) { … }
```

Regras de implementação, todas obrigatórias:

- Percorra as seis categorias **na ordem da tabela**. A ordem decide quem cede
  numa colisão, e é por isso que ela é fixa e não alfabética.
- Cada categoria produz uma **lista ordenada de candidatos**, não um só. A
  colisão precisa do próximo.
- `usadas` é um `Set<String>` de classes já na tela.
- O rótulo suave: guarde os dois textos por categoria (`o mais barato` /
  `dos mais baratos`) e escolha pelo fato de ter havido empurrão. Nunca derive
  o texto com `replace` sobre o outro.
- A nota do **mais caro** é condicional e derivada: se o nível de ataque dele
  for menor que o patamar de 70, a nota é `'E não é o mais forte'`; senão é
  `'O topo do mercado'`. Escrever a primeira incondicionalmente seria uma
  frase que a coleta pode desmentir amanhã.
- A nota do **Atq lvl UP5** e do **Def lvl UP5** conta quantos existem:
  `'${n} no mercado inteiro'`. Derive `n`, nunca escreva.
- O selo da carta das chaves é a **contagem**, formatada com separador de
  milhar, e vem de `countOf`.
- `busca` de cada carta é a `SearchQuery` que o filtro abriria. Use
  `weaponQuery` para as de arma; a de chaves usa `shownOwned`.

- [ ] **Step 4: Verde**
- [ ] **Step 5: Suíte inteira, analyze, commit**

---

### Task 3: `DestaquesView` — as seis cartas

**Files:**
- Create: `lib/features/home/ui/widgets/destaques_view.dart`
- Test: `test/home/destaques_view_test.dart`

**Interfaces:**
- Consumes: `destaquesDe`, `Destaque`, `arteVerticalDaClasse`.
- Produces: `class DestaquesView extends StatelessWidget` com
  `const DestaquesView({required this.index, required this.wide, required this.onAbrir, super.key})`,
  onde `onAbrir` é `void Function(SearchQuery)`.

**A carta:** proporção **2:3**, arte preenchendo (`BoxFit.cover`,
`Alignment(0, -0.76)`), um véu que escurece só o terço de baixo para o texto
ter onde pousar, e no rodapé — nesta ordem — rótulo, nome, `nv X · Classe`,
preço, nota. O selo no canto superior esquerdo quando houver.

**Largura:** seis colunas em tela larga, três no meio, **duas no telefone**.
Nunca uma — duas cartas 2:3 lado a lado a 390 px ainda mostram o corpo, e uma
coluna só faria seis telas de rolagem.

- [ ] **Step 1: Os testes que falham**

```dart
testWidgets('the price is on the body face, never Marcellus', (tester) async {
  await _montar(tester, index: indiceDeTeste());
  final preco = tester.widget<Text>(find.textContaining('TCC').first);
  expect(preco.style?.fontFamily, isNot(PWTheme.display),
      reason: 'Marcellus draws Roman figures: 150 TCC reads I5O TCC');
});

testWidgets('tapping a card asks for that card's search', (tester) async {
  SearchQuery? pedida;
  await _montar(tester, onAbrir: (q) => pedida = q);
  await tester.tap(find.byType(InkWell).first);
  expect(pedida, isNotNull);
});

testWidgets('an empty market draws no section at all', (tester) async {
  await _montar(tester, index: indiceVazio());
  expect(find.byType(DestaquesView), findsOneWidget);
  expect(find.textContaining('TCC'), findsNothing);
});

testWidgets('two columns on a phone, not one', (tester) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await _montar(tester, wide: false);
  // As duas primeiras cartas partilham a mesma linha.
  final a = tester.getTopLeft(find.byType(Card).at(0));
  final b = tester.getTopLeft(find.byType(Card).at(1));
  expect(b.dy, a.dy);
});
```

- [ ] **Step 2: Rode e veja falhar**
- [ ] **Step 3: A implementação.** Carregue as fontes reais no `setUpAll` do
teste — ver `test/home/cartaz_test.dart`.
- [ ] **Step 4: Verde**
- [ ] **Step 5: Suíte inteira, analyze, commit**

---

### Task 4: A barra com gaveta, e a página montada

**Files:**
- Modify: `lib/features/home/ui/widgets/cabecalho.dart`
- Modify: `lib/features/home/ui/home_view.dart`
- Delete: `lib/features/home/ui/widgets/vitrine_view.dart`,
  `lib/features/home/domain/vitrine.dart`,
  `test/home/vitrine_view_test.dart`, `test/home/vitrine_test.dart`,
  `test/home/vitrine_real_market_test.dart`
- Test: `test/home/cabecalho_test.dart`, `test/home/home_ordem_test.dart`

**A barra:** cada entrada vira uma pílula com moldura, e *Ferramentas* e
*Guias* **abrem gaveta ao toque** — nunca só ao passar o rato, porque metade de
quem chega vem do Discord no telefone e lá não há rato. A pílula mostra
**quantos** há dentro, e conta só o que está pronto: uma ferramenta com
`isReady == false` não entra no número, senão o rótulo promete três e a gaveta
entrega duas. Cada item da gaveta leva uma linha de descrição — *Títulos*
sozinho não diz nada a quem nunca usou.

Clicar fora fecha. `Esc` fecha. *Novidades* continua link direto, por não ter
nada dentro para listar.

- [ ] **Step 1: Os testes que falham**

```dart
testWidgets('the pill counts only the tools that are ready', (tester) async {
  await _montarCabecalho(tester);
  final prontas = ferramentas.where((t) => t.isReady).length;
  expect(find.text('$prontas'), findsOneWidget);
});

testWidgets('tapping opens the drawer, tapping away closes it', (tester) async {
  await _montarCabecalho(tester);
  expect(find.text('Calculadora de runas'), findsNothing);
  await tester.tap(find.text('Ferramentas'));
  await tester.pumpAndSettle();
  expect(find.text('Calculadora de runas'), findsOneWidget);
  await tester.tapAt(const Offset(5, 400));
  await tester.pumpAndSettle();
  expect(find.text('Calculadora de runas'), findsNothing);
});

testWidgets('a tool that is not ready is listed, dimmed, and says em breve',
    (tester) async { … });
```

- [ ] **Step 2: Rode e veja falhar**
- [ ] **Step 3: A barra**
- [ ] **Step 4: A página.** `HomeView` troca `VitrineView` por `DestaquesView`.
A ordem final, de cima para baixo: **Cabeçalho → Cartaz → Destaques →
Ferramentas → Guias → Novidades → Streamers → Comunidade → rodapé.**
- [ ] **Step 5: Apague a Vitrine e seus testes.** Um arquivo de teste de um
widget apagado não compila. Procure no repositório inteiro — `lib/`, `test/`,
`docs/`, `CLAUDE.md` — por `VitrineView`, `vitrineDe` e `vitrine.dart`, e não
deixe referência de pé. **Deixe `docs/superpowers/` em paz**: aqueles arquivos
são o registro do que se decidiu quando, não descrição do presente.
- [ ] **Step 6: `flutter build web`** — é a única coisa que pega um
`dart:io` em `lib/`.
- [ ] **Step 7: Suíte inteira, analyze, commit**
