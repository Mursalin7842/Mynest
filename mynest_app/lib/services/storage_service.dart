import 'dart:typed_data';
import 'package:appwrite/appwrite.dart';
import '../config/appwrite_config.dart';
import 'auth_service.dart';

/// ─────────────────────────────────────────────
/// Storage Service V1.2.0 — Files + Profile Pics
/// ─────────────────────────────────────────────

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late Storage _storage;

  void init() {
    _storage = Storage(AuthService().client);
  }

  /// Upload a file (photo/audio) to the main bucket
  Future<String> uploadFile({
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    final file = await _storage.createFile(
      bucketId: AppwriteConfig.storageBucket,
      fileId: ID.unique(),
      file: InputFile.fromBytes(bytes: fileBytes, filename: fileName),
    );
    return file.$id;
  }

  /// Upload profile photo
  Future<String> uploadProfilePhoto({
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    final file = await _storage.createFile(
      bucketId: AppwriteConfig.profileBucket,
      fileId: ID.unique(),
      file: InputFile.fromBytes(bytes: fileBytes, filename: fileName),
    );
    return file.$id;
  }

  /// Get file preview URL
  String getFileUrl(String fileId, {String? bucket}) {
    final b = bucket ?? AppwriteConfig.storageBucket;
    return '${AppwriteConfig.endpoint}/storage/buckets/$b/files/$fileId/view?project=${AppwriteConfig.projectId}';
  }

  /// Get profile photo URL
  String getProfilePhotoUrl(String fileId) {
    return getFileUrl(fileId, bucket: AppwriteConfig.profileBucket);
  }

  /// Delete a file
  Future<void> deleteFile(String fileId, {String? bucket}) async {
    await _storage.deleteFile(
      bucketId: bucket ?? AppwriteConfig.storageBucket,
      fileId: fileId,
    );
  }
}
