import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/sos_contact_model.dart';

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
  Future<List<SosContactModel>> getEmergencyContacts(String userId);
  Future<void> createEmergencyContact(String userId, SosContactModel contact);
}
