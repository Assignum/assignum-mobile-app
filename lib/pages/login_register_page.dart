import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:assignum/auth.dart';
import 'package:assignum/pages/about_you_page.dart';
import 'package:assignum/widgets/ui.dart';

class LoginRegisterPage extends StatefulWidget {
  final bool initialIsLogin;
  const LoginRegisterPage({super.key, this.initialIsLogin = true});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool isLogin = true;
  String? errorMessage;

  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  // Campos solo para registro
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
    setState(() => errorMessage = null);

    try {
      if (isLogin) {
        await Auth().signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
        if (mounted) Navigator.pop(context); // vuelve al árbol -> Home
      } else {
        final cred = await Auth().createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );

        // En registro, pasamos a "Háblanos de ti"
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => AboutYouPage(
                fullName: _nameCtrl.text.trim(),
                birthDate: _birthDate,
                cameFromRegister: true,
              ),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => errorMessage = e.message);
    }
  }

  Future<void> _resetPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => errorMessage = 'Ingresa tu correo para recuperar contraseña.');
      return;
    }
    try {
      await Auth().sendPasswordResetEmail(email: _emailCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Te enviamos un correo para restablecer la contraseña.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => errorMessage = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = isLogin ? 'Inicia sesión' : 'Regístrate';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CardContainer(
                  child: Column(
                    children: [
                      if (!isLogin) ...[
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nombre completo',
                          ),
                          validator: (v) =>
                          (v == null || v.trim().length < 3)
                              ? 'Ingresa tu nombre'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _pickBirthDate,
                          borderRadius: BorderRadius.circular(16),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Fecha de nacimiento',
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_birthDate == null
                                    ? 'Elegir fecha'
                                    : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'),
                                const Icon(Icons.calendar_today_outlined),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                        ),
                        validator: (v) =>
                        (v == null || !v.contains('@')) ? 'Correo inválido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                        ),
                        validator: (v) =>
                        (v == null || v.length < 6)
                            ? 'Mínimo 6 caracteres'
                            : null,
                      ),
                      if (errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 16),
                      PrimaryButton(
                        text: isLogin ? 'Iniciar sesión' : 'Siguiente',
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() => isLogin = !isLogin),
                        child: Text(isLogin
                            ? '¿No tienes cuenta? Regístrate'
                            : '¿Ya tienes cuenta? Inicia sesión'),
                      ),
                      if (isLogin)
                        TextButton(
                          onPressed: _resetPassword,
                          child: const Text('¿Olvidaste tu contraseña?'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
