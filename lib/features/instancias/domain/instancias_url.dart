import 'campo_personalizado.dart';
import 'entrada_de_instancia.dart';
import 'grupo_de_instancias.dart';
import 'personagem_de_instancia.dart';
import 'plano_de_instancias.dart';

/// Os grupos e os personagens num endereço, para poderem sair deste aparelho.
///
/// **É a única rede contra limpar o navegador.** O plano vive em
/// `localStorage`, que é por aparelho: trocar de telemóvel, abrir no
/// computador ou limpar os dados apagava semanas de contagem sem nada a
/// recuperá-las. Um link resolve os três sem conta, sem servidor e sem
/// guardarmos dados de ninguém — e de caminho torna a lista partilhável.
///
/// Os grupos vêm primeiro, em ordem; cada personagem diz a que grupo
/// pertence pelo índice:
///
/// ```
/// /instancias?g=Principal&g=Mula
///            &p=0~Bardo~3~1~2~14~duhit
///            &p=1~Mago~0~0~1~2~mula1
/// ```
///
/// **O índice do grupo é o primeiro campo e um inteiro**, e aqui um índice é
/// seguro ao contrário da classe: ele é resolvido **dentro do próprio link**,
/// contra a lista de `g` que viaja ao lado, e não contra uma recolha que
/// mudou noutro dia. A classe viaja pelo nome pela razão oposta — ela é
/// resolvida contra o jogo, que é externo ao link.
///
/// **O nome vai no fim, que é o que o torna à prova de til.** Tudo antes dele
/// tem aridade fixa — o índice do grupo, a classe e quatro números — portanto
/// o que sobra depois da sexta separação *é* o nome, com tis lá dentro e
/// tudo. O nome do grupo passa por `Uri.encodeQueryComponent` sozinho, no seu
/// próprio parâmetro, portanto nunca precisa de ser separado de mais nada.
const _grupoParam = 'g';
const _personagemParam = 'p';
const _separador = '~';

/// Os campos personalizados no link, e o que neles vai.
///
/// **São três famílias de parâmetro, e cada uma usa a regra do *último é o
/// resto* para o til não a partir.** `cf` define um campo — `id~sigla~nome`,
/// com o nome a ser tudo o que sobra; `co` dá uma opção de uma escolha —
/// `id~opção`, a opção é o resto; `x` dá o valor de um campo num personagem —
/// `índiceGlobal~id~valor`, o valor é o resto, com tis e tudo. O índice
/// global é a posição do personagem na ordem em que os `p` aparecem, a mesma
/// de um lado e do outro.
const _campoParam = 'cf';
const _opcaoParam = 'co';
const _valorParam = 'x';

const maximoDeCampos = 40;

/// Quantos campos vêm antes do nome do personagem: o índice do grupo, a
/// classe e as quatro contagens.
const _camposFixos = 1 + 1 + 4 + 1;

/// Tectos, para o endereço não ser a arma. Um link que nenhum navegador
/// aceita e que nenhum campo de chat deixa colar não é um link. Largos de
/// mais para qualquer conta real e curtos o bastante para continuar a ser um
/// link.
const maximoDeGrupos = 30;
const maximoDePersonagens = 200;

String encodeInstancias(PlanoDeInstancias plano) {
  final partes = <String>[];

  // Sempre a ordem de origem, nunca `emOrdem`: a ordenação é uma vista de
  // quem está a olhar, e gravá-la entregaria ao próximo a lista baralhada.
  final grupos = plano.grupos.take(maximoDeGrupos).toList();
  for (final g in grupos) {
    partes.add('$_grupoParam=${Uri.encodeQueryComponent(g.nome)}');
  }

  // Os campos personalizados primeiro, para a lista de `cf` chegar na ordem
  // em que foram criados (`queryParametersAll` preserva-a por chave).
  final campos = plano.campos.take(maximoDeCampos).toList();
  for (final c in campos) {
    partes.add(
      '$_campoParam=${Uri.encodeQueryComponent('${c.id}$_separador${c.tipo.sigla}$_separador${c.nome}')}',
    );
    for (final o in c.opcoes) {
      partes.add(
        '$_opcaoParam=${Uri.encodeQueryComponent('${c.id}$_separador$o')}',
      );
    }
  }

  var escritos = 0;
  for (var gi = 0; gi < grupos.length; gi++) {
    for (final p in grupos[gi].personagens) {
      if (escritos >= maximoDePersonagens) break;
      final camposP = [
        '$gi',
        p.classe,
        for (final e in EntradaDeInstancia.values) '${p.de(e)}',
        // A data da coleta diária, antes do nome: tem forma fixa (sem tis),
        // portanto não estraga a regra de o nome ser o resto. Vazia quando
        // nunca se pegou.
        p.coletadoEm ?? '',
        p.nome,
      ].join(_separador);
      partes.add('$_personagemParam=${Uri.encodeQueryComponent(camposP)}');
      // Os valores dos campos personalizados deste personagem, cada um com o
      // índice global dele: `índice~id~valor`, valor é o resto.
      for (final e in p.extras.entries) {
        if (e.value.isEmpty) continue;
        partes.add(
          '$_valorParam=${Uri.encodeQueryComponent('$escritos$_separador${e.key}$_separador${e.value}')}',
        );
      }
      escritos++;
    }
  }

  return partes.join('&');
}

