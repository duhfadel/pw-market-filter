# Registro de Jogadores da Guild — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Um painel autenticado em `/guild` onde a staff da guild cria e vê jogadores com os status lidos do print, protegido por Supabase Auth e papéis.

**Architecture:** Rota Flutter nova (`Tela.guild`) atrás de login. Autenticação e dados via `supabase_flutter` (RLS fecha tudo ao anônimo). Domínio puro (`Papel`, `Jogador`) testado em Dart; repositórios embrulham o SDK; a UI reaproveita `PWColors`/`PWTheme` e o padrão ViewModel-é-Bloc das outras ferramentas.

**Tech Stack:** Flutter web, `supabase_flutter`, Supabase (Postgres + Auth + Storage), GetIt, flutter_bloc.

**Spec:** `docs/superpowers/specs/2026-11-26-registro-de-jogadores-design.md`

## Global Constraints

- **UI em português; comentários, docstrings e nomes de teste em inglês.** (CLAUDE.md)
- **Toda cor vem de `PWColors` como `static const`;** sem `Color(0xFF…)` fora de lá, exceto `Colors.transparent`.
- **Repositórios devolvem `Result<T>`, nunca lançam;** estado é Bloc (`setState` só para visual local).
- **Nada de `dart:io` em `lib/`** (o app é web).
- **RLS é a linha de defesa, não a UI.** Toda tabela/bucket novo nega o anônimo; provar com `curl` anônimo antes de confiar.
- **Supabase projeto `portal-pw`:** URL `https://yadfbwsolmkcaylbxviw.supabase.co`, chave publicável (anon) `sb_publishable_D2hgezeh5BbZVpt_QLeXwg_FowKweu2`.
- **Papéis:** `admin`, `staff_editor`, `staff_basico`, `sala_guerras`. Nesta iteração os três primeiros fazem CRUD de jogadores; `sala_guerras` não acessa nada aqui.
- **Iteração 1 (este plano):** login, papéis, criar/ver jogador, subir print. **Filtro por status e recortes de runas/gear por UI ficam para a 2ª iteração;** o schema já tem os campos de recorte, preenchidos na transcrição.
- `flutter analyze` tem de terminar com `No issues found!`.

---

### Task 1: Schema e RLS no Supabase

**Files:**
- Create: `supabase/migracoes/2026-11-26_registro_jogadores.sql` (versionado; aplicado no projeto via MCP/dashboard)

**Interfaces:**
- Produces: tabelas `public.perfis`, `public.jogadores`; função `public.papel_do(uuid) → text`; bucket privado `prints`. Nomes de coluna consumidos pelo `Jogador.fromJson` da Task 3.

- [ ] **Step 1: Escrever a migração**

```sql
-- perfis: liga uma conta do Auth a um papel
create table public.perfis (
  id uuid primary key references auth.users(id) on delete cascade,
  papel text not null check (papel in ('admin','staff_editor','staff_basico','sala_guerras')),
  nome text,
  criado_em timestamptz not null default now()
);
alter table public.perfis enable row level security;

-- o papel do usuário, para as policies lerem sem recursão (security definer)
create or replace function public.papel_do(uid uuid)
returns text language sql security definer stable as $$
  select papel from public.perfis where id = uid
$$;

create table public.jogadores (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  cla text, classe text, nivel int, despertares int, cultivo text, limite text,
  hp int, mp int,
  ataque_fisico text, ataque_magico text, acerto int, nivel_ataque int, furia text,
  def_fisica int, def_metal int, def_madeira int, def_agua int, def_fogo int, def_terra int,
  esquiva int, nivel_defesa int, critico text, canalizacao text,
  penetracao_fisica int, penetracao_magica int, espirito int,
  indice_dano bigint, sobrevivencia bigint,
  print_url text, recorte_runas_url text, recorte_gear_url text,
  status text not null default 'pendente' check (status in ('pendente','transcrito')),
  criado_por uuid references auth.users(id),
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);
alter table public.jogadores enable row level security;

-- perfis: cada um lê o seu; só admin escreve
create policy perfis_self_select on public.perfis
  for select to authenticated using (id = auth.uid());
create policy perfis_admin_all on public.perfis
  for all to authenticated
  using (public.papel_do(auth.uid()) = 'admin')
  with check (public.papel_do(auth.uid()) = 'admin');

-- jogadores: admin e os dois staff leem e escrevem; sala_guerras e anônimo, nada
create policy jogadores_staff_select on public.jogadores
  for select to authenticated
  using (public.papel_do(auth.uid()) in ('admin','staff_editor','staff_basico'));
create policy jogadores_staff_write on public.jogadores
  for all to authenticated
  using (public.papel_do(auth.uid()) in ('admin','staff_editor','staff_basico'))
  with check (public.papel_do(auth.uid()) in ('admin','staff_editor','staff_basico'));

-- bucket privado dos prints
insert into storage.buckets (id, name, public) values ('prints','prints',false)
  on conflict (id) do nothing;
create policy prints_staff_rw on storage.objects
  for all to authenticated
  using (bucket_id = 'prints' and public.papel_do(auth.uid()) in ('admin','staff_editor','staff_basico'))
  with check (bucket_id = 'prints' and public.papel_do(auth.uid()) in ('admin','staff_editor','staff_basico'));
```

