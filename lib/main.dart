import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:assignum/firebase_options.dart';
import 'package:assignum/theme/app_theme.dart';
import 'package:assignum/widget_tree.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      home: const WidgetTree(),
    );
  }
}
