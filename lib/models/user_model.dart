import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final bool onboardingDone;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    required this.lastActiveAt,
    this.onboardingDone = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      onboardingDone: map['onboardingDone'] ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      lastActiveAt: map['lastActiveAt'] != null
          ? (map['lastActiveAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'onboardingDone': onboardingDone,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
    };
  }

  /// Why copyWith? → lets us update ONE field without rewriting the whole object
  /// e.g. user.copyWith(onboardingDone: true)
  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    bool? onboardingDone,
    DateTime? lastActiveAt,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      createdAt: createdAt,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}
