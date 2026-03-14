import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../repository/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription? _userSubscription;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<UserAuthenticated>(_onUserAuthenticated);
    on<UserUnauthenticated>(_onUserUnauthenticated);

    _userSubscription = _authRepository.user.listen((user) {
      if (user != null) {
        add(UserAuthenticated(user));
      } else {
        add(UserUnauthenticated());
      }
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = await _authRepository.user.first;
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.signInWithEmailAndPassword(
        event.email,
        event.password,
      );
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.signUpWithEmailAndPassword(
        event.email,
        event.password,
        event.displayName,
      );
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.signInWithGoogle();
    } catch (e, stackTrace) {
      print('=== GOOGLE SIGN IN ERROR ===');
      print(e);
      print(stackTrace);
      print('=============================');
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.signOut();
      // We don't emit Unauthenticated here because the listener will catch it
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  void _onUserAuthenticated(UserAuthenticated event, Emitter<AuthState> emit) {
    emit(Authenticated(event.user));
  }

  void _onUserUnauthenticated(
    UserUnauthenticated event,
    Emitter<AuthState> emit,
  ) {
    emit(Unauthenticated());
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
