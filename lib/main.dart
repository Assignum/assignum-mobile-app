import 'package:flutter/material.dart';
import 'package:assignum/core/infrastructure/auth_session.dart';
import 'package:assignum/core/infrastructure/api_client.dart';
import 'package:assignum/core/infrastructure/socket_service.dart';
import 'package:assignum/shared/presentation/theme/app_theme.dart';
import 'package:assignum/core/presentation/widget_tree.dart';
import 'package:assignum/activities/domain/auth_facade.dart';
import 'package:assignum/core/infrastructure/core_auth_facade.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthSession().init();
  IAuthFacade.instance = CoreAuthFacade();
  // Warm up backend in background (Render free tier cold start)
  ApiClient.postPublic('/api/auth/login', {'email': '', 'password': ''}).catchError((_) => null);
  // Connect socket if session already exists (app reopen)
  if (AuthSession().isLoggedIn) SocketService().connect();
  // Keep socket in sync with auth state
  AuthSession().authStateChanges.listen((loggedIn) {
    if (loggedIn) {
      SocketService().connect();
    } else {
      SocketService().disconnect();
    }
  });
  runApp(const AssignumApp());
}

class AssignumApp extends StatelessWidget {
  const AssignumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Assignum',
      debugShowCheckedModeBanner: false,
      theme: upcTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const WidgetTree(),
        '/home': (context) => const WidgetTree(),
      },
    );
  }
}
