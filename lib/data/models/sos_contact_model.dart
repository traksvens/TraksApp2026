import 'package:equatable/equatable.dart';

class SosContactModel extends Equatable {
  final String? id;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String email;
  final String userId;

  const SosContactModel({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
    required this.userId,
  });

  factory SosContactModel.fromJson(Map<String, dynamic> json) {
    return SosContactModel(
      id: json['id'] as String?,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String,
      userId: json['userId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'email': email,
      'userId': userId,
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
  ];
}
