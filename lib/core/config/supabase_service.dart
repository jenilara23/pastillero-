import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Constantes del proyecto Supabase (leídas desde .env) ───────────────────
String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

// ─── Cliente global de Supabase ─────────────────────────────────────────────
SupabaseClient get supabase => Supabase.instance.client;

// ─── Usuario actual ──────────────────────────────────────────────────────────
User? get currentUser => supabase.auth.currentUser;
String? get currentUserId => supabase.auth.currentUser?.id;
bool get isLoggedIn => supabase.auth.currentUser != null;
