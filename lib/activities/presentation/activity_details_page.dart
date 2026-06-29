import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assignum/activities/domain/activity.dart';
import 'package:assignum/activities/domain/activity_task.dart';
import 'package:assignum/activities/domain/auth_facade.dart';
import 'package:assignum/activities/infrastructure/activity_service.dart';
import 'package:assignum/activities/presentation/task_details_page.dart';
import 'package:assignum/activities/presentation/member_task_page.dart';
import 'package:assignum/core/infrastructure/api_client.dart';

// ── Tokens de color ────────────────────────────────────────────────────
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
  Color(0xFFDC2F26), Color(0xFF5C7B97), Color(0xFFB26B36),
  Color(0xFF6C8A57), Color(0xFF7B6B9A), Color(0xFF4A8A8A),
];

class ActivityDetailsPage extends StatefulWidget {
  final Activity activity;
  final bool isCreationFlow;

  const ActivityDetailsPage({
    super.key,
    required this.activity,
    this.isCreationFlow = false,
  });

  @override
  State<ActivityDetailsPage> createState() => _ActivityDetailsPageState();
}

class _ActivityDetailsPageState extends State<ActivityDetailsPage> {
  late bool _showTasks;
  String _leaderName = 'Cargando...';
  late Activity _currentActivity;
  StreamSubscription<Activity?>? _activitySub;

  @override
  void initState() {
    super.initState();
    _currentActivity = widget.activity;
    _showTasks = !widget.isCreationFlow;
    _initLeaderName();
    _activitySub = ActivityService()
        .getActivityStreamById(widget.activity.id)
        .listen((updated) {
      if (updated != null && mounted) setState(() => _currentActivity = updated);
    });
  }

  @override
  void dispose() {
    _activitySub?.cancel();
    super.dispose();
  }

  void _initLeaderName() {
    // Always resolve the real name regardless of whether current user is leader
    if (_currentActivity.leaderName.isNotEmpty) {
      _leaderName = _currentActivity.leaderName;
      return;
    }
    ActivityService().getActivity(_currentActivity.id).then((a) {
      if (!mounted) return;
      setState(() => _leaderName =
          (a?.leaderName.isNotEmpty == true) ? a!.leaderName : 'Sin nombre');
    });
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  int _calculateProgress() {
    if (_currentActivity.tasks.isEmpty) return 0;
    return ((_currentActivity.tasks
                    .where((t) => t.status == 'Verificado')
                    .length /
                _currentActivity.tasks.length) *
            100)
        .toInt();
  }

  String get _activityStatus {
    if (_currentActivity.finalized) return 'Completada';
    if (_calculateProgress() > 0) return 'En curso';
    return 'Pendiente';
  }

  int get _memberCount => _currentActivity.acceptedEmails.length + 1;

  String _formatDate(DateTime d) {
    const months = ['ene','feb','mar','abr','may','jun',
                    'jul','ago','sep','oct','nov','dic'];
    return '${d.day} ${months[d.month - 1]}';
  }

  String _shortName(String name) {
    if (name.isEmpty) return 'Sin asignar';
    if (name.contains('@')) return name.split('@').first;
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0]} ${parts[1][0]}.';
    return parts.isNotEmpty ? parts[0] : name;
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    if (name.contains('@')) return name[0].toUpperCase();
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  // ── Finalize logic ──────────────────────────────────────────────────

