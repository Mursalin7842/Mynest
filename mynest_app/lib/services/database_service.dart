import 'package:appwrite/appwrite.dart';
import '../config/appwrite_config.dart';
import '../models/models.dart';
import 'auth_service.dart';

/// ─────────────────────────────────────────────
/// Database Service V1.2.0 — Full CRUD + Links
/// ─────────────────────────────────────────────

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  late Databases _db;

  void init() {
    _db = Databases(AuthService().client);
  }

  // ═══════════════════════════════════════════
  //  USER PROFILE
  // ═══════════════════════════════════════════

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final res = await _db.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollection,
        queries: [Query.equal('userId', userId), Query.limit(1)],
      );
      if (res.documents.isNotEmpty) {
        return UserProfile.fromMap(res.documents.first.data);
      }
    } catch (_) {}
    return null;
  }

  Future<void> createUserProfile(UserProfile profile) async {
    await _db.createDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.usersCollection,
      documentId: ID.unique(),
      data: profile.toMap(),
    );
  }

  Future<void> updateUserProfile(String docId, Map<String, dynamic> data) async {
    await _db.updateDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.usersCollection,
      documentId: docId,
      data: data,
    );
  }

  // ═══════════════════════════════════════════
  //  FAMILY MEMBERS
  // ═══════════════════════════════════════════

  Future<List<FamilyMember>> getFamilyMembers(String userId) async {
    final res = await _db.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.familyMembersCollection,
      queries: [Query.equal('userId', userId), Query.limit(100)],
    );
    return res.documents.map((d) => FamilyMember.fromMap(d.data)).toList();
  }

  Future<List<FamilyMember>> getPendingMembers(String userId) async {
    final res = await _db.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.familyMembersCollection,
      queries: [
        Query.equal('userId', userId),
        Query.equal('isApproved', false),
        Query.limit(50),
      ],
    );
    return res.documents.map((d) => FamilyMember.fromMap(d.data)).toList();
  }

  Future<void> addFamilyMember(FamilyMember member) async {
    await _db.createDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.familyMembersCollection,
      documentId: ID.unique(),
      data: member.toMap(),
    );
  }

  Future<void> updateFamilyMember(String id, Map<String, dynamic> data) async {
    await _db.updateDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.familyMembersCollection,
      documentId: id,
      data: data,
    );
  }

  Future<void> approveFamilyMember(String id) async {
    await updateFamilyMember(id, {'isApproved': true});
  }

  Future<void> deleteFamilyMember(String id) async {
    await _db.deleteDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.familyMembersCollection,
      documentId: id,
    );
  }

  // ═══════════════════════════════════════════
  //  MEMORIES
  // ═══════════════════════════════════════════

  Future<List<Memory>> getMemories(String userId) async {
    final res = await _db.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.memoriesCollection,
      queries: [
        Query.equal('userId', userId),
        Query.limit(100),
        Query.orderDesc('\$createdAt'),
      ],
    );
    return res.documents.map((d) => Memory.fromMap(d.data)).toList();
  }

  Future<List<Memory>> getPublicMemories(String userId) async {
    final res = await _db.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.memoriesCollection,
      queries: [
        Query.equal('userId', userId),
        Query.equal('visibility', 'public'),
        Query.equal('isApproved', true),
        Query.limit(100),
      ],
    );
    return res.documents.map((d) => Memory.fromMap(d.data)).toList();
  }

  Future<List<Memory>> getPendingMemories(String userId) async {
    final res = await _db.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.memoriesCollection,
      queries: [
        Query.equal('userId', userId),
        Query.equal('isApproved', false),
        Query.limit(50),
      ],
    );
    return res.documents.map((d) => Memory.fromMap(d.data)).toList();
  }

  Future<void> addMemory(Memory memory) async {
    await _db.createDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.memoriesCollection,
      documentId: ID.unique(),
      data: memory.toMap(),
    );
  }

  Future<void> updateMemory(String id, Map<String, dynamic> data) async {
    await _db.updateDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.memoriesCollection,
      documentId: id,
      data: data,
    );
  }

  Future<void> approveMemory(String id) async {
    await updateMemory(id, {'isApproved': true});
  }

  Future<void> deleteMemory(String id) async {
    await _db.deleteDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.memoriesCollection,
      documentId: id,
    );
  }

  // ═══════════════════════════════════════════
  //  SHARE LINKS
  // ═══════════════════════════════════════════

  Future<ShareLink> createShareLink(ShareLink link) async {
    final doc = await _db.createDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.linksCollection,
      documentId: ID.unique(),
      data: link.toMap(),
    );
    return ShareLink.fromMap(doc.data);
  }

  Future<List<ShareLink>> getShareLinks(String userId) async {
    final res = await _db.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.linksCollection,
      queries: [
        Query.equal('userId', userId),
        Query.orderDesc('\$createdAt'),
        Query.limit(50),
      ],
    );
    return res.documents.map((d) => ShareLink.fromMap(d.data)).toList();
  }

  Future<ShareLink?> getShareLinkById(String linkId) async {
    try {
      final doc = await _db.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.linksCollection,
        documentId: linkId,
      );
      return ShareLink.fromMap(doc.data);
    } catch (_) {
      return null;
    }
  }

  Future<void> deactivateLink(String id) async {
    await _db.updateDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.linksCollection,
      documentId: id,
      data: {'isActive': false},
    );
  }
}
