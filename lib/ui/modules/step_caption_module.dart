import 'package:flutter/material.dart';

import '../../core/step_info.dart';

/// Plain-language caption of the micro-step just executed, e.g.
/// `T3  LDA 0xE` / `RAM[0xE] = 0x07 → bus → A` / `(RO|AI)`.
class StepCaptionModule extends StatelessWidget {
  final StepInfo info;

  /// Also show the raw control signals.
  final bool detailed;

  const StepCaptionModule({
    super.key,
    required this.info,
    required this.detailed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.5),
          width: 2,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'LAST STEP',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                info.stepLabel,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  info.purpose,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            info.caption,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          if (detailed && info.step != null) ...[
            const SizedBox(height: 4),
            Text(
              'signals: ${info.signals}',
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}
