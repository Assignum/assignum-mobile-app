import 'package:flutter/material.dart';
import 'package:assignum/core/infrastructure/auth_session.dart';
import 'package:assignum/core/infrastructure/api_client.dart';
import 'package:assignum/iam/infrastructure/auth.dart';
import 'package:assignum/iam/presentation/welcome_page.dart';
import 'package:assignum/core/presentation/home_page.dart';
import 'package:assignum/iam/infrastructure/user_service.dart';
import 'package:assignum/iam/presentation/about_you_page.dart';

// Result of profile check
enum _ProfileStatus { hasProfile, noProfile, networkError, authError }

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  Future<_ProfileStatus> _checkProfile() async {
    try {
      final exists = await UserService()
          .profileExists()
          .timeout(const Duration(seconds: 25));
      return exists ? _ProfileStatus.hasProfile : _ProfileStatus.noProfile;
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) return _ProfileStatus.authError;
      return _ProfileStatus.networkError;
    } catch (_) {
      return _ProfileStatus.networkError;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: AuthSession().authStateChanges,
      initialData: AuthSession().isLoggedIn,
      builder: (context, snapshot) {
        final loggedIn = snapshot.data ?? false;

        if (!loggedIn) return const WelcomePage();

        return FutureBuilder<_ProfileStatus>(
          future: _checkProfile(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Scaffold(
                backgroundColor: Color(0xFF1A1A1A),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFFE51D2A)),
                      SizedBox(height: 16),
                      Text('Conectando...', style: TextStyle(color: Colors.white54, fontSize: 14)),
                    ],
                  ),
                ),
              );
            }

            switch (snap.data!) {
              case _ProfileStatus.hasProfile:
                return const HomePage();
              case _ProfileStatus.noProfile:
                return const AboutYouPage(cameFromRegister: false);
              case _ProfileStatus.authError:
                // Token expirado — limpiar sesión y volver al login
                Auth().signOut();
                return const WelcomePage();
              case _ProfileStatus.networkError:
                return _NetworkErrorScreen(onRetry: () {});
            }
          },
        );
      },
    );
  }
}

class _NetworkErrorScreen extends StatelessWidget {
  final VoidCallback onRetry;
  const _NetworkErrorScreen({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.white24),
            const SizedBox(height: 20),
            const Text('Sin conexión al servidor', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('El servidor puede estar iniciando.\nEspera unos segundos e intenta de nuevo.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE51D2A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14), elevation: 0),
              child: const Text('Reintentar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
