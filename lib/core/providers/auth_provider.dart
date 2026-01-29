import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'items_provider.dart'; // for firestoreServiceProvider
import '../models/user_model.dart';


// Firebase Auth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Current user stream
final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

// Current user model stream (Real-time profile updates + Subscription Data)
final userModelProvider = StreamProvider<UserModel?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return Stream.value(null);
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  // Create a merged stream manually
  final userStream = firestoreService.getUserStream(currentUser.uid);
  final subStream = firestoreService.getSubscriptionStream(currentUser.uid);

  // Directly combine the streams
  return _combineLatest(userStream, subStream);
});

// Helper to merge streams
Stream<UserModel?> _combineLatest(Stream<UserModel?> userAbs, Stream<Map<String, dynamic>?> subAbs) {
  final controller = StreamController<UserModel?>();
  UserModel? lastUser;
  // Initialize with null/empty if needed, but here we wait for first user
  Map<String, dynamic>? lastSub;
  
  // Track if we have received at least one event from user stream
  // (Subscription is optional, so we can emit without it initially if needed, 
  // but ideally we wait for both or handle nulls)
  
  // Actually, standard behavior: Wait for User. Subscription can be null.
  
  void update() {
     if (lastUser == null) {
       // If explicitly null (logged out or not found), emit null
       // But if just waiting, we don't emit yet?
       // userAbs emits nullable UserModel.
       controller.add(null);
       return;
     }
     
     // We have a user. Merge sub if available.
     if (lastSub != null) {
        controller.add(lastUser!.copyWith(
          subscriptionTier: lastSub!['subscriptionTier'],
          subscriptionStatus: lastSub!['subscriptionStatus'],
          subscriptionExpiry: (lastSub!['subscriptionExpiry'] as Timestamp?)?.toDate(),
        ));
     } else {
        // No sub data yet (or none exists). Emit user as is.
        controller.add(lastUser);
     }
  }

  // Manage subscriptions
  final userSub = userAbs.listen((u) {
    lastUser = u;
    update();
  });
  
  final subSub = subAbs.listen((s) {
    lastSub = s;
    update();
  });

  controller.onCancel = () {
    userSub.cancel();
    subSub.cancel();
  };

  return controller.stream;
}



// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthProvider));
});

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthService(this._auth);

  // Email/Password Sign Up
  Future<UserCredential?> signUpWithEmail(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await credential.user?.updateDisplayName(name);
      await credential.user?.reload();
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Email/Password Sign In
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // The user canceled the sign-in
        return null; 
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Google Sign In failed: $e';
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Password Reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}
