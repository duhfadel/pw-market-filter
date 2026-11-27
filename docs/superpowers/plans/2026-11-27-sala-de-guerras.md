# Painel NewAge — Sala de Guerras — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Montar as pts da TW arrastando os jogadores da guild entre grupos nomeados/coloridos com líderes, salvando a formação compartilhada no Supabase.

**Architecture:** Flutter web + Bloc/Cubit + GetIt + Supabase. A formação é uma linha única no Supabase (`formacao_guerra`), guardando ids de jogadores; nome/classe/NA vêm do roster vivo. O arrasto reaproveita o padrão do organizador de instâncias.

**Tech Stack:** Dart/Flutter, flutter_bloc, supabase_flutter, Postgres/RLS.

**Spec:** `docs/superpowers/specs/2026-11-27-sala-de-guerras-design.md`

## Global Constraints

- Flutter web; `lib/` nunca importa `dart:io`.
- Estado é Bloc/Cubit (o ViewModel É o Cubit); `setState` só para visual local (arrasto em curso, diálogo).
- Cores só de `PWColors` (`static const`), exceto `Colors.transparent`.
- UI em português; comentários, docstrings e nomes de teste em inglês.
- `Result<T>`, nunca lança; falha **tipada** (`GuildFailure`/`GuildErro` em `lib/core/result/result.dart`), nunca string.
- Roteamento pelo `MaterialApp`; a Sala abre por `Navigator.push` a partir do menu. `flutter analyze` limpo.
- Nada de dado inventado: id sem jogador no roster não desenha membro.
- Supabase project `yadfbwsolmkcaylbxviw`. `service_role` nunca no navegador.
- Invariantes de tetos (10 por pt, 20 pts, um jogador numa pt só, líder zera ao mover) vivem **no modelo**, testados — não só na UI.

---

### Task 1: Migração — tabela `formacao_guerra`

**Files:**
- Create: `supabase/migracoes/2026-11-27_formacao_guerra.sql`
- (o controller aplica via MCP e confere RLS)

**Interfaces:**
- Produces: `formacao_guerra(id text pk, pts jsonb, salvo_em timestamptz, salvo_por uuid, salvo_por_email text)` — uma linha de id fixo `'atual'`.

- [ ] **Step 1: Escrever a migração**
```sql
create table if not exists public.formacao_guerra (
  id text primary key,
  pts jsonb not null default '[]'::jsonb,
  salvo_em timestamptz,
  salvo_por uuid references auth.users(id),
  salvo_por_email text
);
-- a formação é uma só: semeia a linha única.
insert into public.formacao_guerra (id, pts) values ('atual', '[]'::jsonb)
  on conflict (id) do nothing;

alter table public.formacao_guerra enable row level security;
create policy formacao_staff_select on public.formacao_guerra
  for select to authenticated using (papel_do(auth.uid()) is not null);
create policy formacao_staff_write on public.formacao_guerra
  for all to authenticated
  using (papel_do(auth.uid()) is not null)
  with check (papel_do(auth.uid()) is not null);
```
(Escrita liberada a qualquer staff autenticado — a sala é coordenação; quem vê, edita.)

- [ ] **Step 2: Commit** (o controller aplica + confere: anon select `formacao_guerra` → `[]`).
```bash
git add supabase/migracoes/2026-11-27_formacao_guerra.sql
git commit -m "feat(guerra): tabela formacao_guerra (linha unica, RLS staff)"
```

---

### Task 2: Modelos — `MembroGuerra`, `GrupoGuerra`, `FormacaoGuerra`

**Files:**
- Create: `lib/features/guild/domain/guerra/membro_guerra.dart`
- Create: `lib/features/guild/domain/guerra/grupo_guerra.dart`
- Create: `lib/features/guild/domain/guerra/formacao_guerra.dart`
- Test: `test/guild/guerra/formacao_guerra_test.dart`

