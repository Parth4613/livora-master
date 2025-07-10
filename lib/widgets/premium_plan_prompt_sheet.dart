import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../premium_plans_page.dart';

class PremiumPlanPromptSheet extends StatefulWidget {
  const PremiumPlanPromptSheet({Key? key}) : super(key: key);

  @override
  State<PremiumPlanPromptSheet> createState() => _PremiumPlanPromptSheetState();
}

class _PremiumPlanPromptSheetState extends State<PremiumPlanPromptSheet> {
  Map<String, double> premiumPrices = {
    'Express Hunt': 29.0,
    'Prime Seeker': 49.0,
    'Precision Pro': 99.0,
  };
  bool pricesLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPremiumPrices();
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

  @override
  Widget build(BuildContext context) {
    final plans = [
      {
        'title': 'Express Hunt',
        'price': '₹${premiumPrices['Express Hunt']?.toInt() ?? 29}',
        'tagline': 'Quick access. Fast results. Start your property hunt today.',
        'features': ['Unlimited Chat & Call access for 7 Days'],
        'color': Colors.lightBlueAccent,
        'icon': Icons.flash_on,
      },
      {
        'title': 'Prime Seeker',
        'price': '₹${premiumPrices['Prime Seeker']?.toInt() ?? 49}',
        'tagline': 'Unlock a full month of seamless connections and smarter searches.',
        'features': ['Unlimited Chat & Call access for 1 Month'],
        'color': Colors.green,
        'icon': Icons.star,
      },
      {
        'title': 'Precision Pro',
        'price': '₹${premiumPrices['Precision Pro']?.toInt() ?? 99}',
        'tagline': 'Search exactly where you want. Connect with who you need.',
        'features': [
          'Pin Drop & Radius Search feature for hyper-targeted browsing',
          'Unlimited Chat & Call access for 1 Month',
        ],
        'color': Colors.orangeAccent,
        'icon': Icons.location_searching,
      },
    ];

    return Container(
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Unlock Premium Features',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            if (pricesLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              ...plans.map((plan) => _PlanPreviewCard(plan: plan, onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const PremiumPlansPage(),
                ));
              })).toList(),
            const SizedBox(height: 12),
            Text(
              'Select a plan to see more details and purchase.',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _PlanPreviewCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final VoidCallback onTap;
  const _PlanPreviewCard({required this.plan, required this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (plan['color'] as Color).withOpacity(0.15),
              (plan['color'] as Color).withOpacity(0.08),
              const Color(0xFF1E1E1E),
            ],
          ),
          border: Border.all(
            color: (plan['color'] as Color).withOpacity(0.4),
            width: 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (plan['color'] as Color).withOpacity(0.13),
              ),
              child: Icon(plan['icon'] as IconData, color: plan['color'] as Color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan['title'],
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...List.generate(plan['features'].length, (i) => Text(
                    '• ${plan['features'][i]}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              plan['price'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: plan['color'] as Color,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 