  Future<void> _finalizeActivity(BuildContext context) async {
    final progress = _calculateProgress();
    if (progress == 100) {
      await _doFinalizeActivity(context);
      return;
    }
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _surface2,
        title: Text('¿Finalizar actividad?',
            style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700, color: _text)),
        content: Text(
            'La actividad está al $progress% de progreso. ¿Estás seguro?',
            style: GoogleFonts.hankenGrotesk(color: _text2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: GoogleFonts.hankenGrotesk(color: _text2, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _doFinalizeActivity(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              elevation: 0,
            ),
            child: Text('Finalizar',
                style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _doFinalizeActivity(BuildContext context) async {
    try {
      await ActivityService().finalizeActivity(_currentActivity.id);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: _surface2,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7EFDC),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(Icons.check_rounded, color: Color(0xFF6C8A57), size: 32),
              ),
              const SizedBox(height: 16),
              Text('Actividad finalizada',
                  style: GoogleFonts.hankenGrotesk(
                      fontSize: 18, fontWeight: FontWeight.w700, color: _text)),
              const SizedBox(height: 8),
              Text('"${_currentActivity.name}" ha sido marcada como finalizada.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(fontSize: 14, color: _text2)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    elevation: 0,
                  ),
                  child: Text('Aceptar',
                      style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAssignAnimation() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AssignAnimationDialog(
        assignFuture: ActivityService().assignTasks(_currentActivity.id),
      ),
    );
    if (!mounted) return;
    if (ok == true) {
      _showDivideSuccessDialog();
    } else if (ok == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al asignar tareas')),
      );
    }
  }

  void _showDivideSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: _surface2,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: _primaryTint, borderRadius: BorderRadius.circular(999)),
                child: const Icon(Icons.task_alt_rounded, color: _primary, size: 32),
              ),
              const SizedBox(height: 16),
              Text('Tareas divididas exitosamente',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(
                      fontSize: 18, fontWeight: FontWeight.w700, color: _text)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(ctx); setState(() => _showTasks = true); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    elevation: 0,
                  ),
                  child: Text('Ver tareas',
                      style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dark extended header ─────────────────────────────────────────────

  Widget _buildHeader() {
    final progress = _calculateProgress();
    final status = _activityStatus;

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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderIconBtn(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
              const SizedBox(height: 16),
              _HeaderStatusBadge(status: status),
              const SizedBox(height: 10),
              Text(
                _currentActivity.name,
                style: GoogleFonts.hankenGrotesk(
                  color: const Color(0xFFF6F3EA),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _MetaItem(icon: Icons.calendar_today_outlined, label: _formatDate(_currentActivity.dueDate)),
                  const SizedBox(width: 20),
                  _MetaItem(icon: Icons.people_outline_rounded, label: '$_memberCount miembros'),
                  const SizedBox(width: 20),
                  _MetaItem(icon: Icons.track_changes_rounded, label: '$progress%'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Members list ─────────────────────────────────────────────────────

  Widget _buildMembersList() {
    final isLeader = _currentActivity.uid == IAuthFacade.instance.currentUserId;
    final accepted = _currentActivity.acceptedEmails;
    final pending = _currentActivity.invitedEmails;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Leader
        _MemberTile(
          name: isLeader ? 'Tú' : _leaderName,
          isLeader: true,
          isPending: false,
          index: 0,
        ),
        const SizedBox(height: 8),
        // Accepted
        ...accepted.asMap().entries.map((e) {
          final email = e.value;
          final name = _currentActivity.memberNames[email] ??
              _currentActivity.memberNames[email.replaceAll('.', '_')] ??
              email;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MemberTile(
              name: name, isLeader: false, isPending: false, index: e.key + 1),
          );
        }),
        // Pending invites
        ...pending.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MemberTile(
                name: e.value,
                isLeader: false,
                isPending: true,
                index: accepted.length + e.key + 1,
              ),
            )),
        // Dividir tareas (only in creation flow)
        if (widget.isCreationFlow) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _currentActivity.tasks.isEmpty
                  ? null
                  : () => _showAssignAnimation(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _surfaceInset,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                elevation: 0,
              ),
              child: Text('Dividir tareas',
                  style: GoogleFonts.hankenGrotesk(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ],
    );
  }

  // ── Tasks list ───────────────────────────────────────────────────────

  Widget _buildTasksList() {
    final isLeader = _currentActivity.uid == IAuthFacade.instance.currentUserId;
    final currentUserEmail = IAuthFacade.instance.currentUserEmail;
    final tasks = _currentActivity.tasks;

    if (tasks.isEmpty) {
      return Center(
        child: Text('Sin tareas aún',
            style: GoogleFonts.hankenGrotesk(color: _text3, fontSize: 14)),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16),
      itemCount: tasks.length,
      itemBuilder: (ctx, i) {
        final task = tasks[i];
        final canTap = isLeader || task.assignedToEmail == currentUserEmail;

        String displayName;
        if (task.assignedToEmail.isEmpty) {
          displayName = 'Sin asignar';
        } else if (task.assignedToEmail == currentUserEmail) {
          // Leader name is already resolved in _leaderName (real name, not 'Tú')
          // For members, look up in memberNames
          final myName = isLeader
              ? _leaderName
              : _currentActivity.memberNames[task.assignedToEmail] ??
                  _currentActivity.memberNames[
                      task.assignedToEmail.replaceAll('.', '_')] ??
                  IAuthFacade.instance.currentUserDisplayName ??
                  task.assignedToEmail;
          displayName = isLeader ? '(Líder) $myName' : myName;
        } else if (_currentActivity.acceptedEmails.contains(task.assignedToEmail)) {
          displayName = _currentActivity.memberNames[task.assignedToEmail] ??
              _currentActivity.memberNames[task.assignedToEmail.replaceAll('.', '_')] ??
              task.assignedToEmail;
        } else if (_currentActivity.invitedEmails.contains(task.assignedToEmail)) {
          // Pending invite — show email
          displayName = task.assignedToEmail;
        } else {
          // Not a member nor pending — must be the leader
          displayName = '(Líder) $_leaderName';
        }

        final shortDisplay = displayName == 'Sin asignar' ||
                displayName.startsWith('(Líder)')
            ? displayName
            : _shortName(displayName);

        return _TaskCard(
          task: task,
          displayName: shortDisplay,
          avatarInitials: _initials(displayName),
          onTap: canTap
              ? () async {
                  if (isLeader) {
                    await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => TaskDetailsPage(
                          activity: _currentActivity, task: task, assigneeName: displayName),
                    ));
                  } else {
                    await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => MemberTaskPage(
                          activity: _currentActivity, task: task, assigneeName: displayName),
                    ));
                  }
                }
              : null,
        );
      },
    );
  }

  // ── Bottom finalize button ───────────────────────────────────────────

  Widget _buildFinalizeBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      color: _bg,
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: () => _finalizeActivity(context),
            icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
            label: Text('Finalizar actividad',
                style: GoogleFonts.hankenGrotesk(
                    fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLeader = _currentActivity.uid == IAuthFacade.instance.currentUserId;
    final showFinalize = isLeader && !_currentActivity.finalized && !widget.isCreationFlow;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        top: false,
        child: Column(
        children: [
          _buildHeader(),
          // Segmented control
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _SegmentedControl(
              showTasks: _showTasks,
              onSelect: (v) => setState(() => _showTasks = v),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _showTasks
                  ? _buildTasksList()
                  : SingleChildScrollView(
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom + 16),
                      child: _buildMembersList(),
                    ),
            ),
          ),
        ],
        ),
      ),
      bottomNavigationBar: showFinalize ? _buildFinalizeBar() : null,
    );
  }
}

