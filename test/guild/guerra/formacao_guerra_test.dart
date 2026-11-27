import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/guild/domain/guerra/formacao_guerra.dart';
import 'package:pw_market_filter/features/guild/domain/guerra/grupo_guerra.dart';
import 'package:pw_market_filter/features/guild/domain/guerra/membro_guerra.dart';

FormacaoGuerra umaFormacao() => FormacaoGuerra(
  grupos: [
    GrupoGuerra(
      nome: 'Pt 1',
      cor: '#E8707C',
      membros: [MembroGuerra(jogadorId: 'a')],
    ),
    GrupoGuerra(nome: 'Pt 2', cor: '#56A8F5', membros: const []),
  ],
);

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
    final cheio = GrupoGuerra(
      nome: 'x',
      cor: '#fff',
      membros: [for (var i = 0; i < 10; i++) MembroGuerra(jogadorId: 'm$i')],
    );
    final f = FormacaoGuerra(
      grupos: [
        cheio,
        GrupoGuerra(
          nome: 'y',
          cor: '#fff',
          membros: [MembroGuerra(jogadorId: 'z')],
        ),
      ],
    );
    final depois = f.moverMembro('z', 0); // grupo 0 está cheio
    expect(depois.grupos[0].membros.length, 10);
    expect(depois.grupos[1].membros.single.jogadorId, 'z'); // ficou onde estava
  });
  test('toggling leader is per-group and resets on move', () {
    final alternado = umaFormacao().grupos[0].alternarLider('a');
    expect(alternado.membros.single.lider, isTrue);
    // após mover, o membro entra como não-líder
    expect(
      umaFormacao().moverMembro('a', 1).grupos[1].membros.single.lider,
      isFalse,
    );
  });
  test(
    'disponiveis excludes placed ids and the formation drops unknown ids on podada',
    () {
      final f = umaFormacao();
      expect(f.disponiveis(['a', 'b', 'c']), ['b', 'c']);
      final podada = FormacaoGuerra(
        grupos: [
          GrupoGuerra(
            nome: 'Pt 1',
            cor: '#fff',
            membros: [
              MembroGuerra(jogadorId: 'a'),
              MembroGuerra(jogadorId: 'sumiu'),
            ],
          ),
        ],
      ).podada({'a'});
      expect(podada.grupos[0].membros.map((m) => m.jogadorId), ['a']);
    },
  );
  test('round-trips through json', () {
    final f = umaFormacao();
    final back = FormacaoGuerra.fromJson(f.toJson());
    expect(back.grupos[0].membros.single.jogadorId, 'a');
  });
  test('comGrupo caps at 20', () {
    var f = FormacaoGuerra(grupos: const []);
    for (var i = 0; i < 25; i++) {
      f = f.comGrupo('Pt', '#fff');
    }
    expect(f.grupos.length, 20);
  });
}
