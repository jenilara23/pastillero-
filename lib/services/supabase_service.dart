import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Constantes del proyecto Supabase ───────────────────────────────────────
// URL del proyecto en Supabase
const String supabaseUrl = 'https://ixzihjionmzmsvwzymza.supabase.co';

// IMPORTANTE: Reemplaza este valor con la clave "anon public" de tu proyecto.
// La puedes encontrar en: supabase.com → Tu proyecto → Project Settings → API
// → Project API Keys → "anon public"  (debe empezar con "eyJ...")
// ⚠️ La clave actual NO es válida. Cópiala desde el dashboard de Supabase.
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml4emloamlvbm16bXN2d3p5bXphIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIzNDM4MzIsImV4cCI6MjA4NzkxOTgzMn0.lMp81TEmKAvwQ-Wpk4KKBwSo26vLPyaLMXu2Srd5YSI';

// ─── Cliente global de Supabase ─────────────────────────────────────────────
SupabaseClient get supabase => Supabase.instance.client;

// ─── Usuario actual ──────────────────────────────────────────────────────────
User? get currentUser => supabase.auth.currentUser;
String? get currentUserId => supabase.auth.currentUser?.id;
bool get isLoggedIn => supabase.auth.currentUser != null;
