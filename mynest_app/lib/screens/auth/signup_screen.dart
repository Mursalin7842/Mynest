import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import 'profile_setup_screen.dart';

/// ─────────────────────────────────────────────
/// Signup Screen — Create a Legacy Account
/// ─────────────────────────────────────────────

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _createAccountAndSendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userId = await AuthService().signupAndSendOtp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );
      
      if (mounted) {
        setState(() {
          _showOtpField = true;
          _otpUserId = userId;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created! Code sent to your email.'), backgroundColor: NestTheme.sage),
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Account creation failed. Please try again.';
        if (e.toString().contains('already exists')) {
          msg = 'An account with this email already exists.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid code. Please try again.'),
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
                  // ── Logo ──
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: NestTheme.amberGradient,
                      boxShadow: [
                        BoxShadow(
                          color: NestTheme.amber.withOpacity(0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.home_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(begin: const Offset(0.5, 0.5)),
                  const SizedBox(height: 20),
                  Text(
                    'MyNest',
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge!
                        .copyWith(color: Colors.white),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 8),
                  Text(
                    'Begin preserving your family legacy today.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: Colors.white70),
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 40),

                  // ── Form Card ──
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: NestTheme.cardRadius,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
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
                          Text(
                            'Create Account',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Join our private archive of memories.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 28),

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
                            // Full Name
                            Text('Full Name',
                                style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                hintText: 'Evelyn Sinclair',
                                prefixIcon:
                                    Icon(Icons.person_outline, size: 20),
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Name required' : null,
                            ),
                            const SizedBox(height: 18),

                            // Email
                            Text('Email Address',
                                style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: 'evelyn@legacy.com',
                                prefixIcon:
                                    Icon(Icons.mail_outline, size: 20),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Email required';
                                if (!v.contains('@')) return 'Invalid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            // Password
                            Text('Create Password',
                                style: Theme.of(context).textTheme.bodySmall),
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
                                if (v == null || v.length < 8) {
                                  return 'Min 8 characters required';
                                }
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 28),

                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : (_showOtpField ? _verifyOtp : _createAccountAndSendOtp),
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
                                      _showOtpField ? 'Verify Code' : 'Sign Up',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: RichText(
                                text: TextSpan(
                                  text: 'Already have an account? ',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  children: [
                                    TextSpan(
                                      text: 'Log In',
                                      style: TextStyle(
                                        color: NestTheme.deepAmber,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 700.ms)
                      .slideY(begin: 0.15, end: 0),

                  const SizedBox(height: 32),
                  Text(
                    'Heritage Worth Preserving',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(
                            color: NestTheme.softGold,
                            fontStyle: FontStyle.italic),
                  ).animate().fadeIn(delay: 800.ms),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
