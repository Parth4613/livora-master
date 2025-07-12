import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'services/efficient_payment_service.dart';
import 'services/google_play_billing_service.dart';

class PremiumPlansPage extends StatefulWidget {
  const PremiumPlansPage({Key? key}) : super(key: key);

  @override
  State<PremiumPlansPage> createState() => _PremiumPlansPageState();
}

class _PremiumPlansPageState extends State<PremiumPlansPage> {
  List<Map<String, dynamic>> userPlans = [];
  bool loading = true;
  
  // Premium plan prices
  Map<String, double> premiumPrices = {
    'Express Hunt': 29.0,
    'Prime Seeker': 49.0,
    'Precision Pro': 99.0,
  };
  bool pricesLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserPlans();
    _fetchPremiumPrices();
  }

  // Helper to get plan duration in days
  int _planDurationDays(String plan) {
    switch (plan) {
      case 'Express Hunt':
        return 7;
      case 'Prime Seeker':
      case 'Precision Pro':
        return 30;
      default:
        return 0;
    }
  }

  // Helper to get active plan names
  List<String> get activePlanNames {
    final now = DateTime.now();
    return userPlans
        .where((plan) => plan['expiresAt'] != null && (plan['expiresAt'] as Timestamp).toDate().isAfter(now))
        .map((plan) => plan['name'] as String)
        .toList();
  }

  Future<void> _fetchUserPlans() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        userPlans = [];
        loading = false;
      });
      return;
    }
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (userDoc.exists && userDoc.data() != null && userDoc.data()!.containsKey('plans')) {
      final plansRaw = userDoc['plans'];
      if (plansRaw is List) {
        setState(() {
          userPlans = plansRaw.cast<Map<String, dynamic>>();
          loading = false;
        });
      } else {
        setState(() {
          userPlans = [];
          loading = false;
        });
      }
    } else {
      setState(() {
        userPlans = [];
        loading = false;
      });
    }
  }

  Future<void> _addPlanToUser(String plan) async {
    print('_addPlanToUser called with plan: $plan');
    final amount = premiumPrices[plan] ?? 0.0;
    print('Amount for plan $plan: $amount');
    
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid plan price'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('Processing premium plan payment for: $plan');
    try {
      // Use Google Play Billing for mobile, Razorpay for web
      if (kIsWeb) {
        await EfficientPaymentService().processPremiumPlanPayment(
          planName: plan,
          amount: amount,
          context: context,
        );
      } else {
        await GooglePlayBillingService().processPremiumPlanPayment(
          planName: plan,
          amount: amount,
          context: context,
        );
      }
      print('Payment processing completed');
    } catch (e) {
      print('Error in payment processing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    // Refresh user plans after payment
    await _fetchUserPlans();
  }

  Future<void> _fetchPremiumPrices() async {
    setState(() {
      pricesLoading = true;
    });

    try {
      // Map plan names to Firestore document IDs
      final planMapping = {
        'Express Hunt': 'express_hunt',
        'Prime Seeker': 'prime_seeker',
        'Precision Pro': 'precision_pro',
      };

      for (final entry in planMapping.entries) {
        final planName = entry.key;
        final docId = entry.value;
        
        final doc = await FirebaseFirestore.instance
            .collection('premium_plans')
            .doc(docId)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          final price = (data['price'] as num?)?.toDouble() ?? 
                       (data['actual_price'] as num?)?.toDouble() ?? 
                       premiumPrices[planName] ?? 0.0;
          premiumPrices[planName] = price;
        }
      }
    } catch (e) {
      // Keep default prices if fetch fails
      print('Error fetching premium prices: $e');
    } finally {
      setState(() {
        pricesLoading = false;
      });
    }
  }

  void _showUpgradeSheet(BuildContext context, String upgradeTitle, String upgradeTagline, VoidCallback onUpgrade, VoidCallback onContinue, String continueLabel) {
    print('_showUpgradeSheet called with title: $upgradeTitle');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2A2A2A),
              Color(0xFF1A1A1A),
            ],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blueAccent.withOpacity(0.3),
                      Colors.purpleAccent.withOpacity(0.2),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.upgrade,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                upgradeTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  upgradeTagline,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.4,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blueAccent,
                            Colors.blue,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: onUpgrade,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Upgrade Now',
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.05),
                            Colors.white.withOpacity(0.02),
                          ],
                        ),
                      ),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: onContinue,
                        child: Text(
                          continueLabel,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final activePlans = activePlanNames;
    bool hasExpress = activePlans.contains('Express Hunt');
    bool hasPrime = activePlans.contains('Prime Seeker');
    bool hasPro = activePlans.contains('Precision Pro');
    
    print('Active plans: $activePlans');
    print('hasExpress: $hasExpress, hasPrime: $hasPrime, hasPro: $hasPro');

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Premium Plans',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF121212),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: pricesLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          children: [
            _PlanCard(
              title: 'Express Hunt',
              subtitle: '',
              tagline: 'Quick access. Fast results. Start your property hunt today.',
                    price: '₹${premiumPrices['Express Hunt']?.toInt() ?? 29}',
              features: [
                'Unlimited Chat & Call access for 7 Days',
              ],
              color: Colors.lightBlueAccent,
              icon: Icons.flash_on,
              buttonLabel: hasExpress ? 'Owned' : 'Buy Now',
              onBuy: hasExpress
                  ? null
                  : () {
                      _showUpgradeSheet(
                        context,
                        'Buy Prime Seeker for More Benefits',
                        'Unlock a full month of seamless connections and smarter searches.',
                        () async {
                                print('Prime Seeker upgrade button pressed!');
                          Navigator.of(context).pop();
                          await _addPlanToUser('Prime Seeker');
                        },
                        () async {
                                print('Express Hunt upgrade button pressed!');
                          Navigator.of(context).pop();
                          await _addPlanToUser('Express Hunt');
                        },
                        'Continue with Express Hunt',
                      );
                    },
            ),
            const SizedBox(height: 20),
            _PlanCard(
              title: 'Prime Seeker',
              subtitle: '',
              tagline: 'Unlock a full month of seamless connections and smarter searches.',
                    price: '₹${premiumPrices['Prime Seeker']?.toInt() ?? 49}',
              features: [
                'Unlimited Chat & Call access for 1 Month',
              ],
              color: Colors.green,
              icon: Icons.star,
              buttonLabel: hasPrime ? 'Owned' : 'Buy Now',
              onBuy: hasPrime
                  ? null
                  : () {
                      _showUpgradeSheet(
                        context,
                        'Buy Precision Pro for Ultimate Benefits',
                        'Search exactly where you want. Connect with who you need.',
                        () async {
                                print('Precision Pro upgrade button pressed!');
                          Navigator.of(context).pop();
                          await _addPlanToUser('Precision Pro');
                        },
                        () async {
                                print('Prime Seeker upgrade button pressed!');
                          Navigator.of(context).pop();
                          await _addPlanToUser('Prime Seeker');
                        },
                        'Continue with Prime Seeker',
                      );
                    },
            ),
            const SizedBox(height: 20),
            _PlanCard(
              title: 'Precision Pro',
              subtitle: '',
              tagline: 'Search exactly where you want. Connect with who you need.',
                    price: '₹${premiumPrices['Precision Pro']?.toInt() ?? 99}',
              features: [
                'Pin Drop & Radius Search feature for hyper-targeted browsing',
                'Unlimited Chat & Call access for 1 Month',
              ],
              color: Colors.orangeAccent,
              icon: Icons.location_searching,
              buttonLabel: hasPro ? 'Owned' : 'Buy Now',
              onBuy: hasPro
                  ? null
                  : () async {
                            print('Precision Pro buy button pressed!');
                            // Show a test dialog to confirm button press
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Button Pressed'),
                                content: Text('Precision Pro button was pressed!'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: Text('OK'),
                                  ),
                                ],
                              ),
                            );
                      await _addPlanToUser('Precision Pro');
                    },
              isPro: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String tagline;
  final String price;
  final List<String> features;
  final Color color;
  final IconData icon;
  final String buttonLabel;
  final bool isPro;
  final VoidCallback? onBuy;

  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.tagline,
    required this.price,
    required this.features,
    required this.color,
    required this.icon,
    required this.buttonLabel,
    this.isPro = false,
    this.onBuy,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.08),
            const Color(0xFF1E1E1E),
          ],
        ),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative elements
          Positioned(
            top: -22,
            right: -22,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -15,
            left: -15,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.03),
              ),
            ),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(0.3),
                            color.withOpacity(0.1),
                          ],
                        ),
                        border: Border.all(
                          color: color.withOpacity(0.4),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white60,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        if (isPro)
                          Container(
                            margin: const EdgeInsets.only(top: 5),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  color.withOpacity(0.2),
                                  color.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: color.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'BEST VALUE',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        if (title == 'Prime Seeker' && !isPro)
                          Container(
                            margin: const EdgeInsets.only(top: 5),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  color.withOpacity(0.2),
                                  color.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: color.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'POPULAR',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                
                // Tagline
                Text(
                  tagline,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Features
                ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.2),
                        ),
                        child: Icon(
                          Icons.check,
                          color: color,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.22,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 19),
                
                // Button
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          color,
                          color.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.33),
                          blurRadius: 9,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: onBuy,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            buttonLabel,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 7),
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}