// ── Subwidgets ─────────────────────────────────────────────────────────

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(icon, color: const Color(0xFFF6F3EA), size: 20),
        ),
      );
}

class _HeaderStatusBadge extends StatelessWidget {
  final String status;
  const _HeaderStatusBadge({required this.status});

  Color get _badgeBg => switch (status) {
        'En curso'   => const Color(0xFF3D1918),
        'Pendiente'  => const Color(0xFF3D2D1A),
        'Completada' => const Color(0xFF1D2B18),
        _            => const Color(0xFF2F2D27),
      };

  Color get _badgeText => switch (status) {
        'En curso'   => const Color(0xFFFF9B91),
        'Pendiente'  => const Color(0xFFE8A87C),
        'Completada' => const Color(0xFF9FCC7E),
        _            => const Color(0xFFA8A599),
      };

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: _badgeBg, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: _badgeText, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(status,
                style: GoogleFonts.hankenGrotesk(
                    fontSize: 12, fontWeight: FontWeight.w600, color: _badgeText)),
          ],
        ),
      );
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF9A8E7E)),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.hankenGrotesk(
                  fontSize: 13, color: const Color(0xFFBBB5A8))),
        ],
      );
}

class _SegmentedControl extends StatelessWidget {
  final bool showTasks;
  final ValueChanged<bool> onSelect;
  const _SegmentedControl({required this.showTasks, required this.onSelect});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _surfaceInset, borderRadius: BorderRadius.circular(999)),
        child: Row(
          children: [
            _Segment(label: 'Miembros', active: !showTasks, onTap: () => onSelect(false)),
            _Segment(label: 'Tareas',   active: showTasks,  onTap: () => onSelect(true)),
          ],
        ),
      );
}

