import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assignum/activities/infrastructure/activity_service.dart';

// ── Tokens ─────────────────────────────────────────────────────────────
const _bg           = Color(0xFFF4F2EA);
const _surface      = Color(0xFFFBFAF4);
const _surfaceInset = Color(0xFFF0EDE2);
const _text         = Color(0xFF21201B);
const _text2        = Color(0xFF6E6B61);
const _text3        = Color(0xFF9A978C);
const _border       = Color(0xFFE7E2D5);
const _primary      = Color(0xFFDC2F26);

const _avatarPalette = [
  Color(0xFF5C7B97), Color(0xFF7B6B9A), Color(0xFF4A8A8A),
  Color(0xFFB26B36), Color(0xFF6C8A57), Color(0xFFDC2F26),
];

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _service = ActivityService();
  List<Map<String, dynamic>> _invitations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _service.getPendingInvitations();
    if (mounted) setState(() { _invitations = list; _loading = false; });
  }

  Future<void> _accept(String activityId) async {
    setState(() => _loading = true);
    await _service.acceptInvitation(activityId);
    await _load();
  }

  Future<void> _decline(String activityId) async {
    setState(() => _loading = true);
    await _service.declineInvitation(activityId);
    await _load();
  }

  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) return '${words[0][0]}${words[1][0]}'.toUpperCase();
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  Color _avatarColor(String name) =>
      _avatarPalette[name.codeUnitAt(0) % _avatarPalette.length];

  @override
  Widget build(BuildContext context) {
    final count = _invitations.length;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        top: false,
        child: Column(
        children: [
          _buildHeader(count),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _primary))
                : _invitations.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildHeader(int count) {
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
                    Text('Notificaciones',
                        style: GoogleFonts.hankenGrotesk(
                          color: const Color(0xFFF6F3EA),
                          fontSize: 17, fontWeight: FontWeight.w700,
                        )),
                    Text(
                      count == 0
                          ? 'Sin invitaciones pendientes'
                          : '$count invitación${count == 1 ? '' : 'es'} pendiente${count == 1 ? '' : 's'}',
                      style: GoogleFonts.hankenGrotesk(
                        color: const Color(0xFFF6F3EA).withValues(alpha: 0.6),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(Icons.check_rounded,
                    color: Color(0xFFF6F3EA), size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: _surfaceInset, borderRadius: BorderRadius.circular(999)),
            child: const Icon(Icons.notifications_none_rounded,
                size: 30, color: _text3),
          ),
          const SizedBox(height: 16),
          Text('Sin invitaciones',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16, fontWeight: FontWeight.w600, color: _text2)),
          const SizedBox(height: 4),
          Text('No tienes invitaciones pendientes.',
              style: GoogleFonts.hankenGrotesk(fontSize: 13, color: _text3)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      itemCount: _invitations.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('INVITACIONES',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: _text3, letterSpacing: 1.2,
                )),
          );
        }
        final inv          = _invitations[i - 1];
        final activityId   = inv['activityId']   as String? ?? '';
        final activityName = inv['activityName'] as String? ?? 'Actividad';
        final leaderName   = inv['leaderName']   as String? ?? '';

        return _InvitationCard(
          activityName: activityName,
          leaderName: leaderName,
          initials: _initials(activityName),
          avatarColor: _avatarColor(activityName),
          onAccept: () => _accept(activityId),
          onDecline: () => _decline(activityId),
        );
      },
    );
  }
}

// ── Invitation card ────────────────────────────────────────────────────

class _InvitationCard extends StatelessWidget {
  final String activityName;
  final String leaderName;
  final String initials;
  final Color avatarColor;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _InvitationCard({
    required this.activityName,
    required this.leaderName,
    required this.initials,
    required this.avatarColor,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final inviteText = leaderName.isNotEmpty
        ? '$leaderName te invitó a una actividad'
        : 'Te invitaron a una actividad';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3C321E).withValues(alpha: 0.07),
            blurRadius: 14, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Activity avatar
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: avatarColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(initials,
                    style: GoogleFonts.hankenGrotesk(
                      color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.w700,
                    )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inviteText,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13, color: _text2)),
                    const SizedBox(height: 3),
                    Text(activityName,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: _text, height: 1.25,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _text2,
                      side: BorderSide(color: _border, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999)),
                    ),
                    child: Text('Rechazar',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13.5, fontWeight: FontWeight.w600,
                          color: _text2,
                        )),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999)),
                      elevation: 0,
                    ),
                    child: Text('Aceptar',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13.5, fontWeight: FontWeight.w700,
                        )),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
