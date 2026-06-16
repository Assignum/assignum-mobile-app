import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assignum/iam/infrastructure/user_service.dart';
import 'package:assignum/iam/domain/user_profile.dart';
import 'package:assignum/core/infrastructure/auth_session.dart';

class AboutYouPage extends StatefulWidget {
  final bool cameFromRegister;
  final String? initialName;
  final DateTime? initialBirthDate;

  const AboutYouPage({
    super.key,
    this.cameFromRegister = false,
    this.initialName,
    this.initialBirthDate,
  });

  @override
  State<AboutYouPage> createState() => _AboutYouPageState();
}

class _AboutYouPageState extends State<AboutYouPage> {
  final _userService = UserService();
  final _nameCtrl = TextEditingController();
  DateTime? _birthDate;

  // Disponibilidad: 1=Mañana, 2=Tarde, 3=Noche
  double _disponibilidad = 1;
  // Carga académica: 1=Ligera, 2=Media, 3=Alta
  double _cargaAcademica = 2;
  // Sliders numéricos
  double _trabajoEnEquipo = 3;
  double _comunicacion = 3;
  double _horasEstudio = 20;

  bool _saving = false;

  static const _disponibilidadLabels = ['Mañana', 'Tarde', 'Noche'];
  static const _cargaLabels = ['Ligera', 'Media', 'Alta'];

