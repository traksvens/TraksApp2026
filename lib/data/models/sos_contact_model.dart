import 'package:equatable/equatable.dart';

class SosContactModel extends Equatable {
  final String? id;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? email;
  final String userId;
  final double? lat;
  final double? lng;
  final String? createdAt;
  final String? updatedAt;

  const SosContactModel({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.email,
    required this.userId,
    this.lat,
    this.lng,
    this.createdAt,
    this.updatedAt,
  });

  factory SosContactModel.fromJson(Map<String, dynamic> json) {
    return SosContactModel(
      id: json['id'] as String?,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      email: json['email'] as String?,
      userId: json['userId'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      if (email != null) 'email': email,
      'userId': userId,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        phoneNumber,
        email,
        userId,
        lat,
        lng,
        createdAt,
        updatedAt,
      ];
}
