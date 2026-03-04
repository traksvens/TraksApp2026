import 'package:flutter/foundation.dart';

@immutable
class RatingRequest {
  final String userId;
  final String rating; // 'confirm' or 'refute'

  const RatingRequest({required this.userId, required this.rating});

  factory RatingRequest.fromJson(Map<String, dynamic> json) {
    return RatingRequest(
      userId: json['userId'] as String,
      rating: json['rating'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'rating': rating};
  }
}