- [ ] **Step 2: Aplicar no projeto** via `mcp__plugin_supabase__apply_migration` (ou colar no SQL editor do dashboard). Criar **uma conta admin** de teste no painel Auth e inserir seu `perfis` (`insert into perfis (id, papel, nome) values ('<uid>','admin','dono')`).

- [ ] **Step 3: Provar o RLS com curl (anônimo nega)**

Run:
```bash
curl -s -o /dev/null -w "%{http_code}\n" \
  "https://yadfbwsolmkcaylbxviw.supabase.co/rest/v1/jogadores?select=id" \
  -H "apikey: sb_publishable_D2hgezeh5BbZVpt_QLeXwg_FowKweu2"
```
Expected: devolve `[]` (zero linhas) — o anônimo não lê nada. Um `insert` anônimo responde `401/403`. Crê no `select` de volta, não no status (ver a nota do mapa no CLAUDE.md).

- [ ] **Step 4: Commit**
```bash
git add supabase/migracoes/2026-11-26_registro_jogadores.sql
git commit -m "feat(guild): schema e RLS do registro de jogadores"
```

---

### Task 2: Dependência supabase_flutter e inicialização

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/main.dart` (o `main()` antes do `runApp`)
- Create: `lib/core/supabase/cliente.dart`

**Interfaces:**
- Produces: `Supabase.instance.client` inicializado; `supa` (getter de conveniência) em `cliente.dart`.

- [ ] **Step 1: Adicionar a dependência** em `pubspec.yaml` (bloco `dependencies:`), e `flutter pub get`:
```yaml
  supabase_flutter: ^2.8.0
```
Run: `flutter pub get` — Expected: resolve sem conflito.

- [ ] **Step 2: Criar o getter de conveniência** `lib/core/supabase/cliente.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// O endereço e a chave publicável (anon) do projeto `portal-pw`. A chave vai
/// no bundle de propósito — quem protege os dados é o RLS, não escondê-la.
const _url = 'https://yadfbwsolmkcaylbxviw.supabase.co';
const _anon = 'sb_publishable_D2hgezeh5BbZVpt_QLeXwg_FowKweu2';

/// Chamado uma vez em `main()` antes do `runApp`.
Future<void> iniciarSupabase() =>
    Supabase.initialize(url: _url, anonKey: _anon);

/// Atalho para o cliente já inicializado.
SupabaseClient get supa => Supabase.instance.client;
```

- [ ] **Step 3: Chamar na partida** — em `lib/main.dart`, tornar `main` async e inicializar antes do `runApp`:
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await iniciarSupabase();
  configureDependencies();
  runApp(const PortalApp());
}
```
(Importar `core/supabase/cliente.dart`. Manter a chamada a `configureDependencies()` que já existe.)

