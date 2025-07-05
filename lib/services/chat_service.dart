import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../api/firebase_api.dart';
import '../services/user_service.dart';
import '../utils/user_utils.dart';

class ChatService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseApi _firebaseApi = FirebaseApi.instance;
  final UserService _userService = UserService();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Send a message
  Future<void> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    if (currentUserId == null) return;

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: currentUserId!,
      receiverId: receiverId,
      content: content,
      timestamp: DateTime.now(),
    );

    // Create a chat room ID (sorted to ensure consistency)
    final List<String> ids = [currentUserId!, receiverId];
    ids.sort();
    final String chatRoomId = ids.join('_');

    final chatRoomRef = _database.child('chat_rooms').child(chatRoomId);
    final metadataRef = chatRoomRef.child('metadata');
    final metadataSnapshot = await metadataRef.get();

    // Always set participants at the root for query support
    await chatRoomRef.update({
      'participants': {
        currentUserId: true,
        receiverId: true,
      },
    });

    if (metadataSnapshot.value == null) {
      // First message: create metadata with participants
      await metadataRef.set({
        'participants': {
          currentUserId: true,
          receiverId: true,
        },
        'lastMessage': content,
        'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
        'lastSenderId': currentUserId,
        'lastMessageId': '', // will update after message is sent
      });
    }

    // Add message to chat room
    final messageRef = chatRoomRef.child('messages').push();
    await messageRef.set(message.toMap());

    // Update chat room metadata with last message info (do NOT overwrite participants)
    await metadataRef.update({
      'lastMessage': content,
      'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
      'lastSenderId': currentUserId,
      'lastMessageId': messageRef.key,
    });

    // Trigger server-side notification
    await _triggerServerNotification(receiverId, content, chatRoomId);
  }

  Future<void> _triggerServerNotification(
    String receiverId, 
    String message, 
    String chatRoomId
  ) async {
    try {
      // Get sender's name
      final senderName = await _getCurrentUserName();
      
      // Write to Firestore to trigger Cloud Function
      await FirebaseFirestore.instance
          .collection('notification_requests')
          .add({
        'receiverId': receiverId,
        'senderId': currentUserId,
        'senderName': senderName,
        'message': message,
        'chatRoomId': chatRoomId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'chat_message',
        'status': 'pending',
      });
      
      print('Server notification triggered for $receiverId');
    } catch (e) {
      print('Error triggering server notification: $e');
    }
  }

  Future<String> _getCurrentUserName() async {
    try {
      return await UserUtils.getCurrentUsername();
    } catch (e) {
      return 'User';
    }
  }

  // Get messages stream for a specific chat
  Stream<List<ChatMessage>> getMessages(String otherUserId) {
    if (currentUserId == null) return Stream.value([]);

    final List<String> ids = [currentUserId!, otherUserId];
    ids.sort();
    final String chatRoomId = ids.join('_');

    return _database
        .child('chat_rooms')
        .child(chatRoomId)
        .child('messages')
        .orderByChild('timestamp')
        .onValue
        .handleError((error) {
          print('Error getting messages: $error');
          return <ChatMessage>[];
        })
        .map((event) {
          if (event.snapshot.value == null) return <ChatMessage>[];
          
          final Map<dynamic, dynamic> messagesMap = 
              event.snapshot.value as Map<dynamic, dynamic>;
          
          final List<ChatMessage> messages = [];
          messagesMap.forEach((key, value) {
            if (value is Map) {
              try {
                final messageData = Map<String, dynamic>.from(value);
                messageData['id'] = key.toString();
                messages.add(ChatMessage.fromRealtimeDatabase(messageData));
              } catch (e) {
                print('Error parsing message: $e');
              }
            }
          });
          
          // Sort by timestamp (newest first)
          messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return messages;
        });
  }

  // Get all chat rooms for current user
  Stream<List<Map<String, dynamic>>> getChatRooms() {
    if (currentUserId == null) return Stream.value([]);

    return _database
        .child('chat_rooms')
        .orderByChild('participants/$currentUserId')
        .equalTo(true)
        .onValue
        .handleError((error) {
          print('Error getting chat rooms: $error');
          return <Map<String, dynamic>>[];
        })
        .map((event) {
          if (event.snapshot.value == null) return <Map<String, dynamic>>[];
          
          final Map<dynamic, dynamic> chatRoomsMap = 
              event.snapshot.value as Map<dynamic, dynamic>;
          
          final List<Map<String, dynamic>> chatRooms = [];
          chatRoomsMap.forEach((key, value) {
            if (value is Map) {
              try {
                final chatRoomData = Map<String, dynamic>.from(
                  (value as Map).map((k, v) => MapEntry(k.toString(), v))
                );
                final metadata = chatRoomData['metadata'] is Map
                    ? Map<String, dynamic>.from((chatRoomData['metadata'] as Map).map((k, v) => MapEntry(k.toString(), v)))
                    : null;
                final participants = chatRoomData['participants'] is Map
                    ? Map<String, dynamic>.from((chatRoomData['participants'] as Map).map((k, v) => MapEntry(k.toString(), v)))
                    : null;
                if (metadata != null && participants != null && participants[currentUserId] == true) {
                  chatRooms.add({
                    'id': key.toString(),
                    ...metadata,
                    'participants': participants,
                  });
                }
              } catch (e) {
                print('Error parsing chat room: $e');
              }
            }
          });
          // Sort by last message time (newest first)
          chatRooms.sort((a, b) {
            final aTime = a['lastMessageTime'] ?? 0;
            final bTime = b['lastMessageTime'] ?? 0;
            return bTime.compareTo(aTime);
          });
          return chatRooms;
        });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatRoomId) async {
    if (currentUserId == null) return;

    final messagesRef = _database.child('chat_rooms').child(chatRoomId).child('messages');
    final query = messagesRef.orderByChild('receiverId').equalTo(currentUserId);
    
    final snapshot = await query.get();
    if (snapshot.value == null) return;
    
    final Map<dynamic, dynamic> messagesMap = 
        snapshot.value as Map<dynamic, dynamic>;
    
    final Map<String, dynamic> updates = {};
    messagesMap.forEach((key, value) {
      if (value is Map) {
        final messageData = Map<String, dynamic>.from(value);
        if (messageData['isRead'] != true) {
          updates['chat_rooms/$chatRoomId/messages/$key/isRead'] = true;
        }
      }
    });
    
    if (updates.isNotEmpty) {
      await _database.update(updates);
    }
  }

  // Get unread message count for a specific chat
  Stream<int> getUnreadMessageCount(String otherUserId) {
    if (currentUserId == null) return Stream.value(0);

    final List<String> ids = [currentUserId!, otherUserId];
    ids.sort();
    final String chatRoomId = ids.join('_');

    return _database
        .child('chat_rooms')
        .child(chatRoomId)
        .child('messages')
        .orderByChild('receiverId')
        .equalTo(currentUserId)
        .onValue
        .map((event) {
          if (event.snapshot.value == null) return 0;
          
          final Map<dynamic, dynamic> messagesMap = 
              event.snapshot.value as Map<dynamic, dynamic>;
          
          int unreadCount = 0;
          messagesMap.forEach((key, value) {
            if (value is Map) {
              final messageData = Map<String, dynamic>.from(value);
              if (messageData['isRead'] != true) {
                unreadCount++;
              }
            }
          });
          
          return unreadCount;
        });
  }

  // Delete a message
  Future<void> deleteMessage(String chatRoomId, String messageId) async {
    await _database
        .child('chat_rooms')
        .child(chatRoomId)
        .child('messages')
        .child(messageId)
        .remove();
  }

  // Delete entire chat room
  Future<void> deleteChatRoom(String chatRoomId) async {
    await _database
        .child('chat_rooms')
        .child(chatRoomId)
        .remove();
  }
} 