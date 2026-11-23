import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/auth_remote_ds.dart';
import '../../../domain/repositories/auth_repository.dart';

// Pantalla de login: valida el formulario y autentica contra el backend.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.authRepository, this.oauthRepository});

  /// Auth a usar; por defecto, el backend real.
  final AuthRepository? authRepository;
  final OAuthRepository? oauthRepository;

  static final uctEmail = RegExp(
    r'^[^@\s]+@([a-z0-9-]+\.)*uct\.cl$',
    caseSensitive: false,
  );

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  late final AuthRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = widget.authRepository ?? AuthRemoteDataSource();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await _authenticate(
      () => _repo.login(email: _emailCtrl.text, password: _passCtrl.text),
    );
  }

  Future<void> _authenticate(Future<AuthLoginResult?> Function() signIn) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await signIn();
      if (!mounted || result == null) return;
      Navigator.pop(context, {
        'ok': true,
        'email': result.email,
        'userId': result.userId,
        'token': result.token,
      });
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Ocurrió un error inesperado. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final from = ModalRoute.of(context)?.settings.arguments as String?;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (Navigator.canPop(context)) ...[
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.uctBlue,
                        ),
                        tooltip: 'Volver',
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.uctYellow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.uctBlue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'UCT MAP',
                        style: TextStyle(
                          color: AppColors.uctBlue,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Idioma',
                      onPressed: () {},
                      icon: const Icon(
                        Icons.language,
                        color: AppColors.ink,
                        size: 26,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: AppColors.fieldBorder),
                const SizedBox(height: 28),
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.uctYellow.withValues(alpha: 0.55),
                          blurRadius: 40,
                          spreadRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.explore_outlined,
                      color: AppColors.uctBlue,
                      size: 46,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Inicia Sesión',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  from == null
                      ? 'Explora y navega por el campus de forma fácil'
                      : 'Para acceder a $from inicia sesión',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.subtitle,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Correo Electrónico',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText: 'usuario@uct.cl',
                    hintStyle: TextStyle(color: AppColors.hint),
                    prefixIconConstraints: BoxConstraints(
                      minWidth: 56,
                      minHeight: 48,
                    ),
                    prefixIcon: Icon(
                      Icons.mail_outlined,
                      color: AppColors.subtitle,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(color: AppColors.fieldBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(color: AppColors.fieldBorder),
                    ),
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Ingresa tu correo';
                    if (!LoginPage.uctEmail.hasMatch(value)) {
                      return 'Usa tu correo UCT (ej. usuario@uct.cl o usuario@alu.uct.cl)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Contraseña',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: const TextStyle(color: AppColors.hint),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 56,
                      minHeight: 48,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outlined,
                      color: AppColors.subtitle,
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 56,
                      minHeight: 48,
                    ),
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Mostrar' : 'Ocultar',
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(color: AppColors.fieldBorder),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(color: AppColors.fieldBorder),
                    ),
                  ),
                  validator: (v) {
                    final value = v ?? '';
                    if (value.isEmpty) return 'Ingresa tu contraseña';
                    if (value.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.uctBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                // Mostrar cuando estén conectados el proveedor y la sesión Identity.
                /*
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _loading || widget.oauthRepository == null
                      ? null
                      : () => _authenticate(widget.oauthRepository!.signIn),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    foregroundColor: AppColors.uctBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text(
                    'Continuar con cuenta externa',
                    textAlign: TextAlign.center,
                  ),
                ),
                if (widget.oauthRepository == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Acceso externo aún no disponible.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.subtitle),
                    ),
                  ),
                */
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Volver',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
