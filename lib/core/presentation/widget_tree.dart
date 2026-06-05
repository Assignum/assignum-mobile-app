import 'package:flutter/material.dart';
import 'package:assignum/core/infrastructure/auth_session.dart';
import 'package:assignum/iam/presentation/welcome_page.dart';
import 'package:assignum/core/presentation/home_page.dart';
import 'package:assignum/iam/infrastructure/user_service.dart';
import 'package:assignum/iam/presentation/about_you_page.dart';

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: AuthSession().authStateChanges,
      initialData: AuthSession().isLoggedIn,
      builder: (context, snapshot) {
        final loggedIn = snapshot.data ?? false;

        if (!loggedIn) return const WelcomePage();

        return FutureBuilder<bool>(
          future: UserService().profileExists(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.data == true) {
              return const HomePage();
            } else {
              return const AboutYouPage(cameFromRegister: false);
            }
          },
        );
      },
    );
  }
}
