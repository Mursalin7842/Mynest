/// ─────────────────────────────────────────────
/// MyNest V1.2.0 — Configuration
/// ─────────────────────────────────────────────
library;

class AppwriteConfig {
  // ── Appwrite Cloud ──
  static const String endpoint = 'https://nyc.cloud.appwrite.io/v1';
  static const String projectId = '687e9e6200375f703df2';   // ← Paste here
  static const String databaseId = '69e916610024758bfa45'; // ← Paste here

  // ── Collection IDs ──
  static const String usersCollection = 'users';
  static const String familyMembersCollection = 'family_members';
  static const String memoriesCollection = 'memories';
  static const String linksCollection = 'links';

  // ── Storage ──
  static const String storageBucket = 'mynest_files';
  static const String profileBucket = 'profile_photos';

  // ── Gemini AI ──
  static const String geminiApiKey = 'INSERT_YOUR_API_KEY_HERE'; // ← Paste here
  static const String geminiModel = 'gemini-3.1-flash-lite-preview';

  // ── Backend Function ──
  static const String backendFunctionId = 'mynest_backend';

  // ── Web Portal ──
  static const String webDomain = 'https://mynest.mursalin.engineer';

  // ── Test Account (bypasses email verification) ──
  static const String testEmail = 'test@gmail.com';
  static const String testPassword = 'testtest';

  // ── App Version ──
  static const String appVersion = 'V1.2.0';
}
