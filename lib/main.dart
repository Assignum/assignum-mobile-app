import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:assignum/core/infrastructure/firebase_options.dart';
import 'package:assignum/shared/presentation/theme/app_theme.dart';
import 'package:assignum/core/presentation/widget_tree.dart';
import 'package:assignum/activities/domain/auth_facade.dart';
import 'package:assignum/core/infrastructure/core_auth_facade.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  IAuthFacade.instance = CoreAuthFacade();
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
