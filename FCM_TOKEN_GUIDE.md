# FCM Token Guide & Cloud Functions Deployment

## **FCM Token Registration & Storage**

### **1. When FCM Tokens Are Generated:**

FCM tokens are automatically generated and managed by Firebase in these scenarios:

- **App Startup**: When the app initializes and requests notification permissions
- **User Login**: When a user logs in (auth state changes)
- **Token Refresh**: Firebase automatically refreshes tokens periodically (every 6-12 months)
- **App Reinstall**: When the app is reinstalled on the device

### **2. Where FCM Tokens Are Stored:**

The app saves FCM tokens in **3 locations**:

#### **A. Firebase Realtime Database**
```
/users/{userId}/
├── fcmToken: "fMEP0vJqS0:APA91bH..."
├── lastTokenUpdate: 1703123456789
└── ... (other user data)
```

#### **B. Firestore Database**
```
/users/{userId}/
├── fcmToken: "fMEP0vJqS0:APA91bH..."
├── lastTokenUpdate: Timestamp
└── ... (other user data)
```

#### **C. Local Storage (SharedPreferences)**
```
Key: 'fcm_token'
Value: "fMEP0vJqS0:APA91bH..."
```

### **3. Token Refresh Process:**

```dart
// The app listens for token refresh automatically
_firebaseMessaging.onTokenRefresh.listen(_saveFCMToken);
```

When Firebase refreshes a token:
1. New token is generated
2. `onTokenRefresh` listener is triggered
3. New token is saved to all 3 locations
4. Old token becomes invalid

## **Cloud Functions Deployment**

### **Step 1: Install Firebase CLI**
```bash
npm install -g firebase-tools
```

### **Step 2: Login to Firebase**
```bash
firebase login
```

### **Step 3: Initialize Functions (if not done)**
```bash
firebase init functions
```
- Select your project
- Choose JavaScript
- Say NO to ESLint
- Say YES to installing dependencies

### **Step 4: Install Dependencies**
```bash
cd functions
npm install
```

### **Step 5: Deploy Functions**
```bash
firebase deploy --only functions
```

## **Testing the Implementation**

### **1. Test Local Notifications**
- Go to Settings → Test Notifications → Test Local Notification
- Should work immediately (foreground only)

### **2. Test Server Notifications**
- Go to Settings → Test Notifications → Test Server Notification
- Requires Cloud Functions to be deployed
- Will send notification even if app is closed

### **3. Test Real Chat Notifications**
1. Send a message to another user
2. Close the app completely
3. Have the other user send you a message
4. You should receive a notification

## **Verification Steps**

### **1. Check FCM Token Storage**
```bash
# Check Firestore
firebase firestore:get /users/{userId}

# Check Realtime Database
firebase database:get /users/{userId}
```

### **2. Check Cloud Functions Logs**
```bash
firebase functions:log
```

### **3. Check Notification Requests**
```bash
# Check Firestore for notification requests
firebase firestore:get /notification_requests
```

## **Troubleshooting**

### **Issue: "Server notifications require Cloud Functions deployment"**
**Solution**: Deploy the Cloud Functions using the steps above.

### **Issue: No FCM token found**
**Causes**:
- User hasn't granted notification permissions
- App hasn't been opened after installation
- Token refresh failed

**Solutions**:
1. Check notification permissions in device settings
2. Restart the app
3. Check Firebase console for errors

### **Issue: Notifications not working in background**
**Causes**:
- Cloud Functions not deployed
- FCM token not saved to Firestore
- Device battery optimization blocking notifications

**Solutions**:
1. Deploy Cloud Functions
2. Check FCM token in Firestore
3. Disable battery optimization for the app

### **Issue: Function deployment fails**
**Common causes**:
- Billing not enabled (Cloud Functions require billing)
- Node.js version mismatch
- Missing dependencies

**Solutions**:
1. Enable billing in Firebase console
2. Use Node.js 18+ (as specified in package.json)
3. Run `npm install` in functions directory

## **Cost Considerations**

- **Free Tier**: 2 million function invocations per month
- **Each notification**: 1 function invocation
- **Storage**: FCM tokens and notification requests count towards Firestore usage

## **Security Rules**

Make sure your Firestore security rules allow:
```javascript
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

## **Monitoring**

### **Firebase Console**
- Functions → Logs: Check function execution
- Firestore → Data: Check notification requests
- Analytics → Events: Check notification delivery

### **Local Testing**
```bash
# Test functions locally
firebase emulators:start --only functions

# Check logs
firebase functions:log --only sendChatNotification
``` 