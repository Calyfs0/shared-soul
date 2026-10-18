import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'session_cache.dart';

const _fileName = 'ss_session_cache.json';

Future<File> _file() async {
  final dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}/$_fileName');
}

Future<CachedSession?> read(String coupleId) async {
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

Future<void> write({
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

Future<void> clear() async {
  try {
    final file = await _file();
    if (await file.exists()) await file.delete();
  } catch (_) {}
}
