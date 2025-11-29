import 'dart:async';
import 'package:flutter/material.dart';
import 'home_page.dart'; // Assuming your main app page is HomePage

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Duration of the fade animation
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward(); // Start the animation

    Timer(const Duration(seconds: 3), () {
      // Total time for splash screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (context) =>
                const HomePage()), // Navigate to your home page
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Or your desired background color
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Make sure to replace 'assets/images/logo.png' with the correct path to your logo
              Image.asset('assets/logo.png',
                  width: 150, height: 150), // Adjust size as needed
              const SizedBox(height: 20),
              const Text(
                'Pocket Doctor', // Your app name or a tagline
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent, // Choose your color
                ),
              ),
              const SizedBox(height: 20),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
