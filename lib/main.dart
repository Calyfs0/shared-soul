import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/soul_app.dart';
import 'app/splash_screen.dart';
import 'config/auth_storage.dart';
import 'config/supabase_config.dart';
import 'theme/soul_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }
  // Paint immediately — never block the first frame on network/auth.
  runApp(const _BootApp());
}

class _BootApp extends StatefulWidget {
  const _BootApp();

  @override
  State<_BootApp> createState() => _BootAppState();
}

class _BootAppState extends State<_BootApp> {
  Object? _error;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final host = Uri.parse(SupabaseConfig.url).host.split('.').first;
      final persistKey = 'sb-$host-auth-token';

      // Web uses SharedPreferences (browser localStorage); mobile uses files.
      final storage = createAuthStorage(persistKey);
      final authOptions = FlutterAuthClientOptions(
        localStorage: storage.localStorage,
        pkceAsyncStorage: storage.pkceAsyncStorage,
        detectSessionInUri: false,
      );

      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
        authOptions: authOptions,
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;
      setState(() => _ready = true);
    } catch (e) {
      debugPrint('Supabase init failed: $e');
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: SoulColors.nightDeep,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Center(
                child: Text(
                  'Couldn’t start Shared Soul.\n\n$_error',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SoulColors.warmIvory.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (!_ready) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      );
    }
    return const SharedSoulApp();
  }
}
