import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assignum/activities/infrastructure/activity_service.dart';
import 'package:assignum/activities/domain/activity.dart';
import 'package:assignum/activities/presentation/activity_details_page.dart';

// ── Tokens ─────────────────────────────────────────────────────────────
const _bg           = Color(0xFFF4F2EA);
const _surface      = Color(0xFFFBFAF4);
const _surface2     = Color(0xFFFFFFFF);
const _surfaceInset = Color(0xFFF0EDE2);
const _text         = Color(0xFF21201B);
const _text2        = Color(0xFF6E6B61);
const _text3        = Color(0xFF9A978C);
const _border       = Color(0xFFE7E2D5);
const _primary      = Color(0xFFDC2F26);
const _primaryTint  = Color(0xFFFAE7E2);

const _avatarPalette = [
  Color(0xFF5C7B97), Color(0xFF7B6B9A), Color(0xFF4A8A8A),
  Color(0xFFB26B36), Color(0xFF6C8A57), Color(0xFFDC2F26),
];

class InviteMembersPage extends StatefulWidget {
  final Activity activity;
  const InviteMembersPage({super.key, required this.activity});

  @override
  State<InviteMembersPage> createState() => _InviteMembersPageState();
}

class _InviteMembersPageState extends State<InviteMembersPage> {
  final _emailCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final List<String> _emails = [];
  bool _saving = false;
  bool _emailValid = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(() {
      final valid = _isValidEmail(_emailCtrl.text.trim());
      if (valid != _emailValid) setState(() => _emailValid = valid);
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  bool _isValidEmail(String v) =>
      v.contains('@') && v.contains('.') && v.length > 5;

  String _initials(String email) {
    final parts = email.split('@').first.split('.');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return email.substring(0, email.length >= 2 ? 2 : 1).toUpperCase();
  }

  Color _avatarColor(String email) =>
      _avatarPalette[email.codeUnitAt(0) % _avatarPalette.length];

  void _addEmail() {
    final text = _emailCtrl.text.trim();
    if (!_isValidEmail(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un correo electrónico válido')));
      return;
    }
    if (!_emails.contains(text)) {
      setState(() {
        _emails.add(text);
        _emailCtrl.clear();
        _emailValid = false;
      });
    } else {
      _emailCtrl.clear();
    }
  }

  void _removeEmail(int i) => setState(() => _emails.removeAt(i));

  // ── Submit ───────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_emails.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ActivityDetailsPage(
              activity: widget.activity, isCreationFlow: true),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ActivityService().inviteMembers(widget.activity.id, _emails);
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          backgroundColor: _surface2,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: _primaryTint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(Icons.mark_email_read_outlined,
                      color: _primary, size: 30),
                ),
                const SizedBox(height: 16),
                Text('Invitaciones enviadas',
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: _text)),
                const SizedBox(height: 8),
                Text('${_emails.length} compañero${_emails.length == 1 ? '' : 's'} han sido invitados.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 14, color: _text2)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final updated = await ActivityService()
                          .getActivity(widget.activity.id);
                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ActivityDetailsPage(
                              activity: updated ?? widget.activity,
                              isCreationFlow: true,
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999)),
                      elevation: 0,
                    ),
                    child: Text('Continuar',
                        style: GoogleFonts.hankenGrotesk(
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        top: false,
        child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Email input
                  _buildEmailInput(),
                  const SizedBox(height: 10),
                  // Añadir button
                  GestureDetector(
                    onTap: _emailValid ? _addEmail : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _emailValid ? _primaryTint : _surfaceInset,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add,
                              size: 16,
                              color: _emailValid ? _primary : _text3),
                          const SizedBox(width: 6),
                          Text('Añadir a la invitación',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _emailValid ? _primary : _text3,
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // List
                  if (_emails.isNotEmpty) ...[
                    Text(
                      'POR INVITAR · ${_emails.length}',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: _text3, letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._emails.asMap().entries.map((e) => _EmailTile(
                          email: e.value,
                          initials: _initials(e.value),
                          color: _avatarColor(e.value),
                          onRemove: () => _removeEmail(e.key),
                        )),
                  ] else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text('Añade correos para invitar miembros.',
                            style: GoogleFonts.hankenGrotesk(
                                fontSize: 13, color: _text3)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A2723), Color(0xFF46413A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Color(0xFFF6F3EA), size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invitar miembros',
                        style: GoogleFonts.hankenGrotesk(
                          color: const Color(0xFFF6F3EA),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        )),
                    Text(widget.activity.name,
                        style: GoogleFonts.hankenGrotesk(
                          color: const Color(0xFFF6F3EA).withValues(alpha: 0.6),
                          fontSize: 12.5,
                        ),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Email input ──────────────────────────────────────────────────────

  Widget _buildEmailInput() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _emailValid ? _primary : _border,
          width: _emailValid ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Icon(Icons.email_outlined, size: 18, color: _text3),
          ),
          Expanded(
            child: TextField(
              controller: _emailCtrl,
              focusNode: _focusNode,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.hankenGrotesk(fontSize: 14, color: _text),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 14),
                hintText: 'correo@ejemplo.com',
                hintStyle: GoogleFonts.hankenGrotesk(
                    fontSize: 14, color: _text3),
              ),
              onSubmitted: (_) => _addEmail(),
            ),
          ),
          if (_emailValid)
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: Icon(Icons.check_rounded,
                  size: 18, color: Color(0xFF6C8A57)),
            ),
        ],
      ),
    );
  }

  // ── Bottom bar ───────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final count = _emails.length;
    final label = count == 0
        ? 'Continuar sin invitar'
        : 'Enviar $count invitación${count == 1 ? '' : 'es'}';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        color: _bg, border: Border(top: BorderSide(color: _border))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: _saving ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: count > 0 ? _primary : _surfaceInset,
              foregroundColor: count > 0 ? Colors.white : _text3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999)),
              elevation: 0,
            ),
            child: _saving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(label,
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}

// ── Email tile ─────────────────────────────────────────────────────────

class _EmailTile extends StatelessWidget {
  final String email;
  final String initials;
  final Color color;
  final VoidCallback onRemove;

  const _EmailTile({
    required this.email,
    required this.initials,
    required this.color,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFAF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E2D5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color,
            child: Text(initials,
                style: GoogleFonts.hankenGrotesk(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(email,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF21201B),
                ),
                overflow: TextOverflow.ellipsis),
          ),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: 18, color: Color(0xFF9A978C)),
          ),
        ],
      ),
    );
  }
}
