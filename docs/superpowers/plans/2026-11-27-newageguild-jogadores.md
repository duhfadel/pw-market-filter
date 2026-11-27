# Painel NewAge — subsistema Jogadores (iteração 2) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Evoluir o painel `/newageguild` de uma lista simples para o subsistema Jogadores completo: menu-hub, histórico de fichas com delta, detalhe, runas, busca/filtro/ordenação, adicionar/editar por imagem e "revisar".

**Architecture:** Flutter web + Bloc/Cubit + GetIt + Supabase. Duas tabelas (`jogadores` = identidade + ficha atual; `fichas` = histórico de fotos). A transcrição é feita pelo assistente via a porta do Worker (que ganha um endpoint `salvar`). A imagem é lida e descartada; só os números ficam.

**Tech Stack:** Dart/Flutter, flutter_bloc, supabase_flutter, Cloudflare Worker (JS), Postgres/RLS.

**Spec:** `docs/superpowers/specs/2026-11-27-newageguild-jogadores-design.md`

## Global Constraints

- Flutter web; `lib/` **nunca** importa `dart:io` (código de browser atrás de conditional import).
- Estado é Bloc/Cubit (o ViewModel É o Bloc); `setState` só para visual local.
- Cores só de `PWColors` (`static const`), exceto `Colors.transparent`.
- UI em português; comentários, docstrings e nomes de teste em inglês.
- `Result<T>`, nunca lança; falha **tipada** (`GuildFailure`/`GuildErro` em `lib/core/result/result.dart`), nunca string.
- Roteamento pertence ao `MaterialApp` (`onGenerateRoute`), nunca a um `Navigator` aninhado.
- `flutter analyze` termina com `No issues found!`.
- Nada de dado inventado: ausência não é zero; leitura que falha não vira afirmação.
- Supabase project `yadfbwsolmkcaylbxviw`. A `service_role` vive só no Worker.

---

### Task 1: Migração do banco — `fichas` + campos novos em `jogadores`

**Files:**
- Create: `supabase/migracoes/2026-11-27_fichas_e_atribuicao.sql`
- (aplicar no banco via MCP `apply_migration`/`execute_sql`)

**Interfaces:**
- Produces: tabela `fichas(id uuid pk, jogador_id uuid fk, criada_em timestamptz, criado_por uuid, dados jsonb, runas jsonb)`; colunas novas em `jogadores`: `nota text`, `atualizado_por uuid`, `atualizado_em timestamptz`; `status` passa a aceitar `'revisar'`.

- [ ] **Step 1: Escrever a migração**
```sql
-- jogadores: atribuição da última foto + nota de revisão
alter table public.jogadores
  add column if not exists nota text,
  add column if not exists atualizado_por uuid references auth.users(id),
  add column if not exists atualizado_em timestamptz;

-- histórico: uma foto por transcrição. dados/runas em jsonb (flexível, barato).
create table if not exists public.fichas (
  id uuid primary key default gen_random_uuid(),
  jogador_id uuid not null references public.jogadores(id) on delete cascade,
  criada_em timestamptz not null default now(),
  criado_por uuid references auth.users(id) default auth.uid(),
  dados jsonb not null default '{}'::jsonb,
  runas jsonb not null default '[]'::jsonb
);
create index if not exists fichas_jogador_idx on public.fichas(jogador_id, criada_em desc);

alter table public.fichas enable row level security;
-- leitura para staff autenticado (mesma função de papel do resto)
create policy fichas_staff_select on public.fichas
  for select to authenticated using (papel_do(auth.uid()) is not null);
create policy fichas_staff_write on public.fichas
  for all to authenticated
  using (papel_do(auth.uid()) in ('admin','staff_editor','staff_basico'))
  with check (papel_do(auth.uid()) in ('admin','staff_editor','staff_basico'));
```

- [ ] **Step 2: Aplicar e conferir**
Rodar via MCP. Depois conferir: `select column_name from information_schema.columns where table_name='jogadores' and column_name in ('nota','atualizado_por','atualizado_em')` → 3 linhas; `select policyname from pg_policies where tablename='fichas'` → 2 linhas.

- [ ] **Step 3: Prova de RLS (curl anônimo)**
`curl .../rest/v1/fichas?select=* -H "apikey: <publishable>"` → `[]` (RLS fecha). Anotar no report.