- [ ] **Step 4: Verificar que compila** — Run: `flutter analyze` → Expected: `No issues found!`. Run: `flutter test test/rotas_test.dart` → Expected: passa (nada de rota mudou ainda).

- [ ] **Step 5: Commit**
```bash
git add pubspec.yaml pubspec.lock lib/core/supabase/cliente.dart lib/main.dart
git commit -m "feat(guild): inicializar supabase_flutter"
```

---

### Task 3: Domínio — Papel e Jogador

**Files:**
- Create: `lib/features/guild/domain/papel.dart`
- Create: `lib/features/guild/domain/jogador.dart`
- Test: `test/guild/papel_test.dart`, `test/guild/jogador_test.dart`

**Interfaces:**
- Produces: `enum Papel { admin, staffEditor, staffBasico, salaGuerras }` com `Papel.doBanco(String)` e `papel.podeEditarJogadores`; `class Jogador` com `Jogador.fromJson(Map)` e `toJson()`.

- [ ] **Step 1: Teste do Papel (falha)** — `test/guild/papel_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/guild/domain/papel.dart';

void main() {
  test('reads the role name the database stores', () {
    expect(Papel.doBanco('staff_editor'), Papel.staffEditor);
    expect(Papel.doBanco('admin'), Papel.admin);
  });

  test('an unknown role is null, never a default', () {
    expect(Papel.doBanco('xpto'), isNull);
    expect(Papel.doBanco(null), isNull);
  });

  test('every edit role may edit players, sala_guerras may not', () {
    expect(Papel.admin.podeEditarJogadores, isTrue);
    expect(Papel.staffEditor.podeEditarJogadores, isTrue);
    expect(Papel.staffBasico.podeEditarJogadores, isTrue);
    expect(Papel.salaGuerras.podeEditarJogadores, isFalse);
  });
}
```

- [ ] **Step 2: Rodar — FAIL** — Run: `flutter test test/guild/papel_test.dart` → Expected: FAIL (arquivo não existe).

- [ ] **Step 3: Implementar Papel** — `lib/features/guild/domain/papel.dart`:
```dart
/// Who someone is in the guild panel. The string on the left is exactly what
/// `perfis.papel` stores in the database — the join key, never translated.
enum Papel {
  admin('admin'),
  staffEditor('staff_editor'),
  staffBasico('staff_basico'),
  salaGuerras('sala_guerras');

  const Papel(this.noBanco);
  final String noBanco;

  /// `null` for an unknown or absent role — an account with no row in `perfis`
  /// has no power, which is not the same as a default role.
  static Papel? doBanco(String? valor) {
    for (final p in Papel.values) {
      if (p.noBanco == valor) return p;
    }
    return null;
  }

  /// The three edit roles may create/edit/remove players this iteration;
  /// `salaGuerras` is for the second piece and touches nothing here.
  bool get podeEditarJogadores => this != Papel.salaGuerras;
}
```

- [ ] **Step 4: Rodar — PASS** — Run: `flutter test test/guild/papel_test.dart` → Expected: PASS.

- [ ] **Step 5: Teste do Jogador (falha)** — `test/guild/jogador_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/guild/domain/jogador.dart';

void main() {
  test('round-trips the fields the character sheet prints', () {
    const json = {
      'id': 'abc', 'nome': 'Mozaum', 'cla': 'Ragnarok', 'classe': 'Retalhador',
      'nivel': 105, 'despertares': 2, 'cultivo': 'Alma Celestial',
      'limite': 'Céu Soberano IV', 'hp': 59225, 'nivel_ataque': 428,
      'critico': '74%', 'status': 'transcrito',
    };
    final j = Jogador.fromJson(json);
    expect(j.nome, 'Mozaum');
    expect(j.nivelAtaque, 428);
    expect(j.hp, 59225);
    expect(j.transcrito, isTrue);
    // toJson não escreve campos nulos, para não afirmar zero onde é "oculto"
    expect(j.toJson().containsKey('mp'), isFalse);
  });

  test('pending is the honest state of a player whose print was not read yet', () {
    final j = Jogador.fromJson(const {'id': 'x', 'nome': 'Fulano', 'status': 'pendente'});
    expect(j.transcrito, isFalse);
    expect(j.nivelAtaque, isNull);
  });
}
```

