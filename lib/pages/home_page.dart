import 'package:assignum/pages/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:assignum/services/user_service.dart';
import 'package:assignum/models/user_profile.dart';
import 'package:assignum/auth.dart';
import 'package:assignum/widgets/ui.dart';
import 'package:assignum/pages/create_activity_page.dart';
import 'package:assignum/pages/activities_list_page.dart';
import 'package:assignum/services/activity_service.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final User? user = Auth().currentUser;
  final UserService _userService = UserService();

  Future<void> signOut(BuildContext context) async {
    await Auth().signOut();
    Navigator.pop(WelcomePage() as BuildContext);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión cerrada')),

      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            onPressed: () => signOut(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Salir',

          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<UserProfile?>(
                future: user != null ? _userService.getProfile(user!.uid) : Future.value(null),
                builder: (context, snapshot) {
                  final name = snapshot.data?.fullName ?? user?.displayName ?? 'Usuario';
                  return Text('Bienvenido, $name',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ));
                },
              ),
              const SizedBox(height: 24),
              CardContainer(
                child: Column(
                  children: [
                    PrimaryButton(
                      text: 'Tus actividades',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ActivitiesListPage())
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      text: 'Crear actividad',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CreateActivityPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      text: 'Chatbot de consultas',
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
