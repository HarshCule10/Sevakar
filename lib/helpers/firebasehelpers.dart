import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save fact check to Firebase
  static Future<void> saveFactCheck(
    String claim,
    Map<String, dynamic> factCheckResult,
  ) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Create the chat history entry
        final chatEntry = {
          'claim': claim,
          'factCheckResult': factCheckResult,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'factCheck',
        };

        // Get the user document
        DocumentReference userDoc = _firestore
            .collection('users')
            .doc(currentUser.uid);

        // Update the user document to add the new chat entry
        await userDoc.update({
          'userChatHistory': FieldValue.arrayUnion([chatEntry]),
        });

        // Also save to the factChecks subcollection for backward compatibility
        await userDoc.collection('factChecks').add({
          'claim': claim,
          'factCheckResult': factCheckResult,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error saving fact check to history: $e');
    }
  }

  // Get chat history for current user
  static Future<List<Map<String, dynamic>>> getChatHistory() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          if (userData.containsKey('userChatHistory')) {
            List<dynamic> history = userData['userChatHistory'];
            return history.cast<Map<String, dynamic>>();
          }
        }
      }
      return [];
    } catch (e) {
      print('Error getting chat history: $e');
      return [];
    }
  }

  // Delete a chat history item
  static Future<void> deleteChatHistoryItem(
    Map<String, dynamic> chatEntry,
  ) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentReference userDoc = _firestore
            .collection('users')
            .doc(currentUser.uid);

        await userDoc.update({
          'userChatHistory': FieldValue.arrayRemove([chatEntry]),
        });
      }
    } catch (e) {
      print('Error deleting chat history item: $e');
    }
  }

  // Clear entire chat history
  static Future<void> clearChatHistory() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentReference userDoc = _firestore
            .collection('users')
            .doc(currentUser.uid);

        await userDoc.update({'userChatHistory': []});
      }
    } catch (e) {
      print('Error clearing chat history: $e');
    }
  }

  // Get fact check history for current user (legacy method)
  static Future<List<DocumentSnapshot>> getFactCheckHistory() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        QuerySnapshot querySnapshot =
            await _firestore
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

  // Delete a fact check history item (legacy method)
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
