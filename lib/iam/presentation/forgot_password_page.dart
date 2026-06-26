import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assignum/iam/infrastructure/auth.dart';
import 'package:assignum/core/infrastructure/api_client.dart';

// ── Tokens ─────────────────────────────────────────────────────────────
const _bg          = Color(0xFFF4F2EA);
const _surface     = Color(0xFFFBFAF4);
const _surfaceInset= Color(0xFFF0EDE2);
const _text        = Color(0xFF21201B);
const _text2       = Color(0xFF6E6B61);
const _text3       = Color(0xFF9A978C);
const _border      = Color(0xFFE7E2D5);
const _primary     = Color(0xFFDC2F26);
const _primaryTint = Color(0xFFFAE7E2);

class ForgotPasswordPage extends StatefulWidget {
  final String initialEmail;
  const ForgotPasswordPage({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      await Auth().sendPasswordResetEmail(email: _emailCtrl.text.trim());
      if (mounted) {
        setState(() => _loading = false);
        _showSuccessDialog();
      }
    } on ApiException catch (e) {
      setState(() { _loading = false; _error = e.message; });
    } catch (_) {
      setState(() { _loading = false; _error = 'Ocurrió un error inesperado.'; });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: _surface,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                    color: _primaryTint,
                    borderRadius: BorderRadius.circular(999)),
                child: const Icon(Icons.mark_email_read_outlined,
                    color: _primary, size: 30),
              ),
              const SizedBox(height: 16),
              Text('¡Correo enviado!',
                  style: GoogleFonts.hankenGrotesk(
                      fontSize: 18, fontWeight: FontWeight.w700, color: _text)),
              const SizedBox(height: 8),
              Text(
                'Revisa tu bandeja de entrada en\n${_emailCtrl.text.trim()}',
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(fontSize: 14, color: _text2),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
                    elevation: 0,
                  ),
                  child: Text('Volver al inicio',
                      style: GoogleFonts.hankenGrotesk(
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: back + step dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: _text, size: 24),
                    ),
                    Row(
                      children: List.generate(3, (i) => Container(
                        margin: const EdgeInsets.only(left: 6),
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: i == 0 ? _primary : _border,
                          shape: BoxShape.circle,
                        ),
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                // Lock icon
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: _primaryTint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.lock_outline_rounded,
                      color: _primary, size: 28),
                ),
                const SizedBox(height: 24),
                // Title
                Text('¿Olvidaste tu contraseña?',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 26, fontWeight: FontWeight.w700,
                      color: _text, height: 1.2,
                    )),
                const SizedBox(height: 12),
                // Subtitle
                Text(
                  'No te preocupes. Escribe tu correo y te enviaremos un código para restablecerla.',
                  style: GoogleFonts.hankenGrotesk(
                      fontSize: 14.5, color: _text2, height: 1.5),
                ),
                const SizedBox(height: 32),
                // Email label
                Text('Correo electrónico',
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 13.5, fontWeight: FontWeight.w600,
                        color: _text2)),
                const SizedBox(height: 8),
                // Email field
                Container(
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _error != null ? _primary : _border,
                      width: _error != null ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 14),
                        child: Icon(Icons.email_outlined,
                            size: 18, color: _text3),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.hankenGrotesk(
                              fontSize: 14, color: _text),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 14),
                            hintText: 'correo@ejemplo.com',
                            hintStyle: GoogleFonts.hankenGrotesk(
                                fontSize: 14, color: _text3),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Ingresa tu correo';
                            }
                            if (!v.contains('@')) {
                              return 'Ingresa un correo válido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!,
                      style: GoogleFonts.hankenGrotesk(
                          color: _primary, fontSize: 13)),
                ],
                const SizedBox(height: 20),
                // Send button
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _surfaceInset,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text('Enviar código',
                            style: GoogleFonts.hankenGrotesk(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 20),
                // Spam note
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _surfaceInset,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          size: 16, color: _text3),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Revisa tu carpeta de spam si no ves el correo en unos minutos.',
                          style: GoogleFonts.hankenGrotesk(
                              fontSize: 13, color: _text2, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Back to login link
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.hankenGrotesk(
                          fontSize: 14, color: _text2),
                      children: [
                        const TextSpan(text: '¿Lo recordaste? '),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text('Volver al inicio',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _primary,
                                )),
                          ),
                        ),
                      ],
                    ),
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
