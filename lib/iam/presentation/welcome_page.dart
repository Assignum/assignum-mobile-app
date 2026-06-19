import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assignum/iam/presentation/login_register_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero scene ────────────────────────────────────────────────
            SizedBox(
              height: size.height * 0.46,
              width: double.infinity,
              child: _HeroScene(floatAnim: _floatCtrl),
            ),

            // ── Copy + CTAs ───────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 4, 28, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Eyebrow
                    Text(
                      'TRABAJO EN EQUIPO, SIN FRICCIÓN',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.6,
                        color: const Color(0xFF9A978C),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Headline serif
                    Text.rich(
                      TextSpan(
                        style: GoogleFonts.newsreader(
                          fontSize: 31,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF21201B),
                          height: 1.15,
                        ),
                        children: [
                          const TextSpan(text: 'Coordina tus\n'),
                          TextSpan(
                            text: 'proyectos grupales',
                            style: GoogleFonts.newsreader(
                              fontSize: 31,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFFDC2F26),
                              height: 1.15,
                            ),
                          ),
                          const TextSpan(text: ' sin\ncaos.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Body
                    Text(
                      'Reparte tareas, sigue el progreso y mantén a tu equipo alineado — todo en un solo lugar.',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14.5,
                        height: 1.55,
                        color: const Color(0xFF6E6B61),
                      ),
                    ),

                    const Spacer(),

                    // Crear cuenta (primary)
                    _PillButton(
                      text: 'Crear cuenta',
                      filled: true,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const LoginRegisterPage(initialIsLogin: false),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Ya tengo cuenta (outlined)
                    _PillButton(
                      text: 'Ya tengo cuenta',
                      filled: false,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const LoginRegisterPage(initialIsLogin: true),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero scene ───────────────────────────────────────────────────────────────

class _HeroScene extends StatelessWidget {
  final Animation<double> floatAnim;
  const _HeroScene({required this.floatAnim});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final h = box.maxHeight;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          // Soft blob – azul frío izquierda
          Positioned(
            left: w * 0.04,
            top: h * 0.35,
            child: Container(
              width: 145,
              height: 145,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFCFDFEE).withValues(alpha: 0.55),
              ),
            ),
          ),
          // Soft blob – rosa cálido derecha
          Positioned(
            right: -10,
            top: h * 0.05,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF5DDD9).withValues(alpha: 0.7),
              ),
            ),
          ),

          // Logo "A" central — Positioned directo en Stack, _FloatOffset adentro
          Positioned(
            left: w / 2 - 56,
            top: h / 2 - 60,
            child: _FloatOffset(
              animation: floatAnim,
              amplitude: 5,
              phase: 0,
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2F26),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC2F26).withValues(alpha: 0.28),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'A',
                    style: GoogleFonts.newsreader(
                      fontSize: 60,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // LR – azul grisáceo (arriba-izquierda)
          Positioned(
            left: w * 0.14,
            top: h * 0.09,
            child: _FloatOffset(
              animation: floatAnim,
              amplitude: 7,
              phase: 0.2,
              child: const _AvatarBubble(
                initials: 'LR',
                color: Color(0xFF7B9BB5),
              ),
            ),
          ),

          // MT – verde (arriba-derecha)
          Positioned(
            right: w * 0.14,
            top: h * 0.07,
            child: _FloatOffset(
              animation: floatAnim,
              amplitude: 6,
              phase: 0.5,
              child: const _AvatarBubble(
                initials: 'MT',
                color: Color(0xFF6B9E6B),
              ),
            ),
          ),

          // SP – ámbar (abajo-izquierda)
          Positioned(
            left: w * 0.09,
            bottom: h * 0.18,
            child: _FloatOffset(
              animation: floatAnim,
              amplitude: 8,
              phase: 0.7,
              child: const _AvatarBubble(
                initials: 'SP',
                color: Color(0xFFB8864A),
              ),
            ),
          ),

          // DV – púrpura (abajo-derecha)
          Positioned(
            right: w * 0.12,
            bottom: h * 0.12,
            child: _FloatOffset(
              animation: floatAnim,
              amplitude: 6,
              phase: 0.35,
              child: const _AvatarBubble(
                initials: 'DV',
                color: Color(0xFF8B6BAE),
              ),
            ),
          ),
        ],
      );
    });
  }
}

/// Aplica un offset vertical sinusoidal animado al child.
class _FloatOffset extends AnimatedWidget {
  final Widget child;
  final double amplitude;
  final double phase;

  const _FloatOffset({
    required Animation<double> animation,
    required this.child,
    this.amplitude = 6,
    this.phase = 0,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final anim = listenable as Animation<double>;
    final dy = math.sin((anim.value + phase) * math.pi) * amplitude;
    return Transform.translate(offset: Offset(0, dy), child: child);
  }
}

class _AvatarBubble extends StatelessWidget {
  final String initials;
  final Color color;

  const _AvatarBubble({required this.initials, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Botones pill ─────────────────────────────────────────────────────────────

class _PillButton extends StatelessWidget {
  final String text;
  final bool filled;
  final VoidCallback onPressed;

  const _PillButton({
    required this.text,
    required this.filled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2F26),
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          child: Text(
            text,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF21201B),
          side: const BorderSide(color: Color(0xFFD8D2C2), width: 1.5),
          shape: const StadiumBorder(),
        ),
        child: Text(
          text,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
