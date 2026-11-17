import 'dart:js_interop';

const _key = 'glassbox.lang';

extension type _Storage(JSObject _) implements JSObject {
  external JSString? getItem(String key);
  external void setItem(String key, String value);
}

@JS('localStorage')
external _Storage? get _localStorage;

// Storage can be missing or throw (private windows, blocked site data).
String? readStoredLang() {
  try {
    return _localStorage?.getItem(_key)?.toDart;
  } catch (_) {
    return null;
  }
}

void writeStoredLang(String lang) {
  try {
    _localStorage?.setItem(_key, lang);
  } catch (_) {}
}
