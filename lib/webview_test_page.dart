import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

String generateRazorpayCheckoutHtml({
  required String key,
  required int amount, // in paise
  required String currency,
  required String name,
  required String description,
  required String orderId,
  required String prefillName,
  required String prefillEmail,
  String themeColor = '#3B82F6',
}) {
  return '''
<!DOCTYPE html>
<html>
  <head>
    <title>Razorpay Payment</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
    <style>
      body { font-family: Arial, sans-serif; text-align: center; margin-top: 40px; }
    </style>
  </head>
  <body>
    <h2>Processing Payment...</h2>
    <script>
      var options = {
        key: '$key',
        amount: $amount,
        currency: '$currency',
        name: '$name',
        description: '$description',
        order_id: '$orderId',
        prefill: {
          name: '$prefillName',
          email: '$prefillEmail'
        },
        theme: {
          color: '$themeColor'
        },
        handler: function (response){
          document.body.innerHTML = '<h2>Payment Success!</h2><pre>' + JSON.stringify(response, null, 2) + '</pre>';
        },
        modal: {
          ondismiss: function(){
            document.body.innerHTML = '<h2>Payment Cancelled</h2>';
          }
        }
      };
      var rzp = new Razorpay(options);
      rzp.open();
    </script>
  </body>
</html>
''';
}

class WebViewTestPage extends StatefulWidget {
  @override
  _WebViewTestPageState createState() => _WebViewTestPageState();
}

class _WebViewTestPageState extends State<WebViewTestPage> {
  final TextEditingController _amountController = TextEditingController(text: '10');
  bool _isLoading = false;
  String? _paymentUrl;
  WebViewController? _controller;
  bool _launchedOnWeb = false;

  Future<void> _startPayment() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty || double.tryParse(amountText) == null) {
      _showError('Please enter a valid amount');
      return;
    }
    setState(() {
      _isLoading = true;
      _paymentUrl = null;
      _launchedOnWeb = false;
    });
    try {
      const backendUrl = 'http://10.92.18.47:3000'; // Update if needed
      final response = await http.post(
        Uri.parse('$backendUrl/api/orders/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amountText, // Send as rupees string
          'currency': 'INR',
          'receipt': 'test_receipt_${DateTime.now().millisecondsSinceEpoch}',
          'notes': {
            'planName': 'Test Plan',
            'listingType': 'test',
            'listingId': 'test123',
            'userId': 'testuser',
            'type': 'listing',
          },
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final order = data['order'];
        final paymentUrl = 'https://checkout.razorpay.com/v1/checkout.html?'
            'key=rzp_test_O9xBxveMFHkkdp'
            '&amount=${order['amount']}'
            '&currency=${order['currency']}'
            '&name=Buddy%20App'
            '&description=Test%20Payment'
            '&order_id=${order['id']}'
            '&prefill[name]=Test%20User'
            '&prefill[email]=test@example.com'
            '&theme[color]=3B82F6';
        print('Razorpay Payment URL: ' + paymentUrl);
        if (kIsWeb) {
          // On web, launch in new tab
          await launchUrl(Uri.parse(paymentUrl), mode: LaunchMode.externalApplication);
          setState(() {
            _launchedOnWeb = true;
            _isLoading = false;
          });
        } else {
          // Use dynamic HTML with checkout.js for mobile
          final htmlString = generateRazorpayCheckoutHtml(
            key: 'rzp_test_O9xBxveMFHkkdp',
            amount: order['amount'],
            currency: order['currency'],
            name: 'Buddy App',
            description: 'Test Payment',
            orderId: order['id'],
            prefillName: 'Test User',
            prefillEmail: 'test@example.com',
          );
          setState(() {
            _paymentUrl = null;
          });
          _controller?.loadHtmlString(htmlString);
        }
      } else {
        _showError('Failed to create order: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (!kIsWeb) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = WebViewController()
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
            },
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Payment (WebView)'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (INR)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _startPayment,
                  child: const Text('Pay'),
                ),
              ],
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: kIsWeb
                ? (_launchedOnWeb
                    ? const Center(child: Text('Payment page opened in new tab.'))
                    : const Center(child: Text('Enter an amount and tap Pay to test payment.')))
                : (_controller == null
                    ? const Center(child: Text('Enter an amount and tap Pay to test payment.'))
                    : WebViewWidget(controller: _controller!)),
          ),
        ],
      ),
    );
  }
} 