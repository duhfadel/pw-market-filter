# Painel NewAge — subsistema **Financeiro**

> Desenho aprovado em 27/11/2026, por mockup e conversa. O livro-caixa da guild:
> entradas, despesas, pagamentos de staff, dois potes (Caixa e Reserva) e um
> gráfico com linha de gasto fixo.

## Contexto

Terceiro e último subsistema do painel `/newageguild` (Jogadores e Sala de
Guerras já estão no ar). O botão *Financeiro* já existe no menu-hub, hoje *em
breve*; esta spec o ativa.

A moeda é **TCC** (a do jogo, como no resto do site), sempre em Roboto, nunca em
Marcellus. Tudo compartilhado no Supabase — o staff vê e lança no mesmo caixa.

## A tela

Alcançada pelo botão *Financeiro* do menu. **Gated a admin e staff_editor** —
`SecaoGuild.financeiro.visivelPara` já é `admin || staff_editor`; dinheiro é
sensível e `sala_guerras`/`staff_basico` não veem o botão. Quem vê, lança.

- **Topo**: o **Total da guild** (soma dos dois potes) em destaque, e dois
  cartões — **Caixa (operacional)** e **Reserva** — com o saldo de cada.
- **Ações**: *Adicionar dinheiro*, *Adicionar despesa*, *Pagar staff*, e
  *Transferir entre potes*.
- **Gráfico**: entradas / despesas / pagamentos de staff por mês, com a **linha
  tracejada de Gasto Fixo**.
- **Livro-caixa**: os últimos lançamentos (tipo, categoria/descrição, valor,
  data, selo *fixo*).

## Os lançamentos (o modelo)

Um **lançamento** é uma linha; o saldo é derivado. Campos:

- `tipo`: `entrada` | `despesa` | `pagamento_staff` | `transferencia`.
- `pote`: `caixa` | `reserva` — o pote afetado (na transferência, é a **origem**).
- `pote_destino`: só na `transferencia` — o pote que recebe.
- `valor`: inteiro, em TCC, **sempre positivo**; o sinal vem do `tipo`.
- `categoria`: só na `entrada` — `guild_ativa` | `territorio` | `cashback` |
  `outro`. (As três primeiras são as do dono; `outro` abre a descrição.)
- `descricao`: texto. **Obrigatório na despesa** (tem de explicar o quê);
  opcional na entrada; na transferência, opcional.
- `membro`: só no `pagamento_staff` — o id do jogador/membro pago (ver *Quem é
  pago* abaixo).
- `fixo`: bool — marca um lançamento **recorrente** (salário de staff, aluguel
  de algo). Alimenta a linha de gasto fixo do gráfico.
- `data`: a data do lançamento (do Brasil, como o resto do site).
- `lancado_por` (uuid) e `lancado_por_email` (text): quem lançou.

**O efeito de cada tipo no saldo de um pote `p`:**
- `entrada` → `+valor` em `pote`.
- `despesa`, `pagamento_staff` → `−valor` em `pote`.
- `transferencia` → `−valor` em `pote` (origem) **e** `+valor` em `pote_destino`.

**Saldo(p) = Σ efeitos de todos os lançamentos sobre p.** Nunca guardado — sempre
somado. O **Total** é `Saldo(caixa) + Saldo(reserva)`, e uma transferência não o
muda (sai de um, entra no outro), o que é a prova de que o cálculo está certo.

## Quem é pago (pagamento de staff)

O `membro` do `pagamento_staff` escolhe **de uma lista** — a definir no plano:
as contas de staff (`perfis`) não têm nome de exibição hoje, e o `email` é o que
há; os **jogadores** (o roster) têm nome mas não são contas. Decisão provável:
escolher da lista de **jogadores do roster** (quem recebe é um personagem da
guild), guardando o `jogador_id`, e a descrição livre cobre o resto. Se o dono
quiser pagar alguém fora do roster, a descrição resolve. **Conta como despesa**
do pote escolhido.

## Os dois potes e a transferência

- **Caixa (operacional)** e **Reserva (intocável)** são o mesmo dinheiro em dois
  bolsos. O Total é a soma.
- **Transferir** move nos **dois sentidos** (Caixa → Reserva e Reserva → Caixa),
  um lançamento `transferencia` com `pote`/`pote_destino`.
- Qualquer **despesa/pagamento** pode sair **direto da reserva** pelo seletor de
  pote — a reserva não é cofre de mão única.

## O gráfico e o Gasto Fixo

- Barras por mês: entradas, despesas, pagamentos de staff (agregados dos
  lançamentos). Agregação no cliente (são poucas centenas de linhas).
- **Gasto Fixo**: a linha de referência é a soma dos lançamentos marcados `fixo`
  por mês — o "todo mês sai X". Marca-se o selo no lançamento; nada a cadastrar à
  parte.

