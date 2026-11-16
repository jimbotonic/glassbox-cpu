import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  Widget build(BuildContext context) {
    return GlassDialogFrame(
      title: 'ABOUT GLASSBOX CPU',
      note: 'every signal visible',
      width: 440,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text:
                      'A visual simulator of an 8-bit breadboard CPU: every '
                      'step shows who drives the bus, who reads it, and why.'
                      '\n\n',
                ),
                const TextSpan(text: 'Based on the 8-bit CPU Simulator by '),
                _link('AbdulMuaz', 'https://devmuaz.com'),
                const TextSpan(text: ', inspired by '),
                _link('Ben Eater', 'https://eater.net'),
                const TextSpan(text: "'s 8-bit breadboard computer."),
              ],
            ),
            style: const TextStyle(
              color: Glass.textSoft,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const GlassSectionTitle('Licence'),
          const Text(
            'Released under the GNU GPL v3. The original simulator code '
            'remains under the MIT licence (see LICENSE and LICENSE-MIT).',
            style: TextStyle(color: Glass.muted, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 16),
          const Text(
            '"Every complex system is just simple parts working together."',
            style: TextStyle(
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
