// The chosen language survives a reload: browser storage on the web,
// nothing elsewhere.
export 'lang_store_stub.dart'
    if (dart.library.js_interop) 'lang_store_web.dart';
