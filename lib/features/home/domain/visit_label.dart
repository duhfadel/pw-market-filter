/// The footer's line: `1.203 visitas`.
///
/// Kept out of the widget so the two things that are easy to get wrong can be
/// tested — the thousand separators, which are off by one digit at every
/// boundary if the loop is written the obvious way, and the singular, which
/// only ever shows up on the very first day of the site's life and so would
/// never be noticed by hand.
///
/// The grouping is written out rather than taken from `NumberFormat`, which
/// would pull in `intl` and its locale data for one line of text.
String visitLabel(int total) =>
    '${groupThousands(total)} ${total == 1 ? 'visita' : 'visitas'}';

String groupThousands(int n) {
  final digits = n.abs().toString();
  final out = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
    out.write(digits[i]);
  }
  return out.toString();
}
