/// One player placed inside a war-room group.
///
/// `lider` is a flag per group membership, not per player — a member who
/// leads one group and is moved to another starts as a non-leader there,
/// which is `FormacaoGuerra.moverMembro`'s job to enforce.
class MembroGuerra {
  MembroGuerra({required this.jogadorId, this.lider = false});

  final String jogadorId;
  final bool lider;

  MembroGuerra comLider(bool valor) =>
      MembroGuerra(jogadorId: jogadorId, lider: valor);

  factory MembroGuerra.fromJson(Map<String, dynamic> json) => MembroGuerra(
    jogadorId: json['jogador_id'] as String,
    lider: json['lider'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {'jogador_id': jogadorId, 'lider': lider};
}
