import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Credits and licence, moved out of the main board to free space.
void showAboutGlassBox(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: const Color(0xFF1a1a1a),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: const SizedBox(width: 420, child: _AboutContent()),
    ),
  );
}

class _AboutContent extends StatelessWidget {
  const _AboutContent();

  TextSpan _link(String text, String url) => TextSpan(
    text: text,
    style: const TextStyle(
      color: Colors.red,
      decoration: TextDecoration.underline,
    ),
    recognizer: TapGestureRecognizer()
      ..onTap = () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ABOUT',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: Colors.white60,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.5,
              ),
              children: [
                const TextSpan(
                  text: 'A visual simulator of an 8-bit breadboard CPU.\n\n',
                ),
                const TextSpan(text: 'Based on the 8-bit CPU Simulator by '),
                _link('AbdulMuaz', 'https://devmuaz.com'),
                const TextSpan(text: ', inspired by '),
                _link('Ben Eater', 'https://eater.net'),
                const TextSpan(text: "'s 8-bit breadboard computer.\n\n"),
                const TextSpan(
                  text:
                      'Released under the GNU GPL v3; the original simulator '
                      'code remains under the MIT licence (see LICENSE and '
                      'LICENSE-MIT).\n\n',
                ),
                const TextSpan(
                  text:
                      '"Every complex system is just simple parts working '
                      'together."',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
