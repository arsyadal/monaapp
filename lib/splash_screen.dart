import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';
import 'auth_screens.dart';
import 'pin_screen.dart';
import 'main.dart'; // untuk kPrimary dan MyHomePage

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Mengatur timer untuk pindah ke halaman utama
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final provider = context.read<AppProvider>();
        Widget nextScreen;
        if (!provider.isAuthenticated) {
          nextScreen = const LoginScreen();
        } else if (provider.usePin) {
          nextScreen = const PinScreen(nextScreen: MyHomePage(title: 'Monaapp'));
        } else {
          nextScreen = const MyHomePage(title: 'Monaapp');
        }

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo aplikasi
            Hero(
              tag: 'app_logo',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/preloader.jpeg',
                  width: 140,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback jika gambar gagal dimuat
                    return Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.wallet, size: 60, color: kPrimary),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Nama aplikasi
            const Text(
              'Monaapp',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: kPrimary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kelola Keuangan dengan Mudah',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 64),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}