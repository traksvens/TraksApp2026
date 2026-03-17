import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:another_telephony/telephony.dart';
import '../../../data/models/sos_contact_model.dart';
import '../../../data/models/sos_model.dart';
import '../../../repository/auth_repository.dart';
import '../../../repository/post_repository.dart';
import '../../../core/services/analytics_service.dart';

part 'sos_state.dart';

class SosCubit extends Cubit<SosState> {
  final AuthRepository _authRepository;
  final PostRepository _postRepository;

  SosCubit({
    required AuthRepository authRepository,
    required PostRepository postRepository,
  }) : _authRepository = authRepository,
       _postRepository = postRepository,
       super(const SosInitial());

  Future<void> loadSosData(String userId) async {
    emit(SosLoading());
    try {
      final contacts = await _authRepository.getEmergencyContacts(userId);
      final history = await _postRepository.getSosByReporter(userId);

      String? activeId;
      if (history.isNotEmpty &&
          history.first.status.toLowerCase() == 'active') {
        activeId = history.first.id; // API might return id as incident_id
      }

      emit(
        SosDataLoaded(
          userId: userId,
          contacts: contacts,
          history: history,
          activeIncidentId: activeId,
        ),
      );
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

      final newCount = currentState is SosDataLoaded
          ? currentState.contacts.length + 1
          : 1;
      AnalyticsHelper.trackEmergencyContactAdded(newCount);
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
      final incidentId = await _postRepository.createSos(sosData);

      final contacts = await _authRepository.getEmergencyContacts(
        sosData.userId,
      );
      final history = await _postRepository.getSosByReporter(sosData.userId);

      emit(
        SosDataLoaded(
          userId: sosData.userId,
          contacts: contacts,
          history: history,
          activeIncidentId: incidentId,
        ),
      );

      AnalyticsHelper.trackSosSent(
        incidentId: incidentId,
        alertType: sosData.alert_type ?? 'UNKNOWN',
        latitude: sosData.location['latitude'] as double?,
        longitude: sosData.location['longitude'] as double?,
      );
    } catch (e) {
      // Offline fallback
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(sosData.reporterId).get(const GetOptions(source: Source.cache));
        final data = doc.data();
        if (data != null && (data['tier'] == 'premium' || data['tier'] == 'reporter')) {
          final contacts = await _authRepository.getLocalEmergencyContacts(sosData.reporterId);
          if (contacts.isNotEmpty) {
            final telephony = Telephony.instance;
            bool? hasPermission = await telephony.requestPhoneAndSmsPermissions;
            if (hasPermission == true) {
              final lat = sosData.location['lat'];
              final lng = sosData.location['lng'];
              final message = "🆘 SOS ALERT from ${sosData.reporterName}!\nLocation: https://maps.google.com/?q=$lat,$lng\nPlease help immediately!";
              for (final contact in contacts) {
                await telephony.sendSms(to: contact.phoneNumber, message: message);
              }
              emit(const SosError('Network failed, but offline SMS SOS was sent successfully!'));
              if (currentState is SosDataLoaded) {
                emit(currentState);
              }
              return;
            }
          }
        }
      } catch (_) {}

      emit(SosError('Failed to broadcast SOS: $e'));
      if (currentState is SosDataLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> updateSosLocation(
    String incidentId,
    double lat,
    double lng,
  ) async {
    try {
      await _postRepository.updateSosLocation(incidentId, lat, lng);
    } catch (e) {
      // We don't necessarily want to emit an error state for background location updates
      // unless it's critical. For now, just print or log.
      print('Failed to update SOS location: $e');
    }
  }

  Future<void> resolveSos(
    String incidentId,
    String resolution, {
    String? note,
  }) async {
    final currentState = state;
    if (currentState is SosDataLoaded) {
      emit(SosLoading());
      try {
        await _postRepository.resolveSos(incidentId, resolution, note: note);
        await loadSosData(currentState.userId);

        AnalyticsHelper.trackSosResolved(incidentId, resolution: resolution);
      } catch (e) {
        emit(SosError('Failed to resolve SOS: $e'));
        emit(currentState);
      }
    }
  }
}
