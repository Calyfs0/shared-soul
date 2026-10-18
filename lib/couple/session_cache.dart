import 'session_cache_store.dart';

/// Last-known couple UI bits so launch can paint without “Them” → name flicker.
class SessionCache {
  SessionCache._();

  static Future<CachedSession?> read(String coupleId) =>
      SessionCacheStore.read(coupleId);

  static Future<void> write({
    required String coupleId,
    required String myName,
    required String partnerName,
    required String cosmetic,
  }) =>
      SessionCacheStore.write(
        coupleId: coupleId,
        myName: myName,
        partnerName: partnerName,
        cosmetic: cosmetic,
      );

  static Future<void> clear() => SessionCacheStore.clear();
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
