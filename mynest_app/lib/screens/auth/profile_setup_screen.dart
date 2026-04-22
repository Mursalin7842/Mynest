import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../home/home_shell.dart';

/// ─────────────────────────────────────────────
/// Profile Setup — One-Time Onboarding
/// ─────────────────────────────────────────────

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  bool _isLoading = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    if (user != null) {
      _nameController.text = user.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: NestTheme.deepAmber,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: NestTheme.charcoal,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _dobController.text =
            '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
      });
    }
  }

  Future<void> _startVault() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = AuthService().currentUser!;

      // Save profile to database
      await DatabaseService().createUserProfile(UserProfile(
        id: '', userId: user.$id,
        fullName: _nameController.text.trim(),
        email: user.email,
        dateOfBirth: _dobController.text,
        profileSetupComplete: true,
      ));

      // Update Appwrite user name
      await AuthService().updateName(_nameController.text.trim());

      // Create root family member node (self)
      await DatabaseService().addFamilyMember(
        FamilyMember(
          id: '',
          userId: user.$id,
          fullName: _nameController.text.trim(),
          dateOfBirth: _dobController.text,
          relation: 'Self',
          isApproved: true,
        ),
      );

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
            content: Text('Setup failed: ${e.toString()}'),
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
      backgroundColor: NestTheme.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Header ──
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: NestTheme.parchment,
                    border: Border.all(
                      color: NestTheme.amber.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.person_add_rounded,
                    size: 48,
                    color: NestTheme.deepAmber,
                  ),
                ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),
                const SizedBox(height: 28),

                Text(
                  'Complete Your\nProfile',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium,
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Set the foundation for your digital legacy. Your details help curate your family history.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 48),

                // ── Name Field ──
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Your Full Name',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Mursaline Huqe',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

                const SizedBox(height: 24),

                // ── DOB Field ──
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Date of Birth',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _dobController,
                      decoration: const InputDecoration(
                        hintText: 'mm/dd/yyyy',
                        prefixIcon:
                            Icon(Icons.calendar_today_outlined, size: 20),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),

                const SizedBox(height: 48),

                // ── Start Button ──
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _startVault,
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
                        : const Text('Start My Vault'),
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),

                const SizedBox(height: 16),
                Text(
                  'By continuing, you agree to our Terms of Legacy & Privacy.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(fontSize: 11),
                ).animate().fadeIn(delay: 700.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

