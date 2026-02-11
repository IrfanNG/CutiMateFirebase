import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '245769007460-vt7qvfc7etoit3lut2n7hdnsjltk8dpq.apps.googleusercontent.com',
  );

  // Auth State Stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current User
  User? get currentUser => _auth.currentUser;

  // Sign in with Email and Password
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      // Verify user exists in Firestore
      final userDoc = await _firestore
          .collection("users")
          .doc(userCredential.user!.uid)
          .get();
      if (!userDoc.exists) {
        // If they auth'd but don't have a doc (edge case), create one or sign out
        // For now, let's treat it as an error to match previous logic,
        // or we could auto-create. The previous logic threw an exception.
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: "This email is not registered in the system",
        );
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign Up with Email and Password
  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await _createUserInFirestore(userCredential.user!, name: name);
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign In with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google [UserCredential]
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Check if user exists in Firestore, if not create
      final userDoc = await _firestore
          .collection("users")
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _createUserInFirestore(
          userCredential.user!,
          name: googleUser.displayName ?? "No Name",
          authMethod: "google",
        );
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Helper argument update for _createUserInFirestore to accept authMethod
  Future<void> _createUserInFirestore(
    User user, {
    required String name,
    String authMethod = "email",
  }) async {
    await _firestore.collection("users").doc(user.uid).set({
      "email": user.email,
      "name": name,
      "role": "user",
      "createdAt": FieldValue.serverTimestamp(),
      "authMethod": authMethod,
    });
  }
}
