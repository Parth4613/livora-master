import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'splash_screen.dart';
import 'home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'phone_verification.dart';

class SplashScreenWrapper extends StatefulWidget {
  const SplashScreenWrapper({Key? key}) : super(key: key);

  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  bool _bannersLoaded = false;
  bool _showSplash = true;
  List<Map<String, dynamic>> _banners = [];
  bool _userDocChecked = false;
  bool _userDocExists = false;

  @override
  void initState() {
    super.initState();
    _loadBanners();
    _checkUserDoc();
    
    // Add a safety timeout to prevent getting stuck
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && _showSplash) {
        print('Splash screen timeout - forcing navigation to home');
        setState(() {
          _showSplash = false;
          _bannersLoaded = true;
        });
      }
    });
  }

  Future<void> _loadBanners() async {
    try {
      // Add a timeout to prevent getting stuck
      final bannersSnap = await FirebaseFirestore.instance
          .collection('promo_banners')
          .get()
          .timeout(const Duration(seconds: 10));
      
      if (mounted) {
        setState(() {
          if (bannersSnap.docs.isNotEmpty) {
            _banners = bannersSnap.docs.map((d) => d.data()).toList();
          } else {
            // If no banners in Firestore, use default banners
            _banners = [
              {
                'title': 'Find Your Perfect Room',
                'subtitle': 'Discover amazing rooms near your campus',
                'icon': 'home_work',
                'image': '',
                'color': '#FF6B6B',
              },
              {
                'title': 'Connect with Flatmates',
                'subtitle': 'Find compatible roommates for your journey',
                'icon': 'group',
                'image': '',
                'color': '#4ECDC4',
              },
              {
                'title': 'Premium Hostels & PG',
                'subtitle': 'Safe and comfortable accommodations',
                'icon': 'hotel',
                'image': '',
                'color': '#45B7D1',
              },
              {
                'title': 'Student Services',
                'subtitle': 'Everything you need for campus life',
                'icon': 'school',
                'image': '',
                'color': '#96CEB4',
              },
            ];
          }
          _bannersLoaded = true;
        });
        
        // Wait a bit for the splash animation to complete
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          setState(() {
            _showSplash = false;
          });
        }
      }
    } catch (e) {
      print('Error loading banners: $e');
      // If there's an error, still proceed with default banners
      if (mounted) {
        setState(() {
          _banners = [
            {
              'title': 'Find Your Perfect Room',
              'subtitle': 'Discover amazing rooms near your campus',
              'icon': 'home_work',
              'image': '',
              'color': '#FF6B6B',
            },
            {
              'title': 'Connect with Flatmates',
              'subtitle': 'Find compatible roommates for your journey',
              'icon': 'group',
              'image': '',
              'color': '#4ECDC4',
            },
            {
              'title': 'Premium Hostels & PG',
              'subtitle': 'Safe and comfortable accommodations',
              'icon': 'hotel',
              'image': '',
              'color': '#45B7D1',
            },
            {
              'title': 'Student Services',
              'subtitle': 'Everything you need for campus life',
              'icon': 'school',
              'image': '',
              'color': '#96CEB4',
            },
          ];
          _bannersLoaded = true;
        });
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          setState(() {
            _showSplash = false;
          });
        }
      }
    }
  }

  Future<void> _checkUserDoc() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _userDocChecked = true;
        _userDocExists = doc.exists;
      });
    } else {
      setState(() {
        _userDocChecked = true;
        _userDocExists = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash || !_userDocChecked) {
      return const SplashScreen();
    } else {
      if (FirebaseAuth.instance.currentUser == null) {
        // Not authenticated, let AuthStateHandler handle onboarding/login
        return const SplashScreen();
      } else if (!_userDocExists) {
        // Authenticated but Firestore user doc missing, force to phone verification (name input)
        return PhoneVerificationPage();
      } else {
        // Authenticated and Firestore user doc exists
        return const HomeScreen();
      }
    }
  }
} 