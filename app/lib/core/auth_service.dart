import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Guest-first Firebase auth (US-9): every shopper is anonymous from first
/// launch, and Google is a link-on-demand upgrade of that same UID rather
/// than a separate sign-in — /me/banks works before anyone touches Google.
class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;
  bool _googleSignInReady = false;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;

  /// A guest already holds a token at first launch — anonymous sign-in is
  /// what makes that true.
  Future<void> ensureSignedIn() async {
    if (_auth.currentUser == null) await _auth.signInAnonymously();
  }

  Future<String?> idToken() => _auth.currentUser?.getIdToken() ?? Future.value();

  /// Links the signed-in guest to a Google account, keeping the same UID so
  /// nothing the guest already saved needs to migrate.
  ///
  /// If that Google account is already tied to a *different* Firebase user —
  /// the shopper linked it on another device or a previous install — signs
  /// into that account instead. The caller is expected to reconcile
  /// device-local state against the server afterwards, the same as at launch.
  Future<UserCredential?> linkGoogleAccount() async {
    if (!_googleSignInReady) {
      await GoogleSignIn.instance.initialize();
      _googleSignInReady = true;
    }

    final googleUser = await GoogleSignIn.instance.authenticate();
    final credential = GoogleAuthProvider.credential(
      idToken: googleUser.authentication.idToken,
    );

    try {
      return await _auth.currentUser!.linkWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      if (error.code != 'credential-already-in-use') rethrow;
      return _auth.signInWithCredential(credential);
    }
  }
}

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(FirebaseAuth.instance),
);

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges(),
);

/// How a repository asks for the current Firebase ID token, without taking a
/// hard dependency on [AuthService] — so a test can stub it with a plain
/// lambda instead of standing up real Firebase Auth.
typedef IdTokenProvider = Future<String?> Function();

Future<String?> noIdToken() => Future.value();