- [ ] **Step 4: Commit**
```bash
git add supabase/migracoes/2026-11-27_fichas_e_atribuicao.sql
git commit -m "feat(guild): tabela fichas (historico) e campos de atribuicao/nota"
```

---

### Task 2: Modelos de domínio — `Runa`, `Ficha`, e extensão de `Jogador`

**Files:**
- Create: `lib/features/guild/domain/runa.dart`
- Create: `lib/features/guild/domain/ficha.dart`
- Modify: `lib/features/guild/domain/jogador.dart`
- Test: `test/guild/ficha_test.dart`, `test/guild/runa_test.dart`

**Interfaces:**
- Produces: `Runa({required NivelRuna nivel, required String familia})` com `fromJson`/`toJson`; `enum NivelRuna` 1..10 com `rotulo`. `Ficha({required String jogadorId, required Map<String,dynamic> dados, required List<Runa> runas, DateTime? criadaEm, String? criadoPor})` com `fromJson(Map)`/`toJson()`. `Jogador` ganha `String? nota`, `String? atualizadoPor`, `DateTime? atualizadoEm`, e `bool get aRevisar => status == 'revisar'`.

- [ ] **Step 1: Teste do `Runa` (TDD)**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/guild/domain/runa.dart';
void main(){
  test('runa round-trips by family and level',(){
    final r=Runa(familia:'Áurea', nivel:NivelRuna.nv10);
    final back=Runa.fromJson(r.toJson());
    expect(back.familia,'Áurea'); expect(back.nivel,NivelRuna.nv10);
  });
  test('level 10 is the top of the ladder',(){
    expect(NivelRuna.nv10.numero,10); expect(NivelRuna.nv7.numero,7);
  });
}
```

- [ ] **Step 2: Implementar `runa.dart`**
```dart
/// A rune's level (1..10). 10 is the diamond frame; 9/8/7 differ only by the
/// centre symbol — read by hand from the sheet, stored here as a number.
enum NivelRuna {
  nv1(1),nv2(2),nv3(3),nv4(4),nv5(5),nv6(6),nv7(7),nv8(8),nv9(9),nv10(10);
  const NivelRuna(this.numero); final int numero;
  static NivelRuna doNumero(int n)=>NivelRuna.values.firstWhere((e)=>e.numero==n);
}

/// One equipped rune: a family (its colour/name) and a level. The colour does
/// not affect anything but identity; the level is what matters.
class Runa {
  const Runa({required this.familia, required this.nivel});
  final String familia; final NivelRuna nivel;
  factory Runa.fromJson(Map<String,dynamic> j)=>
      Runa(familia:j['familia'] as String, nivel:NivelRuna.doNumero(j['nivel'] as int));
  Map<String,dynamic> toJson()=>{'familia':familia,'nivel':nivel.numero};
}
```

- [ ] **Step 3: Teste do `Ficha` (TDD)**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/guild/domain/ficha.dart';
import 'package:pw_market_filter/features/guild/domain/runa.dart';
void main(){
  test('ficha round-trips stats and runes',(){
    final f=Ficha(jogadorId:'j1', dados:{'nivel_ataque':428,'critico':'74%'},
        runas:[Runa(familia:'Áurea',nivel:NivelRuna.nv10)]);
    final back=Ficha.fromJson(f.toJson());
    expect(back.dados['nivel_ataque'],428);
    expect(back.runas.single.nivel,NivelRuna.nv10);
  });
}
```

- [ ] **Step 4: Implementar `ficha.dart`**
```dart
import 'runa.dart';
/// A snapshot of a player's sheet at one transcription. The image that
/// produced it is discarded; this is what stays and stacks over time.
class Ficha {
  Ficha({required this.jogadorId, required this.dados, required this.runas,
    this.id, this.criadaEm, this.criadoPor});
  final String? id; final String jogadorId;
  final DateTime? criadaEm; final String? criadoPor;
  final Map<String,dynamic> dados; // the ~25 attributes, snake_case keys
  final List<Runa> runas;
  factory Ficha.fromJson(Map<String,dynamic> j)=>Ficha(
    id:j['id'] as String?, jogadorId:j['jogador_id'] as String,
    criadaEm:j['criada_em']!=null?DateTime.parse(j['criada_em'] as String):null,
    criadoPor:j['criado_por'] as String?,
    dados:Map<String,dynamic>.from(j['dados'] as Map? ?? {}),
    runas:[for(final r in (j['runas'] as List? ?? [])) Runa.fromJson(Map<String,dynamic>.from(r as Map))],
  );
  Map<String,dynamic> toJson()=>{
    if(id!=null)'id':id, 'jogador_id':jogadorId,
    if(criadoPor!=null)'criado_por':criadoPor,
    'dados':dados, 'runas':[for(final r in runas) r.toJson()],
  };
}
```

