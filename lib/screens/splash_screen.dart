// El lottie (Animación) gira en la dirección incorrecta, espero poder cambiarlo en un futuro no tan lejano.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'home_screen.dart';
import '../data/services/tasa_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final Future<Map<String, dynamic>> _preloadFuture =
    TasaService().getTasas();

  @override
  void initState() {
    super.initState();

    // Controlador para la animación de fade
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    Timer(const Duration(milliseconds: 1500), () {
      _fadeController.forward(); // Inicia el desvanecimiento6
    });

    Timer(const Duration(milliseconds: 2000), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomeScreen(preloadFuture: _preloadFuture),
        ),
      );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 28, 27, 32),
      body: content(),
    );
  }

  Widget content() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              "assets/lotties/vex_lottie.json",
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              'VEX',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 77, 170, 2),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tasa libre de Venezuela',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}