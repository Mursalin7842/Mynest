import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/theme.dart';
import 'config/appwrite_config.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/storage_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize services
  AuthService().init();
  DatabaseService().init();
  StorageService().init();

  runApp(const MyNestApp());
}

class MyNestApp extends StatelessWidget {
  const MyNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyNest',
      debugShowCheckedModeBanner: false,
      theme: NestTheme.lightTheme,
      darkTheme: NestTheme.lightTheme, // Force light on dark-mode phones
      themeMode: ThemeMode.light,
      home: const SplashGate(),
    );
  }
}

/// Splash gate checks if user is already logged in
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    bool isLoggedIn = false;
    try {
      isLoggedIn = await AuthService().checkSession();
    } catch (_) {
      isLoggedIn = false;
    }

    // Show splash for 1.5s then navigate
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              isLoggedIn ? const HomeShell() : const LoginScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: NestTheme.heroGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                builder: (_, val, child) => Transform.scale(
                  scale: 0.5 + (val * 0.5),
                  child: Opacity(opacity: val, child: child),
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: NestTheme.amberGradient,
                    boxShadow: [
                      BoxShadow(
                        color: NestTheme.amber.withAlpha(128),
                        blurRadius: 40,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (_, val, __) => Opacity(
                  opacity: val,
                  child: Text(
                    'MyNest',
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge!
                        .copyWith(color: Colors.white, fontSize: 40),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (_, val, __) => Opacity(
                  opacity: val,
                  child: Text(
                    'Before your memory fades away.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(
                            color: NestTheme.softGold,
                            fontStyle: FontStyle.italic,
                            fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppwriteConfig.appVersion,
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: NestTheme.softGold.withAlpha(153),
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
