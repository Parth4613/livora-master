import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import '../payment_success_page.dart';
import 'razorpay_inapp_service.dart';

class EfficientPaymentService {
  static final EfficientPaymentService _instance = EfficientPaymentService._internal();
  factory EfficientPaymentService() => _instance;
  EfficientPaymentService._internal();

  // Razorpay configuration
  static const String _razorpayKey = 'rzp_test_O9xBxveMFHkkdp';
  static const String _razorpaySecret = '540ObIojNTJlPoQMdZsdXoyX';
  
  // Your backend API URL (update this with your deployed backend URL)
  static String get _backendUrl {
    if (kIsWeb) {
      return 'http://localhost:3000'; // For web development
    } else {
      // For Android device - try multiple URLs
      // Uncomment the line below for testing with localhost
      return 'http://localhost:3000'; // For testing - use this if IP address fails
      // return 'http://10.92.18.47:3000'; // For real Android device
    }
  }
  // static const String _backendUrl = 'https://your-production-backend.com'; // For production

  // Test backend connectivity
  static Future<bool> testBackendConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Backend connectivity test failed: $e');
      return false;
    }
  }

  Future<void> processPremiumPlanPayment({
    required String planName,
    required double amount,
    required BuildContext context,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackBar(context, 'User not authenticated');
      return;
    }

    try {
      // Use Razorpay payment link for all platforms
      final paymentLinkUrl = await _createPaymentLinkWeb(
        'premium_plan',
        planName,
        amount,
        user.uid, // Use userId as a unique identifier for premium plan
        user.uid,
      );
      if (paymentLinkUrl == null) {
        throw Exception('Failed to get payment link URL');
      }
      if (kIsWeb) {
        // On web, open payment link in a new tab
        if (await canLaunchUrl(Uri.parse(paymentLinkUrl))) {
          await launchUrl(Uri.parse(paymentLinkUrl), mode: LaunchMode.externalApplication);
        } else {
          _showErrorSnackBar(context, 'Could not open payment link');
        }
      } else {
        // On mobile, open payment link in browser
        if (await canLaunchUrl(Uri.parse(paymentLinkUrl))) {
          await launchUrl(Uri.parse(paymentLinkUrl), mode: LaunchMode.externalApplication);
        } else {
          _showErrorSnackBar(context, 'Could not open payment link');
        }
      }
    } catch (e) {
      print('Payment error: $e');
      _showErrorSnackBar(context, 'Payment failed: $e');
    }
  }

  Future<void> processListingPayment({
    required String listingType,
    required String planName,
    required double amount,
    required String listingId,
    required BuildContext context,
  }) async {
    print('EfficientPaymentService.processListingPayment called');
    print('Listing Type: $listingType, Plan: $planName, Amount: $amount, Listing ID: $listingId');
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not authenticated');
      _showErrorSnackBar(context, 'User not authenticated');
      return;
    }

    // Test backend connectivity first
    final isBackendConnected = await testBackendConnectivity();
    if (!isBackendConnected) {
      _showErrorSnackBar(context, 'Unable to connect to payment server. Please check your internet connection and try again.');
      return;
    }

    try {
      if (kIsWeb) {
        print('Processing web payment with Razorpay Payment Link');
        // Create payment link on backend
        final paymentLinkUrl = await _createPaymentLinkWeb(listingType, planName, amount, listingId, user.uid);
        if (paymentLinkUrl == null) {
          throw Exception('Failed to get payment link URL');
        }
        if (await canLaunchUrl(Uri.parse(paymentLinkUrl))) {
          await launchUrl(Uri.parse(paymentLinkUrl), mode: LaunchMode.externalApplication);
        } else {
          _showErrorSnackBar(context, 'Could not open payment link');
        }
      } else {
        print('Processing mobile payment with RazorpayInAppService');
        // Mobile implementation - use Razorpay In-App WebView
        await RazorpayInAppService().processListingPayment(
          listingType: listingType,
          planName: planName,
          amount: amount,
          listingId: listingId,
          context: context,
        );
      }
      print('Payment processing completed successfully');
    } catch (e) {
      print('Payment error in EfficientPaymentService: $e');
      _showErrorSnackBar(context, 'Payment failed: $e');
    }
  }

  Future<Map<String, dynamic>> _createOrder(String planName, double amount, String userId) async {
    try {
      final int amountPaise = (amount * 100).round();
      final response = await http.post(
        Uri.parse('$_backendUrl/api/orders/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amountPaise,
          'currency': 'INR',
          'receipt': 'receipt_${DateTime.now().millisecondsSinceEpoch}',
          'notes': {
            'planName': planName,
            'userId': userId,
            'type': 'premium_plan',
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['order'];
      } else {
        throw Exception('Failed to create order: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating order: $e');
      throw Exception('Failed to create order: $e');
    }
  }

  Future<String?> _createPaymentLinkWeb(String listingType, String planName, double amount, String listingId, String userId) async {
    // DO NOT multiply by 100 here; backend does it
    final response = await http.post(
      Uri.parse('$_backendUrl/api/payment-links/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': amount, // rupees
        'currency': 'INR',
        'description': 'Listing Payment: $planName',
        'customer': {
          'name': FirebaseAuth.instance.currentUser?.displayName ?? 'User',
          'email': FirebaseAuth.instance.currentUser?.email ?? 'test@example.com',
          'contact': '9875067129',
        },
        'notes': {
          'planName': planName,
          'listingType': listingType,
          'listingId': listingId,
          'userId': userId,
          'type': 'listing',
        },
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['payment_link']?['short_url'];
    } else {
      print('Failed to create payment link: ${response.statusCode}');
      return null;
    }
  }

  Future<void> _processWebPayment(Map<String, dynamic> order, BuildContext context) async {
    // Web implementation - open payment URL in new tab
    final paymentUrl = 'https://checkout.razorpay.com/v1/checkout.html?' +
        'key=${_razorpayKey}' +
        '&amount=${order['amount']}' +
        '&currency=${order['currency']}' +
        '&name=Buddy%20App' +
        '&description=Premium%20Plan%20Payment' +
        '&order_id=${order['id']}' +
        '&prefill[name]=${Uri.encodeComponent(FirebaseAuth.instance.currentUser?.displayName ?? '')}' +
        '&prefill[email]=${Uri.encodeComponent(FirebaseAuth.instance.currentUser?.email ?? '')}' +
        '&theme[color]=3B82F6';

    final uri = Uri.parse(paymentUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      
      // Show a dialog to guide user back to app
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('Payment in Progress'),
            content: Text('Please complete the payment in your browser and return to the app.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Check payment status
                  _checkPaymentStatus(order['id'], context);
                },
                child: Text('I\'ve Completed Payment'),
              ),
            ],
          ),
        );
      }
    } else {
      _showErrorSnackBar(context, 'Could not open payment page');
    }
  }

  Future<void> _processMobilePayment(Map<String, dynamic> order, BuildContext context) async {
    // Mobile implementation - open payment URL in browser
    final paymentUrl = 'https://checkout.razorpay.com/v1/checkout.html?' +
        'key=${_razorpayKey}' +
        '&amount=${order['amount']}' +
        '&currency=${order['currency']}' +
        '&name=Buddy%20App' +
        '&description=Premium%20Plan%20Payment' +
        '&order_id=${order['id']}' +
        '&prefill[name]=${Uri.encodeComponent(FirebaseAuth.instance.currentUser?.displayName ?? '')}' +
        '&prefill[email]=${Uri.encodeComponent(FirebaseAuth.instance.currentUser?.email ?? '')}' +
        '&theme[color]=3B82F6';

    final uri = Uri.parse(paymentUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      
      // Show a dialog to guide user back to app
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('Payment in Progress'),
            content: Text('Please complete the payment in your browser and return to the app.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Check payment status
                  _checkPaymentStatus(order['id'], context);
                },
                child: Text('I\'ve Completed Payment'),
              ),
            ],
          ),
        );
      }
    } else {
      _showErrorSnackBar(context, 'Could not open payment page');
    }
  }

  Future<void> _handlePaymentSuccess(Map<String, dynamic> response, BuildContext context) async {
    try {
      // Verify payment signature (in production, do this on your backend)
      final paymentId = response['razorpay_payment_id'];
      final orderId = response['razorpay_order_id'];
      final signature = response['razorpay_signature'];

      // Save payment record
      await FirebaseFirestore.instance
          .collection('payments')
          .add({
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'paymentId': paymentId,
        'orderId': orderId,
        'signature': signature,
        'amount': response['amount'] / 100, // Convert from paise
        'currency': 'INR',
        'status': 'success',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Process the payment based on type
      await _processPaymentSuccess(response, context);
    } catch (e) {
      print('Error handling payment success: $e');
      _showErrorSnackBar(context, 'Error processing payment: $e');
    }
  }

  Future<void> _processPaymentSuccess(Map<String, dynamic> response, BuildContext context) async {
    // Get order details to determine payment type
    final orderId = response['razorpay_order_id'];
    
    // In production, fetch order details from your backend
    // For now, we'll process based on the order ID pattern
    if (orderId.contains('premium')) {
      await _activatePremiumPlan(response, context);
    } else {
      await _activateListing(response, context);
    }
  }

  Future<void> _activatePremiumPlan(Map<String, dynamic> response, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final now = DateTime.now();
      // Determine plan name and duration
      String planName = response['planName'] ?? 'Precision Pro';
      int days = 0;
      switch (planName) {
        case 'Express Hunt':
          days = 7;
          break;
        case 'Prime Seeker':
        case 'Precision Pro':
          days = 30;
          break;
        default:
          days = 30;
      }
      final expiresAt = now.add(Duration(days: days));
      final planObj = {
        'name': planName,
        'activatedAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'paymentId': response['razorpay_payment_id'],
      };

      // Get existing plans and update
      final userData = await userDoc.get();
      List<Map<String, dynamic>> updatedPlans = [];
      if (userData.exists && userData.data()!.containsKey('plans')) {
        updatedPlans = List<Map<String, dynamic>>.from(userData.data()!['plans']);
      }
      // Remove any existing plan with same name
      updatedPlans.removeWhere((p) => p['name'] == planName);
      updatedPlans.add(planObj);

      await userDoc.set({
        'plans': updatedPlans
      }, SetOptions(merge: true));

      // Navigate to success page
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PaymentSuccessPage(
              title: 'Premium Plan Activated!',
              message: 'Your premium plan is now active. Enjoy enhanced features!',
              onContinue: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error activating premium plan: $e');
      _showErrorSnackBar(context, 'Error activating plan: $e');
    }
  }

  Future<void> _activateListing(Map<String, dynamic> response, BuildContext context) async {
    try {
      final paymentId = response['razorpay_payment_id'];
      final orderId = response['razorpay_order_id'];
      
      // Get order details from backend to determine listing type and ID
      final orderResponse = await http.get(
        Uri.parse('$_backendUrl/api/orders/$orderId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (orderResponse.statusCode == 200) {
        final orderData = jsonDecode(orderResponse.body);
        final notes = orderData['order']['notes'] ?? {};
        final listingType = notes['listingType'] ?? '';
        final listingId = notes['listingId'] ?? '';
        final planName = notes['planName'] ?? '';

        if (listingId.isNotEmpty) {
          // Update the listing to make it visible
          final collectionName = _getCollectionName(listingType);
          
          await FirebaseFirestore.instance
              .collection(collectionName)
              .doc(listingId)
              .update({
            'visibility': true,
            'paymentStatus': 'completed',
            'paymentId': paymentId,
            'orderId': orderId,
            'planName': planName,
            'activatedAt': FieldValue.serverTimestamp(),
            'paymentCompletedAt': FieldValue.serverTimestamp(),
          });

          // Save detailed payment record
          await FirebaseFirestore.instance
              .collection('payments')
              .add({
            'userId': FirebaseAuth.instance.currentUser?.uid,
            'paymentId': paymentId,
            'orderId': orderId,
            'signature': response['razorpay_signature'],
            'amount': response['amount'] / 100, // Convert from paise
            'currency': 'INR',
            'type': 'listing',
            'listingType': listingType,
            'planName': planName,
            'listingId': listingId,
            'status': 'success',
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Navigate to success page
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => PaymentSuccessPage(
                  title: 'Payment Successful!',
                  message: 'Your listing is now active and visible to users.',
                  orderId: orderId,
                  onContinue: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ),
            );
          }
        } else {
          throw Exception('Listing ID not found in order');
        }
      } else {
        throw Exception('Failed to fetch order details');
      }
    } catch (e) {
      print('Error activating listing: $e');
      _showErrorSnackBar(context, 'Error activating listing: $e');
    }
  }

  String _getCollectionName(String listingType) {
    switch (listingType) {
      case 'list_hostelpg':
        return 'hostel_listings';
      case 'list_room':
        return 'room_listings';
      case 'list_service':
        return 'service_listings';
      case 'room_request':
        return 'roomRequests';
      default:
        return 'listings';
    }
  }

  Future<void> _checkPaymentStatus(String orderId, BuildContext context) async {
    try {
      // In a real implementation, you would get payment details from the payment response
      // For now, we'll simulate the verification with mock data
      // In production, this should be called with actual payment response data
      
      // Simulate payment verification
      final response = await http.post(
        Uri.parse('$_backendUrl/api/payments/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'razorpay_order_id': orderId,
          'razorpay_payment_id': 'pay_${DateTime.now().millisecondsSinceEpoch}', // This should come from payment response
          'razorpay_signature': 'signature_${DateTime.now().millisecondsSinceEpoch}', // This should come from payment response
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          // Payment verified successfully - simulate success response
          await _handlePaymentSuccess({
            'razorpay_payment_id': data['payment_id'] ?? 'pay_${DateTime.now().millisecondsSinceEpoch}',
            'razorpay_order_id': orderId,
            'razorpay_signature': 'verified_signature',
            'amount': 9900, // This should come from actual payment
          }, context);
        } else {
          _showErrorSnackBar(context, 'Payment verification failed: ${data['error']}');
        }
      } else {
        _showErrorSnackBar(context, 'Payment verification failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking payment status: $e');
      _showErrorSnackBar(context, 'Error verifying payment: $e');
    }
  }

  Future<Map<String, dynamic>?> getPaymentStatus(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/api/orders/$orderId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['order'];
      } else {
        print('Failed to get payment status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting payment status: $e');
      return null;
    }
  }

  Future<void> retryPayment(String orderId, BuildContext context) async {
    try {
      final orderDetails = await getPaymentStatus(orderId);
      if (orderDetails != null) {
        final notes = orderDetails['notes'] ?? {};
        final listingType = notes['listingType'] ?? '';
        final planName = notes['planName'] ?? '';
        final listingId = notes['listingId'] ?? '';
        final amount = (orderDetails['amount'] ?? 0) / 100; // Convert from paise

        await processListingPayment(
          listingType: listingType,
          planName: planName,
          amount: amount,
          listingId: listingId,
          context: context,
        );
      } else {
        _showErrorSnackBar(context, 'Could not retrieve order details');
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Error retrying payment: $e');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
} 