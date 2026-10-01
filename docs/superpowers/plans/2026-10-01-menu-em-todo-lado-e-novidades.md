# O menu em todo lado, e as Novidades com tela própria

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> to implement this plan task-by-task.

**Goal:** O cabeçalho com as pílulas deixa de ser exclusivo da home e passa a
viver no Filtro, nos Títulos e nas Runas; as Novidades ganham tela própria em
`/novidades`; e a home perde o menu de baixo, que passou a ser duplicata.

**Architecture:** `Cabecalho` já é um `Row` comum, não um `PreferredSizeWidget`
— então entra no `title` de cada `AppBar` com `automaticallyImplyLeading: false`
em vez de virar uma barra nova. `/novidades` é uma rota a mais no `onGenerateRoute`
que já existe, e **não depende do `MarketIndex`**, que é o que a torna
reaproveitável no 1.2.6.

**Tech Stack:** Flutter web, Bloc, GetIt. Sem dependência nova.

**Spec:** Não há spec escrito; a direção foi tomada pelo dono em 01/10/2026,
depois de ver a build local. As três decisões, nas palavras dele: o menu deve
aparecer *"das outras páginas, até do market"*; as Novidades viram tela que
*"mostre a data, título, etc"* e que serve *"pra todo site, não apenas pra
1.8.7"*; e o menu de baixo da home sai, porque *"não acho que valha a pena
duplicar"*.

## Global Constraints

- **Nenhuma cor inline.** Toda cor é `static const` em `PWColors`. A única
  exceção é `Colors.transparent`.
- **Marcellus desenha algarismos romanos** — seu `0` mal se distingue de `O`.
  `PWTheme.display` é só para títulos e nomes; **nenhum número** pode cair
  nele. Datas, contagens e preços ficam na Inter.
- Comentários, docstrings e nomes de teste em **inglês**. Identificadores podem
  ser portugueses. A UI é portuguesa.
- `lib/` nunca importa `dart:io`.
- Nenhuma dependência nova.
- **Roteamento pertence ao `MaterialApp`**, nunca a um `Navigator` aninhado. Um
  aninhado navega perfeito e nunca toca a barra de endereços — a tela fica sem
  link próprio e o botão voltar do navegador sai do site. Os dois parecem
  certos numa captura de tela.
- `dart format lib/ test/` antes de cada commit; `flutter analyze` tem de
  terminar com `No issues found!`.
- Em `flutter_test` todo glifo é um quadrado do tamanho da fonte, então o
  harness **fabrica** overflows que navegador nenhum tem. Nunca encolha um
  layout para calar um: carregue as fontes reais com `FontLoader` num
  `setUpAll`, como `test/home/cartaz_test.dart` faz.
- A suíte está em **543 verde**.

---

### Task 1: `/novidades`, a tela

**Files:**
- Create: `lib/features/novidades/ui/novidades_view.dart`
- Modify: `lib/main.dart` (a rota)
- Test: `test/novidades/novidades_view_test.dart`

**Interfaces:**
- Consumes: `Novidade` (`lib/features/home/domain/novidade.dart`) — já tem
  `titulo`, `corpo`, `autor` e `publicadaEm`; e `NovidadeRepository`
  (`lib/features/home/data/novidade_repository.dart`). **Leia os dois antes de
  escrever**; as assinaturas são a verdade.
- Produces: a rota `/novidades`.

**O que a tela é.** Uma lista do mais recente para o mais antigo. Cada entrada
mostra **data, título e corpo**. Sem acordeão, sem "ver mais": quem abriu
`/novidades` veio ler, ao contrário de quem está na home e topa com a barra.

**A regra que a torna reaproveitável, e que é o pedido do dono:** esta tela
**não pode tocar no `MarketIndex`**. Ela fala do site, não de uma versão do
jogo — a mesma tela servirá o 1.2.6 sem uma linha de diferença. Se ela precisar
de qualquer coisa do índice, a dependência está errada.

**A data vai na Inter, nunca em Marcellus.** O título vai em Marcellus porque é
nome, não número.

- [ ] **Step 1: Os testes que falham**

