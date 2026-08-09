/// An item's rank, read from the stars its name begins with.
///
/// The site publishes no rank field — not in the HTML, not in the item JSON,
/// and the word appears once on a whole character page as flavour text. What it
/// does publish is the star prefix, and the player's rule is that the two are
/// the same thing: no stars is rank 1, `★★★` is rank 4.
///
/// Checked against all 538 items in the collected market: every name that has
/// stars carries them as a prefix and nowhere else, and no name has more than
/// three. Rank therefore needs no collection of its own — it was already in
/// the index, spelled differently.
///
/// Rank is independent of attack level: ★★★Dilacerador Raivoso gives 70 and
/// ★★★Geada Tardia gives nothing, and both are rank 4. Filtering on one is not
/// filtering on the other.
int rankFromName(String name) {
  var stars = 0;
  while (stars < name.length && name.codeUnitAt(stars) == 0x2605) {
    stars++;
  }
  return stars + 1;
}
