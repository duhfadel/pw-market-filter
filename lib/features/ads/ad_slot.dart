import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/pw_colors.dart';

/// The one place a paid banner can appear, and everything about it.
///
/// It is written as a space rather than as an advert: when AdSense or anyone
/// else arrives, what changes is what goes **inside** [AdSlot], not where it
/// sits, how it is labelled, or how much room it takes. Those three were
/// decided once, here, and are the part that is easy to get wrong later under
/// pressure from a network's own recommendations.
///
/// While there is no sponsor the slot advertises itself. An empty box teaches
/// the layout nothing and earns nothing; a house ad does both, and it is how
/// the first sponsor finds out the space exists.
///
/// **This screen says the site sells nothing, and that has to stay true.** So
/// the label is always on, the surface is never the surface a result card uses,
/// and the slot never sits between the disclaimer and the results. Those are
/// not style choices — they are what keeps an advert from reading as a listing.
class AdConfig {
  const AdConfig({this.active = false, this.image, this.link, this.title = ''});

  /// Off until there is something to show. A slot that reserves height for
  /// nothing is a hole in the page.
  final bool active;

  /// The sponsor's art, from `assets/images/`. Null falls back to the house ad.
  final String? image;

  /// Where the banner leads. Null makes it a picture rather than a link.
  final String? link;

  /// Read out to screen readers, and shown if the art fails to load.
  final String title;
}

/// The live configuration. Editing this file and pushing is the whole
/// workflow for changing a banner — CI deploys within a couple of minutes.
///
/// To hand the space to a sponsor: set [AdConfig.active] to true, drop the art
/// in `assets/images/`, and fill in the link.
const adConfig = AdConfig(
  // TODO(portal): fill in `houseAdLink` below and flip this to true. The house
  // ad needs somewhere to send whoever clicks it — a Discord invite, a profile,
  // an e-mail — and inventing one would send people nowhere.
  active: false,
  title: 'Publicidade',
);

/// Where the house ad sends someone who wants to advertise.
const houseAdLink = '';

/// A banner, or nothing at all.
///
/// Returns a zero-size box when the slot is off, so no page pays layout for a
/// space that has nothing in it.
class AdSlot extends StatelessWidget {
  const AdSlot({super.key, this.compact = false, this.config = adConfig});

  /// Half the height, for the filter, where every pixel is already spoken for.
  final bool compact;

  /// Overridable so the rules above can be tested with a sponsor in place —
  /// the label, the surface, the height — instead of only in the state where
  /// the slot draws nothing.
  final AdConfig config;

  @override
  Widget build(BuildContext context) {
    if (!config.active) return const SizedBox.shrink();

    return Semantics(
      label: 'Publicidade',
      child: Container(
        width: double.infinity,
        // Never `surface`: that is the colour of a result card, and an advert
        // that looks like a card is an advert being mistaken for a listing.
        color: PWColors.background,
        padding: EdgeInsets.symmetric(vertical: compact ? 8 : 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PUBLICIDADE',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.6,
                color: PWColors.textMuted,
              ),
            ),
            SizedBox(height: compact ? 5 : 8),
            _Banner(compact: compact, config: config),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.compact, required this.config});

  final bool compact;
  final AdConfig config;

  @override
  Widget build(BuildContext context) {
    final image = config.image;
    final link = config.link ?? (image == null ? houseAdLink : null);

    final banner = ConstrainedBox(
      // The proportions of a leaderboard, which is what a sponsor will hand
      // over and what an ad network would fill.
      constraints: BoxConstraints(maxWidth: 728, maxHeight: compact ? 60 : 90),
      child: image == null
          ? const _HouseAd()
          : Image.asset(
              image,
              fit: BoxFit.contain,
              // A missing file leaves the page whole rather than a broken box.
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
    );

    if (link == null || link.isEmpty) return banner;

    return InkWell(
      onTap: () =>
          launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication),
      child: banner,
    );
  }
}

/// What sits in the space while nobody has bought it.
class _HouseAd extends StatelessWidget {
  const _HouseAd();

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: PWColors.border),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: const Text(
      'Quer anunciar aqui? Fale com o Portal PW.',
      textAlign: TextAlign.center,
      style: TextStyle(color: PWColors.textMuted, fontSize: 13),
    ),
  );
}
