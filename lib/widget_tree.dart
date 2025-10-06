import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:assignum/auth.dart';
import 'package:assignum/pages/welcome_page.dart';
import 'package:assignum/pages/home_page.dart';
import 'package:assignum/services/user_service.dart';
import 'package:assignum/pages/about_you_page.dart';

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: Auth().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) return const WelcomePage();

        // Verifica si ya completó su perfil
        return FutureBuilder<bool>(
          future: UserService().profileExists(user.uid),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.data == true) {
              return HomePage();
            } else {
              // Si no existe perfil, forzamos completar "Háblanos de ti".
              return const AboutYouPage(
                fullName: '',
                birthDate: null,
                cameFromRegister: false,
              );
            }
          },
        );
      },
    );
  }
}
