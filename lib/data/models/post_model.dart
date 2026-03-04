import 'package:flutter/foundation.dart';
import 'address_model.dart';

@immutable
class PostModel {
  /// Base URL for the API service, used to construct absolute image URLs.
  static const String _baseUrl =
      'https://traks-api-945904604038.us-central1.run.app';

  final String id;
  final String userId;
  final String severity;
  final bool isAnonymous;
  final String timestamp;
  final int confirmCount;
  final int refuteCount;
  final String incidentType;
  final int replyCount;
  final Map<String, String> ratedBy;
  final AddressModel address;
  final String content;
  final String? imageUrl;
  final Map<String, dynamic>? location; // Lat/Lng
  final String? userName;
  final String? userAvatarUrl;

  /// Returns the absolute image URL, prepending the base API URL if needed.
  /// Returns null if imageUrl is null or empty.
  String? get absoluteImageUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    if (imageUrl!.startsWith('http')) return imageUrl;
    return '$_baseUrl$imageUrl';
  }

  const PostModel({
    required this.id,
    required this.userId,
    required this.severity,
    this.isAnonymous = false,
    required this.timestamp,
    required this.confirmCount,
    required this.refuteCount,
    required this.incidentType,
    required this.replyCount,
    required this.ratedBy,
    required this.address,
    required this.content,
    this.imageUrl,
    this.location,
    this.userName,
    this.userAvatarUrl,
  });

  // Factory constructor for JSON deserialization
  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      severity: json['severity'] as String? ?? 'low',
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      timestamp: json['timestamp'] as String? ?? '',
      confirmCount: json['confirmCount'] as int? ?? 0,
      refuteCount: json['refuteCount'] as int? ?? 0,
      incidentType: json['incidentType'] as String? ?? 'General',
      replyCount: json['replyCount'] as int? ?? 0,
      ratedBy: json['ratedBy'] != null
          ? Map<String, String>.from(json['ratedBy'] as Map)
          : {},
      address: json['address'] != null
          ? AddressModel.fromJson(
              Map<String, dynamic>.from(json['address'] as Map),
            )
          : const AddressModel(),
      content: json['content'] as String? ?? '',
      imageUrl: json['post_img'] as String? ?? json['imageUrl'] as String?,
      location: json['location'] != null
          ? Map<String, dynamic>.from(json['location'] as Map)
          : null,
      userName: json['userName'] as String?,
      userAvatarUrl: json['userAvatarUrl'] as String?,
    );
  }

  // Method for JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'severity': severity,
      'isAnonymous': isAnonymous,
      'timestamp': timestamp,
      'confirmCount': confirmCount,
      'refuteCount': refuteCount,
      'incidentType': incidentType,
      'replyCount': replyCount,
      'ratedBy': ratedBy,
      'address': address.toJson(),
      'content': content,
      'imageUrl': imageUrl,
      'location': location,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
    };
  }

  // CopyWith for immutability updates
  PostModel copyWith({
    String? id,
    String? userId,
    String? severity,
    bool? isAnonymous,
    String? timestamp,
    int? confirmCount,
    int? refuteCount,
    String? incidentType,
    int? replyCount,
    Map<String, String>? ratedBy,
    AddressModel? address,
    String? content,
    String? imageUrl,
    Map<String, dynamic>? location,
    String? userName,
    String? userAvatarUrl,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      severity: severity ?? this.severity,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      timestamp: timestamp ?? this.timestamp,
      confirmCount: confirmCount ?? this.confirmCount,
      refuteCount: refuteCount ?? this.refuteCount,
      incidentType: incidentType ?? this.incidentType,
      replyCount: replyCount ?? this.replyCount,
      ratedBy: ratedBy ?? this.ratedBy,
      address: address ?? this.address,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
    );
  }
}
