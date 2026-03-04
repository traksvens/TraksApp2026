import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Stream<User?> get user;
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  );
  Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  );
  Future<UserCredential> signInWithGoogle();
  Future<void> signOut();
}