  @override
  void initState() {
    super.initState();
    if (widget.initialName != null) _nameCtrl.text = widget.initialName!;
    if (widget.initialBirthDate != null) _birthDate = widget.initialBirthDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String get _disponibilidadStr =>
      _disponibilidadLabels[(_disponibilidad - 1).round().clamp(0, 2)];

  String get _cargaStr =>
      _cargaLabels[(_cargaAcademica - 1).round().clamp(0, 2)];

  Future<void> _save() async {
    if (_saving) return;
    if (_nameCtrl.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu nombre completo')),
      );
      return;
    }
    setState(() => _saving = true);

    final profile = UserProfile(
      uid: AuthSession().uid ?? '',
      fullName: _nameCtrl.text.trim(),
      birthDate: _birthDate,
      disponibilidad: _disponibilidadStr,
      cargaAcademica: _cargaStr,
      trabajoEnEquipo: _trabajoEnEquipo.round(),
      comunicacion: _comunicacion.round(),
      horasEstudio: _horasEstudio.round(),
    );

    await _userService.createOrUpdateProfile(profile);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Color(0xFF21201B)),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  if (widget.cameFromRegister)
                    Text(
                      'Paso 2 de 3',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6E6B61),
                      ),
                    ),
                ],
              ),
            ),

            // ── Progress bar ──────────────────────────────────────────────
            if (widget.cameFromRegister) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: 2 / 3,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFE7E2D5),
                    valueColor:
                        const AlwaysStoppedAnimation(Color(0xFFDC2F26)),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Copy ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CUÉNTANOS SOBRE TI',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.6,
                      color: const Color(0xFF9A978C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Así te asignamos\nlas tareas ideales',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF21201B),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajusta cada control según tu realidad. Podrás cambiarlo cuando quieras.',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14.5,
                      height: 1.5,
                      color: const Color(0xFF6E6B61),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Scrollable content ────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  children: [
                    // Nombre (cuando no viene del registro)
                    if (!widget.cameFromRegister) ...[
                      _nameField(),
                      const SizedBox(height: 16),
                    ],

                    // Card de sliders
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBFAF4),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: const Color(0xFFE7E2D5), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3C321E)
                                .withValues(alpha: 0.06),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Disponibilidad (3 posiciones)
                          _LabelSliderRow(
                            icon: Icons.schedule_outlined,
                            label: 'Disponibilidad',
                            displayValue: _disponibilidadStr,
                            bottomLabels: const ['Mañana', 'Tarde', 'Noche'],
                            child: _buildDisponibilidadSlider(),
                          ),
                          _divider(),

                          // Carga académica (3 posiciones)
                          _LabelSliderRow(
                            icon: Icons.school_outlined,
                            label: 'Carga académica',
                            displayValue: _cargaStr,
                            bottomLabels: const ['Ligera', 'Media', 'Alta'],
                            child: _buildCargaSlider(),
                          ),
                          _divider(),

                          // Trabajo en equipo (1–5)
                          _LabelSliderRow(
                            icon: Icons.groups_2_outlined,
                            label: 'Trabajo en equipo',
                            displayValue: '${_trabajoEnEquipo.round()}/5',
                            bottomLabels: const ['Bajo', 'Alto'],
                            child: _buildNumericSlider(
                              value: _trabajoEnEquipo,
                              max: 5,
                              divisions: 4,
                              onChanged: (v) =>
                                  setState(() => _trabajoEnEquipo = v),
                            ),
                          ),
                          _divider(),

                          // Comunicación (1–5)
                          _LabelSliderRow(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Comunicación',
                            displayValue: '${_comunicacion.round()}/5',
                            bottomLabels: const ['Bajo', 'Alto'],
                            child: _buildNumericSlider(
                              value: _comunicacion,
                              max: 5,
                              divisions: 4,
                              onChanged: (v) =>
                                  setState(() => _comunicacion = v),
                            ),
                          ),
                          _divider(),

                          // Horas de estudio (1–50)
                          _LabelSliderRow(
                            icon: Icons.menu_book_outlined,
                            label: 'Horas de estudio',
                            displayValue: '${_horasEstudio.round()}h/sem',
                            bottomLabels: const ['1 h', '50 h'],
                            isLast: true,
                            child: _buildNumericSlider(
                              value: _horasEstudio,
                              min: 1,
                              max: 50,
                              divisions: 49,
                              onChanged: (v) =>
                                  setState(() => _horasEstudio = v),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── CTA ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
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
                    _saving ? 'Guardando...' : 'Continuar',
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

  Widget _divider() => const Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFE7E2D5),
        indent: 20,
        endIndent: 20,
      );

  Widget _buildDisponibilidadSlider() {
    return _themedSlider(
      value: _disponibilidad,
      min: 1,
      max: 3,
      divisions: 2,
      onChanged: (v) => setState(() => _disponibilidad = v),
    );
  }

  Widget _buildCargaSlider() {
    return _themedSlider(
      value: _cargaAcademica,
      min: 1,
      max: 3,
      divisions: 2,
      onChanged: (v) => setState(() => _cargaAcademica = v),
    );
  }

  Widget _buildNumericSlider({
    required double value,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    double min = 1,
  }) {
    return _themedSlider(
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      onChanged: onChanged,
    );
  }

  Widget _themedSlider({
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: const Color(0xFFDC2F26),
        inactiveTrackColor: const Color(0xFFE7E2D5),
        thumbColor: Colors.white,
        overlayColor: const Color(0xFFDC2F26).withValues(alpha: 0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
        trackHeight: 4,
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }

  Widget _nameField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFAF4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7E2D5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nombre completo',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF21201B),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            style: GoogleFonts.hankenGrotesk(
                fontSize: 15, color: const Color(0xFF21201B)),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person_outline_rounded,
                  size: 18, color: Color(0xFF9A978C)),
              filled: true,
              fillColor: const Color(0xFFF0EDE2),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slider row ───────────────────────────────────────────────────────────────

class _LabelSliderRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String displayValue;
  final Widget child;
  final List<String> bottomLabels;
  final bool isLast;

  const _LabelSliderRow({
    required this.icon,
    required this.label,
    required this.displayValue,
    required this.child,
    required this.bottomLabels,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título + valor
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFFDC2F26)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF21201B),
                  ),
                ),
              ),
              Text(
                displayValue,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFDC2F26),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Slider
          child,

          // Etiquetas inferior
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: bottomLabels.length == 3
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  bottomLabels.first,
                  style: GoogleFonts.hankenGrotesk(
                      fontSize: 12, color: const Color(0xFF9A978C)),
                ),
                if (bottomLabels.length == 3)
                  Text(
                    bottomLabels[1],
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 12, color: const Color(0xFF9A978C)),
                  ),
                Text(
                  bottomLabels.last,
                  style: GoogleFonts.hankenGrotesk(
                      fontSize: 12, color: const Color(0xFF9A978C)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
