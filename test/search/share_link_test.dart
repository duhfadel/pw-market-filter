import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/search/data/address_bar.dart';

/// The address somebody is handed. It has to be the search and nothing else:
/// a link carrying the sharer's own analytics parameters, or their leftover
/// fragment, is a link that says something they did not mean to say.
///
/// It also has to be the canonical `/1.8.7/filtro`, not the bare `/filtro`
/// `core/rotas.dart` keeps alive only for links that already exist — see
/// `AddressBar`'s own note on why this is a one-way door.
void main() {
  test('the link is the search, on the site it came from', () {
    expect(
      AddressBar.linkTo(
        Uri.parse('https://portalpw.net/#/1.8.7/filtro?preco=-500'),
        'preco=-500',
      ),
      'https://portalpw.net/#/1.8.7/filtro?preco=-500',
    );
  });

  test('an empty search still gives a usable link', () {
    expect(
      AddressBar.linkTo(Uri.parse('https://portalpw.net/'), ''),
      'https://portalpw.net/#/1.8.7/filtro',
    );
  });

  test('whatever else was in the address does not travel', () {
    expect(
      AddressBar.linkTo(
        Uri.parse('https://portalpw.net/?utm_source=discord#/1.8.7/filtro'),
        'classe=Mago',
      ),
      'https://portalpw.net/#/1.8.7/filtro?classe=Mago',
    );
  });
}
