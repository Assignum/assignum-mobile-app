import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assignum/core/infrastructure/auth_session.dart';
import 'package:assignum/iam/infrastructure/user_service.dart';
import 'package:assignum/iam/infrastructure/auth.dart';
import 'package:assignum/iam/domain/user_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _userService = UserService();
  final _nameCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  UserProfile? _profile;

  double _teamwork     = 3;
  double _communication= 3;
  double _leadership   = 3;
  double _organization = 3;
  double _hours        = 10;

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

  Future<void> _loadProfile() async {
    final p = await _userService.getProfile();
    if (!mounted) return;
    setState(() {
      _profile = p;
      _loading = false;
      if (p != null) {
        _nameCtrl.text = p.fullName;
        _teamwork      = p.teamworkSkill.toDouble().clamp(1, 5);
        _communication = p.communicationSkill.toDouble().clamp(1, 5);
        _leadership    = p.leadershipSkill.toDouble().clamp(1, 5);
        _organization  = p.organizationSkill.toDouble().clamp(1, 5);
        _hours         = p.availableHoursPerWeek.toDouble().clamp(1, 40);
      }
    });
  }

  Future<void> _saveChanges() async {
    if (_saving || _profile == null) return;
    if (_nameCtrl.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre debe tener al menos 3 caracteres')),
      );
      return;
    }
    setState(() => _saving = true);

    final updated = UserProfile(
      uid: _profile!.uid,
      fullName: _nameCtrl.text.trim(),
      birthDate: _profile!.birthDate,
      backendSkill:            _profile!.backendSkill,
      frontendSkill:           _profile!.frontendSkill,
      databaseSkill:           _profile!.databaseSkill,
      testingSkill:            _profile!.testingSkill,
      documentationSkill:      _profile!.documentationSkill,
      gitGithubSkill:          _profile!.gitGithubSkill,
      agileMethodologiesSkill: _profile!.agileMethodologiesSkill,
      teamworkSkill:           _teamwork.round(),
      communicationSkill:      _communication.round(),
      leadershipSkill:         _leadership.round(),
      organizationSkill:       _organization.round(),
      projectsCompleted:       _profile!.projectsCompleted,
      availableHoursPerWeek:   _hours.round(),
      lastRole:                _profile!.lastRole,
      lastRolePerformance:     _profile!.lastRolePerformance,
      peerEvaluation:          _profile!.peerEvaluation,
    );

    await _userService.createOrUpdateProfile(updated);
    if (!mounted) return;
    setState(() { _saving = false; _profile = updated; });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Perfil actualizado',
          style: GoogleFonts.hankenGrotesk(fontSize: 14),
        ),
        backgroundColor: const Color(0xFF6C8A57),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _logout() async {
    await Auth().signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F2EA),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFDC2F26))),
      );
    }

    final name = _profile?.fullName ?? AuthSession().email ?? 'Usuario';
    final email = AuthSession().email ?? '';
    final initials = _initials(name);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EA),
      body: Column(
        children: [
          // ── AppBar carbon ─────────────────────────────────────────────
          _ProfileAppBar(
            initials: initials,
            onBack: () => Navigator.pop(context),
            onLogout: _logout,
          ),

          // ── Scrollable content ────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + nombre
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2F26),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF21201B),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Nombre (editable)
                  _fieldLabel('Nombre'),
                  const SizedBox(height: 8),
                  _textField(
                    controller: _nameCtrl,
                    icon: Icons.person_outline_rounded,
                  ),

                  const SizedBox(height: 16),

                  // Correo (solo lectura)
                  _fieldLabel('Correo'),
                  const SizedBox(height: 8),
                  _readonlyField(
                    value: email,
                    icon: Icons.mail_outline_rounded,
                  ),

                  const SizedBox(height: 28),

                  // Sección preferencias
                  Text(
                    'PREFERENCIAS DE TRABAJO',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.6,
                      color: const Color(0xFF9A978C),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Card de sliders
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBFAF4),
                      borderRadius: BorderRadius.circular(22),
                      border:
                          Border.all(color: const Color(0xFFE7E2D5), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3C321E).withValues(alpha: 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _ProfileSliderRow(
                          icon: Icons.groups_2_outlined,
                          label: 'Trabajo en equipo',
                          displayValue: '${_teamwork.round()}/5',
                          bottomLabels: const ['Bajo', 'Alto'],
                          child: _slider(
                            value: _teamwork,
                            min: 1, max: 5, divisions: 4,
                            onChanged: (v) => setState(() => _teamwork = v),
                          ),
                        ),
                        _divider(),
                        _ProfileSliderRow(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'Comunicación',
                          displayValue: '${_communication.round()}/5',
                          bottomLabels: const ['Bajo', 'Alto'],
                          child: _slider(
                            value: _communication,
                            min: 1, max: 5, divisions: 4,
                            onChanged: (v) => setState(() => _communication = v),
                          ),
                        ),
                        _divider(),
                        _ProfileSliderRow(
                          icon: Icons.star_outline_rounded,
                          label: 'Liderazgo',
                          displayValue: '${_leadership.round()}/5',
                          bottomLabels: const ['Bajo', 'Alto'],
                          child: _slider(
                            value: _leadership,
                            min: 1, max: 5, divisions: 4,
                            onChanged: (v) => setState(() => _leadership = v),
                          ),
                        ),
                        _divider(),
                        _ProfileSliderRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Organización',
                          displayValue: '${_organization.round()}/5',
                          bottomLabels: const ['Bajo', 'Alto'],
                          child: _slider(
                            value: _organization,
                            min: 1, max: 5, divisions: 4,
                            onChanged: (v) => setState(() => _organization = v),
                          ),
                        ),
                        _divider(),
                        _ProfileSliderRow(
                          icon: Icons.schedule_outlined,
                          label: 'Horas disponibles / semana',
                          displayValue: '${_hours.round()} h',
                          bottomLabels: const ['1 h', '40 h'],
                          isLast: true,
                          child: _slider(
                            value: _hours,
                            min: 1, max: 40, divisions: 39,
                            onChanged: (v) => setState(() => _hours = v),
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

          // ── Botón guardar ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveChanges,
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
                  _saving ? 'Guardando...' : 'Aceptar cambios',
                  style: GoogleFonts.hankenGrotesk(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers de UI ──────────────────────────────────────────────────────────

  Widget _fieldLabel(String text) => Text(
        text,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF21201B),
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style:
          GoogleFonts.hankenGrotesk(fontSize: 15, color: const Color(0xFF21201B)),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF9A978C)),
        filled: true,
        fillColor: const Color(0xFFFBFAF4),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE7E2D5), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE7E2D5), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDC2F26), width: 1.5),
        ),
      ),
    );
  }

  Widget _readonlyField({required String value, required IconData icon}) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EDE2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E2D5), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF9A978C)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.hankenGrotesk(
                  fontSize: 15, color: const Color(0xFF6E6B61)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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

  Widget _slider({
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
}

// ── AppBar personalizado ──────────────────────────────────────────────────────

class _ProfileAppBar extends StatelessWidget {
  final String initials;
  final VoidCallback onBack;
  final VoidCallback onLogout;

  const _ProfileAppBar({
    required this.initials,
    required this.onBack,
    required this.onLogout,
  });

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
            child: Text(
              'Mi perfil',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          // Logout button
          GestureDetector(
            onTap: onLogout,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slider row ────────────────────────────────────────────────────────────────

class _ProfileSliderRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String displayValue;
  final List<String> bottomLabels;
  final bool isLast;
  final Widget child;

  const _ProfileSliderRow({
    required this.icon,
    required this.label,
    required this.displayValue,
    required this.bottomLabels,
    this.isLast = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          child,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(bottomLabels.first,
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 12, color: const Color(0xFF9A978C))),
                if (bottomLabels.length == 3)
                  Text(bottomLabels[1],
                      style: GoogleFonts.hankenGrotesk(
                          fontSize: 12, color: const Color(0xFF9A978C))),
                Text(bottomLabels.last,
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 12, color: const Color(0xFF9A978C))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
