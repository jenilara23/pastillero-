import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../perfil/services/perfil_store.dart';
import '../../../core/config/supabase_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  DateTime? _birthDate;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _birthDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Selecciona tu fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (picked == null) return;

    setState(() {
      _birthDate = picked;
      _birthDateCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
    });
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      _showSnack('Por favor completa todos los campos');
      return;
    }
    if (_birthDate == null) {
      _showSnack('Selecciona tu fecha de nacimiento');
      return;
    }
    if (pass != confirm) {
      _showSnack('Las contraseñas no coinciden');
      return;
    }
    if (pass.length < 6) {
      _showSnack('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() => _loading = true);
    debugPrint('📝 [Register] Intentando registrar usuario: $email');
    try {
      await supabase.auth.signUp(
        email: email,
        password: pass,
        data: {
          'nombre': name,
          'fecha_nacimiento': DateFormat('yyyy-MM-dd').format(_birthDate!),
        },
      );
      if (supabase.auth.currentUser != null) {
        await PerfilStore.instance.saveInitial(nombre: name);
      }
      debugPrint(
          '📝 [Register] Usuario registrado con éxito (falta confirmar correo si aplica)');
      if (mounted) {
        _showSnack('¡Cuenta creada! Revisa tu correo para confirmarla 📧',
            success: true);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String msg;
        if (e is AuthException) {
          // Traducir mensajes comunes de Supabase
          if (e.message.contains('already registered') ||
              e.message.contains('already been registered')) {
            msg = 'Este correo ya está registrado. ¿Olvidaste tu contraseña?';
          } else if (e.message.contains('invalid')) {
            msg = 'Correo electrónico inválido';
          } else if (e.message.contains('weak')) {
            msg = 'La contraseña es muy débil';
          } else {
            msg = 'Error Supabase: ${e.message}';
          }
        } else {
          msg = 'Error de conexión: $e';
        }
        debugPrint('📝 [Register] ERROR en registro: $e');
        _showSnack(msg);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _loading = true);
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
      );
      if (mounted) {
        _showSnack('Continuando con Google...', success: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('No se pudo iniciar con Google: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AppColors.green : AppColors.navy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.navy, AppColors.navyLight, AppColors.blueGradientEnd],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    // ── Back button ──
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // ── Logo + título ──
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2),
                      ),
                      child: const Center(
                          child: Text('💊', style: TextStyle(fontSize: 34))),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Crea tu cuenta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Únete a PillCare y cuida tu salud',
                      style: TextStyle(
                          color: AppColors.blueLight.withValues(alpha: 0.9),
                          fontSize: 13),
                    ),
                    const SizedBox(height: 28),
                    // ── Card ──
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('NOMBRE COMPLETO'),
                          const SizedBox(height: 8),
                          _textField(
                              controller: _nameCtrl,
                              hint: 'Tu nombre',
                              icon: Icons.person_outline_rounded),
                          const SizedBox(height: 16),
                          _fieldLabel('CORREO ELECTRÓNICO'),
                          const SizedBox(height: 8),
                          _textField(
                              controller: _emailCtrl,
                              hint: 'correo@ejemplo.com',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 16),
                          _fieldLabel('CONTRASEÑA'),
                          const SizedBox(height: 8),
                          _textField(
                            controller: _passCtrl,
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscurePass,
                            suffix: _eyeBtn(
                                _obscurePass,
                                () => setState(
                                    () => _obscurePass = !_obscurePass)),
                          ),
                          const SizedBox(height: 16),
                          _fieldLabel('CONFIRMAR CONTRASEÑA'),
                          const SizedBox(height: 8),
                          _textField(
                            controller: _confirmCtrl,
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscureConfirm,
                            suffix: _eyeBtn(
                                _obscureConfirm,
                                () => setState(
                                    () => _obscureConfirm = !_obscureConfirm)),
                          ),
                          const SizedBox(height: 16),
                          _fieldLabel('FECHA DE NACIMIENTO'),
                          const SizedBox(height: 8),
                          _textField(
                            controller: _birthDateCtrl,
                            hint: 'DD/MM/AAAA',
                            icon: Icons.cake_outlined,
                            readOnly: true,
                            onTap: _pickBirthDate,
                            suffix: const Icon(
                              Icons.calendar_month_outlined,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.green,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    AppColors.green.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50)),
                                elevation: 6,
                                shadowColor:
                                    AppColors.green.withValues(alpha: 0.4),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5))
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle_outline,
                                            size: 20),
                                        SizedBox(width: 8),
                                        Text('Crear cuenta',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800)),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: AppColors.inputBorder,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  'O iniciar sesión con Google',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: AppColors.inputBorder,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _loading ? null : _continueWithGoogle,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textDark,
                                side: const BorderSide(
                                  color: AppColors.inputBorder,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/Inicio_Sesion/google_logo.png',
                                    width: 20,
                                    height: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Entrar con Google',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('¿Ya tienes una cuenta? ',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text('Inicia sesión',
                              style: TextStyle(
                                  color: AppColors.blueLight,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.textMuted),
      );

  Widget _eyeBtn(bool obscure, VoidCallback onTap) => IconButton(
        icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textMuted,
            size: 20),
        onPressed: onTap,
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
  }) =>
      TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(fontSize: 15, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
          suffixIcon: suffix,
          filled: true,
          fillColor: AppColors.inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.inputBorder, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.inputBorder, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.blue, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}
