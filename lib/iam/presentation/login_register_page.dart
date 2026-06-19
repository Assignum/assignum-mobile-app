import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assignum/iam/infrastructure/auth.dart';
import 'package:assignum/core/infrastructure/api_client.dart';
import 'package:assignum/iam/presentation/about_you_page.dart';
import 'package:assignum/iam/presentation/forgot_password_page.dart';

class LoginRegisterPage extends StatefulWidget {
  final bool initialIsLogin;
  const LoginRegisterPage({super.key, this.initialIsLogin = true});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  late bool isLogin;
  String? errorMessage;
  bool _loading = false;
  bool _obscurePassword = true;

  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _nameCtrl  = TextEditingController();
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    isLogin = widget.initialIsLogin;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year - 10, 12, 31),
      initialDate: DateTime(now.year - 20, now.month, now.day),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { errorMessage = null; _loading = true; });

    try {
      if (isLogin) {
        await Auth().signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
        }
      } else {
        await Auth().createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => AboutYouPage(
                cameFromRegister: true,
                initialName: _nameCtrl.text.trim(),
                initialBirthDate: _birthDate,
              ),
            ),
          );
        }
      }
    } on ApiException catch (e) {
      if (mounted) setState(() { errorMessage = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { errorMessage = 'Error inesperado. Intenta de nuevo.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF21201B)),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isLogin ? 'Bienvenido\nde vuelta' : 'Crea tu\ncuenta',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF21201B),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isLogin
                        ? 'Inicia sesión para continuar coordinando.'
                        : 'Únete y empieza a coordinar en minutos.',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14.5,
                      color: const Color(0xFF6E6B61),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Segmented control ────────────────────────────────────
                  _SegmentedControl(
                    isLogin: isLogin,
                    onChanged: (v) => setState(() {
                      isLogin = v;
                      errorMessage = null;
                    }),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // ── Form (scrollable) ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre — solo en registro
                      if (!isLogin) ...[
                        _LabeledField(
                          label: 'Nombre completo',
                          icon: Icons.person_outline_rounded,
                          controller: _nameCtrl,
                          validator: (v) => (v == null || v.trim().length < 3)
                              ? 'Ingresa tu nombre completo'
                              : null,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Correo
                      _LabeledField(
                        label: 'Correo electrónico',
                        icon: Icons.mail_outline_rounded,
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            (v == null || !v.contains('@')) ? 'Correo inválido' : null,
                      ),

                      // Fecha — solo en registro
                      if (!isLogin) ...[
                        const SizedBox(height: 16),
                        _BirthdatePicker(
                          date: _birthDate,
                          onTap: _pickBirthDate,
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Contraseña
                      _PasswordField(
                        controller: _passCtrl,
                        obscure: _obscurePassword,
                        onToggle: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                        validator: (v) =>
                            (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                      ),

                      // Olvidaste contraseña — solo en login
                      if (isLogin) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ForgotPasswordPage(
                                    initialEmail: _emailCtrl.text.trim()),
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2F26),
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              '¿Olvidaste tu contraseña?',
                              style: GoogleFonts.hankenGrotesk(
                                  fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ],

                      // Error
                      if (errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAE7E2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Color(0xFFDC2F26), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: GoogleFonts.hankenGrotesk(
                                    color: const Color(0xFFDC2F26),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // ── CTA fijo abajo ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2F26),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFFDC2F26).withValues(alpha: 0.5),
                    shape: const StadiumBorder(),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: Text(
                    _loading
                        ? (isLogin ? 'Iniciando...' : 'Registrando...')
                        : (isLogin ? 'Iniciar sesión' : 'Continuar'),
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Segmented control ────────────────────────────────────────────────────────

class _SegmentedControl extends StatelessWidget {
  final bool isLogin;
  final ValueChanged<bool> onChanged;

  const _SegmentedControl({required this.isLogin, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFECE8DC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _SegmentTab(
            label: 'Iniciar sesión',
            active: isLogin,
            onTap: () => onChanged(true),
          ),
          _SegmentTab(
            label: 'Registrarme',
            active: !isLogin,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SegmentTab(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active
                    ? const Color(0xFF21201B)
                    : const Color(0xFF9A978C),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared field widgets ─────────────────────────────────────────────────────

const _inputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(16)),
  borderSide: BorderSide(color: Color(0xFFE7E2D5), width: 1.5),
);
const _focusedBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(16)),
  borderSide: BorderSide(color: Color(0xFFDC2F26), width: 1.5),
);
const _errorBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(16)),
  borderSide: BorderSide(color: Color(0xFFDC2F26), width: 1.5),
);

class _LabeledField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _LabeledField({
    required this.label,
    required this.icon,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF21201B),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.hankenGrotesk(
              fontSize: 15, color: const Color(0xFF21201B)),
          decoration: InputDecoration(
            prefixIcon:
                Icon(icon, size: 18, color: const Color(0xFF9A978C)),
            filled: true,
            fillColor: const Color(0xFFFBFAF4),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: _inputBorder,
            enabledBorder: _inputBorder,
            focusedBorder: _focusedBorder,
            errorBorder: _errorBorder,
            focusedErrorBorder: _errorBorder,
          ),
        ),
      ],
    );
  }
}

class _BirthdatePicker extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;

  const _BirthdatePicker({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha de nacimiento',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF21201B),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFAF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE7E2D5), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 18, color: Color(0xFF9A978C)),
                const SizedBox(width: 12),
                Text(
                  date == null
                      ? 'Seleccionar fecha'
                      : '${date!.day.toString().padLeft(2, '0')} / '
                          '${date!.month.toString().padLeft(2, '0')} / '
                          '${date!.year}',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    color: date == null
                        ? const Color(0xFF9A978C)
                        : const Color(0xFF21201B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contraseña',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF21201B),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: GoogleFonts.hankenGrotesk(
              fontSize: 15, color: const Color(0xFF21201B)),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline_rounded,
                size: 18, color: Color(0xFF9A978C)),
            hintText: 'Mínimo 6 caracteres',
            hintStyle:
                GoogleFonts.hankenGrotesk(color: const Color(0xFF9A978C)),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: const Color(0xFF9A978C),
              ),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: const Color(0xFFFBFAF4),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: _inputBorder,
            enabledBorder: _inputBorder,
            focusedBorder: _focusedBorder,
            errorBorder: _errorBorder,
            focusedErrorBorder: _errorBorder,
          ),
        ),
      ],
    );
  }
}