## Persistência

Tabela **`lancamentos`** no Supabase: `id uuid`, `tipo text`, `pote text`,
`pote_destino text`, `valor bigint`, `categoria text`, `descricao text`,
`membro uuid` (→ jogadores), `fixo bool`, `data date`, `criado_em timestamptz`,
`lancado_por uuid`, `lancado_por_email text`. RLS: leitura e escrita para
**admin/staff_editor** (via `papel_do`), fechada ao anônimo e aos outros papéis.

**Append + apagar.** Lança-se e, para desfazer um erro, **apaga-se** aquele
lançamento (o saldo recalcula sozinho). Não há edição no lugar — um valor errado
é apagado e relançado, para o histórico não mentir sobre o que aconteceu.
`CHECK (valor > 0)` e `CHECK (tipo in (...))` no banco guardam a forma.

## Honestidade e bordas

- **Saldo nunca é um campo guardado** — é sempre a soma. Impossível desencontrar
  do histórico.
- **Um valor é sempre positivo**; o sinal é do tipo. Guardar `−8000` seria duas
  fontes de verdade para o mesmo fato.
- **Apagar é a única correção** — sem edição silenciosa de um lançamento.
- **Transferência não muda o Total** — um teste crava isso.
- **Falha de rede ao lançar/apagar avisa** (SnackBar tipado), como a Sala de
  Guerras — é trabalho compartilhado, um lançamento perdido é prejuízo.

## Modelo (Dart)

Em `lib/features/guild/domain/financeiro/`:

- `enum TipoLancamento { entrada, despesa, pagamentoStaff, transferencia }`,
  `enum Pote { caixa, reserva }`, `enum CategoriaEntrada { guildAtiva,
  territorio, cashback, outro }` — todos com `fromJson`/valor de banco.
- `Lancamento({required id, tipo, pote, poteDestino?, valor, categoria?,
  descricao?, membro?, fixo, data, lancadoPorEmail?})` com `fromJson`/`toJson`.
- Funções puras (testadas): `saldoDoPote(List<Lancamento>, Pote) → int`,
  `total(List<Lancamento>) → int`, `porMes(List<Lancamento>) → ...` (a agregação
  do gráfico), `gastoFixoMensal(List<Lancamento>) → int`.

## UI / dados

- `FinanceiroRepository.lista() → Future<Result<List<Lancamento>>>`,
  `adicionar(Lancamento) → Future<Result<void>>`, `remover(String id) →
  Future<Result<void>>`.
- `FinanceiroViewModel` (Cubit): `carregar()`; os saldos/total/agregações via as
  funções puras; `adicionar`/`remover` reemitem; falha de escrita num
  `Stream<GuildFailure>` para a tela mostrar.
- `FinanceiroView` + widgets (os cartões dos potes, os botões, o gráfico, o
  livro-caixa, os diálogos de cada tipo). O gráfico é **SVG/Canvas desenhado à
  mão ou um CustomPainter** — nada de nova dependência sem perguntar. `PWColors`
  para tudo; o gráfico usa `ok`/`down`/`blue`/`warn` que já existem.

## Testes

- **Modelo**: `saldoDoPote` soma entradas e subtrai despesas/pagamentos; uma
  transferência tira da origem e põe no destino; o **Total não muda** numa
  transferência; `gastoFixoMensal` soma só os `fixo`; round-trip `fromJson`/`toJson`.
- **VM**: carregar emite os saldos certos; adicionar/remover recalculam; falha
  de escrita é surfada.
- **RLS**: anônimo e `sala_guerras` não leem `lancamentos` (curl / lógica).
- UI onde valer, com atenção ao overflow (a lição das iterações anteriores).

## Fora de escopo (futuro)

- **Mais de dois potes** (ex.: um pote por evento) — dois bastam.
- **Relatórios/export** (CSV, fechamento mensal) — o gráfico e o livro bastam
  para começar.
- **Orçamento/metas** por categoria — depois, se pedirem.

## Restrições globais (do projeto)

- Flutter web + Bloc/Cubit (o ViewModel É o Cubit); `setState` só para visual
  local. Cores só de `PWColors`. UI em português; comentários/testes em inglês.
- `Result<T>`, nunca lança; falha **tipada** (`GuildFailure`), nunca string.
- `lib/` nunca importa `dart:io`. Roteamento pelo `MaterialApp` (push a partir do
  menu). `flutter analyze` limpo. **Sem nova dependência** (o gráfico é à mão).
- Dinheiro em Roboto, nunca Marcellus. Nada de saldo inventado — sempre somado.
- Supabase project `yadfbwsolmkcaylbxviw`; `service_role` nunca no navegador.