**Interfaces:**
- Produces: `MembroGuerra({required String jogadorId, bool lider})` com `fromJson`/`toJson`. `GrupoGuerra({required String nome, required String cor, List<MembroGuerra> membros})` com `bool get cheio` (≥10), `comMembro(id)`, `semMembro(id)`, `alternarLider(id)`, `renomear(nome)`, `recolorir(cor)`, `fromJson`/`toJson`. `FormacaoGuerra({required List<GrupoGuerra> grupos})` com `moverMembro(String jogadorId, int? destino)`, `comGrupo(nome,cor)`, `semGrupo(int i)`, `Set<String> colocados()`, `List<String> disponiveis(List<String> rosterIds)`, `FormacaoGuerra podada(Set<String> rosterIds)`, `fromJson`/`toJson`; `static const maxGrupos=20, maxMembros=10`.

- [ ] **Step 1: Teste (TDD)** em `test/guild/guerra/formacao_guerra_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/guild/domain/guerra/formacao_guerra.dart';
import 'package:pw_market_filter/features/guild/domain/guerra/grupo_guerra.dart';
import 'package:pw_market_filter/features/guild/domain/guerra/membro_guerra.dart';

FormacaoGuerra umaFormacao() => FormacaoGuerra(grupos: [
  GrupoGuerra(nome: 'Pt 1', cor: '#E8707C', membros: [MembroGuerra(jogadorId: 'a')]),
  GrupoGuerra(nome: 'Pt 2', cor: '#56A8F5', membros: const []),
]);

void main() {
  test('move a member from one group to another, removing from origin', () {
    final f = umaFormacao().moverMembro('a', 1);
    expect(f.grupos[0].membros, isEmpty);
    expect(f.grupos[1].membros.single.jogadorId, 'a');
  });
  test('moving back out (destino null) removes from the formation', () {
    final f = umaFormacao().moverMembro('a', null);
    expect(f.colocados(), isEmpty);
  });
  test('a full group refuses a new member', () {
    final cheio = GrupoGuerra(nome: 'x', cor: '#fff',
      membros: [for (var i = 0; i < 10; i++) MembroGuerra(jogadorId: 'm$i')]);
    final f = FormacaoGuerra(grupos: [cheio, GrupoGuerra(nome: 'y', cor: '#fff', membros: [MembroGuerra(jogadorId: 'z')])]);
    final depois = f.moverMembro('z', 0); // grupo 0 está cheio
    expect(depois.grupos[0].membros.length, 10);
    expect(depois.grupos[1].membros.single.jogadorId, 'z'); // ficou onde estava
  });
  test('toggling leader is per-group and resets on move', () {
    var f = umaFormacao().grupos[0].alternarLider('a').membros.single.lider;
    expect(f, isTrue);
    final movida = umaFormacao()
      ..moverMembro('a', 1);
    // após mover, o membro entra como não-líder
    expect(umaFormacao().moverMembro('a', 1).grupos[1].membros.single.lider, isFalse);
  });
  test('disponiveis excludes placed ids and the formation drops unknown ids on podada', () {
    final f = umaFormacao();
    expect(f.disponiveis(['a', 'b', 'c']), ['b', 'c']);
    final podada = FormacaoGuerra(grupos: [
      GrupoGuerra(nome: 'Pt 1', cor: '#fff', membros: [MembroGuerra(jogadorId: 'a'), MembroGuerra(jogadorId: 'sumiu')]),
    ]).podada({'a'});
    expect(podada.grupos[0].membros.map((m) => m.jogadorId), ['a']);
  });
  test('round-trips through json', () {
    final f = umaFormacao();
    final back = FormacaoGuerra.fromJson(f.toJson());
    expect(back.grupos[0].membros.single.jogadorId, 'a');
  });
  test('comGrupo caps at 20', () {
    var f = FormacaoGuerra(grupos: const []);
    for (var i = 0; i < 25; i++) { f = f.comGrupo('Pt', '#fff'); }
    expect(f.grupos.length, 20);
  });
}
```

- [ ] **Step 2: Implementar os três modelos** (imutáveis; `moverMembro` tira de onde estiver e, se `destino != null` e o grupo não está cheio, acrescenta como **não-líder**; grupo cheio → devolve inalterado; `comGrupo` respeita o teto 20; `podada` filtra ids fora do roster). `fromJson`/`toJson` em snake_case (`jogador_id`, `lider`, `nome`, `cor`, `membros`).

