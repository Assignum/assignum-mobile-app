import 'package:flutter/material.dart';
import 'package:assignum/core/infrastructure/auth_session.dart';
import 'package:assignum/iam/infrastructure/user_service.dart';
import 'package:assignum/iam/domain/user_profile.dart';
import 'package:assignum/iam/infrastructure/auth.dart';
import 'package:assignum/activities/infrastructure/activity_service.dart';
import 'package:assignum/activities/presentation/create_activity_page.dart';
import 'package:assignum/activities/presentation/activities_list_page.dart';
import 'package:assignum/core/presentation/notifications_page.dart';
import 'package:assignum/iam/presentation/profile_page.dart';
import 'package:assignum/chatbox/presentation/chatbox_page.dart';
import 'package:assignum/shared/presentation/theme/app_theme.dart';
import 'package:assignum/shared/presentation/widgets/premium_app_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final UserService _userService = UserService();
  final ActivityService _activityService = ActivityService();

  late Future<Map<String, int>> _statsFuture;

  late final AnimationController _animController;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnims = List.generate(4, (i) {
      final start = (i * 0.18).clamp(0.0, 1.0);
      final end = (start + 0.45).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Interval(start, end, curve: Curves.easeOut)),
      );
    });

    _slideAnims = List.generate(4, (i) {
      final start = (i * 0.18).clamp(0.0, 1.0);
      final end = (start + 0.45).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
        CurvedAnimation(parent: _animController, curve: Interval(start, end, curve: Curves.easeOut)),
      );
    });

    _animController.forward();
    _statsFuture = _activityService.getDashboardStats();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _getFirstName(String fullName) => fullName.trim().split(' ').first;

  Future<void> _signOut(BuildContext context) async {
    await Auth().signOut();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión cerrada')),
      );
    }
  }

  void _navigateTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page))
        .then((_) {
          if (mounted) {
            setState(() {
              _statsFuture = _activityService.getDashboardStats();
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: _userService.getProfileStream(),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final name = profile?.fullName ?? AuthSession().email ?? 'Usuario';
        final firstName = _getFirstName(name);
        final initials = name.trim().split(' ').map((e) => e[0].toUpperCase()).take(2).join();
        final email = AuthSession().email ?? '';

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: PremiumAppBar(titleText: 'Inicio', showProfileAvatar: true),
          drawer: _buildDrawer(context, name, initials, email),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _animated(0, _buildHeroHeader(firstName, initials)),
                  const SizedBox(height: 20),
                  _animated(1, _buildStatsRow()),
                  const SizedBox(height: 28),
                  _animated(2, const Text(
                    'Accesos rápidos',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.upcBlack, letterSpacing: 0.2),
                  )),
                  const SizedBox(height: 12),
                  _animated(3, Column(
                    children: [
                      _buildFeatureCard(
                        icon: Icons.task_alt_rounded,
                        title: 'Tus actividades',
                        subtitle: 'Revisa y gestiona tus tareas asignadas',
                        onTap: () => _navigateTo(const ActivitiesListPage()),
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureCard(
                        icon: Icons.add_circle_outline_rounded,
                        title: 'Crear actividad',
                        subtitle: 'Organiza una nueva actividad grupal',
                        onTap: () => _navigateTo(const CreateActivityPage()),
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureCard(
                        icon: Icons.smart_toy_rounded,
                        title: 'Chatbot de consultas',
                        subtitle: 'Asistente inteligente para ayudarte',
                        onTap: () => _navigateTo(const ChatboxPage()),
                      ),
                    ],
                  )),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _animated(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnims[index],
      child: SlideTransition(position: _slideAnims[index], child: child),
    );
  }

  Widget _buildHeroHeader(String firstName, String initials) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.upcBlack, Color(0xFF2C2C2C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.upcBlack.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getGreeting(), style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14, letterSpacing: 0.3)),
                const SizedBox(height: 4),
                Text(firstName, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
                const SizedBox(height: 10),
                Container(height: 3, width: 36, decoration: BoxDecoration(color: AppColors.upcRed, borderRadius: BorderRadius.circular(2))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.upcRed.withValues(alpha: 0.6), width: 2.5),
            ),
            child: CircleAvatar(
              radius: 38,
              backgroundColor: AppColors.upcRed,
              child: Text(initials.isNotEmpty ? initials : 'U', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return FutureBuilder<Map<String, int>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data;
        final isLoading = !snapshot.hasData;

        return Row(
          children: [
            _buildStatCard(icon: Icons.folder_rounded, label: 'Actividades', value: isLoading ? '·' : '${stats!['totalActivities']}', color: AppColors.upcRed),
            const SizedBox(width: 10),
            _buildStatCard(icon: Icons.pending_actions_rounded, label: 'Pendientes', value: isLoading ? '·' : '${stats!['pendingTasks']}', color: const Color(0xFFE65100)),
            const SizedBox(width: 10),
            _buildStatCard(icon: Icons.event_rounded, label: 'Próximas', value: isLoading ? '·' : '${stats!['upcomingActivities']}', color: const Color(0xFF1565C0)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({required IconData icon, required String label, required String value, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 18)),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.upcBlack)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.upcGray, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.upcRed.withValues(alpha: 0.07),
          highlightColor: AppColors.upcRed.withValues(alpha: 0.03),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Container(width: 50, height: 50, decoration: BoxDecoration(color: AppColors.upcRed, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: Colors.white, size: 24)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.upcBlack)),
                      const SizedBox(height: 3),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.upcGray)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.upcGray),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, String name, String initials, String email) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(30), bottomRight: Radius.circular(30))),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 48, bottom: 24, left: 24, right: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.upcBlack, Color(0xFF2C2C2C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.only(topRight: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(radius: 32, backgroundColor: AppColors.upcRed, child: Text(initials.isNotEmpty ? initials : 'U', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                    IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white70), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(email, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildDrawerItem(context: context, title: 'Inicio', icon: Icons.home_rounded, onTap: () => Navigator.pop(context)),
          _buildDrawerItem(context: context, title: 'Perfil', icon: Icons.person_rounded, onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())); }),
          _buildDrawerItem(context: context, title: 'Notificaciones', icon: Icons.notifications_rounded, onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())); }),
          const Spacer(),
          _buildDrawerItem(context: context, title: 'Cerrar Sesión', icon: Icons.logout_rounded, isDestructive: true, onTap: () { Navigator.pop(context); _signOut(context); }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({required BuildContext context, required String title, required IconData icon, required VoidCallback onTap, bool isDestructive = false}) {
    final color = isDestructive ? AppColors.upcRed : AppColors.upcBlack;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                Icon(icon, color: color.withValues(alpha: isDestructive ? 0.9 : 0.7), size: 22),
                const SizedBox(width: 16),
                Text(title, style: TextStyle(color: color, fontSize: 15, fontWeight: isDestructive ? FontWeight.w600 : FontWeight.w500)),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, color: isDestructive ? color.withValues(alpha: 0.5) : AppColors.upcGray.withValues(alpha: 0.3), size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
