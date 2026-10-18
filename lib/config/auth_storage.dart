import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'file_local_storage_stub.dart'
    if (dart.library.io) 'file_local_storage_io.dart' as impl;

/// Platform-safe Supabase auth persistence.
///
/// Web uses SharedPreferences (works in browsers). Mobile/desktop uses files
/// to avoid the Android SharedPreferences JNI crash.
({LocalStorage localStorage, GotrueAsyncStorage pkceAsyncStorage})
    createAuthStorage(String persistSessionKey) {
  if (kIsWeb) {
    return (
      localStorage: SharedPreferencesLocalStorage(
        persistSessionKey: persistSessionKey,
      ),
      pkceAsyncStorage: SharedPreferencesGotrueAsyncStorage(),
    );
  }
  return (
    localStorage: impl.FileLocalStorage(persistSessionKey: persistSessionKey),
    pkceAsyncStorage: impl.FileGotrueAsyncStorage(),
  );
}
