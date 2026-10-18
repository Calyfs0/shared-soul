import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// File-backed auth storage — avoids Android SharedPreferences JNI crashes.
class FileLocalStorage extends LocalStorage {
  FileLocalStorage({required this.persistSessionKey});

  final String persistSessionKey;
  File? _file;

  Future<File> _sessionFile() async {
    if (_file != null) return _file!;
    final dir = await getApplicationDocumentsDirectory();
    final safe = persistSessionKey.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    _file = File('${dir.path}/$safe.json');
    return _file!;
  }

  @override
  Future<void> initialize() async {
    await _sessionFile();
  }

  @override
  Future<bool> hasAccessToken() async {
    final file = await _sessionFile();
    return file.exists();
  }

  @override
  Future<String?> accessToken() async {
    final file = await _sessionFile();
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  @override
  Future<void> removePersistedSession() async {
    final file = await _sessionFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    final file = await _sessionFile();
    await file.writeAsString(persistSessionString, flush: true);
  }
}

/// PKCE code-verifier storage without SharedPreferences.
class FileGotrueAsyncStorage extends GotrueAsyncStorage {
  FileGotrueAsyncStorage() {
    unawaited(_load());
  }

  final Completer<void> _ready = Completer<void>();
  final Map<String, String> _map = {};
  File? _file;

  Future<void> _load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/supabase_pkce_async.json');
      if (await _file!.exists()) {
        final raw = jsonDecode(await _file!.readAsString());
        if (raw is Map) {
          raw.forEach((k, v) {
            if (k is String && v is String) _map[k] = v;
          });
        }
      }
      if (!_ready.isCompleted) _ready.complete();
    } catch (e, st) {
      if (!_ready.isCompleted) _ready.completeError(e, st);
    }
  }

  Future<void> _persist() async {
    final file = _file;
    if (file == null) return;
    await file.writeAsString(jsonEncode(_map), flush: true);
  }

  @override
  Future<String?> getItem({required String key}) async {
    await _ready.future;
    return _map[key];
  }

  @override
  Future<void> removeItem({required String key}) async {
    await _ready.future;
    _map.remove(key);
    await _persist();
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    await _ready.future;
    _map[key] = value;
    await _persist();
  }
}
