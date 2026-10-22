import 'package:flutter/foundation.dart';

class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static void validate() {
    if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
      throw StateError(
        'Missing Supabase configuration. Run with '
        '--dart-define=SUPABASE_URL=... '
        '--dart-define=SUPABASE_PUBLISHABLE_KEY=...',
      );
    }
    if (kDebugMode) {
      debugPrint('Supabase configuration loaded.');
    }
  }
}
