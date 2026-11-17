import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import 'board/glass_widgets.dart';
import 'theme/glass.dart';

/// Credits and licence, moved out of the main board to free space.
void showAboutGlassBox(BuildContext context) {
  showGlassDialog<void>(context, child: const _AboutContent());
}

class _AboutContent extends StatelessWidget {
  const _AboutContent();

  TextSpan _link(String text, String url) => TextSpan(
    text: text,
    style: const TextStyle(
      color: Glass.driveText,
      decoration: TextDecoration.underline,
      decorationColor: Glass.driveText,
    ),
    recognizer: TapGestureRecognizer()
      ..onTap = () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
  );

  /// [template] as spans, with `{muaz}` and `{eater}` made into links.
  List<InlineSpan> _credits(String template) {
    final links = {
      '{muaz}': _link('AbdulMuaz', 'https://devmuaz.com'),
      '{eater}': _link('Ben Eater', 'https://eater.net'),
    };
    final spans = <InlineSpan>[];
    var rest = template;
    while (rest.isNotEmpty) {
      final hits = [
        for (final key in links.keys)
          if (rest.contains(key)) (rest.indexOf(key), key),
      ]..sort((a, b) => a.$1.compareTo(b.$1));
      if (hits.isEmpty) {
        spans.add(TextSpan(text: rest));
        break;
      }
      final (at, key) = hits.first;
      if (at > 0) spans.add(TextSpan(text: rest.substring(0, at)));
      spans.add(links[key]!);
      rest = rest.substring(at + key.length);
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final t = tApp;
    return GlassDialogFrame(
      title: t.aboutTitle,
      note: t.tagline,
      width: 440,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${t.aboutIntro}\n\n'),
                ..._credits(t.aboutCredits),
              ],
            ),
            style: const TextStyle(
              color: Glass.textSoft,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          GlassSectionTitle(t.licenceTitle),
          Text(
            t.licenceText,
            style: const TextStyle(
              color: Glass.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.quote,
            style: const TextStyle(
              color: Glass.dim,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
