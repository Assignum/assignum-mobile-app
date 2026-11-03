import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assignum/core/infrastructure/api_client.dart';
import 'package:assignum/iam/domain/privacy_policy.dart';
import 'package:assignum/iam/infrastructure/auth.dart';
import 'package:assignum/iam/infrastructure/user_service.dart';

// ── Tokens ─────────────────────────────────────────────────────────────
const _bg          = Color(0xFFF4F2EA);
const _surface     = Color(0xFFFBFAF4);
const _text        = Color(0xFF21201B);
const _text2       = Color(0xFF6E6B61);
const _text3       = Color(0xFF9A978C);
const _border      = Color(0xFFE7E2D5);
const _primary     = Color(0xFFDC2F26);

// ── Aviso completo ──────────────────────────────────────────────────────

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        foregroundColor: _text,
        title: Text('Aviso de privacidad',
            style: GoogleFonts.hankenGrotesk(
                fontSize: 17, fontWeight: FontWeight.w700, color: _text)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text('Versión $privacyPolicyVersion',
                style: GoogleFonts.hankenGrotesk(fontSize: 12.5, color: _text3)),
            const SizedBox(height: 16),
            for (final section in privacyPolicySections) ...[
              Semantics(
                header: true,
                child: Text(section.title,
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 15.5, fontWeight: FontWeight.w700, color: _text)),
              ),
              const SizedBox(height: 6),
              if (section.body != null)
                Text(section.body!,
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 14, height: 1.5, color: _text2)),
              for (final item in section.items) _PolicyItemRow(item),
              const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _PolicyItemRow extends StatelessWidget {
  final PolicyItem item;
  const _PolicyItemRow(this.item);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(
              text: '${item.data}: ',
              style: const TextStyle(fontWeight: FontWeight.w700, color: _text)),
          TextSpan(text: item.purpose),
        ]),
        style: GoogleFonts.hankenGrotesk(fontSize: 14, height: 1.5, color: _text2),
      ),
    );
  }
}

// ── Tarjeta de consentimiento (registro y reaceptación) ─────────────────

/// Resumen de la finalidad de cada dato, enlace al aviso completo y casilla
/// obligatoria. El formulario que la contiene no debe continuar sin [accepted].
class PrivacyConsentCard extends StatelessWidget {
  final bool accepted;
  final ValueChanged<bool> onChanged;

  const PrivacyConsentCard({super.key, required this.accepted, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 18, color: _primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Cómo usamos tus datos',
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 14, fontWeight: FontWeight.w700, color: _text)),
              ),
            ],
          ),
          for (final item in policyDataUses) _PolicyItemRow(item),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyPolicyPage())),
            style: TextButton.styleFrom(
                foregroundColor: _primary, padding: EdgeInsets.zero),
            child: Text('Leer el aviso de privacidad completo',
                style: GoogleFonts.hankenGrotesk(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline)),
          ),
          const Divider(height: 1, color: _border),
          CheckboxListTile(
            value: accepted,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: _primary,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
                'He leído el aviso de privacidad y acepto el tratamiento de mis datos para estos fines.',
                style: GoogleFonts.hankenGrotesk(fontSize: 13.5, height: 1.4, color: _text)),
          ),
        ],
      ),
    );
  }
}

// ── Pantalla de reaceptación ────────────────────────────────────────────

/// Se muestra al iniciar sesión cuando el usuario no aceptó la versión vigente
/// del aviso (cuentas anteriores al aviso o aviso actualizado).
class PrivacyReconsentPage extends StatefulWidget {
  final VoidCallback onAccepted;
  const PrivacyReconsentPage({super.key, required this.onAccepted});

  @override
  State<PrivacyReconsentPage> createState() => _PrivacyReconsentPageState();
}

class _PrivacyReconsentPageState extends State<PrivacyReconsentPage> {
  bool _accepted = false;
  bool _saving = false;

  Future<void> _continue() async {
    setState(() => _saving = true);
    try {
      await UserService().acceptPrivacyPolicy();
      widget.onAccepted();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            Text('AVISO DE PRIVACIDAD',
                style: GoogleFonts.hankenGrotesk(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    letterSpacing: 1.6, color: _text3)),
            const SizedBox(height: 8),
            Text('Antes de continuar',
                style: GoogleFonts.hankenGrotesk(
                    fontSize: 26, fontWeight: FontWeight.w700, color: _text)),
            const SizedBox(height: 6),
            Text('Actualizamos cómo te explicamos el uso de tus datos. Revísalo y acéptalo para seguir usando Assignum.',
                style: GoogleFonts.hankenGrotesk(fontSize: 14.5, height: 1.5, color: _text2)),
            const SizedBox(height: 20),
            PrivacyConsentCard(
                accepted: _accepted,
                onChanged: (v) => setState(() => _accepted = v)),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _accepted && !_saving ? _continue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _primary.withValues(alpha: 0.5),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Aceptar y continuar',
                        style: GoogleFonts.hankenGrotesk(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            TextButton(
              onPressed: _saving ? null : () => Auth().signOut(),
              style: TextButton.styleFrom(foregroundColor: _text2),
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
