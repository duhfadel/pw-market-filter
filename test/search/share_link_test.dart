import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/search/data/address_bar.dart';

/// The address somebody is handed. It has to be the search and nothing else:
/// a link carrying the sharer's own analytics parameters, or their leftover
/// fragment, is a link that says something they did not mean to say.
void main() {
  test('the link is the search, on the site it came from', () {
    expect(
      AddressBar.linkTo(
        Uri.parse('https://portalpw.net/#/filtro?preco=-500'),
        'preco=-500',
      ),
      'https://portalpw.net/#/filtro?preco=-500',
    );
  });

  test('an empty search still gives a usable link', () {
    expect(
      AddressBar.linkTo(Uri.parse('https://portalpw.net/'), ''),
      'https://portalpw.net/#/filtro',
    );
  });

  test('whatever else was in the address does not travel', () {
    expect(
      AddressBar.linkTo(
        Uri.parse('https://portalpw.net/?utm_source=discord#/filtro'),
        'classe=Mago',
      ),
      'https://portalpw.net/#/filtro?classe=Mago',
    );
  });
}