- [ ] **Step 3: Rodar e commitar** — `flutter test test/guild/` + `flutter analyze` limpos.
```bash
git add lib/features/guild/domain/guerra test/guild/guerra/formacao_guerra_test.dart
git commit -m "feat(guerra): modelos MembroGuerra/GrupoGuerra/FormacaoGuerra com invariantes"
```

---

### Task 3: `FormacaoRepository` (carregar/salvar) + DI

**Files:**
- Create: `lib/features/guild/data/formacao_repository.dart`
- Modify: `lib/core/di/injection.dart`
- Test: `test/guild/guerra/formacao_repository_test.dart` (fake sobre a interface)

**Interfaces:**
- Produces: `FormacaoRepository.carregar() → Future<Result<FormacaoGuerra>>` (lê a linha `'atual'`; `pts` ausente/vazio → formação vazia). `salvar(FormacaoGuerra) → Future<Result<void>>` (upsert da linha `'atual'` com `pts` + `salvo_em=now` + `salvo_por=currentUser.id` + `salvo_por_email=currentUser.email`).

- [ ] **Step 1: Implementar `formacao_repository.dart`**
```dart
import '../../../core/result/result.dart';
import '../../../core/supabase/cliente.dart';
import '../domain/guerra/formacao_guerra.dart';

class FormacaoRepository {
  Future<Result<FormacaoGuerra>> carregar() async {
    try {
      final row = await supa.from('formacao_guerra').select('pts').eq('id', 'atual').maybeSingle();
      final pts = (row?['pts'] as List?) ?? const [];
      return Success(FormacaoGuerra.fromJson({'grupos': pts}));
    } catch (_) {
      return const Failure(GuildFailure(GuildErro.carregar));
    }
  }

  Future<Result<void>> salvar(FormacaoGuerra f) async {
    try {
      final u = supa.auth.currentUser;
      await supa.from('formacao_guerra').upsert({
        'id': 'atual',
        'pts': f.toJson()['grupos'],
        'salvo_em': DateTime.now().toUtc().toIso8601String(),
        'salvo_por': u?.id,
        'salvo_por_email': u?.email,
      });
      return const Success<void>(null);
    } catch (_) {
      return const Failure(GuildFailure(GuildErro.salvar));
    }
  }
}
```
(Ajuste `FormacaoGuerra.fromJson`/`toJson` para casar: a lista de grupos é a chave `grupos`; aqui a coluna `pts` **é** essa lista. Se preferir, dê a `FormacaoGuerra` um `fromGrupos(List)`/`gruposJson()` e use-os — o que ficar mais limpo, anote no report.)

- [ ] **Step 2: DI** — `..registerLazySingleton<FormacaoRepository>(FormacaoRepository.new)` + import.

- [ ] **Step 3: Teste de contrato** (fake devolvendo uma `FormacaoGuerra`), analyze/test limpos.

- [ ] **Step 4: Commit**
```bash
git add lib/features/guild/data/formacao_repository.dart lib/core/di/injection.dart test/guild/guerra/formacao_repository_test.dart
git commit -m "feat(guerra): FormacaoRepository (carregar/salvar a formacao unica)"
```

---

### Task 4: `SalaGuerrasViewModel` + estado

**Files:**
- Create: `lib/features/guild/ui/guerra/sala_estado.dart`
- Create: `lib/features/guild/ui/guerra/sala_view_model.dart`
- Test: `test/guild/guerra/sala_view_model_test.dart`

