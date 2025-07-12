import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import '../payment_success_page.dart';
import 'google_play_billing_service.dart';
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
      return 'http://10.92.18.47:3000'; // For real Android device
    }
  }
  // static const String _backendUrl = 'https://your-production-backend.com'; // For production

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
      if (kIsWeb) {
        // Web implementation - use Razorpay
        final order = await _createOrder(planName, amount, user.uid);
        await _processWebPayment(order, context);
      } else {
        // Mobile implementation - use Google Play Billing
        await GooglePlayBillingService().processPremiumPlanPayment(
          planName: planName,
          amount: amount,
          context: context,
        );
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

    try {
      if (kIsWeb) {
        print('Processing web payment');
        // Web implementation - use browser-based Razorpay
        final order = await _createListingOrder(listingType, planName, amount, listingId, user.uid);
        await _processWebPayment(order, context);
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
      final response = await http.post(
        Uri.parse('$_backendUrl/api/orders/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
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

  Future<Map<String, dynamic>> _createListingOrder(String listingType, String planName, double amount, String listingId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/orders/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'currency': 'INR',
          'receipt': 'receipt_${DateTime.now().millisecondsSinceEpoch}',
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
        return data['order'];
      } else {
        throw Exception('Failed to create listing order: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating listing order: $e');
      throw Exception('Failed to create listing order: $e');
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
      
      // For now, we'll activate a default plan
      // In production, get plan details from order
      const planName = 'Precision Pro';
      const days = 30;
      
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
      // Update listing with payment info
      // In production, get listing details from order
      final paymentId = response['razorpay_payment_id'];
      
      // For now, we'll just show success
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PaymentSuccessPage(
              title: 'Payment Successful!',
              message: 'Your listing is now active and visible to users.',
              onContinue: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error activating listing: $e');
      _showErrorSnackBar(context, 'Error activating listing: $e');
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