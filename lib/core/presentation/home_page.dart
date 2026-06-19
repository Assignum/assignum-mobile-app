import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assignum/core/infrastructure/auth_session.dart';
import 'package:assignum/iam/infrastructure/user_service.dart';
import 'package:assignum/iam/domain/user_profile.dart';
import 'package:assignum/iam/infrastructure/auth.dart';
import 'package:assignum/activities/infrastructure/activity_service.dart';
import 'package:assignum/activities/domain/activity.dart';
import 'package:assignum/activities/presentation/create_activity_page.dart';
import 'package:assignum/activities/presentation/activities_list_page.dart';
import 'package:assignum/core/presentation/notifications_page.dart';
import 'package:assignum/iam/presentation/profile_page.dart';
import 'package:assignum/chatbox/presentation/chatbox_page.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _bg        = Color(0xFFF4F2EA);
const _surface   = Color(0xFFFBFAF4);
const _red       = Color(0xFFDC2F26);
const _textMain  = Color(0xFF21201B);
const _textSub   = Color(0xFF6E6B61);
const _textMuted = Color(0xFF9A978C);
const _border    = Color(0xFFE7E2D5);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _userService = UserService();
  final _activityService = ActivityService();
  int _pendingInvitations = 0;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
    try {
      final list = await _activityService.getPendingInvitations();
      if (mounted) setState(() => _pendingInvitations = list.length);
    } catch (_) {
      // No interrumpir el home si falla la carga de invitaciones
    }
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días,';
    if (h < 18) return 'Buenas tardes,';
    return 'Buenas noches,';
  }

  String _firstName(String full) => full.trim().split(' ').first;

  String _initials(String full) {
    final parts = full.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  void _go(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: _userService.getProfileStream(),
      builder: (context, profileSnap) {
        final profile = profileSnap.data;
        final name = profile?.fullName ?? AuthSession().email ?? 'Usuario';
        final initials = _initials(name);

        return StreamBuilder<List<Activity>>(
          stream: _activityService.getActivitiesStream(),
          builder: (context, activitiesSnap) {
            final activities = activitiesSnap.data ?? [];
            final email = AuthSession().email ?? '';

            final activeActivities =
                activities.where((a) => !a.finalized).toList();

            final myTasks = activities
                .expand((a) => a.tasks)
                .where((t) => t.assignedToEmail == email)
                .toList();

            final completedTasks =
                myTasks.where((t) => t.status == 'Verificado').length;
            final pendingTasks = myTasks
                .where((t) =>
                    t.status == 'Pendiente' || t.status == 'En Progreso')
                .length;
            final totalTasks = myTasks.length;
            final progress =
                totalTasks > 0 ? completedTasks / totalTasks : 0.0;

            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: _bg,
              drawer: _buildDrawer(name, initials),
              // ── Body: fixed layout, no scroll ──────────────────────────────
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // AppBar
                  _HomeAppBar(
                    greeting: _getGreeting(),
                    firstName: _firstName(name),
                    initials: initials,
                    onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                    onNotificationTap: () async {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const NotificationsPage()));
                      _loadInvitations();
                    },
                    onAvatarTap: () => _go(const ProfilePage()),
                    hasPendingNotifications: _pendingInvitations > 0,
                  ),

                  // Progress card
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: _ProgressCard(
                      progress: progress,
                      completedTasks: completedTasks,
                      totalTasks: totalTasks,
                      pendingCount: pendingTasks,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Stat cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.folder_open_rounded,
                            iconBg: const Color(0xFFDDE8F5),
                            iconColor: const Color(0xFF4A7FB5),
                            value: '${activeActivities.length}',
                            label: 'Actividades\nactivas',
                            onTap: () => _go(const ActivitiesListPage()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.notifications_outlined,
                            iconBg: const Color(0xFFDDF0E4),
                            iconColor: const Color(0xFF4A8C6A),
                            value: '$_pendingInvitations',
                            label: 'Notificaciones',
                            onTap: () => _go(const NotificationsPage()),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'ACCESOS RÁPIDOS',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.6,
                        color: _textMuted,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Quick cards
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: SizedBox(
                      height: 140,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _QuickCard(
                              icon: Icons.task_alt_rounded,
                              iconBg: const Color(0xFFDDE8F5),
                              iconColor: const Color(0xFF4A7FB5),
                              label: 'Mis actividades',
                              onTap: () => _go(const ActivitiesListPage()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickCard(
                              icon: Icons.add_rounded,
                              iconBg: const Color(0xFFFAE7E2),
                              iconColor: _red,
                              label: 'Crear actividad',
                              onTap: () => _go(const CreateActivityPage()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickCard(
                              icon: Icons.chat_bubble_outline_rounded,
                              iconBg: const Color(0xFFEDE8DC),
                              iconColor: const Color(0xFF8B7355),
                              label: 'Asistente IA',
                              onTap: () => _go(const ChatboxPage()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDrawer(String name, String initials) {
    final email = AuthSession().email ?? '';
    return Drawer(
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.only(
                top: 56, bottom: 24, left: 24, right: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2A2723), Color(0xFF46413A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  BorderRadius.only(topRight: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.hankenGrotesk(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(name,
                    style: GoogleFonts.hankenGrotesk(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(email,
                    style: GoogleFonts.hankenGrotesk(
                        color: Colors.white60, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _drawerItem(
            icon: Icons.home_rounded,
            label: 'Inicio',
            onTap: () => Navigator.pop(context),
          ),
          _drawerItem(
            icon: Icons.person_rounded,
            label: 'Perfil',
            onTap: () {
              Navigator.pop(context);
              _go(const ProfilePage());
            },
          ),
          _drawerItem(
            icon: Icons.notifications_rounded,
            label: 'Notificaciones',
            onTap: () {
              Navigator.pop(context);
              _go(const NotificationsPage());
            },
          ),
          const Spacer(),
          _drawerItem(
            icon: Icons.logout_rounded,
            label: 'Cerrar sesión',
            isDestructive: true,
            onTap: () async {
              Navigator.pop(context);
              await Auth().signOut();
            },
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? _red : _textMain;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
            child: Row(
              children: [
                Icon(icon, color: color.withValues(alpha: 0.8), size: 20),
                const SizedBox(width: 14),
                Text(label,
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 15,
                        fontWeight: isDestructive
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── AppBar ────────────────────────────────────────────────────────────────────

class _HomeAppBar extends StatelessWidget {
  final String greeting;
  final String firstName;
  final String initials;
  final VoidCallback onMenuTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onAvatarTap;
  final bool hasPendingNotifications;

  const _HomeAppBar({
    required this.greeting,
    required this.firstName,
    required this.initials,
    required this.onMenuTap,
    required this.onNotificationTap,
    required this.onAvatarTap,
    this.hasPendingNotifications = false,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 14, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A2723), Color(0xFF46413A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hamburger
          _AppBarBtn(icon: Icons.menu_rounded, onTap: onMenuTap),
          const SizedBox(width: 14),

          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        color: Colors.white60,
                        fontWeight: FontWeight.w400)),
                Row(
                  children: [
                    Text(firstName,
                        style: GoogleFonts.hankenGrotesk(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),

          // Bell
          _AppBarBtn(
            icon: Icons.notifications_outlined,
            onTap: onNotificationTap,
            badge: hasPendingNotifications,
          ),
          const SizedBox(width: 10),

          // Avatar
          GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(initials,
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBarBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  const _AppBarBtn(
      {required this.icon, required this.onTap, this.badge = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Center(child: Icon(icon, color: Colors.white, size: 20)),
            if (badge)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Progress card ─────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final double progress;
  final int completedTasks;
  final int totalTasks;
  final int pendingCount;

  const _ProgressCard({
    required this.progress,
    required this.completedTasks,
    required this.totalTasks,
    required this.pendingCount,
  });

  String get _headline {
    if (totalTasks == 0) return 'Sin tareas aún';
    if (progress >= 1.0) return '¡Todo completado!';
    if (progress >= 0.7) return 'Tu semana va bien';
    if (progress >= 0.4) return 'Vas por buen camino';
    return 'Empieza fuerte';
  }

  String get _subtitle {
    if (totalTasks == 0) return 'No tienes tareas asignadas aún.';
    return '$completedTasks de $totalTasks tareas completadas. ¡Sigue así!';
  }

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3C321E).withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Donut grande centrado
          SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: _DonutPainter(progress: progress),
              child: Center(
                child: Text(
                  '$pct%',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: _red,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Headline
          Text(
            _headline,
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _textMain,
            ),
          ),
          const SizedBox(height: 6),
          // Subtitle
          Text(
            _subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              height: 1.45,
              color: _textSub,
            ),
          ),
          if (pendingCount > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EDE2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule_rounded, size: 15, color: _textSub),
                  const SizedBox(width: 6),
                  Text(
                    '$pendingCount pendiente${pendingCount == 1 ? '' : 's'}',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _textSub,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double progress;
  _DonutPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 8;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    final trackPaint = Paint()
      ..color = _border
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, trackPaint);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = _red
          ..strokeWidth = 14
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress;
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border, width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3C321E).withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 14),
            Text(value,
                style: GoogleFonts.hankenGrotesk(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: _textMain)),
            const SizedBox(height: 3),
            Text(label,
                style: GoogleFonts.hankenGrotesk(
                    fontSize: 12, color: _textSub, height: 1.3)),
          ],
        ),
      ),
    );
  }
}

// ── Quick card ────────────────────────────────────────────────────────────────

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border, width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3C321E).withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textMain,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
