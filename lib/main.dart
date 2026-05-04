import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'data/services/tasa_service.dart';
import 'package:provider/provider.dart';
import 'data/providers/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'data/firebase/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await TasaService().initCustomRates(); 
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vex - tasa libre',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: SplashScreen(),
    );
  }
}