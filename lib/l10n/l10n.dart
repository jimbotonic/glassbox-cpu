import 'lang_store.dart';

/// The languages the interface is written in.
enum Lang {
  en('EN', 'English'),
  fr('FR', 'Français'),
  de('DE', 'Deutsch');

  final String code;
  final String name;
  const Lang(this.code, this.name);
}

/// The current interface language. Plain Dart, so the core (narration,
/// assembler messages) can read it too.
///
/// Each area keeps its text in its own file under `lib/l10n/`: an abstract
/// class listing every string, one implementation per language (so the
/// compiler flags a missing translation), and a getter that picks the
/// current one with [L10n.pick].
abstract final class L10n {
  static Lang _current = Lang.en;

  static Lang get current => _current;

  /// Starts in the language chosen last time, else the browser's, else
  /// English.
  static void init(String platformLanguage) {
    final stored = readStoredLang();
    _current =
        _byName(stored) ?? _byName(platformLanguage.toLowerCase()) ?? Lang.en;
  }

  /// Switches language and remembers the choice. Callers rebuild the UI.
  static void set(Lang lang) {
    _current = lang;
    writeStoredLang(lang.name);
  }

  /// For tests: switches without storing.
  static void debugSet(Lang lang) => _current = lang;

  static T pick<T>(T en, T fr, T de) => switch (_current) {
    Lang.en => en,
    Lang.fr => fr,
    Lang.de => de,
  };

  static Lang? _byName(String? name) {
    for (final l in Lang.values) {
      if (l.name == name) return l;
    }
    return null;
  }
}
