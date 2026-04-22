import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import '../config/appwrite_config.dart';

/// ─────────────────────────────────────────────
/// Auth Service V1.2.0 — With Email Verification
/// ─────────────────────────────────────────────

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  late Client _client;
  late Account _account;
  models.User? _currentUser;

  models.User? get currentUser => _currentUser;

  void init() {
    _client = Client()
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId);
    _account = Account(_client);
  }

  Client get client => _client;

  /// Check if user has an active session
  Future<bool> checkSession() async {
    try {
      _currentUser = await _account.get();
      return true;
    } catch (_) {
      _currentUser = null;
      return false;
    }
  }

  /// Custom 2FA: Create account and send OTP
  Future<String> signupAndSendOtp({
    required String email,
    required String password,
    required String name,
  }) async {
    // 1. Create account
    await _account.create(
      userId: ID.unique(),
      email: email,
      password: password,
      name: name,
    );

    // 2. Send OTP
    final token = await _account.createEmailToken(
      userId: ID.unique(),
      email: email,
    );
    
    return token.userId;
  }

  /// Ultimate Showcase Bypass
  void performUltimateBypass() {
    _currentUser = models.User.fromMap({
        '\$id': 'demo_user_12345',
        '\$createdAt': DateTime.now().toIso8601String(),
        '\$updatedAt': DateTime.now().toIso8601String(),
        'name': 'Showcase Demo User',
        'registration': DateTime.now().toIso8601String(),
        'status': true,
        'labels': <String>[],
        'passwordUpdate': DateTime.now().toIso8601String(),
        'email': AppwriteConfig.testEmail,
        'phone': '',
        'emailVerification': true,
        'phoneVerification': true,
        'mfa': false,
        'prefs': <String, dynamic>{},
        'targets': <dynamic>[],
        'accessedAt': DateTime.now().toIso8601String(),
        'password': '',
        'hash': '',
        'hashOptions': <String, dynamic>{},
    });
  }

  /// Custom 2FA: Verify password and send OTP
  Future<String?> verifyPasswordAndSendOtp({
    required String email,
    required String password,
  }) async {
    if (email.toLowerCase() == AppwriteConfig.testEmail && password == AppwriteConfig.testPassword) {
      // Test account bypass: Create session and return null to indicate bypass
      try {
        await _account.createEmailPasswordSession(
          email: email,
          password: password,
        );
        _currentUser = await _account.get();
      } catch (e) {
        // Fallback: If test user doesn't exist on server, just mock it completely!
        performUltimateBypass();
      }
      return null;
    }

    // 1. Verify password by creating a session
    final session = await _account.createEmailPasswordSession(
      email: email,
      password: password,
    );
    
    // 2. Delete the session immediately so we can start the OTP flow
    await _account.deleteSession(sessionId: session.$id);

    // 3. Send OTP
    final token = await _account.createEmailToken(
      userId: ID.unique(),
      email: email,
    );

    return token.userId;
  }

  /// Custom 2FA: Verify OTP to log in
  Future<void> verifyOtp(String userId, String secret) async {
    await _account.createSession(
      userId: userId,
      secret: secret,
    );
    _currentUser = await _account.get();
  }

  /// Check if user's email is verified (test account always verified)
  bool get isEmailVerified {
    if (_currentUser == null) return false;
    if (_currentUser!.email.toLowerCase() == AppwriteConfig.testEmail) return true;
    return _currentUser!.emailVerification;
  }

  /// Update display name
  Future<void> updateName(String name) async {
    await _account.updateName(name: name);
    _currentUser = await _account.get();
  }

  /// Update password
  Future<void> updatePassword(String newPassword, String oldPassword) async {
    await _account.updatePassword(
      password: newPassword,
      oldPassword: oldPassword,
    );
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } catch (_) {}
    _currentUser = null;
  }

  /// Resend verification email
  Future<void> resendVerification() async {
    await _account.createVerification(
      url: '${AppwriteConfig.webDomain}/verify',
    );
  }
}
