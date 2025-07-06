// controllers/auth_controller.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> signUp(String name, String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // تحديث displayName في Firebase Auth
      await userCredential.user!.updateDisplayName(name);
      
      try {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // Firestore failed (e.g., not enabled), but account created. Optionally log or show a warning.
      }
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'حدث خطأ غير متوقع';
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'حدث خطأ غير متوقع';
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'لم يتم العثور على مستخدم بهذا البريد الإلكتروني';
      }
      return e.message ?? 'حدث خطأ أثناء إرسال رابط الاستعادة';
    } catch (e) {
      return 'حدث خطأ غير متوقع أثناء إرسال رابط الاستعادة';
    }
  }
} 