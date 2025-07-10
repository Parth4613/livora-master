import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../payment_success_page.dart';
import 'dart:async';

class GooglePlayBillingService {
  static final GooglePlayBillingService _instance = GooglePlayBillingService._internal();
  factory GooglePlayBillingService() => _instance;
  GooglePlayBillingService._internal();

  static const Map<String, String> _planSkus = {
    'Express Hunt': 'express_hunt_plan',
    'Prime Seeker': 'prime_seeker_plan',
    'Precision Pro': 'precision_pro_plan',
  };

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  BuildContext? _pendingContext;
  String? _pendingPlanName;
  double? _pendingAmount;

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

    _pendingContext = context;
    _pendingPlanName = planName;
    _pendingAmount = amount;

    // Initialize and query products
    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      _showErrorSnackBar(context, 'Google Play Billing not available');
      return;
    }

    final Set<String> ids = {_planSkus[planName] ?? ''};
    final ProductDetailsResponse response = await _iap.queryProductDetails(ids);
    if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
      _showErrorSnackBar(context, 'Product not found in Play Console: ${_planSkus[planName]}');
      return;
    }
    _products = response.productDetails;
    final product = _products.first;

    // Listen for purchase updates
    _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(_onPurchaseUpdate, onDone: () {
      _subscription?.cancel();
    }, onError: (error) {
      _showErrorSnackBar(context, 'Purchase error: $error');
    });

    // Launch purchase flow
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        // Verify purchase (for production, use server-side verification)
        await _finalizePurchase(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        _showErrorSnackBar(_pendingContext!, 'Purchase failed: ${purchase.error?.message ?? ''}');
      }
    }
  }

  Future<void> _finalizePurchase(PurchaseDetails purchase) async {
    try {
      // Save purchase record
      await FirebaseFirestore.instance.collection('purchases').add({
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'purchaseToken': purchase.verificationData.serverVerificationData,
        'orderId': purchase.purchaseID,
        'sku': purchase.productID,
        'amount': _pendingAmount,
        'currency': 'INR',
        'type': 'premium_plan',
        'planName': _pendingPlanName,
        'status': 'success',
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Activate the plan
      await _activatePremiumPlan(_pendingPlanName!, purchase.verificationData.serverVerificationData, _pendingContext!);
      // Complete the purchase
      await _iap.completePurchase(purchase);
    } catch (e) {
      print('Error finalizing purchase: $e');
      _showErrorSnackBar(_pendingContext!, 'Error activating plan: $e');
    }
  }

  Future<void> _activatePremiumPlan(String planName, String purchaseToken, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final now = DateTime.now();
      int days = 0;
      switch (planName) {
        case 'Express Hunt': days = 7; break;
        case 'Prime Seeker':
        case 'Precision Pro': days = 30; break;
        default: days = 0;
      }
      final expiresAt = now.add(Duration(days: days));
      final planObj = {
        'name': planName,
        'activatedAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'purchaseToken': purchaseToken,
        'source': 'google_play',
      };
      final userData = await userDoc.get();
      List<Map<String, dynamic>> updatedPlans = [];
      if (userData.exists && userData.data()!.containsKey('plans')) {
        updatedPlans = List<Map<String, dynamic>>.from(userData.data()!['plans']);
      }
      updatedPlans.removeWhere((p) => p['name'] == planName);
      updatedPlans.add(planObj);
      await userDoc.set({'plans': updatedPlans}, SetOptions(merge: true));
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