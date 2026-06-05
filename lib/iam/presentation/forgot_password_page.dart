import 'package:flutter/material.dart';
import 'package:assignum/iam/infrastructure/auth.dart';
import 'package:assignum/core/infrastructure/api_client.dart';
import 'package:assignum/shared/presentation/widgets/ui.dart';
import 'package:assignum/shared/presentation/widgets/premium_app_bar.dart';
import 'package:assignum/shared/presentation/theme/app_theme.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String initialEmail;
  const ForgotPasswordPage({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final PageController _pageController = PageController();
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _errorMessage;
  bool _loading = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMessage = null; });

    try {
      await Auth().sendPasswordResetEmail(email: _emailCtrl.text.trim());
      if (mounted) {
        setState(() { _loading = false; _currentStep = 1; });
        _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      }
    } on ApiException catch (e) {
      setState(() { _loading = false; _errorMessage = e.message; });
    } catch (e) {
      setState(() { _loading = false; _errorMessage = 'Ocurrió un error inesperado. Inténtalo de nuevo.'; });
    }
  }

  InputDecoration _customDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.06),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.upcRed, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PremiumAppBar(titleText: 'Recuperar Contraseña'),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (page) => setState(() => _currentStep = page),
          children: [_buildEmailStep(), _buildSuccessStep()],
        ),
      ),
    );
  }

  Widget _buildStepDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (index) {
        final isActive = index == _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(color: isActive ? AppColors.upcRed : Colors.grey[300], borderRadius: BorderRadius.circular(4)),
        );
      }),
    );
  }

  Widget _buildEmailStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            const Text('Recupera tu contraseña', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.upcBlack)),
            const SizedBox(height: 16),
            _buildStepDots(),
            const SizedBox(height: 24),
            CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Ingresa tu correo electrónico', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.upcBlack)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _customDecoration('Correo electrónico'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Ingresa tu correo electrónico';
                      if (!v.contains('@')) return 'Ingresa un correo válido';
                      return null;
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(_errorMessage!, style: const TextStyle(color: AppColors.upcRed, fontSize: 14), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 32),
                  PrimaryButton(text: _loading ? 'Enviando...' : 'Siguiente', onPressed: _loading ? null : _submit),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          const Text('¡Correo enviado!', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.upcBlack)),
          const SizedBox(height: 16),
          _buildStepDots(),
          const SizedBox(height: 24),
          CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: PulsingEmailIcon()),
                const SizedBox(height: 24),
                Text('Hemos enviado un correo a:\n${_emailCtrl.text.trim()}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.upcBlack)),
                const SizedBox(height: 16),
                const Text('Por favor, revisa tu bandeja de entrada y sigue las instrucciones para restablecer tu contraseña.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.upcGray, height: 1.4)),
                const SizedBox(height: 32),
                PrimaryButton(text: 'Iniciar sesión', onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PulsingEmailIcon extends StatefulWidget {
  const PulsingEmailIcon({super.key});

  @override
  State<PulsingEmailIcon> createState() => _PulsingEmailIconState();
}

class _PulsingEmailIconState extends State<PulsingEmailIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.92, end: 1.08).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.upcRed.withValues(alpha: 0.08), shape: BoxShape.circle),
        child: const Icon(Icons.mail_lock_rounded, color: AppColors.upcRed, size: 64),
      ),
    );
  }
}
