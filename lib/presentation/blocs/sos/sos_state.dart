part of 'sos_cubit.dart';

abstract class SosState extends Equatable {
  const SosState();

  @override
  List<Object?> get props => [];
}

class SosInitial extends SosState {
  const SosInitial();
}

class SosLoading extends SosState {}

class SosDataLoaded extends SosState {
  final String userId;
  final List<SosContactModel> contacts;
  final List<SosModel> history;
  final String? activeIncidentId;

  const SosDataLoaded({
    required this.userId,
    required this.contacts,
    required this.history,
    this.activeIncidentId,
  });

  @override
  List<Object?> get props => [userId, contacts, history, activeIncidentId];
}

class SosError extends SosState {
  final String message;

  const SosError(this.message);

  @override
  List<Object?> get props => [message];
}
