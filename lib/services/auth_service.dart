import 'dart:convert';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:digifarmer/constants/constants.dart';

class AuthService {
  // Firebase authentication with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      //begin interactive sign in process
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        throw Exception("Google Sign In was cancelled");
      }

      //obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      //create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      //sign in to firebase with the credential
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      // After successful Firebase auth, notify backend
      try {
        await _loginWithFirebaseToken(userCredential.user);
      } catch (e) {
        // Log but don't throw the error - backend sync is secondary
        log("Backend sync failed: $e");
      }

      return userCredential;
    } catch (e) {
      log("Error during Google Sign-In: $e");
      throw Exception(e);
    }
  }

  // Register user with email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Create user with Firebase
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // After successful Firebase registration, register with backend
      try {
        await _registerWithBackend(email, password, userCredential.user);
      } catch (e) {
        // Log but don't throw the error - backend sync is secondary
        log("Backend registration failed: $e");
      }

      return userCredential;
    } catch (e) {
      log("Firebase registration error: $e");
      throw e; // Rethrow Firebase errors to be handled by UI
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Sign in with Firebase
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // After successful Firebase auth, login with backend
      try {
        await _loginWithBackend(email, password);
      } catch (e) {
        // Log but don't throw the error - backend sync is secondary
        log("Backend login failed: $e");
      }

      return userCredential;
    } catch (e) {
      log("Firebase login error: $e");
      throw e; // Rethrow Firebase errors to be handled by UI
    }
  }

  // Private methods to communicate with backend API
  Future<void> _registerWithBackend(
    String email,
    String password,
    User? user,
  ) async {
    if (user == null) return;

    try {
      final response = await http.post(
        Uri.parse('$baseURl$registerEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': user.displayName ?? 'testuser',
          'email': email,
          'password':
              password, // Secure random password as we authenticate through Firebase
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        log('Backend registration failed with status: ${response.statusCode}');
        log('Response body: ${response.body}');
      }
    } catch (e) {
      log('Backend registration exception: $e');
    }
  }

  Future<void> _loginWithBackend(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseURl$loginEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode != 200) {
        log('Backend login failed with status: ${response.statusCode}');
        log('Response body: ${response.body}');
      }
    } catch (e) {
      log('Backend login exception: $e');
    }
  }

  Future<void> _loginWithFirebaseToken(User? user) async {
    if (user == null) return;

    try {
      // Get Firebase ID token
      String? idToken = await user.getIdToken();

      final response = await http.post(
        Uri.parse('$baseURl$loginFirebaseEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'firebaseToken': idToken}),
      );

      if (response.statusCode != 200) {
        log(
          'Backend Firebase login failed with status: ${response.statusCode}',
        );
        log('Response body: ${response.body}');
      }
    } catch (e) {
      log('Backend Firebase login exception: $e');
    }
  }
}
