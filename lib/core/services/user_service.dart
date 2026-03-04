import 'package:dio/dio.dart';
import '../../data/models/user_model.dart';
import '../error/exceptions.dart';

class UserService {
  final Dio _dio;
  final String _baseUrl = 'https://traks-api-945904604038.us-central1.run.app';

  UserService({Dio? dio}) : _dio = dio ?? Dio();

  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/users/${user.uid}',
        data: user.toJson(),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          message:
              'Failed to create or update user profile: ${response.statusMessage}',
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
