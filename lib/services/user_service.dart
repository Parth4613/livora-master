import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get user data by ID
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error fetching user data from Firestore: $e');
      return null;
    }
  }

  /// Get current user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final userId = currentUserId;
    if (userId == null) return null;
    return await getUserData(userId);
  }

  /// Update user data
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _database.child('users').child(userId).update(data);
    } catch (e) {
      print('Error updating user data: $e');
      rethrow;
    }
  }

  /// Update current user data
  Future<void> updateCurrentUserData(Map<String, dynamic> data) async {
    final userId = currentUserId;
    if (userId == null) return;
    await updateUserData(userId, data);
  }

  /// Get user's online status
  Stream<bool> getUserOnlineStatus(String userId) {
    return _database
        .child('users')
        .child(userId)
        .child('online')
        .onValue
        .map((event) {
          if (event.snapshot.value == null) return false;
          return event.snapshot.value as bool;
        });
  }

  /// Set current user's online status
  Future<void> setOnlineStatus(bool isOnline) async {
    final userId = currentUserId;
    if (userId == null) return;
    
    try {
      await _database.child('users').child(userId).child('online').set(isOnline);
      
      // Set last seen timestamp when going offline
      if (!isOnline) {
        await _database.child('users').child(userId).child('lastSeen').set(
          DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (e) {
      print('Error setting online status: $e');
    }
  }

  /// Get user's last seen timestamp
  Future<DateTime?> getLastSeen(String userId) async {
    try {
      final snapshot = await _database.child('users').child(userId).child('lastSeen').get();
      if (snapshot.value != null) {
        final timestamp = snapshot.value as int;
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      print('Error fetching last seen: $e');
      return null;
    }
  }

  /// Search users by username
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final snapshot = await _database.child('users').get();
      if (snapshot.value == null) return [];
      
      final Map<dynamic, dynamic> usersMap = 
          snapshot.value as Map<dynamic, dynamic>;
      
      final List<Map<String, dynamic>> results = [];
      usersMap.forEach((key, value) {
        if (value is Map) {
          final userData = Map<String, dynamic>.from(value);
          final username = userData['username']?.toString().toLowerCase() ?? '';
          
          if (username.contains(query.toLowerCase())) {
            userData['id'] = key.toString();
            results.add(userData);
          }
        }
      });
      
      return results;
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  /// Check if current user has any active premium plan
  static Future<bool> hasActivePlan() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (userDoc.exists && userDoc.data() != null && userDoc.data()!.containsKey('plans')) {
      final plansRaw = userDoc['plans'];
      if (plansRaw is List) {
        final now = DateTime.now();
        for (final plan in plansRaw) {
          if (plan is Map && plan['expiresAt'] != null) {
            final expiresAt = (plan['expiresAt'] as Timestamp).toDate();
            if (expiresAt.isAfter(now)) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  /// Check if current user has any active listing (not expired)
  static Future<bool> hasActiveListing() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final uid = user.uid;
    final now = DateTime.now();
    // Helper to check expiry
    bool isActive(dynamic expiry) {
      if (expiry == null) return true; // If no expiry, treat as active (legacy)
      if (expiry is Timestamp) return expiry.toDate().isAfter(now);
      if (expiry is String) {
        final dt = DateTime.tryParse(expiry);
        if (dt == null) return true;
        return dt.isAfter(now);
      }
      return true;
    }
    // Check all listing types
    final checks = [
      FirebaseFirestore.instance.collection('room_listings').where('userId', isEqualTo: uid).get(),
      FirebaseFirestore.instance.collection('hostel_listings').where('uid', isEqualTo: uid).get(),
      FirebaseFirestore.instance.collection('service_listings').where('userId', isEqualTo: uid).get(),
      FirebaseFirestore.instance.collection('roomRequests').where('userId', isEqualTo: uid).get(),
    ];
    for (final snapFuture in checks) {
      final snap = await snapFuture;
      for (final doc in snap.docs) {
        final data = doc.data();
        if (isActive(data['expiryDate'])) {
          return true;
        }
      }
    }
    return false;
  }
} 