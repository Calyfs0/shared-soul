import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import 'session_cache.dart';
import 'session_cache_io_stub.dart'
    if (dart.library.io) 'session_cache_io.dart' as io;

/// Web → SharedPreferences. IO platforms → file (Android prefs JNI workaround).
abstract final class SessionCacheStore {
  static const _kCoupleId = 'ss_couple_id';
  static const _kMyName = 'ss_my_name';
  static const _kPartnerName = 'ss_partner_name';
  static const _kCosmetic = 'ss_cosmetic';

  static Future<CachedSession?> read(String coupleId) async {
    if (!kIsWeb) return io.read(coupleId);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_kCoupleId) != coupleId) return null;
      final my = prefs.getString(_kMyName);
      final partner = prefs.getString(_kPartnerName);
      if (my == null || partner == null) return null;
      return CachedSession(
        myName: my,
        partnerName: partner,
        cosmetic: prefs.getString(_kCosmetic) ?? 'none',
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
    if (!kIsWeb) {
      await io.write(
        coupleId: coupleId,
        myName: myName,
        partnerName: partnerName,
        cosmetic: cosmetic,
      );
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCoupleId, coupleId);
      await prefs.setString(_kMyName, myName);
      await prefs.setString(_kPartnerName, partnerName);
      await prefs.setString(_kCosmetic, cosmetic);
    } catch (_) {}
  }

  static Future<void> clear() async {
    if (!kIsWeb) {
      await io.clear();
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kCoupleId);
      await prefs.remove(_kMyName);
      await prefs.remove(_kPartnerName);
      await prefs.remove(_kCosmetic);
    } catch (_) {}
  }
}
