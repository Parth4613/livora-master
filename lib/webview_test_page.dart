import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

class RazorpayWebViewPage extends StatefulWidget {
  @override
  _RazorpayWebViewPageState createState() => _RazorpayWebViewPageState();
}

class _RazorpayWebViewPageState extends State<RazorpayWebViewPage> {
  final TextEditingController _amountController = TextEditingController(text: '10');
  bool _isLoading = false;
  WebViewController? _controller;
  String _paymentStatus = 'Enter amount and click Pay to start payment';
  String? _currentOrderId;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              print('Page started loading: $url');
            },
            onPageFinished: (String url) {
              print('Page finished loading: $url');
              setState(() {
                _isLoading = false;
              });
            },
            onWebResourceError: (WebResourceError error) {
              print('WebView error: ${error.description}');
              setState(() {
                _paymentStatus = 'Error: ${error.description}';
                _isLoading = false;
              });
            },
            onNavigationRequest: (NavigationRequest request) {
              print('Navigation request: ${request.url}');
              
              // Handle custom URL schemes for payment callbacks
              if (request.url.startsWith('razorpay://') || 
                  request.url.contains('payment_success') ||
                  request.url.contains('payment_failure') ||
                  request.url.contains('payment_cancelled')) {
                _handlePaymentCallback(request.url);
                return NavigationDecision.prevent;
              }
              
              return NavigationDecision.navigate;
            },
          ),
        )
        ..addJavaScriptChannel(
          'RazorpayBridge',
          onMessageReceived: (JavaScriptMessage message) {
            _handleJavaScriptMessage(message.message);
          },
        );
    }
  }

  void _handleJavaScriptMessage(String message) {
    print('JavaScript message: $message');
    try {
      final data = jsonDecode(message);
      switch (data['type']) {
        case 'payment_success':
          _showSuccess('Payment Successful!');
          setState(() {
            _paymentStatus = 'Payment completed successfully!\nPayment ID: ${data['payment_id']}';
          });
          break;
        case 'payment_error':
          _showError('Payment Failed!');
          setState(() {
            _paymentStatus = 'Payment failed: ${data['error'] ?? 'Unknown error'}';
          });
          break;
        case 'payment_cancelled':
          setState(() {
            _paymentStatus = 'Payment cancelled by user';
          });
          break;
        case 'razorpay_loaded':
          setState(() {
            _paymentStatus = 'Payment gateway loaded successfully';
          });
          break;
        case 'razorpay_error':
          _showError('Razorpay initialization failed');
          setState(() {
            _paymentStatus = 'Failed to initialize payment gateway';
          });
          break;
      }
    } catch (e) {
      print('Error parsing JavaScript message: $e');
    }
  }

  void _handlePaymentCallback(String url) {
    print('Payment callback URL: $url');
    
    if (url.contains('payment_success')) {
      _showSuccess('Payment Successful!');
      setState(() {
        _paymentStatus = 'Payment completed successfully!';
      });
    } else if (url.contains('payment_failure')) {
      _showError('Payment Failed!');
      setState(() {
        _paymentStatus = 'Payment failed. Please try again.';
      });
    } else if (url.contains('payment_cancelled')) {
      setState(() {
        _paymentStatus = 'Payment cancelled by user';
      });
    }
  }

  Future<void> _startPayment() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty || double.tryParse(amountText) == null) {
      _showError('Please enter a valid amount');
      return;
    }

    setState(() {
      _isLoading = true;
      _paymentStatus = 'Creating payment link...';
    });

    try {
      final paymentLinkUrl = await _createPaymentLink(amountText);
      if (paymentLinkUrl == null) {
        throw Exception('Failed to get payment link URL');
      }
      setState(() {
        _paymentStatus = 'Loading payment link...';
      });
      if (kIsWeb) {
        // On web, open payment link in a new tab
        if (await canLaunchUrl(Uri.parse(paymentLinkUrl))) {
          await launchUrl(Uri.parse(paymentLinkUrl), mode: LaunchMode.externalApplication);
          setState(() {
            _paymentStatus = 'Payment link opened in new tab.';
          });
        } else {
          _showError('Could not open payment link');
        }
      } else {
        // On mobile, load in WebView
        if (_controller != null) {
          await _controller!.loadRequest(Uri.parse(paymentLinkUrl));
        } else {
          _showError('WebView not initialized');
        }
      }
    } catch (e) {
      _showError('Error: $e');
      setState(() {
        _isLoading = false;
        _paymentStatus = 'Error creating payment link: $e';
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<String?> _createPaymentLink(String amountText) async {
    const backendUrl = 'http://10.92.18.47:3000';
    final response = await http.post(
      Uri.parse('$backendUrl/api/payment-links/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': double.parse(amountText),
        'currency': 'INR',
        'description': 'Test Payment',
        'customer': {
          'name': 'Test User',
          'email': 'test@example.com',
          'contact': '9875067129',
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['payment_link']?['short_url'];
    } else {
      throw Exception('Failed to create payment link: ${response.statusCode}');
    }
  }

  // Remove all previous Razorpay order/checkout HTML logic and related methods

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Razorpay Payment'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            prefixText: '₹ ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: kIsWeb
                          ? (_isLoading ? null : _startPayment)
                          : (_isLoading || _controller == null) ? null : _startPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _paymentStatus,
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: kIsWeb
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.open_in_new, size: 64, color: Colors.blue),
                            SizedBox(height: 16),
                            Text(
                              'Payment will open in a new tab',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'After completing payment, return to this page.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : (_controller == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.hourglass_empty, size: 48, color: Colors.blue),
                                SizedBox(height: 16),
                                Text(
                                  'Initializing payment view...',
                                  style: TextStyle(fontSize: 16, color: Colors.blue),
                                ),
                              ],
                            ),
                          )
                        : WebViewWidget(controller: _controller!)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}