import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get userChanges => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> register(String email, String password) async {
    final userCred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Tạo document user với setupCompleted = false
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userCred.user!.uid)
        .set({
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'displayName': '',
      'photoUrl': null,
      'setupCompleted': false,
    });

    return userCred;
  }

  Future<bool> hasCompletedSetup() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.exists && (doc.data()?['setupCompleted'] == true);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