```dart
testWidgets('the newest entry is at the top', (tester) async {
  await _montar(tester, novidades: [
    _nova(titulo: 'Mais antiga', em: DateTime.utc(2026, 9, 1)),
    _nova(titulo: 'Mais nova', em: DateTime.utc(2026, 10, 1)),
  ]);

  final nova = tester.getRect(find.text('Mais nova'));
  final antiga = tester.getRect(find.text('Mais antiga'));
  expect(nova.top, lessThan(antiga.top));
});

testWidgets('an entry with no title still draws its body and date',
    (tester) async {
  // Uma mensagem curta no Discord não tem primeira linha em negrito, e
  // `Novidade.deTexto` deixa `titulo` nulo. Ela não pode sumir da tela.
  await _montar(tester, novidades: [_nova(titulo: null, corpo: 'servidor de pé')]);
  expect(find.text('servidor de pé'), findsOneWidget);
});

testWidgets('no news at all says so, and does not look broken', (tester) async {
  await _montar(tester, novidades: const []);
  expect(find.textContaining('Nenhuma novidade'), findsOneWidget);
});

testWidgets('the date never renders in Marcellus', (tester) async {
  // Seu `0` mal se distingue de um `O` e seu `1` não tem bandeira: uma data
  // nessa face é ilegível, e é o defeito mais caro disponível nesta tela.
  await _montar(tester, novidades: [_nova(em: DateTime.utc(2026, 10, 1))]);
  for (final texto in tester.widgetList<Text>(find.byType(Text))) {
    final temDigito = RegExp(r'\d').hasMatch(texto.data ?? '');
    if (temDigito) {
      expect(texto.style?.fontFamily, isNot(PWTheme.display),
          reason: 'digits must stay on the body face: ${texto.data}');
    }
  }
});
```

- [ ] **Step 2: Rode e veja falhar**

- [ ] **Step 3: A tela.** `Scaffold` com `AppBar`; o corpo é uma lista. Use
`Result<T>` do repositório — ele nunca lança, e o estado de falha tem de dizer
algo em vez de desenhar vazio, porque *"nenhuma novidade"* e *"não deu para
carregar"* são coisas diferentes e só uma é culpa do servidor.

- [ ] **Step 4: A rota.** Em `lib/main.dart`, ao lado de `/filtro`,
`/registros` e `/runas`. Confira que `/#/novidades` abre direto, digitado na
barra de endereços — é o que torna um recado partilhável.

- [ ] **Step 5: Verde, suíte inteira, analyze, commit**

---

### Task 2: O cabeçalho nas três telas

**Files:**
- Modify: `lib/features/home/ui/widgets/cabecalho.dart`
- Modify: `lib/features/search/ui/search_view.dart`
- Modify: `lib/features/registros/ui/registros_view.dart`
- Modify: `lib/features/runas/ui/runas_view.dart`
- Modify: `lib/features/novidades/ui/novidades_view.dart` (da Tarefa 1)
- Test: `test/home/cabecalho_test.dart`, mais um teste por tela

**Interfaces:**
- Consumes: `Cabecalho({required wide, aoAbrirNovidades})` — hoje um `Row`.
- Produces: o mesmo `Cabecalho` servindo cinco telas.

**Como entra.** `Cabecalho` **não** vira `PreferredSizeWidget` e **não** vira
barra nova. Ele entra no `title:` de cada `AppBar` existente, com
`automaticallyImplyLeading: false`. Assim cada tela mantém o que já tinha de
próprio (o `toolbarHeight` do Filtro, por exemplo) e ganha o menu.

**Mas a seta de voltar não pode simplesmente sumir.** No Filtro ela já é
declarada à mão e o comentário no arquivo diz por quê — `automaticallyImplyLeading`
dava prioridade ao hambúrguer da gaveta e o caminho para casa desaparecia no
telefone. Então: **a marca do cabeçalho é o caminho para casa** e deve navegar
para `/`, e onde já existe uma seta declarada ela fica. Duas portas para casa é
melhor que nenhuma; o que não pode é zero.

**`aoAbrirNovidades` muda de significado e isso é o ponto da tarefa.** Hoje é
um salto para uma seção desta mesma página. Passa a ser
`Navigator.pushNamed(context, '/novidades')` em toda tela — inclusive na home,
onde a barra fechada continua existindo como chamariz. Atualize a docstring: ela
afirma *"only a section further down this same page to jump to"*, e isso deixa
de ser verdade neste commit. **Um comentário que descreve a intenção em vez do
código envelhece para mentira**, e este repositório já pagou por isso.

