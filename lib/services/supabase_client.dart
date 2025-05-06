// File location: lib/services/supabase_client.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Use this getter to access the Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize(String url, String anonKey) async {
    print("SupabaseService: Initializing with URL: $url");

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
    );

    print("SupabaseService: Successfully initialized Supabase");

    // Log if a user is already signed in
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      print("SupabaseService: User already signed in: ${currentUser.id}");
    } else {
      print("SupabaseService: No user signed in");
    }

    // Listen for auth state changes
    listenToAuthEvents();
  }

  // Helper method to log auth state change events
  static void listenToAuthEvents() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      print("SupabaseService: Auth state changed - Event: $event");
      if (session != null) {
        print("SupabaseService: User ID: ${session.user.id}");
      }
    });
  }
}
