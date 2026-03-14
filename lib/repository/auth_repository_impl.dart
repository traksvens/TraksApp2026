import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_repository.dart';
import '../core/services/user_service.dart';
import '../data/models/user_model.dart';
import '../data/models/sos_contact_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final UserService _userService;

  AuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    UserService? userService,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _userService = userService ?? UserService();

  @override
  Stream<User?> get user => _firebaseAuth.authStateChanges();

  @override
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Initialize user profile via API
    if (userCredential.user != null) {
      final user = userCredential.user!;
      await _userService.createOrUpdateUser(
        UserModel(
          uid: user.uid,
          email: user.email ?? email,
          displayName: displayName, // User-provided display name
          joinedAt: DateTime.now(),
        ),
      );
    }

    return userCredential;
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'Sign in aborted by user',
      );
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);

    // Initialize user profile via API ONLY if this is a new google signup
    if (userCredential.user != null &&
        userCredential.additionalUserInfo?.isNewUser == true) {
      final user = userCredential.user!;
      await _userService.createOrUpdateUser(
        UserModel(
          uid: user.uid,
          email: user.email ?? googleUser.email,
          displayName:
              user.displayName ?? googleUser.displayName ?? 'Google User',
          photoURL: user.photoURL ?? googleUser.photoUrl,
          joinedAt: DateTime.now(),
        ),
      );
    }

    return userCredential;
  }

  @override
  Future<void> signOut() async {
    await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
  }

  @override
  Future<List<SosContactModel>> getEmergencyContacts(String userId) async {
    return await _userService.getEmergencyContacts(userId);
  }

  @override
  Future<void> createEmergencyContact(
    String userId,
    SosContactModel contact,
  ) async {
    await _userService.createEmergencyContact(userId, contact);
  }
}