- [ ] **Step 6: Rodar — FAIL** — Run: `flutter test test/guild/jogador_test.dart` → Expected: FAIL.

- [ ] **Step 7: Implementar Jogador** — `lib/features/guild/domain/jogador.dart`:
```dart
/// One character's effective stats, as read from the game's character sheet.
/// Numbers that are a range on screen (`100039-104485`) stay as text; a field
/// the player hid (`Oculto`) is null — null is "not informed", never zero.
class Jogador {
  const Jogador({
    required this.id,
    required this.nome,
    this.cla, this.classe, this.nivel, this.despertares, this.cultivo,
    this.limite, this.hp, this.mp, this.ataqueFisico, this.ataqueMagico,
    this.acerto, this.nivelAtaque, this.furia,
    this.defFisica, this.defMetal, this.defMadeira, this.defAgua,
    this.defFogo, this.defTerra, this.esquiva, this.nivelDefesa,
    this.critico, this.canalizacao, this.penetracaoFisica, this.penetracaoMagica,
    this.espirito, this.indiceDano, this.sobrevivencia,
    this.printUrl, this.recorteRunasUrl, this.recorteGearUrl,
    this.status = 'pendente',
  });

  final String id;
  final String nome;
  final String? cla, classe, cultivo, limite;
  final int? nivel, despertares;
  final int? hp, mp, acerto, nivelAtaque;
  final String? ataqueFisico, ataqueMagico, furia, critico, canalizacao;
  final int? defFisica, defMetal, defMadeira, defAgua, defFogo, defTerra;
  final int? esquiva, nivelDefesa, penetracaoFisica, penetracaoMagica, espirito;
  final int? indiceDano, sobrevivencia;
  final String? printUrl, recorteRunasUrl, recorteGearUrl;
  final String status;

  bool get transcrito => status == 'transcrito';

  factory Jogador.fromJson(Map<String, dynamic> j) => Jogador(
        id: j['id'] as String,
        nome: j['nome'] as String,
        cla: j['cla'] as String?, classe: j['classe'] as String?,
        nivel: j['nivel'] as int?, despertares: j['despertares'] as int?,
        cultivo: j['cultivo'] as String?, limite: j['limite'] as String?,
        hp: j['hp'] as int?, mp: j['mp'] as int?,
        ataqueFisico: j['ataque_fisico'] as String?,
        ataqueMagico: j['ataque_magico'] as String?,
        acerto: j['acerto'] as int?, nivelAtaque: j['nivel_ataque'] as int?,
        furia: j['furia'] as String?,
        defFisica: j['def_fisica'] as int?, defMetal: j['def_metal'] as int?,
        defMadeira: j['def_madeira'] as int?, defAgua: j['def_agua'] as int?,
        defFogo: j['def_fogo'] as int?, defTerra: j['def_terra'] as int?,
        esquiva: j['esquiva'] as int?, nivelDefesa: j['nivel_defesa'] as int?,
        critico: j['critico'] as String?, canalizacao: j['canalizacao'] as String?,
        penetracaoFisica: j['penetracao_fisica'] as int?,
        penetracaoMagica: j['penetracao_magica'] as int?,
        espirito: j['espirito'] as int?,
        indiceDano: j['indice_dano'] as int?,
        sobrevivencia: j['sobrevivencia'] as int?,
        printUrl: j['print_url'] as String?,
        recorteRunasUrl: j['recorte_runas_url'] as String?,
        recorteGearUrl: j['recorte_gear_url'] as String?,
        status: (j['status'] as String?) ?? 'pendente',
      );

  /// Omits null fields so the row never asserts a zero where the player hid
  /// the value — the same rule the market index follows.
  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{'nome': nome, 'status': status};
    void put(String k, Object? v) { if (v != null) m[k] = v; }
    put('cla', cla); put('classe', classe); put('nivel', nivel);
    put('despertares', despertares); put('cultivo', cultivo); put('limite', limite);
    put('hp', hp); put('mp', mp); put('ataque_fisico', ataqueFisico);
    put('ataque_magico', ataqueMagico); put('acerto', acerto);
    put('nivel_ataque', nivelAtaque); put('furia', furia);
    put('def_fisica', defFisica); put('def_metal', defMetal);
    put('def_madeira', defMadeira); put('def_agua', defAgua);
    put('def_fogo', defFogo); put('def_terra', defTerra);
    put('esquiva', esquiva); put('nivel_defesa', nivelDefesa);
    put('critico', critico); put('canalizacao', canalizacao);
    put('penetracao_fisica', penetracaoFisica);
    put('penetracao_magica', penetracaoMagica); put('espirito', espirito);
    put('indice_dano', indiceDano); put('sobrevivencia', sobrevivencia);
    put('print_url', printUrl); put('recorte_runas_url', recorteRunasUrl);
    put('recorte_gear_url', recorteGearUrl);
    return m;
  }
}
```

