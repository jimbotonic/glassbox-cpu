import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'cpu_board.dart';
import 'l10n/app_strings.dart';
import 'l10n/l10n.dart';
import 'ui/theme/glass.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  L10n.init(PlatformDispatcher.instance.locale.languageCode);
  runApp(const CPUSimulatorApp());
}

class CPUSimulatorApp extends StatelessWidget {
  const CPUSimulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlassBox CPU Simulator',
      theme: ThemeData(
        scaffoldBackgroundColor: Glass.ground,
        brightness: Brightness.dark,
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: Glass.raised,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Glass.border),
          ),
          textStyle: const TextStyle(color: Glass.text, fontSize: 12),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Glass.bus,
          selectionColor: Glass.drive.withValues(alpha: 0.35),
          selectionHandleColor: Glass.drive,
        ),
      ),
      home: const _App(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    const requiredWidth = 1340;
    const requiredHeight = 640;
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    if ((width < requiredWidth || height < requiredHeight) && kIsWeb) {
      final t = tApp;
      return Scaffold(
        backgroundColor: Glass.ground,
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Glass.panel,
              borderRadius: BorderRadius.circular(Glass.radius),
              border: Border.all(color: Glass.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.windowTooSmallTitle, style: Glass.dialogTitle),
                const SizedBox(height: 8),
                Text(
                  t.windowTooSmallBody,
                  style: const TextStyle(
                    color: Glass.textSoft,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  t.windowSizes(
                    requiredWidth,
                    requiredHeight,
                    width.round(),
                    height.round(),
                  ),
                  style: Glass.code.copyWith(color: Glass.muted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const CPUBoard();
  }
}