- [ ] **Step 5: Estender `jogador.dart`**
Acrescentar ao construtor e aos campos: `this.nota`, `this.atualizadoPor`, `this.atualizadoEm`; ao `fromJson`: `nota: json['nota'] as String?`, `atualizadoPor: json['atualizado_por'] as String?`, `atualizadoEm: json['atualizado_em']!=null?DateTime.parse(json['atualizado_em'] as String):null`; ao `toJson` (via o helper `put`): `put('nota',nota)`, `put('atualizado_por',atualizadoPor)`, `put('atualizado_em',atualizadoEm?.toIso8601String())`. Acrescentar `bool get aRevisar => status == 'revisar';` ao lado de `transcrito`. **Manter `comPrintUrl` incluindo os campos novos.**

- [ ] **Step 6: Rodar e commitar**
`flutter test test/guild/` e `flutter analyze` limpos.
```bash
git add lib/features/guild/domain test/guild/ficha_test.dart test/guild/runa_test.dart
git commit -m "feat(guild): modelos Ficha e Runa; Jogador ganha nota e atribuicao"
```

---

### Task 3: O delta entre duas fichas

**Files:**
- Create: `lib/features/guild/domain/delta.dart`
- Test: `test/guild/delta_test.dart`

**Interfaces:**
- Consumes: `Ficha` (Task 2).
- Produces: `enum Rumo { subiu, desceu, igual }`; `class DeltaCampo { final num? de; final num? para; final Rumo rumo; }`; `Map<String,DeltaCampo> deltaEntre(Ficha atual, Ficha? anterior)` — compara os campos numéricos de `dados`; sem `anterior`, devolve mapa vazio (um primeiro registro não tem com o que comparar).

- [ ] **Step 1: Teste (TDD)**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/guild/domain/ficha.dart';
import 'package:pw_market_filter/features/guild/domain/delta.dart';
void main(){
  Ficha f(int na)=>Ficha(jogadorId:'j',dados:{'nivel_ataque':na,'hp':1000},runas:[]);
  test('rising attack level reads as subiu',(){
    final d=deltaEntre(f(428),f(396));
    expect(d['nivel_ataque']!.rumo,Rumo.subiu);
    expect(d['nivel_ataque']!.para,428);
  });
  test('no previous ficha means no delta',(){
    expect(deltaEntre(f(428),null),isEmpty);
  });
  test('equal value reads as igual',(){
    expect(deltaEntre(f(428),f(428))['nivel_ataque']!.rumo,Rumo.igual);
  });
}
```

- [ ] **Step 2: Implementar `delta.dart`**
```dart
import 'ficha.dart';
enum Rumo { subiu, desceu, igual }
class DeltaCampo { const DeltaCampo(this.de,this.para,this.rumo);
  final num? de; final num? para; final Rumo rumo; }
