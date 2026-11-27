# Painel NewAge — Financeiro — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** O livro-caixa da guild: lançamentos (entrada/despesa/pagamento de staff/transferência) em dois potes (Caixa e Reserva), saldos derivados, gráfico com linha de gasto fixo — tudo no Supabase.

**Architecture:** Flutter web + Bloc/Cubit + GetIt + Supabase. Cada lançamento é uma linha em `lancamentos`; os saldos/total/agregações do gráfico são **somados no cliente** por funções puras (nunca guardados). Gráfico é um `CustomPainter` (sem nova dependência).

**Tech Stack:** Dart/Flutter, flutter_bloc, supabase_flutter, Postgres/RLS.

**Spec:** `docs/superpowers/specs/2026-11-27-financeiro-design.md`

## Global Constraints

- Flutter web; `lib/` nunca importa `dart:io`. **Sem nova dependência** (gráfico à mão).
- Estado é Bloc/Cubit; `setState` só para visual local.
- Cores só de `PWColors`. Dinheiro em Roboto, nunca Marcellus.
- UI em português; comentários/testes em inglês.
- `Result<T>`, nunca lança; falha **tipada** (`GuildFailure`/`GuildErro`), nunca string.
- Roteamento pelo `MaterialApp` (push do menu). `flutter analyze` limpo.
- Saldo nunca é campo guardado — sempre somado. Valor sempre positivo; o sinal vem do tipo.
- Gated a `admin`/`staff_editor` (RLS + menu). Supabase `yadfbwsolmkcaylbxviw`; `service_role` nunca no navegador.

---

### Task 1: Migração — tabela `lancamentos`

**Files:** Create `supabase/migracoes/2026-11-27_lancamentos.sql` (controller aplica via MCP).

**Interfaces:** Produces `lancamentos(id uuid pk, tipo text, pote text, pote_destino text, valor bigint, categoria text, descricao text, membro uuid, fixo bool, data date, criado_em timestamptz, lancado_por uuid, lancado_por_email text)` + checks + RLS admin/staff_editor.

- [ ] **Step 1: Escrever a migração**
```sql
create table if not exists public.lancamentos (
  id uuid primary key default gen_random_uuid(),
  tipo text not null check (tipo in ('entrada','despesa','pagamento_staff','transferencia')),
  pote text not null check (pote in ('caixa','reserva')),
  pote_destino text check (pote_destino in ('caixa','reserva')),
  valor bigint not null check (valor > 0),
  categoria text check (categoria in ('guild_ativa','territorio','cashback','outro')),
  descricao text,
  membro uuid references public.jogadores(id) on delete set null,
  fixo boolean not null default false,
  data date not null default (now() at time zone 'America/Sao_Paulo')::date,
  criado_em timestamptz not null default now(),
  lancado_por uuid references auth.users(id) default auth.uid(),
  lancado_por_email text
);
create index if not exists lancamentos_data_idx on public.lancamentos(data desc);

alter table public.lancamentos enable row level security;
create policy lancamentos_fin_select on public.lancamentos
  for select to authenticated using (papel_do(auth.uid()) in ('admin','staff_editor'));
create policy lancamentos_fin_write on public.lancamentos
  for all to authenticated
  using (papel_do(auth.uid()) in ('admin','staff_editor'))
  with check (papel_do(auth.uid()) in ('admin','staff_editor'));
```

- [ ] **Step 2: Commit** (controller aplica + confere: anon select → `[]`; um staff_basico de teste não lê).
```bash
git add supabase/migracoes/2026-11-27_lancamentos.sql
git commit -m "feat(fin): tabela lancamentos (checks + RLS admin/editor)"
```

---

### Task 2: Modelos + funções puras

**Files:**
- Create `lib/features/guild/domain/financeiro/lancamento.dart` (enums + Lancamento)
- Create `lib/features/guild/domain/financeiro/calculos.dart` (funções puras)
- Test `test/guild/financeiro/calculos_test.dart`