**Interfaces:**
- Consumes: `FormacaoRepository`, `JogadoresRepository.lista`, `FormacaoGuerra`, `Jogador`.
- Produces: `SalaGuerrasViewModel(this._formacaoRepo, this._jogadoresRepo)` com `carregar()` → emite `SalaPronta(formacao, jogadores)` (jogadores = roster transcrito); `mover(id, destino)`, `alternarLider(grupo, id)`, `renomear(grupo, nome)`, `recolorir(grupo, cor)`, `novaPt()`, `removerPt(grupo)` — cada um recalcula a formação (via os métodos do modelo, **podada** contra o roster) e reemite; `salvar()` → emite `SalaSalvando`→`SalaPronta` com `salvoAgora`, ou um `GuildFailure` exposto para a tela mostrar. `disponiveis` = `formacao.disponiveis(rosterTranscritoIds)`.

- [ ] **Step 1: Teste (TDD)** — fakes de `FormacaoRepository` (devolve uma formação) e `JogadoresRepository` (devolve 3 transcritos + 1 pendente): `carregar` emite `SalaPronta` com só os transcritos no roster; `mover('a', 0)` põe o jogador na pt 0 e tira-o de `disponiveis`; `salvar` chama `_formacaoRepo.salvar` e, em falha, expõe o erro. (Escreva o teste concreto.)

- [ ] **Step 2: Estado + VM** — `sala_estado.dart` (sealed: `SalaCarregando`, `SalaPronta(formacao, jogadores, salvoEm?)`, `SalaFalha`); `sala_view_model.dart` (Cubit) seguindo o teste. Ao carregar, `formacao.podada(rosterIds)` remove ids fantasma.

- [ ] **Step 3: Rodar e commitar**
```bash
git add lib/features/guild/ui/guerra/sala_estado.dart lib/features/guild/ui/guerra/sala_view_model.dart test/guild/guerra/sala_view_model_test.dart
git commit -m "feat(guerra): SalaGuerrasViewModel (carregar, mover, lider, pts, salvar)"
```

---

### Task 5: A tela — lista, pts, controles (sem arrasto ainda)

**Files:**
- Create: `lib/features/guild/ui/guerra/sala_view.dart`
- Create: `lib/features/guild/ui/guerra/widgets/chip_jogador.dart`
- Create: `lib/features/guild/ui/guerra/widgets/cartao_pt.dart`

**Interfaces:**
- Consumes: `SalaGuerrasViewModel`, `Jogador`, `ClassIcon`.
- Produces: `SalaGuerrasView` montando a VM via `getIt`, duas colunas (`LayoutBuilder`: largo lado a lado, estreito empilha a lista por cima). Esquerda: busca + `disponiveis` como `ChipJogador`. Direita: grade de `CartaoPt` (nome editável via ✎, `swatch` de cor abrindo uma paleta de `PWColors`, contagem `N/10`, membros como `ChipJogador` com a **♛** de alternar líder e o **✕** de tirar), mais o cartão **"+ nova pt"** (some em 20), e o botão **"Salvar formação"** com *salvo há X* e um `SnackBar` tipado na falha.

- [ ] **Step 1: `chip_jogador.dart`** — o chip (pega `⠿`, `ClassIcon`, nome, NA em Roboto; opcionalmente a ♛ de líder tingida na cor do grupo e o ✕). Reutilizável na lista e nas pts. Overflow: o nome `Flexible`+ellipsis.

- [ ] **Step 2: `cartao_pt.dart`** — o cartão de uma pt (cabeçalho com nome/✎, swatch/paleta, `N/10`; corpo com os membros ou o vazio "arraste para cá"). Toque na ♛ chama `vm.alternarLider`; ✕ chama `vm.mover(id, null)`; ✎ renomeia; swatch recolore; um botão remover a pt.

- [ ] **Step 3: `sala_view.dart`** — monta tudo, responsivo, `PWColors`. Sem arrasto ainda (botões/toques só). Ligue o Salvar.

- [ ] **Step 4: Rodar e commitar** — analyze/test limpos (teste de widget onde valer; cuidado com overflow horizontal — a lição que a iteração 2 pagou duas vezes).
```bash
git add lib/features/guild/ui/guerra test/guild/guerra
git commit -m "feat(guerra): tela da sala (lista, pts, lider, cor, nome, salvar) sem arrasto"
```

---

### Task 6: O arrasto (reaproveitando o padrão dos Instâncias)