- [ ] **Step 8: Rodar — PASS** — Run: `flutter test test/guild/` → Expected: PASS. Run: `flutter analyze` → `No issues found!`.

- [ ] **Step 9: Commit**
```bash
git add lib/features/guild/domain test/guild/papel_test.dart test/guild/jogador_test.dart
git commit -m "feat(guild): domínio Papel e Jogador"
```

---

### Task 4: Rota /guild

**Files:**
- Modify: `lib/core/rotas.dart` (enum `Tela`, `resolverRota`)
- Modify: `lib/main.dart` (o `switch` do `onGenerateRoute`)
- Test: `test/rotas_test.dart`

**Interfaces:**
- Consumes: `GuildView` (Task 7) no `main.dart`.
- Produces: `Tela.guild`; `resolverRota('/guild') == RotaTela(Tela.guild)`.

- [ ] **Step 1: Teste da rota (falha)** — acrescentar a `test/rotas_test.dart`:
```dart
  test('/guild resolves to the guild panel', () {
    expect(resolverRota('/guild'), const RotaTela(Tela.guild));
  });
```

- [ ] **Step 2: Rodar — FAIL** — Run: `flutter test test/rotas_test.dart` → Expected: FAIL (`Tela.guild` não existe).

- [ ] **Step 3: Adicionar ao enum e à resolução** — em `lib/core/rotas.dart`, juntar `guild,` ao `enum Tela`, e antes do `return const RotaTela(Tela.escolha);` final:
```dart
  if (segments.first == 'guild' && segments.length == 1) {
    return const RotaTela(Tela.guild);
  }
```

- [ ] **Step 4: Rodar — PASS** — Run: `flutter test test/rotas_test.dart` → Expected: PASS.

- [ ] **Step 5: Ligar no main.dart** — no `switch (resolvida)` do `onGenerateRoute`, acrescentar (importando `features/guild/ui/guild_view.dart`):
```dart
          RotaTela(tela: Tela.guild) => const GuildView(),
```
(Esta linha só compila depois da Task 7; se executar em ordem, deixe o import e a linha comentados até lá, ou faça a Task 7 antes do Step 5.)

- [ ] **Step 6: Commit**
```bash
git add lib/core/rotas.dart test/rotas_test.dart
git commit -m "feat(guild): rota /guild"
```

---

### Task 5: AuthRepository

**Files:**
- Create: `lib/features/guild/data/auth_repository.dart`
- Modify: `lib/core/di/injection.dart`

**Interfaces:**
- Consumes: `supa` (Task 2), `Papel` (Task 3), `Result`/`AppFailure` (`core/result/`).
- Produces: `AuthRepository` com `Future<Result<void>> entrar(String email, String senha)`, `Future<void> sair()`, `Session? get sessao`, `Future<Papel?> meuPapel()`, `Stream<AuthState> get mudancas`.

