import 'package:assignum/pages/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:assignum/auth.dart';
import 'package:assignum/widgets/ui.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final User? user = Auth().currentUser;

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
    final email = user?.email ?? 'Usuario';

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
              Text('Bienvenido, $email',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 24),
              CardContainer(
                child: Column(
                  children: [
                    PrimaryButton(
                      text: 'Tus actividades',
                      onPressed: () {},
                    ),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      text: 'Crear actividad',
                      onPressed: () {},
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
