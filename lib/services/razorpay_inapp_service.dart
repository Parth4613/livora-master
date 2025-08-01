import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../payment_success_page.dart';

class RazorpayInAppService {
  static final RazorpayInAppService _instance =
      RazorpayInAppService._internal();
  factory RazorpayInAppService() => _instance;
  RazorpayInAppService._internal();

  // Razorpay configuration
  static const String _razorpayKey = 'rzp_test_O9xBxveMFHkkdp';
  static const String _razorpaySecret = '540ObIojNTJlPoQMdZsdXoyX';

  // Your backend API URL (update this with your deployed backend URL)
  static String get _backendUrl {
    if (kIsWeb) {
      return 'http://localhost:3000'; // For web development
    } else {
      // For Android device - use user's local IP
      return 'http://152.58.15.6:3000';
    }
  }
  // static const String _backendUrl = 'https://your-production-backend.com'; // For production

  Future<void> processListingPayment({
    required String listingType,
    required String planName,
    required double amount,
    required String listingId,
    required BuildContext context,
  }) async {
    print('RazorpayInAppService.processListingPayment called');
    print(
      'Listing Type: $listingType, Plan: $planName, Amount: $amount, Listing ID: $listingId',
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not authenticated in RazorpayInAppService');
      _showErrorSnackBar(context, 'User not authenticated');
      return;
    }

    try {
      print('Creating order on backend...');
      // Create order on your backend
      final order = await _createListingOrder(
        listingType,
        planName,
        amount,
        listingId,
        user.uid,
      );
      print('Order created successfully: ${order['id']}');

      print('Showing in-app payment webview...');
      // Show in-app payment webview
      await _showInAppPayment(order, context);
      print('In-app payment webview shown');
    } catch (e) {
      print('Payment error in RazorpayInAppService: $e');
      _showErrorSnackBar(context, 'Payment failed: $e');
    }
  }

  Future<Map<String, dynamic>> _createListingOrder(
    String listingType,
    String planName,
    double amount,
    String listingId,
    String userId,
  ) async {
    print('Creating listing order...');
    print('Backend URL: $_backendUrl');
    print('Amount: $amount, Listing Type: $listingType, Plan: $planName');

    try {
      final requestBody = {
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
      };

      print('Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_backendUrl/api/orders/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Order created: ${data['order']['id']}');
        return data['order'];
      } else {
        print(
          'Failed to create order. Status: ${response.statusCode}, Body: ${response.body}',
        );
        throw Exception(
          'Failed to create listing order: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error creating listing order: $e');
      throw Exception('Failed to create listing order: $e');
    }
  }

  Future<void> _showInAppPayment(
    Map<String, dynamic> order,
    BuildContext context,
  ) async {
    // Build Razorpay checkout URL
    final paymentUrl =
        'https://checkout.razorpay.com/v1/checkout.html?' +
        'key=${_razorpayKey}' +
        '&amount=${order['amount']}' +
        '&currency=${order['currency']}' +
        '&name=Buddy%20App' +
        '&description=Listing%20Payment' +
        '&order_id=${order['id']}' +
        '&prefill[name]=${Uri.encodeComponent(FirebaseAuth.instance.currentUser?.displayName ?? '')}' +
        '&prefill[email]=${Uri.encodeComponent(FirebaseAuth.instance.currentUser?.email ?? '')}' +
        '&theme[color]=3B82F6' +
        '&callback_url=${Uri.encodeComponent('buddy://payment-success')}' +
        '&cancel_url=${Uri.encodeComponent('buddy://payment-cancel')}';

    // Navigate to in-app payment page
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => InAppPaymentPage(
                paymentUrl: paymentUrl,
                orderId: order['id'],
                listingType: order['notes']['listingType'],
                planName: order['notes']['planName'],
                listingId: order['notes']['listingId'],
                amount: order['notes']['amount'] ?? 0.0,
              ),
        ),
      );
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class InAppPaymentPage extends StatefulWidget {
  final String paymentUrl;
  final String orderId;
  final String listingType;
  final String planName;
  final String listingId;
  final double amount;

  const InAppPaymentPage({
    Key? key,
    required this.paymentUrl,
    required this.orderId,
    required this.listingType,
    required this.planName,
    required this.listingId,
    required this.amount,
  }) : super(key: key);

  @override
  State<InAppPaymentPage> createState() => _InAppPaymentPageState();
}

