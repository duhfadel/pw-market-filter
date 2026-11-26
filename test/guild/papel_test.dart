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
