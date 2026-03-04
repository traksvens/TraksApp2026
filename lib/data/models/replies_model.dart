import 'package:flutter/foundation.dart';

@immutable
class RepliesModel {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final String timestamp;
  final String? fileUrl; // Optional media attachment

  const RepliesModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.timestamp,
    this.fileUrl,
  });

  factory RepliesModel.fromJson(Map<String, dynamic> json) {
    return RepliesModel(
      id: json['id'] as String? ?? '',
      postId: json['postId'] as String? ?? json['post_id'] as String? ?? '',
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
      fileUrl: json['fileUrl'] as String? ?? json['file_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'content': content,
      'timestamp': timestamp,
      if (fileUrl != null) 'fileUrl': fileUrl,
    };
  }
}
