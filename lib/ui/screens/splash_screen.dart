import 'package:flutter/material.dart';

/// Splash screen in-app: logo full KarbonKita selebar layar.
///
/// Menggantikan spinner saat sesi dicek ([AuthStatus.initial],
/// [AuthStatus.checking], [AuthStatus.loading]) dengan durasi tampil
/// minimum 2 detik (diatur di `_SessionGate`). Memakai file
/// `assets/images/logoapp.png` apa adanya tanpa resize.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logoapp.png',
              width: screenWidth * 0.85,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