**No telefone** o cabeçalho já colapsa num botão de overflow — `wide: false`.
Mantenha esse comportamento nas cinco telas; não invente uma segunda forma
estreita.

- [ ] **Step 1: Os testes que falham**

```dart
testWidgets('every tool screen carries the menu', (tester) async {
  for (final rota in ['/filtro', '/registros', '/runas', '/novidades']) {
    await _abrir(tester, rota);
    expect(find.byType(Cabecalho), findsOneWidget, reason: rota);
  }
});

testWidgets('the mark goes home from a tool screen', (tester) async {
  await _abrir(tester, '/runas');
  await tester.tap(find.byKey(const Key('cabecalho-marca')));
  await tester.pumpAndSettle();
  expect(find.byType(HomeView), findsOneWidget);
});

testWidgets('Novidades navigates rather than scrolling', (tester) async {
  await _abrir(tester, '/registros');
  await tester.tap(find.text('Novidades'));
  await tester.pumpAndSettle();
  expect(find.byType(NovidadesView), findsOneWidget);
});
```

- [ ] **Step 2: Rode e veja falhar**
- [ ] **Step 3: A implementação.** Dê à marca uma `Key` para o teste poder
tocá-la, e faça-a navegar para `/` — mas **não empilhe**: de uma tela de
ferramenta, ir para casa é `popUntil` ou `pushNamedAndRemoveUntil`, não um
`push` que deixa a home por cima de si mesma no histórico.
- [ ] **Step 4: Verde**
- [ ] **Step 5: Confira na barra de endereços.** Navegue pelas pílulas e leia
`location.href` a cada salto. Uma captura de tela não vê este defeito: um
`Navigator` aninhado navega perfeito e nunca muda a URL.
- [ ] **Step 6: Suíte inteira, analyze, `flutter build web`, commit**

---

### Task 3: A home perde o menu de baixo

**Files:**
- Modify: `lib/features/home/ui/home_view.dart`
- Delete: `_Menu` e o que só ele usava, se nada mais usar
- Test: `test/home/home_ordem_test.dart`

**O que sai e por quê.** `_Menu` desenha as seções `FERRAMENTAS` e `GUIA` com
cards. Com as pílulas no topo listando as mesmas ferramentas e os mesmos guias,
são duas superfícies de navegação para o mesmo conjunto, uma por cima da outra
na mesma página. **Decisão do dono em 01/10:** *"não acho que valha a pena
duplicar"*.

**O que isso custa, escrito para que a decisão possa ser revista com a conta à
mão:** os cards vendem as ferramentas e as pílulas apenas as listam. Um card
carrega arte, uma frase do que a ferramenta faz e um selo *novo* com data. A
pílula carrega um nome e um número. Quem chega pela primeira vez deixa de ver
*"Busque seu próximo personagem por arma, cartas e atributos"* em lugar nenhum
da home — passa a ter de abrir a gaveta para ler a mesma frase, menor. A troca
é: a home fica sobre o mercado, e as ferramentas vivem no menu.

**O que NÃO sai:** a barra de Novidades, a tira de streamers, a seção de
Comunidade e o rodapé. Nada disso é duplicata de nada.

**O selo `novo` com data mora no card.** Se os cards saem da home, confirme
onde esse selo passa a aparecer — a gaveta é o lugar natural. Um *novo* que
não aparece em lado nenhum é um *novo* que não existe, e o `CLAUDE.md` guarda
a razão de ele expirar sozinho: *"um novo que ninguém lembra de remover deixa
de ser verdade em semanas"*.

- [ ] **Step 1: Atualize `home_ordem_test`** para a ordem nova:
Cabeçalho → Cartaz → Destaques → Novidades → Streamers → Comunidade → rodapé.
Ele deve ficar **vermelho** antes de você mexer no `home_view.dart` — é assim
que se sabe que ele estava mesmo a cravar a ordem.
- [ ] **Step 2: Tire `_Menu` da árvore**
- [ ] **Step 3: Apague o que ficou morto.** Procure no repositório inteiro por
`_Menu`, `ToolCard` e companhia; se `ToolCard` ficar sem chamador, ele e seu
teste saem juntos. Um arquivo de teste de um widget apagado não compila.
**Deixe `docs/superpowers/` em paz.**
- [ ] **Step 4: Verde, suíte inteira, analyze, `flutter build web`, commit**
