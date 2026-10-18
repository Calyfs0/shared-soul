import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Last-known couple UI bits so launch can paint without “Them” → name flicker.
class SessionCache {
  SessionCache._();

  static const _fileName = 'ss_session_cache.json';

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<CachedSession?> read(String coupleId) async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final map = jsonDecode(await file.readAsString());
      if (map is! Map) return null;
      if (map['coupleId'] != coupleId) return null;
      final my = map['myName'] as String?;
      final partner = map['partnerName'] as String?;
      if (my == null || partner == null) return null;
      return CachedSession(
        myName: my,
        partnerName: partner,
        cosmetic: (map['cosmetic'] as String?) ?? 'none',
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> write({
    required String coupleId,
    required String myName,
    required String partnerName,
    required String cosmetic,
  }) async {
    try {
      final file = await _file();
      await file.writeAsString(
        jsonEncode({
          'coupleId': coupleId,
          'myName': myName,
          'partnerName': partnerName,
          'cosmetic': cosmetic,
        }),
        flush: true,
      );
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      final file = await _file();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

class CachedSession {
  const CachedSession({
    required this.myName,
    required this.partnerName,
    required this.cosmetic,
  });

  final String myName;
  final String partnerName;
  final String cosmetic;
}