/// Lê o que [encodeInstancias] escreveu, e deita fora o que não entender.
///
/// **Uma entrada estragada cai sozinha e não leva as outras.** Um link
/// cortado a meio por um cliente de chat é o caso normal disto, e perder um
/// personagem é melhor do que abrir a ferramenta vazia sem dizer porquê.
///
/// `queryParametersAll` preserva a ordem **dentro** de cada chave, portanto a
/// lista de `g` chega na ordem em que foi escrita e o índice que cada `p`
/// carrega aponta para ela com segurança.
PlanoDeInstancias? decodeInstancias(
  Map<String, List<String>> query, {
  required Set<String> classesConhecidas,
}) {
  final nomes = (query[_grupoParam] ?? const <String>[])
      .take(maximoDeGrupos)
      .toList();
  if (nomes.isEmpty) return null;

  // Os campos primeiro: as suas opções e os valores apontam para eles.
  final campos = _lerCampos(query);

  // Um registo por personagem, na ordem em que os `p` aparecem — essa posição
  // é o índice global que os `x` usam. Guardo o `extras` à parte, num mapa por
  // índice, e aplico-o no fim.
  final flat = <_CharCru>[];
  for (final cru in query[_personagemParam] ?? const <String>[]) {
    if (flat.length >= maximoDePersonagens) break;
    // `_camposFixos` e não `.length`: o nome é o resto e pode ter tis.
    final cs = cru.split(_separador);
    if (cs.length < _camposFixos + 1) continue;

    final grupo = int.tryParse(cs[0]);
    // Um índice fora da lista de grupos é lixo de um link cortado — cai, não
    // se inventa um grupo para o acolher.
    if (grupo == null || grupo < 0 || grupo >= nomes.length) continue;

    final classe = cs[1];
    // Uma classe que este site não conhece não desenha ícone nenhum e não há
    // como adivinhar qual era.
    if (!classesConhecidas.contains(classe)) continue;

    final nome = cs.sublist(_camposFixos).join(_separador).trim();
    if (nome.isEmpty) continue;

    final contagens = <EntradaDeInstancia, int>{};
    var valido = true;
    for (var i = 0; i < EntradaDeInstancia.values.length; i++) {
      final n = int.tryParse(cs[2 + i]);
      if (n == null || n < 0) {
        valido = false;
        break;
      }
      contagens[EntradaDeInstancia.values[i]] = n;
    }
    if (!valido) continue;

    final cru6 = cs[_camposFixos - 1];
    final coletadoEm = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(cru6)
        ? cru6
        : null;

    flat.add(_CharCru(grupo, nome, classe, contagens, coletadoEm));
  }

  // Os valores dos campos: `índiceGlobal~id~valor`. Um índice fora da lista,
  // ou um id de campo que não existe, é lixo de um link cortado e cai.
  final idsConhecidos = campos.map((c) => c.id).toSet();
  for (final cru in query[_valorParam] ?? const <String>[]) {
    final cs = cru.split(_separador);
    if (cs.length < 3) continue;
    final idx = int.tryParse(cs[0]);
    if (idx == null || idx < 0 || idx >= flat.length) continue;
    final campoId = cs[1];
    if (!idsConhecidos.contains(campoId)) continue;
    final valor = cs.sublist(2).join(_separador);
    if (valor.isNotEmpty) flat[idx].extras[campoId] = valor;
  }

  final personagensPorGrupo = <int, List<PersonagemDeInstancia>>{};
  for (final c in flat) {
    personagensPorGrupo
        .putIfAbsent(c.grupo, () => [])
        .add(
          PersonagemDeInstancia(
            nome: c.nome,
            classe: c.classe,
            contagens: c.contagens,
            coletadoEm: c.coletadoEm,
            extras: c.extras,
          ),
        );
  }

  return PlanoDeInstancias(
    grupos: [
      for (var i = 0; i < nomes.length; i++)
        GrupoDeInstancias(
          nome: nomes[i],
          personagens: personagensPorGrupo[i] ?? const [],
        ),
    ],
    campos: campos,
  );
}

/// Um personagem meio-lido, antes de os valores dos campos lhe serem
/// atribuídos por índice.
class _CharCru {
  _CharCru(this.grupo, this.nome, this.classe, this.contagens, this.coletadoEm);
  final int grupo;
  final String nome;
  final String classe;
  final Map<EntradaDeInstancia, int> contagens;
  final String? coletadoEm;
  final Map<String, String> extras = {};
}

/// Lê os campos (`cf`) e enche-os com as opções (`co`).
List<CampoPersonalizado> _lerCampos(Map<String, List<String>> query) {
  final defs = <String, _CampoCru>{};
  final ordem = <String>[];
  for (final cru in (query[_campoParam] ?? const <String>[]).take(
    maximoDeCampos,
  )) {
    final cs = cru.split(_separador);
    if (cs.length < 3) continue;
    final id = cs[0];
    final tipo = CampoTipo.daSigla(cs[1]);
    final nome = cs.sublist(2).join(_separador).trim();
    if (id.isEmpty || tipo == null || nome.isEmpty || defs.containsKey(id)) {
      continue;
    }
    defs[id] = _CampoCru(id, nome, tipo);
    ordem.add(id);
  }
  for (final cru in query[_opcaoParam] ?? const <String>[]) {
    final cs = cru.split(_separador);
    if (cs.length < 2) continue;
    final id = cs[0];
    final opcao = cs.sublist(1).join(_separador);
    if (opcao.isNotEmpty) defs[id]?.opcoes.add(opcao);
  }
  return [
    for (final id in ordem)
      CampoPersonalizado(
        id: id,
        nome: defs[id]!.nome,
        tipo: defs[id]!.tipo,
        opcoes: defs[id]!.opcoes,
      ),
  ];
}

class _CampoCru {
  _CampoCru(this.id, this.nome, this.tipo);
  final String id;
  final String nome;
  final CampoTipo tipo;
  final List<String> opcoes = [];
}