class _InAppPaymentPageState extends State<InAppPaymentPage> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _paymentCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                setState(() {
                  _isLoading = true;
                });
              },
              onPageFinished: (String url) {
                setState(() {
                  _isLoading = false;
                });

                // Check for payment completion
                if (url.contains('payment-success') ||
                    url.contains('razorpay_payment_id')) {
                  _handlePaymentSuccess(url);
                } else if (url.contains('payment-cancel') ||
                    url.contains('payment_failed')) {
                  _handlePaymentFailure();
                }
              },
              onNavigationRequest: (NavigationRequest request) {
                // Handle navigation requests
                if (request.url.contains('payment-success') ||
                    request.url.contains('razorpay_payment_id')) {
                  _handlePaymentSuccess(request.url);
                  return NavigationDecision.prevent;
                } else if (request.url.contains('payment-cancel') ||
                    request.url.contains('payment_failed')) {
                  _handlePaymentFailure();
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _handlePaymentSuccess(String url) async {
    if (_paymentCompleted) return;
    _paymentCompleted = true;

    try {
      // Extract payment details from URL parameters
      final uri = Uri.parse(url);
      final paymentId =
          uri.queryParameters['razorpay_payment_id'] ??
          'pay_${DateTime.now().millisecondsSinceEpoch}';
      final orderId =
          uri.queryParameters['razorpay_order_id'] ?? widget.orderId;
      final signature =
          uri.queryParameters['razorpay_signature'] ??
          'signature_${DateTime.now().millisecondsSinceEpoch}';

      // Verify payment with backend
      final verifyResponse = await http.post(
        Uri.parse('${RazorpayInAppService._backendUrl}/api/payments/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
        }),
      );

      if (verifyResponse.statusCode == 200) {
        final verifyData = jsonDecode(verifyResponse.body);
        if (verifyData['success']) {
          // Payment verified successfully
          await _savePaymentRecord(paymentId, orderId, signature);
          await _activateListing(paymentId);

          // Show success page
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder:
                    (context) => PaymentSuccessPage(
                      title: 'Payment Successful!',
                      message:
                          'Your listing is now active and visible to users.',
                      orderId: orderId,
                      onContinue: () {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                    ),
              ),
            );
          }
        } else {
          throw Exception(
            'Payment verification failed: ${verifyData['error']}',
          );
        }
      } else {
        throw Exception(
          'Payment verification failed: ${verifyResponse.statusCode}',
        );
      }
    } catch (e) {
      print('Error handling payment success: $e');
      if (mounted) {
        _showErrorSnackBar('Error processing payment: $e');
        Navigator.of(context).pop();
      }
    }
  }

  void _handlePaymentFailure() {
    if (_paymentCompleted) return;
    _paymentCompleted = true;

    if (mounted) {
      _showErrorSnackBar('Payment was cancelled or failed');
      Navigator.of(context).pop();
    }
  }

  Future<void> _activateListing(String paymentId) async {
    try {
      // Update the listing to make it visible
      final collectionName = _getCollectionName(widget.listingType);

      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(widget.listingId)
          .update({
            'visibility': true,
            'paymentStatus': 'completed',
            'paymentId': paymentId,
            'planName': widget.planName,
            'activatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error activating listing: $e');
      throw e;
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
        return 'room_requests';
      default:
        return 'listings';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _savePaymentRecord(
    String paymentId,
    String orderId,
    String signature,
  ) async {
    await FirebaseFirestore.instance.collection('payments').add({
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'paymentId': paymentId,
      'orderId': orderId,
      'signature': signature,
      'amount': widget.amount,
      'currency': 'INR',
      'type': 'listing',
      'listingType': widget.listingType,
      'planName': widget.planName,
      'listingId': widget.listingId,
      'status': 'success',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading payment form...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
