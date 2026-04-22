/// ─────────────────────────────────────────────
/// MyNest V1.2.0 — Data Models
/// Matched to actual Appwrite collection schema
/// ─────────────────────────────────────────────

class FamilyMember {
  final String id;
  final String userId;
  final String fullName;
  final String? dateOfBirth;
  final String? gender;
  final String? relation;
  final String? relatedTo;
  final String? notes;
  final String? photoUrl;
  final bool isDeceased;
  final bool isApproved;
  final String? createdAt;

  FamilyMember({
    required this.id,
    required this.userId,
    required this.fullName,
    this.dateOfBirth,
    this.gender,
    this.relation,
    this.relatedTo,
    this.notes,
    this.photoUrl,
    this.isDeceased = false,
    this.isApproved = true,
    this.createdAt,
  });

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['\$id'] ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      fullName: map['fullName'] ?? '',
      dateOfBirth: map['dateOfBirth'],
      gender: map['gender'],
      relation: map['relation'],
      relatedTo: map['relatedTo'],
      notes: map['notes'],
      photoUrl: map['photoUrl'],
      isDeceased: map['isDeceased'] ?? false,
      isApproved: map['isApproved'] ?? true, // handles null default
      createdAt: map['\$createdAt'] ?? map['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'relation': relation,
      'relatedTo': relatedTo,
      'notes': notes,
      'photoUrl': photoUrl,
      'isDeceased': isDeceased,
      'isApproved': isApproved,
    };
  }

  FamilyMember copyWith({
    String? fullName,
    String? dateOfBirth,
    String? gender,
    String? relation,
    String? relatedTo,
    String? notes,
    String? photoUrl,
    bool? isDeceased,
    bool? isApproved,
  }) {
    return FamilyMember(
      id: id,
      userId: userId,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      relation: relation ?? this.relation,
      relatedTo: relatedTo ?? this.relatedTo,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      isDeceased: isDeceased ?? this.isDeceased,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt,
    );
  }
}

class Memory {
  final String id;
  final String userId;
  final String title;
  final String? story;
  final String? photoUrl;
  final String? audioUrl;
  final String? taggedPersonId;
  final String? taggedPersonName;
  final String? contributorName;
  final String? contributorRelation;
  final String? eventDate;
  final String? location;
  final bool isApproved;
  final String status; // 'raw', 'ai-ready', 'chaptered'
  final String visibility; // 'public', 'private', 'custom'
  final String? createdAt;

  Memory({
    required this.id,
    required this.userId,
    required this.title,
    this.story,
    this.photoUrl,
    this.audioUrl,
    this.taggedPersonId,
    this.taggedPersonName,
    this.contributorName,
    this.contributorRelation,
    this.eventDate,
    this.location,
    this.isApproved = true,
    this.status = 'raw',
    this.visibility = 'public',
    this.createdAt,
  });

  factory Memory.fromMap(Map<String, dynamic> map) {
    return Memory(
      id: map['\$id'] ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? 'Untitled Memory',
      story: map['story'],
      photoUrl: map['photoUrl'],
      audioUrl: map['audioUrl'],
      taggedPersonId: map['taggedPersonId'],
      taggedPersonName: map['taggedPersonName'],
      contributorName: map['contributorName'],
      contributorRelation: map['contributorRelation'],
      eventDate: map['eventDate'],
      location: map['location'],
      isApproved: map['isApproved'] ?? true, // null treated as approved
      status: map['status'] ?? 'raw',
      visibility: map['visibility'] ?? 'public',
      createdAt: map['\$createdAt'] ?? map['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'story': story,
      'photoUrl': photoUrl,
      'audioUrl': audioUrl,
      'taggedPersonId': taggedPersonId,
      'taggedPersonName': taggedPersonName,
      'contributorName': contributorName,
      'contributorRelation': contributorRelation,
      'eventDate': eventDate,
      'location': location,
      'isApproved': isApproved,
      'status': status,
      'visibility': visibility,
    };
  }

  Memory copyWith({
    String? title,
    String? story,
    String? photoUrl,
    String? audioUrl,
    String? taggedPersonId,
    String? taggedPersonName,
    String? eventDate,
    String? location,
    bool? isApproved,
    String? status,
    String? visibility,
  }) {
    return Memory(
      id: id,
      userId: userId,
      title: title ?? this.title,
      story: story ?? this.story,
      photoUrl: photoUrl ?? this.photoUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      taggedPersonId: taggedPersonId ?? this.taggedPersonId,
      taggedPersonName: taggedPersonName ?? this.taggedPersonName,
      contributorName: contributorName,
      contributorRelation: contributorRelation,
      eventDate: eventDate ?? this.eventDate,
      location: location ?? this.location,
      isApproved: isApproved ?? this.isApproved,
      status: status ?? this.status,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt,
    );
  }
}

/// Shareable link model — 3 types
class ShareLink {
  final String id;
  final String userId;
  final String type; // 'empty', 'photo_context', 'vault_share'
  final String? photoUrl; // only for photo_context
  final String? description;
  final bool isActive;
  final String? createdAt;

  ShareLink({
    required this.id,
    required this.userId,
    required this.type,
    this.photoUrl,
    this.description,
    this.isActive = true,
    this.createdAt,
  });

  factory ShareLink.fromMap(Map<String, dynamic> map) {
    return ShareLink(
      id: map['\$id'] ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: map['type'] ?? 'empty',
      photoUrl: map['photoUrl'],
      description: map['description'],
      isActive: map['isActive'] ?? true,
      createdAt: map['\$createdAt'] ?? map['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'photoUrl': photoUrl,
      'description': description,
      'isActive': isActive,
    };
  }

  String get webUrl {
    const domain = 'https://mynest.mursalin.engineer';
    switch (type) {
      case 'photo_context':
        return '$domain/photo-story/$id';
      case 'vault_share':
        return '$domain/vault/$id';
      default:
        return '$domain/contribute/$id';
    }
  }
}

/// User profile — matches your Appwrite `users` collection schema
class UserProfile {
  final String id;
  final String userId;
  final String fullName; // matches your 'fullName' attribute
  final String? email;
  final String? dateOfBirth;
  final String? profilePhotoUrl;
  final bool profileSetupComplete;
  final String? createdAt;

  UserProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    this.email,
    this.dateOfBirth,
    this.profilePhotoUrl,
    this.profileSetupComplete = false,
    this.createdAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['\$id'] ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'],
      dateOfBirth: map['dateOfBirth'],
      profilePhotoUrl: map['profilePhotoUrl'],
      profileSetupComplete: map['profileSetupComplete'] ?? false,
      createdAt: map['\$createdAt'] ?? map['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'dateOfBirth': dateOfBirth,
      'profilePhotoUrl': profilePhotoUrl,
      'profileSetupComplete': profileSetupComplete,
    };
  }
}
