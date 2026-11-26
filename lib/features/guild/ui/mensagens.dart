import '../../../core/result/result.dart';

/// The screen decides the wording of a typed failure — the repository only
/// says which [GuildErro] happened.
String mensagemDoGuildErro(GuildErro e) => switch (e) {
  GuildErro.credenciais => 'E-mail ou senha inválidos.',
  GuildErro.conexao => 'Sem conexão com o servidor.',
  GuildErro.salvar => 'Não deu para salvar.',
  GuildErro.carregar => 'Não deu para carregar os jogadores.',
  GuildErro.upload => 'Não deu para subir a imagem.',
};
