import 'membro_guerra.dart';

/// A named, coloured group inside a war formation — a "party" slot that
/// holds up to ten members.
class GrupoGuerra {
  GrupoGuerra({required this.nome, required this.cor, this.membros = const []});

  final String nome;
  final String cor;
  final List<MembroGuerra> membros;

  /// A full group refuses new members; `FormacaoGuerra.moverMembro` reads
  /// this before adding anyone.
  bool get cheio => membros.length >= 10;

  GrupoGuerra _comMembros(List<MembroGuerra> novos) =>
      GrupoGuerra(nome: nome, cor: cor, membros: novos);

  GrupoGuerra comMembro(MembroGuerra membro) =>
      _comMembros([...membros, membro]);

  GrupoGuerra semMembro(String jogadorId) =>
      _comMembros(membros.where((m) => m.jogadorId != jogadorId).toList());

  /// Toggles whether the named member leads this group. A member absent
  /// from this group is left alone — there is nothing here to toggle.
  GrupoGuerra alternarLider(String jogadorId) => _comMembros([
    for (final m in membros)
      if (m.jogadorId == jogadorId) m.comLider(!m.lider) else m,
  ]);

  GrupoGuerra renomear(String novoNome) =>
      GrupoGuerra(nome: novoNome, cor: cor, membros: membros);

  GrupoGuerra recolorir(String novaCor) =>
      GrupoGuerra(nome: nome, cor: novaCor, membros: membros);

  factory GrupoGuerra.fromJson(Map<String, dynamic> json) => GrupoGuerra(
    nome: json['nome'] as String,
    cor: json['cor'] as String,
    membros: [
      for (final m in (json['membros'] as List? ?? const []))
        MembroGuerra.fromJson(m as Map<String, dynamic>),
    ],
  );

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'cor': cor,
    'membros': [for (final m in membros) m.toJson()],
  };
}
