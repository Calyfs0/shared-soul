import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/soul_app.dart';
import 'config/file_local_storage.dart';
import 'config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  final host = Uri.parse(SupabaseConfig.url).host.split('.').first;
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: FileLocalStorage(
        persistSessionKey: 'sb-$host-auth-token',
      ),
      pkceAsyncStorage: FileGotrueAsyncStorage(),
    ),
  );

  runApp(const SharedSoulApp());
}
