import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assignum/core/infrastructure/auth_session.dart';
import 'package:assignum/iam/infrastructure/user_service.dart';
import 'package:assignum/iam/infrastructure/auth.dart';
import 'package:assignum/iam/domain/user_profile.dart';

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

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _userService = UserService();
  final _nameCtrl   = TextEditingController();

  bool _loading = true;
  bool _saving  = false;
  UserProfile? _profile;

  DateTime? _birthDate;

  // Competencias Técnicas
  double _backend  = 3, _frontend = 3, _database = 3, _testing  = 3;
  double _docs     = 3, _git      = 3, _agile    = 3;

  // Competencias Colaborativas
  double _teamwork = 3, _communication = 3, _leadership = 3, _organization = 3;

  // Experiencia y Disponibilidad
  double _projects    = 0;
  double _hours       = 10;
  String _lastRole    = 'Frontend';
  double _lastRolePerf= 3;
  double _peerEval    = 3;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Load ────────────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    final p = await _userService.getProfile();
    if (!mounted) return;
    setState(() {
      _profile = p;
      _loading = false;
      if (p != null) {
        _nameCtrl.text = p.fullName;
        _birthDate     = p.birthDate;
        _backend       = p.backendSkill.toDouble().clamp(1, 5);
        _frontend      = p.frontendSkill.toDouble().clamp(1, 5);
        _database      = p.databaseSkill.toDouble().clamp(1, 5);
        _testing       = p.testingSkill.toDouble().clamp(1, 5);
        _docs          = p.documentationSkill.toDouble().clamp(1, 5);
        _git           = p.gitGithubSkill.toDouble().clamp(1, 5);
        _agile         = p.agileMethodologiesSkill.toDouble().clamp(1, 5);
        _teamwork      = p.teamworkSkill.toDouble().clamp(1, 5);
        _communication = p.communicationSkill.toDouble().clamp(1, 5);
        _leadership    = p.leadershipSkill.toDouble().clamp(1, 5);
        _organization  = p.organizationSkill.toDouble().clamp(1, 5);
        _projects      = p.projectsCompleted.toDouble().clamp(0, 50);
        _hours         = p.availableHoursPerWeek.toDouble().clamp(1, 40);
        _lastRole      = p.lastRole;
        _lastRolePerf  = p.lastRolePerformance.toDouble().clamp(1, 5);
        _peerEval      = p.peerEvaluation.toDouble().clamp(1, 5);
      }
    });
  }

  // ── Save ────────────────────────────────────────────────────────────

  Future<void> _saveChanges() async {
    if (_saving || _profile == null) return;
    if (_nameCtrl.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre debe tener al menos 3 caracteres')));
      return;
    }
    setState(() => _saving = true);

    final updated = UserProfile(
      uid:                     _profile!.uid,
      fullName:                _nameCtrl.text.trim(),
      birthDate:               _birthDate,
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

    await _userService.createOrUpdateProfile(updated);
    if (!mounted) return;
    setState(() { _saving = false; _profile = updated; });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Perfil actualizado',
          style: GoogleFonts.hankenGrotesk(fontSize: 14)),
      backgroundColor: const Color(0xFF6C8A57),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _logout() async {
    await Auth().signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
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

  String _initials(String name) {
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    final name    = _profile?.fullName ?? AuthSession().email ?? 'Usuario';
    final email   = AuthSession().email ?? '';
    final initials = _initials(name);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        top: false,
        child: Column(
        children: [
          // Header
          _ProfileAppBar(
            initials: initials,
            onBack: () => Navigator.pop(context),
            onLogout: _logout,
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + nombre display
                  Row(
                    children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: _primary,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Text(initials,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 22, fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(name,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 20, fontWeight: FontWeight.w700,
                              color: _text)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Datos personales ───────────────────────────────
                  _sectionLabel('DATOS PERSONALES'),
                  _card(children: [
                    _inputRow(
                      label: 'Nombre completo',
                      icon: Icons.person_outline_rounded,
                      child: TextField(
                        controller: _nameCtrl,
                        style: GoogleFonts.hankenGrotesk(
                            fontSize: 14, color: _text),
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDeco('Tu nombre completo'),
                      ),
                    ),
                    _divider(),
                    _inputRow(
                      label: 'Fecha de nacimiento',
                      icon: Icons.calendar_today_outlined,
                      child: GestureDetector(
                        onTap: _pickBirthDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            color: _surfaceIn,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _birthDate == null
                                ? 'Selecciona fecha'
                                : _formatDate(_birthDate!),
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 14,
                              color: _birthDate == null ? _text3 : _text,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _divider(),
                    _inputRow(
                      label: 'Correo',
                      icon: Icons.mail_outline_rounded,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: _surfaceIn,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(email,
                            style: GoogleFonts.hankenGrotesk(
                                fontSize: 14, color: _text2),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // ── Competencias Técnicas ──────────────────────────
                  _sectionLabel('COMPETENCIAS TÉCNICAS'),
                  _card(children: [
                    _skill('Desarrollo Backend',         Icons.dns_outlined,         _backend,  (v) => setState(() => _backend  = v)),
                    _divider(),
                    _skill('Desarrollo Frontend',        Icons.web_outlined,         _frontend, (v) => setState(() => _frontend = v)),
                    _divider(),
                    _skill('Bases de Datos',             Icons.storage_outlined,     _database, (v) => setState(() => _database = v)),
                    _divider(),
                    _skill('Testing / QA',               Icons.bug_report_outlined,  _testing,  (v) => setState(() => _testing  = v)),
                    _divider(),
                    _skill('Documentación técnica',      Icons.description_outlined, _docs,     (v) => setState(() => _docs     = v)),
                    _divider(),
                    _skill('Git / Control de versiones', Icons.merge_outlined,       _git,      (v) => setState(() => _git      = v)),
                    _divider(),
                    _skill('Metodologías Ágiles',        Icons.loop_outlined,        _agile,    (v) => setState(() => _agile    = v), isLast: true),
                  ]),

                  const SizedBox(height: 20),

                  // ── Competencias Colaborativas ─────────────────────
                  _sectionLabel('COMPETENCIAS COLABORATIVAS'),
                  _card(children: [
                    _skill('Trabajo en equipo',              Icons.groups_2_outlined,           _teamwork,     (v) => setState(() => _teamwork     = v)),
                    _divider(),
                    _skill('Comunicación',                   Icons.chat_bubble_outline_rounded, _communication,(v) => setState(() => _communication = v)),
                    _divider(),
                    _skill('Liderazgo',                      Icons.star_outline_rounded,        _leadership,   (v) => setState(() => _leadership   = v)),
                    _divider(),
                    _skill('Organización y planificación',   Icons.calendar_today_outlined,     _organization, (v) => setState(() => _organization  = v), isLast: true),
                  ]),

                  const SizedBox(height: 20),

                  // ── Experiencia y Disponibilidad ───────────────────
                  _sectionLabel('EXPERIENCIA Y DISPONIBILIDAD'),
                  _card(children: [
                    _numSlider(
                      label: 'Proyectos completados',
                      icon: Icons.folder_copy_outlined,
                      value: _projects, display: '${_projects.round()}',
                      min: 0, max: 50, divisions: 50,
                      onChanged: (v) => setState(() => _projects = v),
                      bottomLabels: const ['0', '50'],
                    ),
                    _divider(),
                    _numSlider(
                      label: 'Horas disponibles / semana',
                      icon: Icons.schedule_outlined,
                      value: _hours, display: '${_hours.round()} h',
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

          // Botón guardar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveChanges,
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
                    : Text('Aceptar cambios',
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
      height: 1, thickness: 1, color: _border, indent: 20, endIndent: 20);

  InputDecoration _inputDeco(String hint) => InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: _surfaceIn,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        hintText: hint,
        hintStyle: GoogleFonts.hankenGrotesk(fontSize: 14, color: _text3),
      );

  Widget _inputRow({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _text3),
              const SizedBox(width: 8),
              Text(label,
                  style: GoogleFonts.hankenGrotesk(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _text2)),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _skill(String label, IconData icon, double value,
      ValueChanged<double> onChanged, {bool isLast = false}) {
    return _ProfileSliderRow(
      icon: icon, label: label, displayValue: '${value.round()}/5',
      bottomLabels: const ['Sin conocimiento', 'Experto'],
      isLast: isLast,
      child: _themedSlider(value: value, min: 1, max: 5, divisions: 4, onChanged: onChanged),
    );
  }

  Widget _numSlider({
    required String label, required IconData icon,
    required double value, required String display,
    required double min, required double max, required int divisions,
    required ValueChanged<double> onChanged, required List<String> bottomLabels,
    bool isLast = false,
  }) {
    return _ProfileSliderRow(
      icon: icon, label: label, displayValue: display,
      bottomLabels: bottomLabels, isLast: isLast,
      child: _themedSlider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
    );
  }

  Widget _themedSlider({
    required double value, required double min, required double max,
    required int divisions, required ValueChanged<double> onChanged,
  }) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: _primary,
        inactiveTrackColor: _border,
        thumbColor: Colors.white,
        overlayColor: _primary.withValues(alpha: 0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        trackHeight: 4,
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      ),
      child: Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
    );
  }

  Widget _dropdownRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                onChanged: (v) { if (v != null) setState(() => _lastRole = v); },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── AppBar ────────────────────────────────────────────────────────────

class _ProfileAppBar extends StatelessWidget {
  final String initials;
  final VoidCallback onBack;
  final VoidCallback onLogout;

  const _ProfileAppBar({
    required this.initials, required this.onBack, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(8, top + 8, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A2723), Color(0xFF46413A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: onBack,
          ),
          Expanded(
            child: Text('Mi perfil',
                style: GoogleFonts.hankenGrotesk(
                    fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          GestureDetector(
            onTap: onLogout,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slider row ────────────────────────────────────────────────────────

class _ProfileSliderRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String displayValue;
  final List<String> bottomLabels;
  final bool isLast;
  final Widget child;

  const _ProfileSliderRow({
    required this.icon, required this.label, required this.displayValue,
    required this.bottomLabels, this.isLast = false, required this.child,
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
              Icon(icon, size: 18, color: const Color(0xFFDC2F26)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF21201B))),
              ),
              Text(displayValue,
                  style: GoogleFonts.hankenGrotesk(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: const Color(0xFFDC2F26))),
            ],
          ),
          const SizedBox(height: 4),
          child,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(bottomLabels.first,
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 11.5, color: const Color(0xFF9A978C))),
                Text(bottomLabels.last,
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 11.5, color: const Color(0xFF9A978C))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