- [ ] **Step 1: Implementar** — `lib/features/guild/data/auth_repository.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/result/result.dart';
import '../../../core/supabase/cliente.dart';
import '../domain/papel.dart';

/// The guild panel's door. Wraps Supabase Auth; the session and its refresh
/// are the SDK's job, which is the whole reason the dependency was approved.
class AuthRepository {
  Session? get sessao => supa.auth.currentSession;
  Stream<AuthState> get mudancas => supa.auth.onAuthStateChange;

  Future<Result<void>> entrar(String email, String senha) async {
    try {
      await supa.auth.signInWithPassword(email: email.trim(), password: senha);
      return const Ok(null);
    } on AuthException catch (e) {
      // Mensagem genérica de propósito: não revelar se o e-mail existe.
      return Err(AppFailure(e.message.isEmpty ? 'Não deu para entrar.' : 'E-mail ou senha inválidos.'));
    } catch (_) {
      return const Err(AppFailure('Sem conexão com o servidor.'));
    }
  }

  Future<void> sair() => supa.auth.signOut();

  /// O papel do usuário logado, lido de `perfis`. `null` se não há sessão ou
  /// a conta não tem papel — e sem papel não se faz nada.
  Future<Papel?> meuPapel() async {
    final uid = sessao?.user.id;
    if (uid == null) return null;
    try {
      final linha = await supa.from('perfis').select('papel').eq('id', uid).maybeSingle();
      return Papel.doBanco(linha?['papel'] as String?);
    } catch (_) {
      return null;
    }
  }
}
```
(Conferir a assinatura de `Ok`/`Err`/`AppFailure` em `lib/core/result/` e ajustar os construtores a ela — ver um repositório existente, ex. `features/home/data/novidade_repository.dart`.)

- [ ] **Step 2: Registrar no DI** — em `configureDependencies()`:
```dart
    ..registerLazySingleton<AuthRepository>(AuthRepository.new)
```

- [ ] **Step 3: Verificar** — Run: `flutter analyze` → `No issues found!`. (Repositório que embrulha rede não ganha teste unitário; é provado pela UI e pelo curl do RLS.)

- [ ] **Step 4: Commit**
```bash
git add lib/features/guild/data/auth_repository.dart lib/core/di/injection.dart
git commit -m "feat(guild): AuthRepository sobre supabase_flutter"
```

---

### Task 6: JogadoresRepository

**Files:**
- Create: `lib/features/guild/data/jogadores_repository.dart`
- Modify: `lib/core/di/injection.dart`

**Interfaces:**
- Consumes: `supa`, `Jogador`, `Result`.
- Produces: `JogadoresRepository` com `Future<Result<List<Jogador>>> lista()`, `Future<Result<void>> criar(Jogador j)`, `Future<Result<String>> subirPrint(Uint8List bytes, String nomeArquivo)`.

- [ ] **Step 1: Implementar** — `lib/features/guild/data/jogadores_repository.dart`:
```dart
import 'dart:typed_data';

import '../../../core/result/result.dart';
import '../../../core/supabase/cliente.dart';
import '../domain/jogador.dart';

class JogadoresRepository {
  Future<Result<List<Jogador>>> lista() async {
    try {
      final linhas = await supa.from('jogadores').select().order('nome');
      return Ok([for (final l in linhas) Jogador.fromJson(l)]);
    } catch (_) {
      return const Err(AppFailure('Não deu para carregar os jogadores.'));
    }
  }

  Future<Result<void>> criar(Jogador j) async {
    try {
      await supa.from('jogadores').insert(j.toJson());
      return const Ok(null);
    } catch (_) {
      return const Err(AppFailure('Não deu para salvar.'));
    }
  }

  /// Sobe o print para o bucket privado `prints` e devolve o caminho guardado
  /// em `jogadores.print_url`. O nome inclui um sufixo único para dois prints
  /// do mesmo nick não se sobreporem.
  Future<Result<String>> subirPrint(Uint8List bytes, String nomeArquivo) async {
    try {
      final caminho = 'prints/$nomeArquivo';
      await supa.storage.from('prints').uploadBinary(caminho, bytes);
      return Ok(caminho);
    } catch (_) {
      return const Err(AppFailure('Não deu para subir a imagem.'));
    }
  }
}
```

