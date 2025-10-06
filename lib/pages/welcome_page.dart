import 'package:flutter/material.dart';
import 'package:assignum/pages/login_register_page.dart';
import 'package:assignum/widgets/ui.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                const Text(
                  'Bienvenido\na Assignum',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 32),
                CardContainer(
                  child: Column(
                    children: [
                      PrimaryButton(
                        text: 'Iniciar sesión',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginRegisterPage(
                                initialIsLogin: true,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      SecondaryButton(
                        text: 'Regístrate',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginRegisterPage(
                                initialIsLogin: false,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
