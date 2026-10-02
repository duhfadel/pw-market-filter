/// Where a character's page lives on the marketplace.
///
/// **One table, because the shape is inverted between versions and the two
/// halves of this repository both need it.** Measured on 2026-10-01 and again
/// on 2026-10-02:
///
/// | | `/<v>/details/<id>` | `/details/<v>/<id>` |
/// |---|---|---|
/// | pw187 | **200**, canonical | 302 into the canonical |
/// | pw126 | **404** | **200**, canonical |
///
/// It cost a real defect to learn twice. The collector knew it — `Servidor`
/// carries a profile per version — while the results card built
/// `'<server>/details/<id>'` for both, with a comment stating the 1.8.7 rule
/// as though it were universal. Every *ver no marketplace* button on the
/// 1.2.6 side opened a 404, and nothing on screen said so. A rule written
/// down in two places is a rule that disagrees with itself the day one
/// version does something the other does not.
library;

const _origem = 'https://marketplace.theclassic.games';

/// The canonical page for [roleId] on [server] — the form that answers 200
/// with no redirect.
///
/// An unrecognised version falls back to `/details/<server>/<id>`, which is
/// the shape the marketplace's own listing links use: canonical on pw126 and
/// a 302 into the canonical on pw187, so a browser lands on the right page
/// either way. It is the safest guess for a version nobody has measured yet —
/// and the right move when 1.4.4 arrives is to measure it and add a row here,
/// not to lean on the guess.
String enderecoDoPersonagem(String server, int roleId) => switch (server) {
  'pw187' => '$_origem/pw187/details/$roleId',
  'pw126' => '$_origem/details/pw126/$roleId',
  _ => '$_origem/details/$server/$roleId',
};
