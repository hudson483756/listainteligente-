import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Usuário cancelou

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential;

      // Se já existia usuário anônimo, realiza o link
      if (_auth.currentUser != null && _auth.currentUser!.isAnonymous) {
        userCredential = await _auth.currentUser!.linkWithCredential(credential);
      } else {
        userCredential = await _auth.signInWithCredential(credential);
      }

      // Garante que o nome e foto do Google sejam definidos no perfil do Firebase
      final User? user = userCredential.user;
      if (user != null) {
        if (user.displayName == null || user.photoURL == null) {
          await user.updateDisplayName(googleUser.displayName);
          await user.updatePhotoURL(googleUser.photoUrl);
          await user.reload();
        }
      }

      return userCredential;
    } catch (e) {
      debugPrint('Erro no AuthService.signInWithGoogle: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}