- [ ] **Step 2: Registrar no DI** — `..registerLazySingleton<JogadoresRepository>(JogadoresRepository.new)`.

- [ ] **Step 3: Verificar** — Run: `flutter analyze` → `No issues found!`.

- [ ] **Step 4: Commit**
```bash
git add lib/features/guild/data/jogadores_repository.dart lib/core/di/injection.dart
git commit -m "feat(guild): JogadoresRepository (listar, criar, subir print)"
```

---

### Task 7: GuildView — o portão (login vs painel)

**Files:**
- Create: `lib/features/guild/ui/guild_view.dart`
- Create: `lib/features/guild/ui/login_view.dart`
- Modify: `lib/main.dart` (descomentar o case da Task 4 Step 5)

**Interfaces:**
- Consumes: `AuthRepository` (DI), `PWColors`/`PWTheme`, `Cabecalho`.
- Produces: `GuildView` (widget sem parâmetros), `LoginView`.

- [ ] **Step 1: LoginView** — `lib/features/guild/ui/login_view.dart`: um `StatefulWidget` com dois `TextField` (e-mail, senha), um botão "Entrar" que chama `getIt<AuthRepository>().entrar(...)`, mostra a mensagem de erro do `Result` e um `CircularProgressIndicator` enquanto espera. Cores de `PWColors`, título em `PWTheme.display`. (Sem dígitos no título — Marcellus.)

- [ ] **Step 2: GuildView** — `lib/features/guild/ui/guild_view.dart`: escuta `getIt<AuthRepository>().mudancas` (um `StreamBuilder<AuthState>`); se `sessao == null` mostra `LoginView`; senão mostra `RosterView` (Task 8). `Scaffold` com `Cabecalho(versao: null)` e `automaticallyImplyLeading: false`, como as outras telas.

- [ ] **Step 3: Ligar a rota** — descomentar/garantir em `main.dart`: `RotaTela(tela: Tela.guild) => const GuildView(),` e o import.

- [ ] **Step 4: Verificar no navegador** — `flutter run -d chrome`, abrir `/#/guild`: aparece o login; com a conta admin de teste (Task 1), entra e vê a tela vazia da lista; sair volta ao login. Run: `flutter analyze` → `No issues found!`.

- [ ] **Step 5: Commit**
```bash
git add lib/features/guild/ui/guild_view.dart lib/features/guild/ui/login_view.dart lib/main.dart
git commit -m "feat(guild): portão /guild (login ou painel)"
```

---

### Task 8: RosterView — ver e adicionar jogadores

**Files:**
- Create: `lib/features/guild/ui/roster_view.dart`
- Create: `lib/features/guild/ui/roster_view_model.dart`
- Create: `lib/features/guild/ui/roster_state.dart`
- Create: `lib/features/guild/ui/widgets/jogador_form.dart`
- Modify: `lib/core/di/injection.dart`
- Test: `test/guild/roster_view_model_test.dart`

**Interfaces:**
- Consumes: `JogadoresRepository`, `AuthRepository`, `Jogador`, `Papel`.
- Produces: `RosterViewModel` (Bloc: `carregar()`, `adicionar(Jogador, {Uint8List? print})`), estados `RosterLoading`/`RosterPronto(List<Jogador>, Papel?)`/`RosterFalha`.

- [ ] **Step 1: Teste do ViewModel (falha)** — `test/guild/roster_view_model_test.dart`: com um `JogadoresRepository` falso que devolve `Ok([...])`, `carregar()` emite `RosterPronto` com a lista; e `adicionar` com papel `salaGuerras` **não** chama `criar` (defesa em profundidade além do RLS). Use um fake injetado (o VM recebe os repos no construtor).

- [ ] **Step 2: Rodar — FAIL.**

