import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../config/appwrite_config.dart';
import '../../services/auth_service.dart';
import 'signup_screen.dart';
import '../home/home_shell.dart';

/// ─────────────────────────────────────────────
/// Login Screen V1.2.0 — With test account bypass
/// ─────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  bool _showOtpField = false;
  String? _otpUserId;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final userId = await AuthService().verifyPasswordAndSendOtp(
        email: email,
        password: password,
      );
      
      if (userId == null) {
        // Bypass successful
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeShell()),
          );
        }
        return;
      }
      
      if (mounted) {
        setState(() {
          _showOtpField = true;
          _otpUserId = userId;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent to your email!'), backgroundColor: NestTheme.sage),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed.\n\nDetails: ${e.toString()}'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please enter the 6-digit code.'), backgroundColor: Colors.red.shade400),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService().verifyOtp(_otpUserId!, _otpController.text.trim());
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeShell()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid code.\n\nDetails: ${e.toString()}'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: NestTheme.heroGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo & Brand ──
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: NestTheme.amberGradient,
                      boxShadow: [
                        BoxShadow(
                          color: NestTheme.amber.withAlpha(102),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.home_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 800.ms)
                      .scale(begin: const Offset(0.5, 0.5)),
                  const SizedBox(height: 24),
                  Text(
                    'MyNest',
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge!
                        .copyWith(color: Colors.white),
                  ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome Back',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .copyWith(color: NestTheme.softGold),
                  ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                  const SizedBox(height: 6),
                  Text(
                    'Continue curating your family\'s digital legacy.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: Colors.white70),
                  ).animate().fadeIn(delay: 500.ms, duration: 600.ms),

                  const SizedBox(height: 48),

                  // ── Form Card ──
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: NestTheme.cardRadius,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x26000000),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_showOtpField) ...[
                            Text(
                              'Enter Verification Code',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: const InputDecoration(
                                hintText: '123456',
                                prefixIcon: Icon(Icons.security_rounded, size: 20),
                                counterText: '',
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Code is required';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'We sent a 6-digit code to your email.',
                              style: TextStyle(fontSize: 12, color: NestTheme.sage),
                            ),
                          ] else ...[
                            Text(
                              'Email address',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: 'name@example.com',
                                prefixIcon:
                                    Icon(Icons.mail_outline, size: 20),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Email is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Password',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon:
                                    const Icon(Icons.lock_outline, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Password is required';
                                }
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 28),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : (_showOtpField ? _verifyOtp : _verifyPassword),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: NestTheme.buttonRadius,
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      _showOtpField ? 'Verify Code' : 'Verify Password',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 700.ms)
                      .slideY(begin: 0.15, end: 0),

                  const SizedBox(height: 24),

                  // ── Test hint ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '🧪 Test: ${AppwriteConfig.testEmail} / ${AppwriteConfig.testPassword}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ).animate().fadeIn(delay: 800.ms),

                  const SizedBox(height: 16),

                  // ── Sign Up Link ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'New to the sanctuary? ',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(color: Colors.white70),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignupScreen()),
                        ),
                        child: Text(
                          'Create Account',
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    color: NestTheme.softGold,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                    decorationColor: NestTheme.softGold,
                                  ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 900.ms, duration: 600.ms),

                  const SizedBox(height: 48),

                  // ── Footer ──
                  Text(
                    '© 2026 MyNest Digital Curator • ${AppwriteConfig.appVersion}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: Colors.white38, fontSize: 11),
                  ).animate().fadeIn(delay: 1100.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
