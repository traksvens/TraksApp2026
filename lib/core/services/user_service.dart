import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/user_model.dart';
import '../../data/models/sos_contact_model.dart';
import '../error/exceptions.dart';

class UserService {
  final Dio _dio;
  final String _baseUrl = 'https://traks-api-945904604038.us-central1.run.app';

  UserService({Dio? dio}) : _dio = dio ?? Dio();

  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(user.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw ServerException(
        message: 'Failed to create or update user profile: $e',
      );
    }
  }

  Future<List<SosContactModel>> getEmergencyContacts(String userId) async {
    try {
      final response = await _dio.get('$_baseUrl/users/$userId/contacts');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((e) => SosContactModel.fromJson(e)).toList();
      } else {
        throw ServerException(
          message:
              'Failed to fetch emergency contacts: ${response.statusMessage}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data.toString() ?? e.message ?? 'Unknown Dio Error',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  Future<void> createEmergencyContact(
    String userId,
    SosContactModel contact,
  ) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/users/$userId/contacts',
        data: contact.toJson(),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          message:
              'Failed to create emergency contact: ${response.statusMessage}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data.toString() ?? e.message ?? 'Unknown Dio Error',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Unexpected error: $e');
    }
  }
}