class _Segment extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Segment({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? _surface2 : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              boxShadow: active
                  ? [BoxShadow(
                      color: const Color(0xFF3C321E).withValues(alpha: 0.08),
                      blurRadius: 8, offset: const Offset(0, 2))]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? _text : _text3,
                )),
          ),
        ),
      );
}

class _TaskCard extends StatelessWidget {
  final ActivityTask task;
  final String displayName;
  final String avatarInitials;
  final VoidCallback? onTap;

  const _TaskCard({
    required this.task,
    required this.displayName,
    required this.avatarInitials,
    required this.onTap,
  });

  bool get _isVerified => task.status == 'Verificado';

  Color get _avatarBg => switch (task.status) {
        'Verificado'  => const Color(0xFFE7EFDC),
        'Entregado'   => const Color(0xFFE4EAF1),
        'En Progreso' => const Color(0xFFFAE7E2),
        _             => const Color(0xFFF4E7D6),
      };

  Color get _avatarFg => switch (task.status) {
        'Verificado'  => const Color(0xFF6C8A57),
        'Entregado'   => const Color(0xFF5C7B97),
        'En Progreso' => const Color(0xFFDC2F26),
        _             => const Color(0xFFB26B36),
      };

  String get _badgeLabel => task.status;

  Color get _badgeBg => switch (task.status) {
        'Verificado'  => const Color(0xFFE7EFDC),
        'Entregado'   => const Color(0xFFE4EAF1),
        'En Progreso' => const Color(0xFFFAE7E2),
        _             => const Color(0xFFF4E7D6),
      };

