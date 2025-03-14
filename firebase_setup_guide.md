# Firebase Setup Guide

## Deploying Firestore Security Rules

The error you're seeing is due to insufficient permissions in your Firestore security rules. Follow these steps to update your security rules:

1. **Open Firebase Console**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project (Sevakar)

2. **Navigate to Firestore Database**
   - In the left sidebar, click on "Firestore Database"

3. **Update Security Rules**
   - Click on the "Rules" tab
   - Replace the existing rules with the following:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read and write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow access to subcollections
      match /{subcollection}/{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

4. **Publish the Rules**
   - Click the "Publish" button to apply the new rules

## Alternative: Using Firebase CLI

If you prefer using the command line:

1. **Install Firebase CLI** (if not already installed)
   ```
   npm install -g firebase-tools
   ```

2. **Login to Firebase**
   ```
   firebase login
   ```

3. **Initialize Firebase in your project** (if not already done)
   ```
   firebase init firestore
   ```

4. **Deploy the Rules**
   - Make sure the `firestore.rules` file contains the rules above
   - Run:
   ```
   firebase deploy --only firestore:rules
   ```

## Testing the App

After updating the security rules, try using the app again. The chat history feature should now work correctly, allowing you to:
- Save fact checks to your user profile
- View your fact check history
- Delete items from your history

If you continue to experience issues, check the Firebase console logs for more detailed error messages. 