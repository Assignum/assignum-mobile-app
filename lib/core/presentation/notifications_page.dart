import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assignum/activities/domain/inbox_item.dart';
import 'package:assignum/activities/infrastructure/activity_service.dart';
import 'package:assignum/activities/presentation/activity_details_page.dart';
import 'package:assignum/core/infrastructure/api_client.dart';

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
  List<InboxItem> _inbox = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _service.getPendingInvitations().then<Object?>((v) => v, onError: (_) => null),
      _service.getInbox().then<Object?>((v) => v, onError: (_) => null),
    ]);
    if (!mounted) return;
    final invitations = results[0] as List<Map<String, dynamic>>?;
    final inbox = results[1] as List<InboxItem>?;
    setState(() {
      if (invitations != null) _invitations = invitations;
      if (inbox != null) _inbox = inbox;
      _loading = false;
    });
    if (invitations == null || inbox == null) {
      _showError('No se pudieron cargar todas las notificaciones. Desliza para reintentar.');
    }
    // Se marcan como leídos al verlos; el punto de "nuevo" se mantiene en esta visita.
    if (inbox != null && inbox.any((i) => !i.read)) {
      _service.markInboxRead().catchError((_) {});
    }
  }

  bool _opening = false;

  Future<void> _openActivity(InboxItem item) async {
    // Evita abrir la actividad dos veces si se toca el aviso repetidamente
    if (item.activityId.isEmpty || _opening) return;
    _opening = true;
    try {
      final activity = await _service.getActivityFromFirestore(item.activityId);
      if (!mounted) return;
      if (activity == null) {
        _showError('Esta actividad ya no está disponible.');
        return;
      }
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => ActivityDetailsPage(activity: activity)));
    } finally {
      _opening = false;
    }
  }

  Future<void> _accept(String activityId) =>
      _respond(() => _service.acceptInvitation(activityId));

  Future<void> _decline(String activityId) =>
      _respond(() => _service.declineInvitation(activityId));

  Future<void> _respond(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } on ApiException catch (e) {
      // 404 / 400: la actividad fue eliminada o la invitación ya no está pendiente
      _showError(e.statusCode == 404 || e.statusCode == 400
          ? 'Esta invitación ya no está disponible.'
          : 'No se pudo procesar la invitación. Inténtalo de nuevo.');
    } catch (_) {
      _showError('No se pudo procesar la invitación. Revisa tu conexión e inténtalo de nuevo.');
    }
    await _load();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
    final unread = _inbox.where((i) => !i.read).length;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        top: false,
        child: Column(
        children: [
          _buildHeader(count, unread),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _primary))
                : RefreshIndicator(
                    color: _primary,
                    onRefresh: _load,
                    child: _invitations.isEmpty && _inbox.isEmpty
                        ? ListView(children: [
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.6,
                                child: _buildEmpty()),
                          ])
                        : _buildList(),
                  ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildHeader(int count, int unread) {
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
                  child: const Icon(Icons.arrow_back_rounded, semanticLabel: 'Volver',
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
                      [
                        if (count > 0)
                          '$count invitación${count == 1 ? '' : 'es'} pendiente${count == 1 ? '' : 's'}',
                        if (unread > 0) '$unread aviso${unread == 1 ? '' : 's'} nuevo${unread == 1 ? '' : 's'}',
                      ].join(' · ').ifEmpty('Todo al día'),
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
          Text('Sin notificaciones',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16, fontWeight: FontWeight.w600, color: _text2)),
          const SizedBox(height: 4),
          Text('No tienes invitaciones ni avisos.',
              style: GoogleFonts.hankenGrotesk(fontSize: 13, color: _text3)),
        ],
      ),
    );
  }

  Widget _buildList() {
    final children = <Widget>[];
    if (_invitations.isNotEmpty) {
      children.add(const _SectionTitle('INVITACIONES'));
      for (final inv in _invitations) {
        final activityId   = inv['activityId']   as String? ?? '';
        final activityName = inv['activityName'] as String? ?? 'Actividad';
        final leaderName   = inv['leaderName']   as String? ?? '';
        children.add(_InvitationCard(
          activityName: activityName,
          leaderName: leaderName,
          initials: _initials(activityName),
          avatarColor: _avatarColor(activityName),
          onAccept: () => _accept(activityId),
          onDecline: () => _decline(activityId),
        ));
      }
    }
    if (_inbox.isNotEmpty) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 8));
      children.add(const _SectionTitle('AVISOS'));
      children.addAll(_inbox.map((item) => _InboxCard(
            item: item,
            onTap: item.activityId.isEmpty ? null : () => _openActivity(item),
          )));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: children,
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: _text3, letterSpacing: 1.2,
            )),
      );
}

// ── Inbox card ─────────────────────────────────────────────────────────

class _InboxCard extends StatelessWidget {
  final InboxItem item;
  final VoidCallback? onTap;
  const _InboxCard({required this.item, this.onTap});

  (IconData, Color, Color) get _style => switch (item.type) {
        'invitation_accepted' => (Icons.person_add_alt_1_rounded, const Color(0xFFE7EFDC), const Color(0xFF6C8A57)),
        'invitation_declined' || 'invitation_cancelled' || 'member_removed' =>
          (Icons.person_off_outlined, const Color(0xFFF4E7D6), const Color(0xFFB26B36)),
        'task_assigned' => (Icons.assignment_ind_outlined, const Color(0xFFE4EAF1), const Color(0xFF5C7B97)),
        'task_unassigned' => (Icons.swap_horiz_rounded, const Color(0xFFF4E7D6), const Color(0xFFB26B36)),
        'task_delivered' => (Icons.upload_outlined, const Color(0xFFE4EAF1), const Color(0xFF5C7B97)),
        'due_reminder' || 'due_date_changed' => (Icons.alarm_rounded, const Color(0xFFFAE7E2), _primary),
        'member_left' => (Icons.person_off_outlined, const Color(0xFFF4E7D6), const Color(0xFFB26B36)),
        'leadership_transferred' => (Icons.workspace_premium_outlined, const Color(0xFFE7EFDC), const Color(0xFF6C8A57)),
        _ => (Icons.notifications_none_rounded, _surfaceInset, _text2),
      };

  String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'hace ${diff.inDays} d';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg) = _style;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: item.read ? _border : fg.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: fg, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.title,
                            style: GoogleFonts.hankenGrotesk(
                                fontSize: 14, fontWeight: FontWeight.w700, color: _text)),
                      ),
                      if (!item.read)
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(item.body,
                      style: GoogleFonts.hankenGrotesk(fontSize: 13, color: _text2, height: 1.35)),
                  const SizedBox(height: 4),
                  Text(_ago(item.createdAt),
                      style: GoogleFonts.hankenGrotesk(fontSize: 11.5, color: _text3)),
                ],
              ),
            ),
          ],
        ),
      ),
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