  Color get _badgeText => switch (task.status) {
        'Verificado'  => const Color(0xFF6C8A57),
        'Entregado'   => const Color(0xFF5C7B97),
        'En Progreso' => const Color(0xFFDC2F26),
        _             => const Color(0xFFB26B36),
      };

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3C321E).withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon / avatar
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _avatarBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: _isVerified
                    ? Icon(Icons.check_rounded, color: _avatarFg, size: 22)
                    : Text(avatarInitials,
                        style: GoogleFonts.hankenGrotesk(
                            color: _avatarFg, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              // Task info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.name,
                        style: GoogleFonts.hankenGrotesk(
                            fontSize: 14.5, fontWeight: FontWeight.w700, color: _text),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 13, color: _text3),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(displayName,
                              style: GoogleFonts.hankenGrotesk(fontSize: 12.5, color: _text3),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _badgeBg, borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(color: _badgeText, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(_badgeLabel,
                        style: GoogleFonts.hankenGrotesk(
                            fontSize: 11.5, fontWeight: FontWeight.w600, color: _badgeText)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _MemberTile extends StatelessWidget {
  final String name;
  final bool isLeader;
  final bool isPending;
  final int index;
  const _MemberTile({
    required this.name,
    required this.isLeader,
    required this.isPending,
    required this.index,
  });

  String _initials() {
    if (name.contains('@')) return name[0].toUpperCase();
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final color = _avatarPalette[index % _avatarPalette.length];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color,
            child: Text(_initials(),
                style: GoogleFonts.hankenGrotesk(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name,
                style: GoogleFonts.hankenGrotesk(
                    fontSize: 14, fontWeight: FontWeight.w600, color: _text),
                overflow: TextOverflow.ellipsis),
          ),
          if (isLeader)
            _Pill(label: 'Líder', bg: _primaryTint, fg: _primary),
          if (isPending)
            _Pill(label: 'Pendiente', bg: const Color(0xFFF4E7D6), fg: const Color(0xFFB26B36)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Pill({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(label,
            style: GoogleFonts.hankenGrotesk(
                fontSize: 11.5, fontWeight: FontWeight.w600, color: fg)),
      );
}

// ── Assign animation dialog ────────────────────────────────────────────────────

class _AssignAnimationDialog extends StatefulWidget {
  final Future<void> assignFuture;
  const _AssignAnimationDialog({required this.assignFuture});

  @override
  State<_AssignAnimationDialog> createState() => _AssignAnimationDialogState();
}

class _AssignAnimationDialogState extends State<_AssignAnimationDialog>
    with SingleTickerProviderStateMixin {

  static const _steps = [
    ('Recopilando datos de los estudiantes...', Icons.people_outline_rounded),
    ('Analizando habilidades del equipo...', Icons.psychology_outlined),
    ('Identificando al mejor candidato...', Icons.manage_search_rounded),
    ('Asignando de manera equitativa...', Icons.auto_awesome_outlined),
    ('¡Todo listo!', Icons.check_circle_outline_rounded),
  ];

  int _step = 0;
  bool _apiDone = false;
  late AnimationController _spinCtrl;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startSteps();
    widget.assignFuture.then((_) {
      _apiDone = true;
      _tryFinish();
    }).catchError((_) {
      if (mounted) Navigator.of(context).pop(false);
    });
  }

  void _startSteps() {
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1300), (t) {
      if (!mounted) { t.cancel(); return; }
      // Pausar en el último paso animado hasta que la API termine
      if (_step >= _steps.length - 2) {
        t.cancel();
        _tryFinish();
        return;
      }
      setState(() => _step++);
    });
  }

  void _tryFinish() {
    if (!_apiDone || !mounted) return;
    setState(() => _step = _steps.length - 1);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _step == _steps.length - 1;
    final (label, icon) = _steps[_step];

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFAF4),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3C321E).withValues(alpha: 0.12),
              blurRadius: 32, offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Spinner / checkmark
            SizedBox(
              width: 80, height: 80,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: isDone
                    ? Container(
                        key: const ValueKey('done'),
                        width: 80, height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDDF0E4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Color(0xFF4A8C6A), size: 40),
                      )
                    : Stack(
                        key: const ValueKey('spin'),
                        alignment: Alignment.center,
                        children: [
                          RotationTransition(
                            turns: _spinCtrl,
                            child: CustomPaint(
                              size: const Size(80, 80),
                              painter: _ArcPainter(),
                            ),
                          ),
                          Container(
                            width: 56, height: 56,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFAE7E2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: _primary, size: 26),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 28),

            // Steps completados
            ...List.generate(_step, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_rounded,
                      size: 16, color: Color(0xFF4A8C6A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _steps[i].$1,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        color: const Color(0xFF9A978C),
                        decoration: TextDecoration.lineThrough,
                        decorationColor: const Color(0xFF9A978C),
                      ),
                    ),
                  ),
                ],
              ),
            )),

            // Paso actual
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Row(
                key: ValueKey(_step),
                children: [
                  if (!isDone) ...[
                    SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ] else ...[
                    const Icon(Icons.check_rounded,
                        size: 16, color: Color(0xFF4A8C6A)),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDone
                            ? const Color(0xFF4A8C6A)
                            : const Color(0xFF21201B),
                      ),
                    ),
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

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2 - 4);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [Color(0x00DC2F26), Color(0xFFDC2F26)],
      ).createShader(rect);
    canvas.drawArc(rect, 0, 5.5, false, paint);
  }

  @override
  bool shouldRepaint(_ArcPainter _) => false;
}
