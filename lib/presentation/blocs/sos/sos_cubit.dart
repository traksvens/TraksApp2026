import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/sos_contact_model.dart';
import '../../../data/models/sos_model.dart';
import '../../../repository/auth_repository.dart';
import '../../../repository/post_repository.dart';

part 'sos_state.dart';

class SosCubit extends Cubit<SosState> {
  final AuthRepository _authRepository;
  final PostRepository _postRepository;

  SosCubit({
    required AuthRepository authRepository,
    required PostRepository postRepository,
  })  : _authRepository = authRepository,
        _postRepository = postRepository,
        super(const SosInitial());

  Future<void> loadSosData(String userId) async {
    emit(SosLoading());
    try {
      final contacts = await _authRepository.getEmergencyContacts(userId);
      final history = await _postRepository.getSosByReporter(userId);
      emit(SosDataLoaded(contacts: contacts, history: history));
    } catch (e) {
      emit(SosError('Failed to load SOS data: $e'));
    }
  }

  Future<void> addEmergencyContact(
    String userId,
    SosContactModel contact,
  ) async {
    final currentState = state;
    emit(SosLoading());
    try {
      await _authRepository.createEmergencyContact(userId, contact);
      await loadSosData(userId);
    } catch (e) {
      emit(SosError('Failed to add contact: $e'));
      if (currentState is SosDataLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> broadcastSos(SosModel sosData) async {
    final currentState = state;
    emit(SosLoading());
    try {
      await _postRepository.createSos(sosData);
      await loadSosData(sosData.reporterId);
    } catch (e) {
      emit(SosError('Failed to broadcast SOS: $e'));
      if (currentState is SosDataLoaded) {
        emit(currentState);
      }
    }
  }
}
