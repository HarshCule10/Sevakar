import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save fact check to Firebase
  static Future<void> saveFactCheck(String claim, Map<String, dynamic> factCheckResult) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('factChecks')
            .add({
              'claim': claim,
              'factCheckResult': factCheckResult,
              'timestamp': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      print('Error saving fact check to history: $e');
    }
  }

  // Get fact check history for current user
  static Future<List<DocumentSnapshot>> getFactCheckHistory() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        QuerySnapshot querySnapshot = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('factChecks')
            .orderBy('timestamp', descending: true)
            .get();
        
        return querySnapshot.docs;
      }
      return [];
    } catch (e) {
      print('Error getting fact check history: $e');
      return [];
    }
  }

  // Delete a fact check history item
  static Future<void> deleteFactCheck(String factCheckId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('factChecks')
            .doc(factCheckId)
            .delete();
      }
    } catch (e) {
      print('Error deleting fact check: $e');
    }
  }
}