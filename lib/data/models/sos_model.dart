import 'package:flutter/foundation.dart';

@immutable
class SosModel {
  final String userId;
  final String reporterName;
  final Map<String, dynamic> location; // { "latitude": double, "longitude": double, "accuracy": double }
  final String? alert_type; // MANUAL_TRIGGER, FALL_DETECTION, etc.
  final String? message;
  final String status;
  final String? timestamp;
  final String? id;

  const SosModel({
    required this.userId,
    required this.reporterName,
    required this.location,
    this.alert_type = 'MANUAL_TRIGGER',
    this.message,
    required this.status,
    this.timestamp,
    this.id,
  });

  factory SosModel.fromJson(Map<String, dynamic> json) {
    return SosModel(
      userId: json['user_id'] as String? ?? 
              json['userId'] as String? ?? 
              json['reporterId'] as String? ?? 
              json['device_id'] as String? ?? '',
      reporterName: json['reporterName'] as String? ?? json['name'] as String? ?? 'Unknown',
      location: Map<String, dynamic>.from(json['location'] as Map),
      alert_type: json['alert_type'] as String?,
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'Active',
      timestamp: json['timestamp'] as String?,
      id: json['id'] as String? ?? json['incident_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'reporterId': userId, // Fallback for current backend
      'reporterName': reporterName,
      'location': location,
      if (alert_type != null) 'alert_type': alert_type,
      if (message != null) 'message': message,
      'status': status,
      if (timestamp != null) 'timestamp': timestamp,
      if (id != null) 'id': id,
    };
  }
}
