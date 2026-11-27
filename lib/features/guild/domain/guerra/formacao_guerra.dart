import 'grupo_guerra.dart';
import 'membro_guerra.dart';

/// The whole war-room board: an ordered list of groups a staff member drags
/// players between. Every operation returns a new formation — nothing here
/// mutates in place, so a screen can diff old against new to animate a move.
class FormacaoGuerra {
  FormacaoGuerra({required this.grupos});

  final List<GrupoGuerra> grupos;

  static const maxGrupos = 20;
  static const maxMembros = 10;

  /// Moves a player to `destino` (a group index), removing them from
  /// wherever they currently sit first. `destino == null` just removes
  /// them from the formation. A full destination group refuses the move
  /// outright — the formation comes back exactly as it was, member still
  /// wherever they were before the call.
  ///
  /// A member that lands in a new group always arrives as a non-leader:
  /// leadership is a fact about a group, not about the player, and does
  /// not travel with a move.
  FormacaoGuerra moverMembro(String jogadorId, int? destino) {
    if (destino != null) {
      if (destino < 0 || destino >= grupos.length || grupos[destino].cheio) {
        return this;
      }
    }

    final semOrigem = [for (final g in grupos) g.semMembro(jogadorId)];

    if (destino == null) {
      return FormacaoGuerra(grupos: semOrigem);
    }

    final comDestino = [
      for (var i = 0; i < semOrigem.length; i++)
        if (i == destino)
          semOrigem[i].comMembro(MembroGuerra(jogadorId: jogadorId))
        else
          semOrigem[i],
    ];
    return FormacaoGuerra(grupos: comDestino);
  }

  /// Adds a new empty group, up to the twenty-group cap. Past the cap the
  /// formation comes back unchanged — a board with no more room for
  /// another party rather than a silent error.
  FormacaoGuerra comGrupo(String nome, String cor) {
    if (grupos.length >= maxGrupos) return this;
    return FormacaoGuerra(
      grupos: [
        ...grupos,
        GrupoGuerra(nome: nome, cor: cor),
      ],
    );
  }

  /// Drops the group at `indice` entirely, along with whoever was in it.
  FormacaoGuerra semGrupo(int indice) => FormacaoGuerra(
    grupos: [
      for (var i = 0; i < grupos.length; i++)
        if (i != indice) grupos[i],
    ],
  );

  /// Every player id placed in any group, regardless of which.
  Set<String> colocados() => {
    for (final g in grupos)
      for (final m in g.membros) m.jogadorId,
  };

  /// Roster ids that are not currently placed in any group — the pool a
  /// staff member still has to drag from.
  List<String> disponiveis(List<String> rosterIds) {
    final colocadosIds = colocados();
    return [
      for (final id in rosterIds)
        if (!colocadosIds.contains(id)) id,
    ];
  }

  /// A formation with every member outside `rosterIds` dropped — someone
  /// who left the guild stops holding a slot in a group they can no
  /// longer be part of.
  FormacaoGuerra podada(Set<String> rosterIds) => FormacaoGuerra(
    grupos: [
      for (final g in grupos)
        GrupoGuerra(
          nome: g.nome,
          cor: g.cor,
          membros: [
            for (final m in g.membros)
              if (rosterIds.contains(m.jogadorId)) m,
          ],
        ),
    ],
  );

  factory FormacaoGuerra.fromJson(Map<String, dynamic> json) => FormacaoGuerra(
    grupos: [
      for (final g in (json['grupos'] as List? ?? const []))
        GrupoGuerra.fromJson(g as Map<String, dynamic>),
    ],
  );

  Map<String, dynamic> toJson() => {
    'grupos': [for (final g in grupos) g.toJson()],
  };
}
