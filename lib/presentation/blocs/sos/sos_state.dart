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
  final List<SosContactModel> contacts;
  final List<SosModel> history;

  const SosDataLoaded({required this.contacts, required this.history});

  @override
  List<Object?> get props => [contacts, history];
}

class SosError extends SosState {
  final String message;

  const SosError(this.message);

  @override
  List<Object?> get props => [message];
}
