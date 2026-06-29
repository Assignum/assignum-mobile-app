import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:assignum/core/infrastructure/firebase_options.dart';
import 'package:assignum/core/infrastructure/auth_session.dart';
import 'package:assignum/core/infrastructure/api_client.dart';
import 'package:assignum/core/infrastructure/notification_service.dart';
import 'package:assignum/shared/presentation/theme/app_theme.dart';
import 'package:assignum/core/presentation/widget_tree.dart';
import 'package:assignum/core/presentation/notifications_page.dart';
import 'package:assignum/activities/domain/auth_facade.dart';
import 'package:assignum/core/infrastructure/core_auth_facade.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AuthSession().init();
  IAuthFacade.instance = CoreAuthFacade();
  await NotificationService.init();
  // Warm up backend in background (Render free tier cold start)
  ApiClient.postPublic('/api/auth/login', {'email': '', 'password': ''}).catchError((_) => null);
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
      navigatorKey: NotificationService.navigatorKey,
      scaffoldMessengerKey: NotificationService.scaffoldMessengerKey,
      initialRoute: '/',
      routes: {
        '/': (context) => const WidgetTree(),
        '/home': (context) => const WidgetTree(),
        '/notifications': (context) => const NotificationsPage(),
      },
    );
  }
}