**Interfaces:**
- Produces: `enum TipoLancamento { entrada, despesa, pagamentoStaff, transferencia }` (com `banco`/`doBanco`), `enum Pote { caixa, reserva }`, `enum CategoriaEntrada { guildAtiva, territorio, cashback, outro }`. `Lancamento({required String id, required TipoLancamento tipo, required Pote pote, Pote? poteDestino, required int valor, CategoriaEntrada? categoria, String? descricao, String? membro, bool fixo, required DateTime data, String? lancadoPorEmail})` + `fromJson`/`toJson` (snake_case). Puras: `int saldoDoPote(List<Lancamento>, Pote)`, `int total(List<Lancamento>)`, `List<MesFinanceiro> porMes(List<Lancamento>)` (`MesFinanceiro({int ano, int mes, int entrada, int despesa, int staff})`, ordenado), `int gastoFixoMensal(List<Lancamento>)` (soma dos `fixo` do mês mais recente que tem algum `fixo`; 0 se nenhum).

- [ ] **Step 1: Teste (TDD)**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/guild/domain/financeiro/lancamento.dart';
import 'package:pw_market_filter/features/guild/domain/financeiro/calculos.dart';

Lancamento l(TipoLancamento t, Pote p, int v, {Pote? dest, bool fixo = false, DateTime? data}) =>
  Lancamento(id: 'x', tipo: t, pote: p, poteDestino: dest, valor: v, fixo: fixo,
    data: data ?? DateTime(2026, 11, 1));

