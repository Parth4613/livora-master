# Firebase Backend Setup & API Guide for Livora

This guide explains how to set up and use the Firebase backend for the Livora project, with a focus on integrating with a React.js web app.

---

## 1. Firebase Project Configuration

**Project ID:** `application-livora`

### Web App Config (for React)
Use these values in your React app's Firebase initialization:
```js
const firebaseConfig = {
  apiKey: 'AIzaSyAN9R-zNvN8qZ2SO7y4rLu5kwL1BRL_ehU',
  authDomain: 'application-livora.firebaseapp.com',
  projectId: 'application-livora',
  storageBucket: 'application-livora.firebasestorage.app',
  messagingSenderId: '796925603688',
  appId: '1:796925603688:web:126de4bf7094f5d80fb0dd',
};
```

---

## 2. Firebase Services Used
- **Authentication** (Email/Password, Google, etc.)
- **Firestore** (User data, chat, notification requests)
- **Realtime Database** (User FCM tokens, legacy data)
- **Cloud Functions** (Notifications, backend logic)
- **Cloud Messaging (FCM)** (Push notifications)

---

## 3. Firestore Data Structure

### Users
```
/users/{userId}/
  fcmToken: string
  lastTokenUpdate: timestamp
  ...other user data
```

### Notification Requests
```
/notification_requests/{requestId}/
  type: 'chat_message' | ...
  receiverId: string
  senderId: string
  senderName: string
  message: string
  chatRoomId: string
  status: 'pending' | 'sent' | 'error'
  sentAt: timestamp
  fcmResponse: string
  error: string
  errorAt: timestamp
```

---

## 4. Cloud Functions (APIs)

### 4.1. Send Chat Notification (Triggered by Firestore)
- **Trigger:** New document in `/notification_requests/`
- **Action:** Sends FCM push notification to the receiver's device/web.
- **No direct REST endpoint.**

### 4.2. Test Notification (REST API)
- **Endpoint:** `POST https://<your-region>-<your-project-id>.cloudfunctions.net/testNotification`
- **Body:**
  ```json
  {
    "receiverId": "<userId>",
    "message": "Hello from web!"
  }
  ```
- **Response:**
  - `{ success: true, messageId, message }` on success
  - `{ error }` on failure

- **CORS:** Enabled for all origins.

---

## 5. FCM Token Handling
- FCM tokens are generated on client (mobile/web) and saved to:
  - Firestore: `/users/{userId}/fcmToken`
  - Realtime DB: `/users/{userId}/fcmToken`
- Tokens are refreshed and updated automatically.

---

## 6. Security Rules (Firestore)
```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /notification_requests/{document} {
      allow write: if request.auth != null;
    }
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## 7. How to Integrate with React.js Web App

### a. Install Firebase SDK
```bash
npm install firebase
```

### b. Initialize Firebase
```js
import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getMessaging, getToken, onMessage } from 'firebase/messaging';

const firebaseConfig = { /* see above */ };
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
const messaging = getMessaging(app);
```

### c. Save FCM Token to Firestore
```js
import { doc, setDoc } from 'firebase/firestore';

async function saveFcmToken(userId, token) {
  await setDoc(doc(db, 'users', userId), { fcmToken: token }, { merge: true });
}
```

### d. Call Cloud Function (Test Notification)
```js
async function sendTestNotification(receiverId, message) {
  const res = await fetch('https://<your-region>-<your-project-id>.cloudfunctions.net/testNotification', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ receiverId, message })
  });
  return res.json();
}
```

---

## 8. Troubleshooting
- Ensure Cloud Functions are deployed: `firebase deploy --only functions`
- Check Firestore for FCM tokens and notification requests
- Use Firebase Console for logs and debugging

---

## 9. References
- [FCM Token Guide](../FCM_TOKEN_GUIDE.md)
- [Firebase Functions Docs](https://firebase.google.com/docs/functions)
- [Firebase Web Setup](https://firebase.google.com/docs/web/setup) 