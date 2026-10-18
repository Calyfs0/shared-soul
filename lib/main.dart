import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/soul_app.dart';
import 'config/auth_storage.dart';
import 'config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  final host = Uri.parse(SupabaseConfig.url).host.split('.').first;
  final storage = createAuthStorage('sb-$host-auth-token');

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: storage.localStorage,
      pkceAsyncStorage: storage.pkceAsyncStorage,
    ),
  );

  runApp(const SharedSoulApp());
}
