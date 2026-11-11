import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../market/ocupacoes.dart';
import '../data/instancias_memoria.dart';
import '../domain/entrada_de_instancia.dart';
import '../domain/grupo_de_instancias.dart';
import '../domain/instancias_url.dart';
import '../domain/personagem_de_instancia.dart';
import '../domain/plano_de_instancias.dart';

/// O plano de quem está a ler, e quem o grava.
///
/// **Grava a cada mudança**, sem botão de guardar. Um botão de guardar é uma
/// forma de perder trabalho: quem fecha a aba depois de escrever catorze
/// chaves não espera ter de confirmar que é mesmo para lembrar.
///
/// É um `Cubit` e não um `Bloc` com eventos pela razão de sempre aqui: o
/// ViewModel **é** o Bloc, e uma tela de acções diretas não ganha nada em ter
/// uma classe de evento por cada uma.
class InstanciasViewModel extends Cubit<PlanoDeInstancias> {
  InstanciasViewModel(this._memoria) : super(PlanoDeInstancias.inicial());

  final InstanciasMemoria _memoria;

  Set<String> get _classes => ocupacaoDaClasse.keys.toSet();

  /// O que o endereço trouxe, se trouxe alguma coisa.
  ///
  /// **Um link ganha sempre ao que está gravado, e isso é deliberado.** Quem
  /// abre um link está a dizer *quero esta lista*; respeitar a do aparelho
  /// faria o link não funcionar precisamente na máquina nova, que é o único
  /// sítio onde ele serve para alguma coisa. O botão de link existe para que
  /// isso nunca seja uma perda sem saída.
  void carregar(Map<String, List<String>> query) {
    final doLink = decodeInstancias(query, classesConhecidas: _classes);
    if (doLink != null && !doLink.vazio) {
      _emitirEGravar(doLink);
      return;
    }
    emit(_memoria.ler(classesConhecidas: _classes));
  }

  // --- grupos ---

  void adicionarGrupo(String nome) {
    final limpo = nome.trim();
    if (limpo.isEmpty) return;
    if (state.grupos.length >= maximoDeGrupos) return;
    _emitirEGravar(state.maisUmGrupo(limpo));
  }

  void renomearGrupo(int grupo, String nome) =>
      _emitirEGravar(state.renomeandoGrupo(grupo, nome));

  void removerGrupo(int grupo) => _emitirEGravar(state.semOGrupo(grupo));

  /// O desfazer de [removerGrupo]: repõe o grupo e tudo o que estava dentro
  /// dele, no lugar de onde saiu.
  void reporGrupo(int grupo, GrupoDeInstancias quem) =>
      _emitirEGravar(state.inserindoGrupo(grupo, quem));

  // --- personagens ---

  void adicionar(int grupo, String nome, String classe) {
    final limpo = nome.trim();
    if (limpo.isEmpty) return;
    if (state.quantosPersonagens >= maximoDePersonagens) return;
    _emitirEGravar(
      state.maisUmPersonagem(
        grupo,
        PersonagemDeInstancia(nome: limpo, classe: classe),
      ),
    );
  }

  void remover(Morada onde) => _emitirEGravar(state.semOPersonagem(onde));

  void repor(Morada onde, PersonagemDeInstancia quem) =>
      _emitirEGravar(state.inserindoPersonagem(onde, quem));

  /// O que o arrastar faz: leva um personagem para o fim de outro grupo.
  void mover(Morada de, int paraGrupo) => _emitirEGravar(
    state.movendoPersonagem(
      de,
      paraGrupo,
      state.grupos[paraGrupo].personagens.length,
    ),
  );

  void contar(Morada onde, EntradaDeInstancia entrada, int quantos) =>
      _emitirEGravar(state.contando(onde, entrada, quantos));

  /// `+` e `−` do número, nunca abaixo de zero.
  void somar(Morada onde, EntradaDeInstancia entrada, int delta) {
    final atual = state.grupos[onde.grupo].personagens[onde.personagem].de(
      entrada,
    );
    _emitirEGravar(state.contando(onde, entrada, atual + delta));
  }

  void renomear(Morada onde, String nome) =>
      _emitirEGravar(state.renomeandoPersonagem(onde, nome));

  /// Ordenar **não grava**: é uma vista de quem está a olhar, não um facto
  /// sobre a lista. Ver `PlanoDeInstancias.emOrdem`.
  void ordenarPor(EntradaDeInstancia entrada) =>
      emit(state.ordenandoPor(entrada));

  String get link => _memoria.link(state);

  void _emitirEGravar(PlanoDeInstancias novo) {
    emit(novo);
    _memoria.gravar(novo);
  }
}
