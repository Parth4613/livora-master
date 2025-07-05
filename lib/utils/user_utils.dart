import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserUtils {
  /// Get the current user's username from Firebase Auth or Firestore
  static Future<String> getCurrentUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Anonymous User';

    // First try to get from Firebase Auth displayName
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }

    // If not available in Auth, try to get from Firestore
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (doc.exists) {
        final data = doc.data();
        final username = data?['username'];
        if (username != null && username.isNotEmpty) {
          return username;
        }
        
        // If username is not available, try to get from email
        final email = data?['email'] ?? user.email;
        if (email != null && email.isNotEmpty) {
          return email.split('@')[0];
        }
      }
    } catch (e) {
      print('Error fetching username from Firestore: $e');
    }

    // Fallback to phone number or email from Auth
    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
      return user.phoneNumber!;
    }
    
    if (user.email != null && user.email!.isNotEmpty) {
      return user.email!.split('@')[0];
    }

    return 'Anonymous User';
  }

  /// Get the current user's phone number
  static Future<String?> getCurrentUserPhone() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // First try to get from Firebase Auth
    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
      return user.phoneNumber!;
    }

    // If not available in Auth, try to get from Firestore
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (doc.exists) {
        final data = doc.data();
        final phone = data?['phone'];
        if (phone != null && phone.isNotEmpty) {
          return phone;
        }
      }
    } catch (e) {
      print('Error fetching phone from Firestore: $e');
    }

    return null;
  }

  /// Get the current user's email
  static Future<String?> getCurrentUserEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // First try to get from Firebase Auth
    if (user.email != null && user.email!.isNotEmpty) {
      return user.email!;
    }

    // If not available in Auth, try to get from Firestore
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (doc.exists) {
        final data = doc.data();
        final email = data?['email'];
        if (email != null && email.isNotEmpty) {
          return email;
        }
      }
    } catch (e) {
      print('Error fetching email from Firestore: $e');
    }

    return null;
  }

  /// Get current user ID
  static String? getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  /// Check if user is logged in
  static bool isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }
} 