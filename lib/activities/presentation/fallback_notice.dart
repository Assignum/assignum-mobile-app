import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _warn     = Color(0xFFB26B36);
const _warnTint = Color(0xFFF4E7D6);
const _text     = Color(0xFF21201B);

/// Aviso al líder de que el último reparto se hizo sin el servicio de
/// recomendación (round-robin o menor carga) y que puede redistribuir.
class FallbackAssignmentNotice extends StatelessWidget {
  final String message;
  final VoidCallback? onRedistribute;

  const FallbackAssignmentNotice({
    super.key,
    this.message =
        'Este reparto se hizo sin el modelo de recomendación porque no respondió. '
        'Puedes redistribuir las tareas cuando vuelva a estar disponible.',
    this.onRedistribute,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: _warnTint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _warn.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, color: _warn, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Asignación hecha sin ML',
                      style: GoogleFonts.hankenGrotesk(
                          fontSize: 13.5, fontWeight: FontWeight.w700, color: _text)),
                  const SizedBox(height: 2),
                  Text(message,
                      style: GoogleFonts.hankenGrotesk(
                          fontSize: 12.5, height: 1.4, color: _text)),
                  if (onRedistribute != null)
                    TextButton(
                      onPressed: onRedistribute,
                      style: TextButton.styleFrom(
                          foregroundColor: _warn,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(48, 40)),
                      child: Text('Redistribuir',
                          style: GoogleFonts.hankenGrotesk(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
