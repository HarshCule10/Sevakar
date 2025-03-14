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
      print('Current user: ${currentUser?.uid ?? "No user logged in"}');

      if (currentUser != null) {
        // Create the chat history entry with a regular DateTime instead of FieldValue.serverTimestamp()
        final chatEntry = {
          'claim': claim,
          'factCheckResult': factCheckResult,
          'timestamp':
              Timestamp.now(), // Use Timestamp.now() instead of FieldValue.serverTimestamp()
          'type': 'factCheck',
        };

        print('Created chat entry for claim: $claim');

        // Get the user document
        DocumentReference userDoc = _firestore
            .collection('users')
            .doc(currentUser.uid);

        print('Attempting to access user document: ${currentUser.uid}');

        // First check if the document exists and has userChatHistory
        DocumentSnapshot docSnapshot = await userDoc.get();

        print('Document exists: ${docSnapshot.exists}');

        if (docSnapshot.exists) {
          Map<String, dynamic> userData =
              docSnapshot.data() as Map<String, dynamic>;

          print('User data fields: ${userData.keys.join(', ')}');

          if (userData.containsKey('userChatHistory')) {
            print('userChatHistory exists, updating array');
            // If userChatHistory exists, update it
            await userDoc.update({
              'userChatHistory': FieldValue.arrayUnion([chatEntry]),
            });
            print('Successfully updated userChatHistory array');
          } else {
            print('userChatHistory does not exist, creating it');
            // If userChatHistory doesn't exist, create it
            await userDoc.set({
              'userChatHistory': [chatEntry],
            }, SetOptions(merge: true));
            print('Successfully created userChatHistory array');
          }
        } else {
          print('Document does not exist, creating it with userChatHistory');
          // If document doesn't exist, create it with userChatHistory
          await userDoc.set({
            'userChatHistory': [chatEntry],
          }, SetOptions(merge: true));
          print('Successfully created user document with userChatHistory');
        }

        // Also save to the factChecks subcollection for backward compatibility
        await userDoc.collection('factChecks').add({
          'claim': claim,
          'factCheckResult': factCheckResult,
          'timestamp':
              FieldValue.serverTimestamp(), // This is fine here because we're using add()
        });

        print('Successfully saved to factChecks subcollection');
        print('Successfully saved fact check to history');
      } else {
        print('Cannot save fact check: No user is currently logged in');
      }
    } catch (e) {
      print('Error saving fact check to history: $e');
      print('Error stack trace: ${StackTrace.current}');
    }
  }

  // Get chat history for current user
  static Future<List<Map<String, dynamic>>> getChatHistory() async {
    try {
      User? currentUser = _auth.currentUser;
      print(
        'Getting chat history for user: ${currentUser?.uid ?? "No user logged in"}',
      );

      if (currentUser != null) {
        print('Attempting to fetch user document');
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        print('Document exists: ${userDoc.exists}');

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          print('User data fields: ${userData.keys.join(', ')}');

          if (userData.containsKey('userChatHistory')) {
            List<dynamic> history = userData['userChatHistory'];
            print('Found ${history.length} chat history items');
            return history.cast<Map<String, dynamic>>();
          } else {
            print('userChatHistory field not found in user document');
          }
        } else {
          print('User document not found');
        }
      } else {
        print('Cannot get chat history: No user is currently logged in');
      }
      return [];
    } catch (e) {
      print('Error getting chat history: $e');
      print('Error stack trace: ${StackTrace.current}');
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
        print('Attempting to delete chat history item');

        // Get the current user document
        DocumentReference userDoc = _firestore
            .collection('users')
            .doc(currentUser.uid);

        // Get the current chat history
        DocumentSnapshot docSnapshot = await userDoc.get();
        if (docSnapshot.exists) {
          final userData = docSnapshot.data() as Map<String, dynamic>;
          if (userData.containsKey('userChatHistory')) {
            List<dynamic> history = userData['userChatHistory'];

            // Find the matching item by claim
            String claimToDelete = chatEntry['claim'] as String;
            print('Looking for item with claim: $claimToDelete');

            // Find and remove the matching item
            List<dynamic> updatedHistory = List.from(history);
            bool found = false;

            for (int i = 0; i < updatedHistory.length; i++) {
              Map<String, dynamic> item =
                  updatedHistory[i] as Map<String, dynamic>;
              if (item['claim'] == claimToDelete) {
                print('Found matching item, removing it');
                updatedHistory.removeAt(i);
                found = true;
                break;
              }
            }

            if (found) {
              // Update the document with the new history
              await userDoc.update({'userChatHistory': updatedHistory});
              print('Successfully deleted chat history item');
            } else {
              print('Item not found in chat history');
            }
          } else {
            print('userChatHistory field not found in user document');
          }
        } else {
          print('User document not found');
        }
      } else {
        print(
          'Cannot delete chat history item: No user is currently logged in',
        );
      }
    } catch (e) {
      print('Error deleting chat history item: $e');
      print('Error stack trace: ${StackTrace.current}');
    }
  }

  // Clear entire chat history
  static Future<void> clearChatHistory() async {
    try {
      User? currentUser = _auth.currentUser;
      print(
        'Attempting to clear chat history for user: ${currentUser?.uid ?? "No user logged in"}',
      );

      if (currentUser != null) {
        DocumentReference userDoc = _firestore
            .collection('users')
            .doc(currentUser.uid);

        // Check if the document exists
        DocumentSnapshot docSnapshot = await userDoc.get();
        if (docSnapshot.exists) {
          await userDoc.update({'userChatHistory': []});
          print('Successfully cleared chat history');
        } else {
          print('User document not found, cannot clear chat history');
        }
      } else {
        print('Cannot clear chat history: No user is currently logged in');
      }
    } catch (e) {
      print('Error clearing chat history: $e');
      print('Error stack trace: ${StackTrace.current}');
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
