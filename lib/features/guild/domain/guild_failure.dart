import '../../../core/result/result.dart';

/// Why a guild-panel action failed. The screen maps each to its own message —
/// typed, never a bare string, the same rule `AppFailure` keeps everywhere.
enum GuildErro { credenciais, conexao, salvar, carregar, upload }

class GuildFailure extends AppFailure {
  const GuildFailure(this.erro);
  final GuildErro erro;
}
