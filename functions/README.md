# Firebase Cloud Functions

This directory contains Firebase Cloud Functions for the Livora application.

## Available Functions

### 1. sendChatNotification
- **Type**: Callable Function
- **Purpose**: Sends push notifications for chat messages
- **Trigger**: Called from client app when sending chat messages
- **Parameters**: receiverId, senderId, senderName, message, chatRoomId

### 2. testNotification
- **Type**: HTTP Function
- **Purpose**: Test function to manually send notifications
- **Endpoint**: POST request with receiverId and message

### 3. deleteOldChatMessages ⭐ NEW
- **Type**: Scheduled Function
- **Purpose**: Automatically deletes chat messages older than 7 days from Realtime Database
- **Schedule**: Every day at 12:15 AM UTC
- **Database**: Realtime Database (chatRooms collection)
- **Batch Processing**: Yes, processes messages in batches for efficiency

### 4. deleteExpiredListings ⭐ NEW
- **Type**: Scheduled Function
- **Purpose**: Automatically deletes listings that expired more than 24 hours ago
- **Schedule**: Every hour at minute 0
- **Database**: Firestore (listings collection)
- **Batch Processing**: Yes, processes deletions in batches of 500

## Database Structure Requirements

### For Chat Messages (Realtime Database)
```
chatRooms/
  {roomId}/
    messages/
      {messageId}/
        timestamp: number (milliseconds since epoch)
        message: string
        senderId: string
        // ... other message fields
```

### For Listings (Firestore)
```
listings/
  {listingId}/
    expirationDate: timestamp
    // ... other listing fields
```

## Deployment

1. Install dependencies:
```bash
npm install
```

2. Deploy all functions:
```bash
npm run deploy
```

3. Deploy specific function:
```bash
firebase deploy --only functions:deleteOldChatMessages
firebase deploy --only functions:deleteExpiredListings
```

## Monitoring

Monitor function execution in Firebase Console:
- Go to Functions > Logs
- Filter by function name to see execution logs
- Check for any errors or performance issues

## Cost Optimization

- Both scheduled functions use `maxInstances: 1` to prevent multiple concurrent executions
- Batch processing reduces database operations
- Functions are designed to handle large datasets efficiently

## Testing

Test the scheduled functions manually:
```bash
# Test chat message cleanup
firebase functions:shell
deleteOldChatMessages()

# Test expired listings cleanup
deleteExpiredListings()
```

## Troubleshooting

1. **Function not running**: Check Firebase Console > Functions > Logs for errors
2. **Database permission issues**: Ensure service account has proper read/write permissions
3. **Memory/timeout issues**: Monitor function execution time and memory usage in logs 