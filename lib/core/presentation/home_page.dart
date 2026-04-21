import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:assignum/auth/infrastructure/user_service.dart';
import 'package:assignum/auth/domain/user_profile.dart';
import 'package:assignum/auth/infrastructure/auth.dart';
import 'package:assignum/activities/presentation/create_activity_page.dart';
import 'package:assignum/activities/presentation/activities_list_page.dart';
import 'package:assignum/core/presentation/notifications_page.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final User? user = Auth().currentUser;
  final UserService _userService = UserService();

  Future<void> _signOut(BuildContext context) async {
    await Auth().signOut();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión cerrada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Inicio', style: TextStyle(color: Colors.white, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.grey[600],
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
               backgroundColor: Colors.grey[300],
               radius: 16,
            ),
          )
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.grey[300],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        elevation: 0,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 24.0, left: 24.0),
                child: Row(
                  children: [
                    const Icon(Icons.menu, size: 28),
                    const SizedBox(width: 16),
                    const Text('Menu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              _buildDrawerItem(title: 'Inicio', onTap: () {
                Navigator.pop(context);
              }),
              _buildDrawerItem(title: 'Perfil', onTap: () {
                Navigator.pop(context);
              }),
              _buildDrawerItem(title: 'Notificaciones', onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
              }),
              const Spacer(),
              _buildDrawerItem(title: 'Cerrar Sesion', onTap: () {
                Navigator.pop(context);
                _signOut(context);
              }),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FutureBuilder<UserProfile?>(
                  future: user != null ? _userService.getProfile(user!.uid) : Future.value(null),
                  builder: (context, snapshot) {
                    final name = snapshot.data?.fullName ?? user?.displayName ?? 'Usuario';
                    return Text('Bienvenido $name',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w500,
                        ));
                  },
                ),
                const SizedBox(height: 48),
                _buildMenuButton(
                  context: context,
                  text: 'Tus actividades',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ActivitiesListPage())
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuButton(
                  context: context,
                  text: 'Crear Actividad',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateActivityPage())
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuButton(
                  context: context,
                  text: 'Chatbot de consultas',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({required BuildContext context, required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE51D2A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
        ),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildDrawerItem({required String title, required VoidCallback onTap}) {
    return Container(
      color: Colors.grey[400],
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
