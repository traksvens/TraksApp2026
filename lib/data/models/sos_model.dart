import 'package:flutter/foundation.dart';

@immutable
class SosModel {
  final String reporterId;
  final String? reporterName;
  final Map<String, dynamic> location; // { "lat": double, "lng": double }
  final String status;
  final String? timestamp; // Often useful
  final String? id;

  const SosModel({
    required this.reporterId,
    this.reporterName,
    required this.location,
    required this.status,
    this.timestamp,
    this.id,
  });

  factory SosModel.fromJson(Map<String, dynamic> json) {
    return SosModel(
      reporterId: json['reporterId'] as String,
      reporterName: json['reporterName'] as String?,
      location: Map<String, dynamic>.from(json['location'] as Map),
      status: json['status'] as String,
      timestamp: json['timestamp'] as String?,
      id: json['id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reporterId': reporterId,
      if (reporterName != null) 'reporterName': reporterName,
      'location': location,
      'status': status,
      if (timestamp != null) 'timestamp': timestamp,
      if (id != null) 'id': id,
    };
  }
}