/// Per-field change from the previous snapshot. Only numeric fields compare;
/// a field present now but absent before (or vice-versa) is skipped — we do
/// not invent a baseline. No previous snapshot → no deltas at all.
Map<String,DeltaCampo> deltaEntre(Ficha atual, Ficha? anterior){
  if(anterior==null) return {};
  final out=<String,DeltaCampo>{};
  atual.dados.forEach((k,v){
    final a=anterior.dados[k];
    if(v is num && a is num){
      out[k]=DeltaCampo(a,v, v>a?Rumo.subiu:(v<a?Rumo.desceu:Rumo.igual));
    }
  });
  return out;
}
```

- [ ] **Step 3: Rodar e commitar**
```bash
git add lib/features/guild/domain/delta.dart test/guild/delta_test.dart
git commit -m "feat(guild): delta entre duas fichas (subiu/desceu/igual)"
```

---

### Task 4: Endpoint `POST /transcricao/salvar` no Worker

**Files:**
- Modify: `tool/cron/worker.js`
- (deploy pelo controller/dono com `npx wrangler deploy`)

**Interfaces:**
- Consumes: a infra de `/transcricao/*` já existente (token, `supabase()`, `SUPABASE_STORAGE`).
- Produces: `POST /transcricao/salvar` com corpo `{id, dados, runas, status, nota}`. Valida `dados` contra lista branca de colunas; grava uma linha em `fichas`; atualiza `jogadores` (os campos + `status` + `nota` + `atualizado_em`); quando `status==='transcrito'`, apaga o print e zera `print_url`.

- [ ] **Step 1: Implementar o handler** (dentro de `atenderTranscricao`, antes do `return 405`)
```javascript
  if (request.method === 'POST' && url.pathname === '/transcricao/salvar') {
    let corpo;
    try { corpo = await request.json(); } catch (_) {
      return new Response('corpo invalido', { status: 400 });
    }
    const EH_UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    const id = corpo && corpo.id;
    if (typeof id !== 'string' || !EH_UUID.test(id)) {
      return new Response('id invalido', { status: 400 });
    }
    // lista branca: só estas colunas podem ser escritas por transcricao.
    const COLUNAS = new Set(['cla','classe','cultivo','limite','nivel','despertares',
      'hp','mp','acerto','nivel_ataque','ataque_fisico','ataque_magico','furia','critico',
      'canalizacao','def_fisica','def_metal','def_madeira','def_agua','def_fogo','def_terra',
      'esquiva','nivel_defesa','penetracao_fisica','penetracao_magica','espirito',
      'indice_dano','sobrevivencia']);
    const dados = {};
    for (const [k,v] of Object.entries((corpo && corpo.dados) || {})) {
      if (COLUNAS.has(k)) dados[k] = v;
    }
    const runas = Array.isArray(corpo && corpo.runas) ? corpo.runas : [];
    const status = (corpo && corpo.status) === 'revisar' ? 'revisar' : 'transcrito';
    const nota = status === 'revisar' ? ((corpo && corpo.nota) || null) : null;

    // 1) grava a foto no historico
    const fins = await supabase(env, '/fichas', { method: 'POST', prefer: 'return=minimal',
      body: { jogador_id: id, dados, runas } });
    if (!fins.ok) return new Response('erro ao gravar ficha', { status: 502 });

    // 2) atualiza o jogadores (estado atual)
    const patch = { ...dados, status, nota, atualizado_em: new Date().toISOString() };
    const up = await supabase(env, `/jogadores?id=eq.${id}`, { method: 'PATCH',
      prefer: 'return=minimal', body: patch });
    if (!up.ok) return new Response('erro ao atualizar jogador', { status: 502 });

    // 3) transcrito -> apaga o print e zera o print_url
    if (status === 'transcrito') {
      const r = await supabase(env, `/jogadores?id=eq.${id}&select=print_url`);
      const [row] = r.ok ? await r.json() : [];
      if (row && row.print_url) {
        await fetch(`${SUPABASE_STORAGE}/object/${BUCKET_PRINTS}/${encodeURIComponent(row.print_url)}`,
          { method: 'DELETE', headers: { apikey: env.SUPABASE_SERVICE_KEY,
            Authorization: `Bearer ${env.SUPABASE_SERVICE_KEY}` } });
        await supabase(env, `/jogadores?id=eq.${id}`, { method: 'PATCH',
          prefer: 'return=minimal', body: { print_url: null } });
      }
    }
    return Response.json({ ok: true, status });
  }
```
Nota: `new Date().toISOString()` é permitido no Worker (não é um workflow-script).

- [ ] **Step 2: `node --check tool/cron/worker.js`** → sem erro.

- [ ] **Step 3: Deploy + prova (controller/dono)**
`npx wrangler deploy` em `tool/cron/`. Depois um curl com um id de teste e `{status:'revisar',nota:'teste'}` deve marcar `revisar` sem apagar print; conferir no banco. (Fica no report; não some o print num `revisar`.)

- [ ] **Step 4: Commit**
```bash
git add tool/cron/worker.js
git commit -m "feat(worker): /transcricao/salvar grava ficha, atualiza jogador e descarta print"
```

---

### Task 5: Repositórios — `FichasRepository` e `JogadoresRepository.editar`

**Files:**
- Create: `lib/features/guild/data/fichas_repository.dart`
- Modify: `lib/features/guild/data/jogadores_repository.dart`
- Modify: `lib/core/di/injection.dart`
- Test: `test/guild/fichas_repository_test.dart` (fake sobre a interface)

**Interfaces:**
- Produces: `FichasRepository.historico(String jogadorId) → Future<Result<List<Ficha>>>` (ordenado, mais recente primeiro). `JogadoresRepository.editar(String id, Map<String,dynamic> campos) → Future<Result<void>>` (correção à mão; PATCH direto, sem nova foto nesta iteração — ver *Decisão adiada* do spec).

- [ ] **Step 1: Implementar `fichas_repository.dart`**
```dart
import '../../../core/result/result.dart';
import '../../../core/supabase/cliente.dart';
import '../domain/ficha.dart';
class FichasRepository {
  Future<Result<List<Ficha>>> historico(String jogadorId) async {
    try {
      final linhas = await supa.from('fichas').select()
        .eq('jogador_id', jogadorId).order('criada_em', ascending: false);
      return Success([for (final l in linhas) Ficha.fromJson(l)]);
    } catch (_) { return const Failure(GuildFailure(GuildErro.carregar)); }
  }
}
```

- [ ] **Step 2: `editar` no `jogadores_repository.dart`**
```dart
  Future<Result<void>> editar(String id, Map<String,dynamic> campos) async {
    try {
      await supa.from('jogadores').update(campos).eq('id', id);
      return const Success<void>(null);
    } catch (_) { return const Failure(GuildFailure(GuildErro.salvar)); }
  }
```

- [ ] **Step 3: Registrar no DI** — `..registerLazySingleton<FichasRepository>(FichasRepository.new)`.

- [ ] **Step 4: Teste do contrato** (um fake implementando `FichasRepository` devolvendo uma lista, provando que a VM do detalhe a consome — o teste real do consumo fica na Task 8). `flutter analyze` + `flutter test test/guild/` limpos.

- [ ] **Step 5: Commit**
```bash
git add lib/features/guild/data lib/core/di/injection.dart test/guild/fichas_repository_test.dart
git commit -m "feat(guild): FichasRepository (historico) e JogadoresRepository.editar"
```

---

### Task 6: O menu-hub (`/newageguild` vira menu)

**Files:**
- Create: `lib/features/guild/ui/menu_view.dart`
- Create: `lib/features/guild/domain/secao_guild.dart`
- Modify: `lib/features/guild/ui/guild_view.dart` (GuildLogado → MenuView)
- Test: `test/guild/menu_view_test.dart`

**Interfaces:**
- Consumes: `Papel` (`podeVerJogadores`), `RosterView({required papel})`.
- Produces: `MenuView({required Papel papel})` desenha os botões das seções gated por papel; *Jogadores* navega para `RosterView`; *Sala de Guerras* e *Financeiro* são *em breve* (desabilitados). `enum SecaoGuild { jogadores, salaGuerras, financeiro }` com `rotulo`, `icone`, `pronta`, e `bool visivelPara(Papel)`.

- [ ] **Step 1: `secao_guild.dart`** — o enum com: `jogadores` (pronta, visível a quem `podeVerJogadores`), `salaGuerras` (não pronta, visível a todos os papéis — é a casa do `sala_guerras`), `financeiro` (não pronta, admin/editor). `visivelPara(papel)` encapsula a regra.

- [ ] **Step 2: Teste do menu (widget)**
```dart
// monta MenuView(papel: Papel.salaGuerras) e verifica que NÃO há 'Jogadores'
// mas há 'Sala de Guerras'; com Papel.admin, há os três.
```
(Escrever o teste com `find.text('Jogadores')` etc.)

- [ ] **Step 3: `menu_view.dart`** — um grid responsivo de cartões (um por `SecaoGuild.visivelPara(papel)`), seguindo `PWColors`/`PWTheme.display`, com o login/papel/sair no topo. Cartão não-pronto desenha esmaecido e não navega. *Jogadores* faz `Navigator.of(context).push` para `RosterView(papel: papel)` **dentro do `MaterialApp`** (um push interno é navegação de página, permitido; a regra é não ter um `Navigator` que troque a rota-raiz por baixo do `MaterialApp`).

- [ ] **Step 4: Ligar em `guild_view.dart`** — `GuildLogado(:final papel) => MenuView(papel: papel)` no lugar de `RosterView` direto. O `onSair` passa a viver no `MenuView`.

- [ ] **Step 5: Rodar e commitar** — `flutter test`/`analyze` limpos.
```bash
git add lib/features/guild test/guild/menu_view_test.dart
git commit -m "feat(guild): menu-hub com Jogadores, Sala de Guerras e Financeiro"
```

---

### Task 7: A lista — busca, filtro, ordenação, responsiva, ícone de classe

**Files:**
- Modify: `lib/features/guild/ui/roster_view.dart`
- Modify: `lib/features/guild/ui/roster_view_model.dart`
- Create: `lib/features/guild/ui/roster_filtro.dart`
- Test: `test/guild/roster_filtro_test.dart`

**Interfaces:**
- Consumes: `Jogador`, `ClassIcon` (`lib/.../class_icon.dart`), `ocupacaoDaClasse`/`occupationOf`.
- Produces: `RosterFiltro({String busca, String? classe, String? status, OrdemColuna? ordem})` + `List<Jogador> aplicar(List<Jogador>)` puro e testável (busca por nome case-insensitive, filtro por classe, filtro por status, ordenação decrescente por coluna numérica com os sem-valor no fim). `enum OrdemColuna { nivelAtaque, hp, nivelDefesa, critico }`.

- [ ] **Step 1: Teste do filtro (TDD, puro)**
```dart
// lista de 3 Jogadores; aplicar busca 'moz' -> 1; filtro classe 'Místico' -> os místicos;
// ordem nivelAtaque -> decrescente, pendente (na=null) por último.
```

- [ ] **Step 2: Implementar `roster_filtro.dart`** — a função pura (sem Flutter), seguindo o teste.

- [ ] **Step 3: VM** — `RosterViewModel` guarda o `RosterFiltro` e expõe `jogadoresVisiveis` aplicando-o sobre a lista carregada; setters `setBusca`, `setClasse`, `setStatus`, `setOrdem` que reemitem.

- [ ] **Step 4: UI responsiva** — `roster_view.dart`: um campo de busca, chips de classe (das classes presentes) e de status, e uma tabela no largo (`LayoutBuilder`: >680px tabela com colunas ordenáveis; <=680 cartões com as colunas secundárias recolhidas). Ícone real via `ClassIcon`. Chip de status; a `nota` na linha quando `aRevisar`. O **nível de ataque** em destaque, nunca "NA". Cabeçalho de coluna clicável chama `setOrdem`. Seguir o visual dos Instâncias (tabela larga/cartão estreito) e `PWColors`.

- [ ] **Step 5: Rodar e commitar**
```bash
git add lib/features/guild test/guild/roster_filtro_test.dart
git commit -m "feat(guild): lista com busca, filtro por classe/status e ordenacao por coluna"
```

---

### Task 8: O detalhe do jogador — stats agrupados, delta e runas

**Files:**
- Create: `lib/features/guild/ui/detalhe_view.dart`
- Create: `lib/features/guild/ui/detalhe_view_model.dart`
- Create: `lib/features/guild/ui/detalhe_estado.dart`
- Modify: `lib/features/guild/ui/roster_view.dart` (tocar numa linha abre o detalhe)
- Test: `test/guild/detalhe_view_model_test.dart`

**Interfaces:**
- Consumes: `FichasRepository.historico`, `deltaEntre`, `Jogador`, `Ficha`, `Runa`.
- Produces: `DetalheViewModel(this._repo, this._jogador)` com `carregar()` que busca o histórico e emite `DetalhePronto(jogador, fichaAtual, delta, runas)`; `DetalheCarregando`/`DetalheFalha`.

- [ ] **Step 1: Teste da VM (TDD)**
```dart
// fake FichasRepository devolve 2 fichas (428 e 396);
// carregar -> DetalhePronto com delta['nivel_ataque'].rumo == Rumo.subiu
// e fichaAtual.dados['nivel_ataque'] == 428.
// Uma ficha só -> delta vazio.
```

- [ ] **Step 2: VM + estado** — `detalhe_estado.dart` (sealed) e `detalhe_view_model.dart` (Cubit) seguindo o teste: `carregar()` chama `historico`, pega a mais recente como atual e a penúltima para o delta.

- [ ] **Step 3: `detalhe_view.dart`** — cabeçalho (ícone de classe, nome, classe·clã·nível), a linha "atualizado em … por …", a faixa de evolução (delta do nível de ataque/crítico), os atributos agrupados (Ataque/Defesa/Outros) com o chip ↑/↓/— por campo, e a grade de runas + resumo por nível. *Quais campos exibir: usar todos agora, agrupados; a seleção fina é decisão adiada.* `PWColors`, números em Roboto (nunca Marcellus).

- [ ] **Step 4: Abrir do roster** — tocar numa linha/cartão em `roster_view.dart` dá `Navigator.push` para `DetalheView(jogador: j)`.

- [ ] **Step 5: Rodar e commitar**
```bash
git add lib/features/guild test/guild/detalhe_view_model_test.dart
git commit -m "feat(guild): detalhe do jogador com delta de evolucao e runas"
```

---

### Task 9: Editar — nova imagem ou correção à mão

**Files:**
- Modify: `lib/features/guild/ui/widgets/jogador_form.dart` (modo editar)
- Modify: `lib/features/guild/ui/detalhe_view.dart` (botão editar)
- Modify: `lib/features/guild/ui/roster_view_model.dart` (recarregar após editar)
- Test: `test/guild/jogador_form_test.dart` (o modo editar monta com os valores atuais)

**Interfaces:**
- Consumes: `JogadoresRepository.editar`, `RosterViewModel`, o fluxo de upload já existente.
- Produces: `JogadorForm` ganha um modo **editar** — recebe um `Jogador` existente; subir uma imagem nova re-transcreve (mesmo caminho do adicionar, mantendo o id → gera foto nova); ou editar um número à mão chama `editar(id, {campo: valor})`.

- [ ] **Step 1: Teste** — montar `JogadorForm` em modo editar com `mozaum` e verificar que o nome vem preenchido e travado (editar não troca o personagem).

- [ ] **Step 2: Implementar** — o `JogadorForm` aceita `Jogador? inicial`; no modo editar, o nome é fixo e há duas vias: "Nova imagem" (reusa o upload → `pendente` até eu reler, id preservado) e "Corrigir à mão" (campos editáveis → `editar`). A porta de editar vem do `DetalheView` (o "✎ editar").

- [ ] **Step 3: Rodar e commitar**
```bash
git add lib/features/guild test/guild/jogador_form_test.dart
git commit -m "feat(guild): editar jogador por nova imagem ou correcao a mao"
```

---

## Pós-implementação (não são tarefas de código)

- **Deploy**: merge na main + push dispara o Pages. O Worker (Task 4) precisa de `npx wrangler deploy` à parte.
- **O job de 6h**: o controller cria um `CronCreate` (`7 */6 * * *`, não-durável) cujo prompt é "lê os pendentes": listar via Worker, ler, chamar `/transcricao/salvar`, repetir. É setup de runtime, não código.
- **Campos exibidos**: refinar com o dono depois (decisão adiada).

## Self-Review

- **Cobertura do spec**: menu (T6), modelo duas tabelas (T1,T2), delta/evolução (T3,T8), lista busca/filtro/ordem (T7), detalhe+runas (T8), adicionar/editar (T9), transcrição/salvar (T4,T5 + pós), revisar+nota (T1,T4,T7,T8), atribuição (T1,T2,T4,T7,T8). Sala de Guerras/Financeiro: só o botão *em breve* (T6) — resto fora de escopo, como o spec manda. ✓
- **Placeholders**: nenhum "TBD" não-deliberado; as decisões adiadas estão no spec, não no caminho de execução.
- **Consistência de tipos**: `Ficha`/`Runa`/`deltaEntre` usados em T8 batem com T2/T3; `RosterFiltro`/`OrdemColuna` de T7 são consumidos pela UI da mesma task; `editar` de T5 é consumido em T9.
