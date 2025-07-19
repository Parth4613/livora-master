import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/efficient_payment_service.dart';

class PaymentSuccessPage extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onContinue;
  final String? orderId; // Optional order ID for status tracking

  const PaymentSuccessPage({
    Key? key,
    required this.title,
    required this.message,
    required this.onContinue,
    this.orderId,
  }) : super(key: key);

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  bool _isLoading = false;
  Map<String, dynamic>? _paymentStatus;

  @override
  void initState() {
    super.initState();
    if (widget.orderId != null) {
      _loadPaymentStatus();
    }
  }

  Future<void> _loadPaymentStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await EfficientPaymentService().getPaymentStatus(widget.orderId!);
      setState(() {
        _paymentStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading payment status: $e');
    }
  }

  Future<void> _retryPayment() async {
    if (widget.orderId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await EfficientPaymentService().retryPayment(widget.orderId!, context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error retrying payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Animation
              Lottie.asset(
                'assets/animations/success.json',
                width: 200,
                height: 200,
                repeat: false,
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                widget.message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Payment Status (if order ID is provided)
              if (widget.orderId != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Payment Status',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else if (_paymentStatus != null)
                        _buildPaymentStatusInfo()
                      else
                        Text(
                          'Status unavailable',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.orange,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Retry Button (if payment failed)
                if (_paymentStatus != null && 
                    _paymentStatus!['status'] != 'paid' && 
                    _paymentStatus!['status'] != 'captured')
                  ElevatedButton.icon(
                    onPressed: _retryPayment,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
              ],

              const SizedBox(height: 32),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentStatusInfo() {
    final status = _paymentStatus!['status'] ?? 'unknown';
    final amount = _paymentStatus!['amount'] ?? 0;
    final currency = _paymentStatus!['currency'] ?? 'INR';
    
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'paid':
      case 'captured':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Payment Successful';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Payment Pending';
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Payment Failed';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Unknown Status';
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Amount: ₹${(amount / 100).toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (widget.orderId != null) ...[
          const SizedBox(height: 4),
          Text(
            'Order ID: ${widget.orderId!.substring(0, 8)}...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ],
    );
  }
} 