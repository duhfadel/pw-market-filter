import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../market/ocupacoes.dart';
import '../data/instancias_memoria.dart';
import '../domain/entrada_de_instancia.dart';
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
/// ViewModel **é** o Bloc, e uma tela com cinco acções não ganha nada em
/// ter cinco classes de evento.
class InstanciasViewModel extends Cubit<PlanoDeInstancias> {
  InstanciasViewModel(this._memoria) : super(const PlanoDeInstancias());

  final InstanciasMemoria _memoria;

  /// O que o endereço trouxe, se trouxe alguma coisa.
  ///
  /// **Um link ganha sempre ao que está gravado, e isso é deliberado.** Quem
  /// abre um link está a dizer *quero esta lista*; respeitar a do aparelho
  /// faria o link não funcionar precisamente na máquina nova, que é o único
  /// sítio onde ele serve para alguma coisa. O que estava gravado é
  /// substituído — e o botão de link existe para que isso nunca seja uma
  /// perda sem saída.
  void carregar(Map<String, List<String>> query) {
    final doLink = decodeInstancias(
      query,
      classesConhecidas: ocupacaoDaClasse.keys.toSet(),
    );
    if (!doLink.vazio) {
      _emitirEGravar(doLink);
      return;
    }
    emit(_memoria.ler(classesConhecidas: ocupacaoDaClasse.keys.toSet()));
  }

  void adicionar(String nome, String classe) {
    final limpo = nome.trim();
    if (limpo.isEmpty) return;
    if (state.personagens.length >= maximoDePersonagens) return;
    _emitirEGravar(
      state.maisUm(PersonagemDeInstancia(nome: limpo, classe: classe)),
    );
  }

  void remover(int indice) => _emitirEGravar(state.semO(indice));

  /// O desfazer de um [remover]. Ver `PlanoDeInstancias.inserindo` para
  /// porque o índice viaja junto.
  void repor(int indice, PersonagemDeInstancia quem) =>
      _emitirEGravar(state.inserindo(indice, quem));

  void contar(int indice, EntradaDeInstancia entrada, int quantos) =>
      _emitirEGravar(
        state.trocando(indice, state.personagens[indice].com(entrada, quantos)),
      );

  void renomear(int indice, String nome) {
    final limpo = nome.trim();
    if (limpo.isEmpty) return;
    _emitirEGravar(
      state.trocando(indice, state.personagens[indice].renomeado(limpo)),
    );
  }

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
