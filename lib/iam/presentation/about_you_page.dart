import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assignum/iam/infrastructure/user_service.dart';
import 'package:assignum/iam/domain/user_profile.dart';
import 'package:assignum/core/infrastructure/auth_session.dart';

// ── Tokens ─────────────────────────────────────────────────────────────
const _bg          = Color(0xFFF4F2EA);
const _surface     = Color(0xFFFBFAF4);
const _surfaceIn   = Color(0xFFF0EDE2);
const _text        = Color(0xFF21201B);
const _text2       = Color(0xFF6E6B61);
const _text3       = Color(0xFF9A978C);
const _border      = Color(0xFFE7E2D5);
const _primary     = Color(0xFFDC2F26);

const _roles = [
  'Backend', 'Frontend', 'Testing',
  'Database', 'Documentation', 'Management',
];

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
  final _nameCtrl   = TextEditingController();
  DateTime? _birthDate;
  bool _saving = false;

  // ── Competencias Técnicas ──
  double _backend      = 3;
  double _frontend     = 3;
  double _database     = 3;
  double _testing      = 3;
  double _docs         = 3;
  double _git          = 3;
  double _agile        = 3;

  // ── Competencias Colaborativas ──
  double _teamwork     = 3;
  double _communication= 3;
  double _leadership   = 3;
  double _organization = 3;

  // ── Experiencia y Disponibilidad ──
  double _projects     = 0;
  double _hours        = 10;
  String _lastRole     = 'Frontend';
  double _lastRolePerf = 3;
  double _peerEval     = 3;

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

  // ── Date picker ─────────────────────────────────────────────────────

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1970),
      lastDate: DateTime(now.year - 10),
      initialDate: _birthDate ?? DateTime(2000),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  String _formatDate(DateTime d) {
    const m = ['ene','feb','mar','abr','may','jun',
                'jul','ago','sep','oct','nov','dic'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  // ── Save ────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_saving) return;
    if (_nameCtrl.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu nombre completo')));
      return;
    }
    setState(() => _saving = true);

    final profile = UserProfile(
      uid: AuthSession().uid ?? '',
      fullName: _nameCtrl.text.trim(),
      birthDate: _birthDate,
      backendSkill:            _backend.round(),
      frontendSkill:           _frontend.round(),
      databaseSkill:           _database.round(),
      testingSkill:            _testing.round(),
      documentationSkill:      _docs.round(),
      gitGithubSkill:          _git.round(),
      agileMethodologiesSkill: _agile.round(),
      teamworkSkill:           _teamwork.round(),
      communicationSkill:      _communication.round(),
      leadershipSkill:         _leadership.round(),
      organizationSkill:       _organization.round(),
      projectsCompleted:       _projects.round(),
      availableHoursPerWeek:   _hours.round(),
      lastRole:                _lastRole,
      lastRolePerformance:     _lastRolePerf.round(),
      peerEvaluation:          _peerEval.round(),
    );

    await _userService.createOrUpdateProfile(profile);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: _text),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  if (widget.cameFromRegister)
                    Text('Paso 2 de 2',
                        style: GoogleFonts.hankenGrotesk(
                            fontSize: 14, fontWeight: FontWeight.w500,
                            color: _text2)),
                ],
              ),
            ),
            if (widget.cameFromRegister) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: const LinearProgressIndicator(
                    value: 1.0,
                    minHeight: 5,
                    backgroundColor: _border,
                    valueColor: AlwaysStoppedAnimation(_primary),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CUÉNTANOS SOBRE TI',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        letterSpacing: 1.6, color: _text3)),
                  const SizedBox(height: 8),
                  Text('Así te asignamos\nlas tareas ideales',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 26, fontWeight: FontWeight.w700,
                        color: _text, height: 1.2)),
                  const SizedBox(height: 6),
                  Text('Ajusta cada control según tu realidad.',
                      style: GoogleFonts.hankenGrotesk(
                          fontSize: 14.5, height: 1.5, color: _text2)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Scrollable form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Datos personales ───────────────────────────────
                    _sectionLabel('DATOS PERSONALES'),
                    _card(children: [
                      _inputField(
                        label: 'Nombre completo',
                        icon: Icons.person_outline_rounded,
                        controller: _nameCtrl,
                        hint: 'Juan Pérez',
                      ),
                      _divider(),
                      _dateField(),
                    ]),

                    const SizedBox(height: 20),

                    // ── Competencias Técnicas ──────────────────────────
                    _sectionLabel('COMPETENCIAS TÉCNICAS'),
                    _card(children: [
                      _skill('Desarrollo Backend',        Icons.dns_outlined,           _backend,       (v) => setState(() => _backend = v)),
                      _divider(),
                      _skill('Desarrollo Frontend',       Icons.web_outlined,           _frontend,      (v) => setState(() => _frontend = v)),
                      _divider(),
                      _skill('Bases de Datos',            Icons.storage_outlined,       _database,      (v) => setState(() => _database = v)),
                      _divider(),
                      _skill('Testing / QA',              Icons.bug_report_outlined,    _testing,       (v) => setState(() => _testing = v)),
                      _divider(),
                      _skill('Documentación técnica',     Icons.description_outlined,   _docs,          (v) => setState(() => _docs = v)),
                      _divider(),
                      _skill('Git / Control de versiones',Icons.merge_outlined,         _git,           (v) => setState(() => _git = v)),
                      _divider(),
                      _skill('Metodologías Ágiles',       Icons.loop_outlined,          _agile,         (v) => setState(() => _agile = v), isLast: true),
                    ]),

                    const SizedBox(height: 20),

                    // ── Competencias Colaborativas ─────────────────────
                    _sectionLabel('COMPETENCIAS COLABORATIVAS'),
                    _card(children: [
                      _skill('Trabajo en equipo',         Icons.groups_2_outlined,            _teamwork,     (v) => setState(() => _teamwork = v)),
                      _divider(),
                      _skill('Comunicación',              Icons.chat_bubble_outline_rounded,  _communication,(v) => setState(() => _communication = v)),
                      _divider(),
                      _skill('Liderazgo',                 Icons.star_outline_rounded,         _leadership,   (v) => setState(() => _leadership = v)),
                      _divider(),
                      _skill('Organización y planificación', Icons.calendar_today_outlined,  _organization, (v) => setState(() => _organization = v), isLast: true),
                    ]),

                    const SizedBox(height: 20),

                    // ── Experiencia y Disponibilidad ───────────────────
                    _sectionLabel('EXPERIENCIA Y DISPONIBILIDAD'),
                    _card(children: [
                      _numSlider(
                        label: 'Proyectos completados',
                        icon: Icons.folder_copy_outlined,
                        value: _projects,
                        display: '${_projects.round()}',
                        min: 0, max: 50, divisions: 50,
                        onChanged: (v) => setState(() => _projects = v),
                        bottomLabels: const ['0', '50'],
                      ),
                      _divider(),
                      _numSlider(
                        label: 'Horas disponibles / semana',
                        icon: Icons.schedule_outlined,
                        value: _hours,
                        display: '${_hours.round()} h',
                        min: 1, max: 40, divisions: 39,
                        onChanged: (v) => setState(() => _hours = v),
                        bottomLabels: const ['1 h', '40 h'],
                      ),
                      _divider(),
                      _dropdownRow(),
                      _divider(),
                      _skill('Desempeño en ese rol (autoevaluación)',
                          Icons.emoji_events_outlined,
                          _lastRolePerf, (v) => setState(() => _lastRolePerf = v)),
                      _divider(),
                      _skill('Evaluación promedio de compañeros',
                          Icons.people_outline_rounded,
                          _peerEval, (v) => setState(() => _peerEval = v),
                          isLast: true),
                    ]),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
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
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text('Continuar',
                          style: GoogleFonts.hankenGrotesk(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── UI helpers ───────────────────────────────────────────────────────

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 11, fontWeight: FontWeight.w600,
              letterSpacing: 1.4, color: _text3)),
      );

  Widget _card({required List<Widget> children}) => Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3C321E).withValues(alpha: 0.06),
              blurRadius: 14, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(children: children),
      );

  Widget _divider() => const Divider(
      height: 1, thickness: 1, color: _border,
      indent: 20, endIndent: 20);

  Widget _inputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.hankenGrotesk(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _text2)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            style: GoogleFonts.hankenGrotesk(fontSize: 14, color: _text),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 18, color: _text3),
              filled: true,
              fillColor: _surfaceIn,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              hintText: hint,
              hintStyle: GoogleFonts.hankenGrotesk(
                  fontSize: 14, color: _text3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fecha de nacimiento',
              style: GoogleFonts.hankenGrotesk(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _text2)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickBirthDate,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _surfaceIn,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 18, color: _text3),
                  const SizedBox(width: 12),
                  Text(
                    _birthDate == null
                        ? 'Selecciona tu fecha de nacimiento'
                        : _formatDate(_birthDate!),
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      color: _birthDate == null ? _text3 : _text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skill(String label, IconData icon, double value,
      ValueChanged<double> onChanged, {bool isLast = false}) {
    return _SliderRow(
      icon: icon,
      label: label,
      display: '${value.round()}/5',
      min: 1, max: 5, divisions: 4,
      value: value,
      onChanged: onChanged,
      bottomLabels: const ['Sin conocimiento', 'Experto'],
      isLast: isLast,
    );
  }

  Widget _numSlider({
    required String label,
    required IconData icon,
    required double value,
    required String display,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required List<String> bottomLabels,
    bool isLast = false,
  }) {
    return _SliderRow(
      icon: icon,
      label: label,
      display: display,
      min: min, max: max, divisions: divisions,
      value: value,
      onChanged: onChanged,
      bottomLabels: bottomLabels,
      isLast: isLast,
    );
  }

  Widget _dropdownRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          const Icon(Icons.work_outline_rounded, size: 18, color: _primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Último rol desempeñado',
                style: GoogleFonts.hankenGrotesk(
                    fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _surfaceIn,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _lastRole,
                isDense: true,
                style: GoogleFonts.hankenGrotesk(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _text),
                items: _roles
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _lastRole = v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slider row ────────────────────────────────────────────────────────

class _SliderRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String display;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final List<String> bottomLabels;
  final bool isLast;

  const _SliderRow({
    required this.icon,
    required this.label,
    required this.display,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    required this.bottomLabels,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
              ),
              Text(display,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _primary)),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _primary,
              inactiveTrackColor: const Color(0xFFE7E2D5),
              thumbColor: Colors.white,
              overlayColor: _primary.withValues(alpha: 0.12),
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 4,
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: value,
              min: min, max: max, divisions: divisions,
              onChanged: onChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(bottomLabels.first,
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 11.5, color: _text3)),
                Text(bottomLabels.last,
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 11.5, color: _text3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