- [ ] **Step 3: Implementar o ViewModel/estados** — `RosterViewModel extends Cubit<RosterState>` recebendo `JogadoresRepository` e `Papel?` (o papel já resolvido pela GuildView). `adicionar` curto-circuita se `!papel.podeEditarJogadores`.

- [ ] **Step 4: Rodar — PASS.**

- [ ] **Step 5: A tela** — `RosterView`: um `BlocBuilder` que mostra a lista (uma linha por jogador: nome, classe, limite, nível de ataque, HP; os `pendente` com um selo "à espera de leitura"). Um botão "Adicionar jogador" (só se `papel.podeEditarJogadores`) abre `JogadorForm` num diálogo/rota. `JogadorForm`: campos do `Jogador` + um seletor de imagem (`image_picker` web já disponível? senão `FileUploadInputElement` via `package:web`) que lê os bytes e passa para `adicionar`. Ao salvar: sobe o print (se houver) e cria o jogador com `status='pendente'`.

- [ ] **Step 6: Registrar no DI** — `..registerFactory<RosterViewModel>(() => RosterViewModel(getIt<JogadoresRepository>()))` (o papel é passado pela view ao montar; ajuste a fábrica se preferir injetar o papel por parâmetro do `create` do BlocProvider).

- [ ] **Step 7: Verificar no navegador** — logado, adicionar um jogador com um print de teste: aparece na lista como `pendente`; recarregar mantém. Conferir no Supabase que a linha e o objeto no bucket existem. Run: `flutter analyze` → `No issues found!`. Run: `flutter test test/guild/` → PASS.

- [ ] **Step 8: Commit**
```bash
git add lib/features/guild/ui test/guild/roster_view_model_test.dart lib/core/di/injection.dart
git commit -m "feat(guild): lista e cadastro de jogadores"
```

---

### Task 9: Entrada no menu e verificação final

**Files:**
- Modify: `lib/features/home/domain/tool.dart` (ou onde as ferramentas/entradas são declaradas) — opcional, só se o painel deve aparecer para quem tem o link.

**Interfaces:**
- Consumes: nada novo.

- [ ] **Step 1: Decisão de visibilidade** — o painel é **privado e não anunciado** (só quem tem o endereço e a conta entra), como a página `/newage`. Portanto **não** entra no menu público de ferramentas. Confirmar que nada em `tool.dart`/`Cabecalho` o lista.

- [ ] **Step 2: Suíte inteira** — Run: `flutter test` → Expected: `All tests passed!`. Run: `flutter analyze` → `No issues found!`.

- [ ] **Step 3: Prova de RLS final (curl)** — repetir o curl anônimo da Task 1 e um `insert` anônimo; confirmar que nenhum devolve dado. Logado como `staff_basico` de teste, confirmar que NÃO consegue `select` em `perfis` de outro e NÃO acessa a (futura) sala de guerras.

- [ ] **Step 4: Commit (se houve mudança)**
```bash
git add -A
git commit -m "chore(guild): painel privado, fora do menu público"
```

---

## Self-Review

**Spec coverage:** auth+papéis (Tasks 1,3,5,7) ✓; base de jogadores (Tasks 1,3,6,8) ✓; upload do print (Tasks 1,6,8) ✓; RLS fechado ao anônimo (Task 1, verificado 1/9) ✓; campos de recorte no schema (Task 1) ✓ — preenchidos na transcrição, UI deles é 2ª iteração (fora do escopo, declarado) ✓; filtro por status — **fora do escopo por decisão (2ª iteração)**, não há task, correto. Sala de guerras — 2º projeto, só o papel existe (Task 1) ✓.

**Placeholder scan:** sem TBD/TODO; o único "ajustar à assinatura de `Result`" (Task 5) aponta um arquivo concreto a conferir, não um vazio.

**Type consistency:** `Papel.doBanco`/`podeEditarJogadores`, `Jogador.fromJson`/`toJson`/`transcrito`, `AuthRepository.entrar/sair/sessao/meuPapel/mudancas`, `JogadoresRepository.lista/criar/subirPrint`, `Tela.guild` — usados com os mesmos nomes nas tasks que os consomem.
