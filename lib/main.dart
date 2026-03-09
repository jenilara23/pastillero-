import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tzLib;
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';
import 'models/app_theme.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🚀 [Main] Iniciando PillCare App...');

  // ── Cargar variables de entorno ──
  await dotenv.load(fileName: '.env');

  // ── Inicializar timezone ──
  tz.initializeTimeZones();
  tzLib.setLocalLocation(tzLib.getLocation('America/Mexico_City'));

  // ── Inicializar Notificaciones ──
  await NotificationService.init();

  // ── Inicializar Supabase ──
  debugPrint('🚀 [Main] Inicializando Supabase...');
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const PillCareApp());
  debugPrint('🚀 [Main] App ejecutándose');
}

class PillCareApp extends StatelessWidget {
  const PillCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PillCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.blue),
        useMaterial3: true,
        fontFamily: 'Nunito',
        scaffoldBackgroundColor: AppColors.bgColor,
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.navy,
          contentTextStyle:
              TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      // Determina pantalla inicial según sesión activa
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/register': (_) => const RegisterScreen(),
      },
    );
  }
}