void main() {
  test('saldo adds entradas and subtracts despesas/staff', () {
    final ls = [l(TipoLancamento.entrada, Pote.caixa, 100),
      l(TipoLancamento.despesa, Pote.caixa, 30),
      l(TipoLancamento.pagamentoStaff, Pote.caixa, 20)];
    expect(saldoDoPote(ls, Pote.caixa), 50);
  });
  test('a transfer moves between potes and does not change the total', () {
    final ls = [l(TipoLancamento.entrada, Pote.caixa, 100),
      l(TipoLancamento.transferencia, Pote.caixa, 40, dest: Pote.reserva)];
    expect(saldoDoPote(ls, Pote.caixa), 60);
    expect(saldoDoPote(ls, Pote.reserva), 40);
    expect(total(ls), 100);
  });
  test('gastoFixoMensal sums only fixo of the latest month with any', () {
    final ls = [l(TipoLancamento.pagamentoStaff, Pote.caixa, 8, fixo: true, data: DateTime(2026, 11, 1)),
      l(TipoLancamento.pagamentoStaff, Pote.caixa, 8, fixo: true, data: DateTime(2026, 11, 20)),
      l(TipoLancamento.despesa, Pote.caixa, 50, fixo: false, data: DateTime(2026, 11, 5))];
    expect(gastoFixoMensal(ls), 16);
  });
  test('porMes buckets by month and type', () {
    final ls = [l(TipoLancamento.entrada, Pote.caixa, 100, data: DateTime(2026, 10, 2)),
      l(TipoLancamento.despesa, Pote.caixa, 30, data: DateTime(2026, 11, 2))];
    final m = porMes(ls);
    expect(m.firstWhere((x) => x.mes == 10).entrada, 100);
    expect(m.firstWhere((x) => x.mes == 11).despesa, 30);
  });
  test('round-trips through json', () {
    final x = l(TipoLancamento.entrada, Pote.caixa, 100);
    expect(Lancamento.fromJson(x.toJson()).valor, 100);
  });
}
```

- [ ] **Step 2: Implementar** os enums (com `banco`: `entrada`/`despesa`/`pagamento_staff`/`transferencia`, `caixa`/`reserva`, `guild_ativa`/`territorio`/`cashback`/`outro`), `Lancamento` (fromJson/toJson snake_case; `data` como `YYYY-MM-DD`), e as funções puras.

- [ ] **Step 3: Rodar e commitar** — analyze/test limpos.
```bash
git add lib/features/guild/domain/financeiro test/guild/financeiro/calculos_test.dart
git commit -m "feat(fin): modelo Lancamento e calculos (saldo, total, porMes, gasto fixo)"
```

---

### Task 3: `FinanceiroRepository` + DI

**Files:** Create `lib/features/guild/data/financeiro_repository.dart`; Modify `lib/core/di/injection.dart`; Test `test/guild/financeiro/financeiro_repository_test.dart` (fake).

**Interfaces:** Produces `FinanceiroRepository.lista() → Future<Result<List<Lancamento>>>` (order data desc), `adicionar(Lancamento) → Future<Result<void>>` (insert; `lancado_por_email` = currentUser.email; `id` gerado pelo banco — remove do json), `remover(String id) → Future<Result<void>>`.

- [ ] **Step 1: Implementar** (padrão dos outros repos: `supa.from('lancamentos')`, `GuildFailure(GuildErro.carregar/salvar)`; `adicionar` faz `l.toJson()..remove('id')` e acrescenta `'lancado_por_email': supa.auth.currentUser?.email`; `remover` faz `.delete().eq('id', id)`).
- [ ] **Step 2: DI** — `..registerLazySingleton<FinanceiroRepository>(FinanceiroRepository.new)` + import.
- [ ] **Step 3: Teste de contrato** (fake) + analyze/test limpos.
- [ ] **Step 4: Commit**
```bash
git add lib/features/guild/data/financeiro_repository.dart lib/core/di/injection.dart test/guild/financeiro/financeiro_repository_test.dart
git commit -m "feat(fin): FinanceiroRepository (listar, adicionar, remover)"
```

---

### Task 4: `FinanceiroViewModel` + estado

**Files:** Create `lib/features/guild/ui/financeiro/fin_estado.dart`, `lib/features/guild/ui/financeiro/fin_view_model.dart`; Test `test/guild/financeiro/fin_view_model_test.dart`.

**Interfaces:** Consumes `FinanceiroRepository`, `JogadoresRepository.lista` (para o seletor de staff e para nomear o `membro`), `Lancamento`, as funções puras. Produces `FinanceiroViewModel(FinanceiroRepository, JogadoresRepository)` Cubit: `carregar()` → `FinPronto(List<Lancamento> lancamentos, List<Jogador> jogadores)`; getters derivados `saldoCaixa`, `saldoReserva`, `totalGuild`, `meses`, `gastoFixo` (via as funções puras); `adicionar(Lancamento)` / `remover(id)` reemitem após sucesso; falha de escrita num `Stream<GuildFailure> falhas`. `FinCarregando`/`FinFalha`.

- [ ] **Step 1: Teste (TDD)** — fakes; carregar emite `FinPronto` com os saldos certos (via uma lista com entrada+despesa+transferência); adicionar chama o repo e recarrega; falha de escrita é surfada. (Concreto.)
- [ ] **Step 2: Estado + VM** seguindo o teste.
- [ ] **Step 3: Rodar e commitar**
```bash
git add lib/features/guild/ui/financeiro/fin_estado.dart lib/features/guild/ui/financeiro/fin_view_model.dart test/guild/financeiro/fin_view_model_test.dart
git commit -m "feat(fin): FinanceiroViewModel (saldos, total, meses, lancar/remover)"
```

---

### Task 5: A tela — potes, botões, diálogos, livro-caixa

**Files:** Create `lib/features/guild/ui/financeiro/fin_view.dart` + `widgets/` (cartões de pote, diálogos, linha do livro-caixa).

**Interfaces:** Consumes `FinanceiroViewModel`. Produces `FinanceiroView` (via `getIt`, BlocProvider+BlocBuilder): topo com **Total** + dois cartões (Caixa/Reserva); quatro ações — **Adicionar dinheiro** (diálogo: valor, pote, categoria `guild_ativa`/`territorio`/`cashback`/`outro`, observação), **Adicionar despesa** (valor, pote, **descrição obrigatória**, selo `fixo`), **Pagar staff** (valor, pote, escolher um `Jogador` do roster, descrição, selo `fixo`), **Transferir** (valor, origem→destino nos dois sentidos); o **livro-caixa** (os lançamentos, com tipo/categoria/descrição/valor/data, selo `fixo`, e um apagar com confirmação → `vm.remover`). O botão de lançar chama `vm.adicionar(Lancamento(...))`. SnackBar em `vm.falhas`.

- [ ] **Step 1** cartões de pote + total (um widget). **Step 2** os diálogos de cada tipo (um helper por tipo; valores parseados de texto; a despesa exige descrição não-vazia). **Step 3** o livro-caixa + apagar. **Step 4** `fin_view.dart` responsivo, `PWColors`, dinheiro em Roboto. Sem o gráfico ainda (próxima task).
- [ ] **Step 5: Rodar e commitar** — analyze/test limpos; cuidado com overflow.
```bash
git add lib/features/guild/ui/financeiro test/guild/financeiro
git commit -m "feat(fin): tela do financeiro (potes, lancamentos, transferencia, livro) sem grafico"
```

---

### Task 6: O gráfico (CustomPainter)

**Files:** Create `lib/features/guild/ui/financeiro/widgets/grafico_fin.dart`; Modify `fin_view.dart` (encaixa o gráfico).

**Interfaces:** Consumes `List<MesFinanceiro>` + `gastoFixo`. Produces `GraficoFin({required List<MesFinanceiro> meses, required int gastoFixo})` — um `CustomPainter` desenhando barras por mês (entrada `PWColors.ok`, despesa `PWColors.danger`, staff um azul de `PWColors`) e a **linha tracejada** do gasto fixo (`PWColors` âmbar/warn), com rótulos de mês e uma escala. Sem dependência nova.

- [ ] **Step 1** o `CustomPainter` (escala pelo maior valor; barras agrupadas; linha de gasto fixo; rótulos). **Step 2** encaixar em `fin_view.dart` com a legenda. **Step 3** um teste de widget leve (monta com dados e não estoura) — pintura é difícil de afirmar, então o teste confirma que renderiza sem exceção.
- [ ] **Step 4: Rodar e commitar**
```bash
git add lib/features/guild/ui/financeiro
git commit -m "feat(fin): grafico de entradas/despesas/staff com linha de gasto fixo"
```

---

### Task 7: Ativar o botão do menu

**Files:** Modify `lib/features/guild/domain/secao_guild.dart` (financeiro `pronta`), `lib/features/guild/ui/menu_view.dart` (navega); Test `test/guild/menu_view_test.dart`.

**Interfaces:** Consumes `FinanceiroView`. Produces `SecaoGuild.financeiro.pronta == true`; o cartão navega `Navigator.push → FinanceiroView` (como os outros). Confirme a gating: o cartão só aparece para `admin`/`staff_editor` (já é a regra de `visivelPara`).

- [ ] **Step 1** `financeiro` → `pronta: true`. **Step 2** `menu_view.dart` navega. **Step 3** teste: o cartão do financeiro, para admin, é clicável. **Step 4** analyze/test/`flutter build web` limpos.
```bash
git add lib/features/guild test/guild/menu_view_test.dart
git commit -m "feat(fin): ativar Financeiro no menu"
```

---

## Self-Review

- **Cobertura do spec**: tabela/RLS (T1); modelo+cálculos com saldo/total/transferência-não-muda-total/gasto-fixo (T2); repo lista/adicionar/remover (T3); VM saldos+lançar+falha (T4); tela potes+4 diálogos+livro (T5); gráfico com gasto fixo (T6); ativar menu (T7). Fora de escopo (mais potes, export, orçamento) não vira tarefa. ✓
- **Placeholders**: nenhum. **Ruling (quem é pago)**: `pagamento_staff.membro` = um `Jogador` do roster (id), descrição cobre quem for de fora — decidido, registrado no ledger na execução.
- **Consistência de tipos**: `saldoDoPote`/`total`/`porMes`/`gastoFixoMensal` (T2) consumidos por T4/T6; `FinanceiroRepository` (T3) por T4; `MesFinanceiro` (T2) por T6; `FinanceiroView` (T5/T6) por T7.