**Files:**
- Modify: `lib/features/guild/ui/guerra/widgets/chip_jogador.dart`
- Modify: `lib/features/guild/ui/guerra/widgets/cartao_pt.dart`
- Modify: `lib/features/guild/ui/guerra/sala_view.dart`

**Interfaces:**
- Consumes: `SalaGuerrasViewModel.mover`.
- Produces: arrastar um `ChipJogador` pela pega e largar numa pt chama `vm.mover(id, indiceDaPt)`; largar na lista geral chama `vm.mover(id, null)`; uma pt cheia **recusa** (`onWillAccept` checa `grupo.cheio`).

- [ ] **Step 1: Ler o padrão** em `lib/features/instancias/ui/widgets/tabela_de_instancias.dart` — `_PegaArrasto` (`LongPressDraggable` no telemóvel, `Draggable` no rato; só a pega arrasta), o grupo como `DragTarget`, e o `movendoPersonagem` que tira antes de calcular o destino.

- [ ] **Step 2: A pega** no `ChipJogador` — um `Draggable`/`LongPressDraggable` carregando o `jogadorId` (o payload do arrasto). Só a pega, não o chip inteiro (o resto toca na ♛/✕).

- [ ] **Step 3: Os alvos** — cada `CartaoPt` é um `DragTarget<String>` que aceita se `!grupo.cheio` (ou se o membro já é dali) e no `onAccept` chama `vm.mover(id, indice)`. A coluna da esquerda é um `DragTarget<String>` que no `onAccept` chama `vm.mover(id, null)`.

- [ ] **Step 4: Rodar e commitar** — analyze/test limpos. (O arrasto em si é difícil de testar em widget; a lógica já está coberta no modelo/VM — um teste de widget que confirme que soltar numa pt cheia não move é bônus, não obrigatório.)
```bash
git add lib/features/guild/ui/guerra
git commit -m "feat(guerra): arrastar jogadores entre pts e para fora"
```

---

### Task 7: Ativar o botão do menu e ligar a rota

**Files:**
- Modify: `lib/features/guild/domain/secao_guild.dart` (sala vira `pronta`)
- Modify: `lib/features/guild/ui/menu_view.dart` (navega para a sala)
- Test: `test/guild/menu_view_test.dart` (a sala agora navega)

**Interfaces:**
- Consumes: `SalaGuerrasView`.
- Produces: `SecaoGuild.salaGuerras.pronta == true`; o cartão da sala no menu navega `Navigator.push → SalaGuerrasView` (como o de Jogadores), sem `onTap: null`.

- [ ] **Step 1: `secao_guild.dart`** — `salaGuerras` passa a `pronta: true`.
- [ ] **Step 2: `menu_view.dart`** — o cartão da sala, quando `pronta`, navega para `SalaGuerrasView` (em vez de ficar esmaecido). Confirme que `financeiro` continua *em breve*.
- [ ] **Step 3: Teste** — o menu com a sala `pronta` tem o cartão clicável (não esmaecido).
- [ ] **Step 4: Rodar e commitar** — analyze/test/`flutter build web` limpos.
```bash
git add lib/features/guild test/guild/menu_view_test.dart
git commit -m "feat(guerra): ativar Sala de Guerras no menu"
```

---

## Self-Review

- **Cobertura do spec**: tabela/RLS (T1); modelo com invariantes 10/20/um-por-pt/líder-zera (T2); carregar+salvar compartilhado (T3); VM com disponiveis/mover/lider/salvar (T4); tela lista+pts+nome+cor+líder+salvar (T5); arrasto (T6); ativar o menu (T7). Fora de escopo (várias formações, presença, totais) não vira tarefa. ✓
- **Placeholders**: nenhum "TBD" não-deliberado.
- **Consistência de tipos**: `FormacaoGuerra.moverMembro(id, int?)`, `disponiveis(List<String>)`, `podada(Set<String>)` de T2 são consumidos por T4; `FormacaoRepository.carregar/salvar` de T3 por T4; `vm.mover(id, int?)` de T4 por T5/T6; `SalaGuerrasView` de T5 por T7.
