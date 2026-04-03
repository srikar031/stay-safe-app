import 'package:firebase_auth/firebase_auth.dart';
import 'package:stay_safe_app/services/database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Create user object based on Firebase user
  User? _userFromFirebaseUser(User? user) {
    return user;
  }
  
  // Auth change user stream
  Stream<User?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }
  
  // Sign in with email and password
  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      User? user = result.user;
      return _userFromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      print(e.message);
      return e.message; // Return the error message
    } catch (e) {
      print(e.toString());
      return "An unexpected error occurred";
    }
  }
  
  // Register with email and password
  Future registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      User user = result.user!;
      
      // Create a new document for the user with the uid
      await DatabaseService(uid: user.uid).updateUserData(
        'New User', 
        email.trim(), 
        '', // Custom message will be empty initially
        '', // Country will be set later
      );
      
      return _userFromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      print(e.message);
      return e.message; // Return the error message
    } catch (e) {
      print(e.toString());
      return "An unexpected error occurred";
    }
  }
  
  // Sign out
  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
}