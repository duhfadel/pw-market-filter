import '../../../core/rotas.dart' as rotas;
import '../../../market/index_repository.dart' show IndexRepository;
import '../../../market/versoes.dart';

/// One door on the choice screen: a version the site knows about, merged
/// with whatever `versoes.json` says about it today.
///
/// The known versions are listed by hand in [portasDe] rather than derived
/// from the file, because a version with no collection yet has no row there
/// at all — `pw126` right now, see `web/versoes.json`'s real shape — and its
/// door still has to exist, dimmed. The same rule `Tool.isReady` already
/// applies to the front page's menu.
class Porta {
  const Porta({
    required this.chave,
    required this.nome,
    required this.rota,
    this.resumo,
  });

  /// Matches `IndexRepository.pw187`/`pw126` and `VersaoResumo.chave`.
  final String chave;

  /// The readable name shown on the door — '1.8.7', '1.2.6'. A numeral, not a
  /// title: it stays on the body face wherever it is drawn, never Marcellus.
  final String nome;

  /// Where tapping the door goes — the version's own home, from
  /// `core/rotas.dart`.
  final String rota;

  /// What the last collection for this version found, or `null` before the
  /// first one has ever run — the state that draws this door dimmed.
  final VersaoResumo? resumo;

  bool get pronta => resumo != null;
}

/// Every door the site shows, in the order it shows them — 1.8.7 first,
/// since it is the version that was already live before this screen existed.
///
/// A version [versoes] has no row for — missing from the file entirely, or
/// the file itself never written yet — still gets a door here, with
/// [Porta.resumo] left `null`. That is deliberate: "nobody has collected
/// this version" and "nobody has collected anything at all" are the same
/// fact from a single door's point of view, and both draw the same way.
List<Porta> portasDe(Map<String, VersaoResumo> versoes) => [
  Porta(
    chave: IndexRepository.pw187,
    nome: rotas.pw187,
    rota: '/${rotas.pw187}',
    resumo: versoes[IndexRepository.pw187],
  ),
  Porta(
    chave: IndexRepository.pw126,
    nome: rotas.pw126,
    rota: '/${rotas.pw126}',
    resumo: versoes[IndexRepository.pw126],
  ),
];
