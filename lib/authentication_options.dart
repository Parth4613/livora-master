import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'google_profile_completion.dart';

class AuthOptionsPage extends StatefulWidget {
  const AuthOptionsPage({super.key});

  @override
  State<AuthOptionsPage> createState() => _AuthOptionsPageState();
}

class _AuthOptionsPageState extends State<AuthOptionsPage> {
  bool _isGoogleLoading = false;
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Stack(
      children: [
        Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFF),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            systemOverlayStyle: isDark 
              ? SystemUiOverlayStyle.light 
              : SystemUiOverlayStyle.dark,
            iconTheme: IconThemeData(
              color: isDark ? Colors.white : const Color(0xFF1E3A8A),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(isDark),
                  const SizedBox(height: 50),
                  _buildAuthButtons(isDark),
                ],
              ),
            ),
          ),
        ),
        if (_isGoogleLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C3E50) : const Color(0xFF4A90E2),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (isDark ? const Color(0xFF2C3E50) : const Color(0xFF4A90E2)).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_outline,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Sign in to your account',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E3A8A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose how you\'d like to sign in',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF64748B),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthButtons(bool isDark) {
    return Column(
      children: [
        _buildGoogleButton(isDark),
        const SizedBox(height: 16),
        _buildPhoneButton(isDark),
      ],
    );
  }

  Widget _buildGoogleButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3E50) : const Color(0xFF4A90E2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF2C3E50) : const Color(0xFF4A90E2)).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _signInWithGoogle,
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '(recommended)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
    });
    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
        final user = userCredential.user;
        if (user == null) {
          setState(() { _isGoogleLoading = false; });
          return;
        }
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          final result = await Navigator.push<Map<String, String>>(
            context,
            MaterialPageRoute(
              builder: (context) => GoogleProfileCompletionPage(),
            ),
          );
          if (result == null || result['username'] == null || result['phone'] == null) {
            await FirebaseAuth.instance.signOut();
            setState(() { _isGoogleLoading = false; });
            return;
          }
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'username': result['username'],
            'phone': result['phone'],
            'createdAt': DateTime.now().toIso8601String(),
          });
          await user.updateDisplayName(result['username']);
        }
        if (mounted) {
          setState(() { _isGoogleLoading = false; });
          Navigator.pushReplacementNamed(context, '/home');
        }
        return;
      }
      await GoogleSignIn().signOut();
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() { _isGoogleLoading = false; });
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        setState(() { _isGoogleLoading = false; });
        return;
      }
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        final result = await Navigator.push<Map<String, String>>(
          context,
          MaterialPageRoute(
            builder: (context) => GoogleProfileCompletionPage(),
          ),
        );
        if (result == null || result['username'] == null || result['phone'] == null) {
          setState(() { _isGoogleLoading = false; });
          await GoogleSignIn().signOut();
          await FirebaseAuth.instance.signOut();
          return;
        }
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'username': result['username'],
          'phone': result['phone'],
          'createdAt': DateTime.now().toIso8601String(),
        });
        await user.updateDisplayName(result['username']);
      }
      if (mounted) {
        setState(() { _isGoogleLoading = false; });
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e, stack) {
      setState(() { _isGoogleLoading = false; });
      print('Google sign-in failed: $e');
      print(stack);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $e')),
      );
    }
  }

  Widget _buildPhoneButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3E50) : const Color(0xFF4A90E2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF2C3E50) : const Color(0xFF4A90E2)).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToPhoneAuth,
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Continue with Phone',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToPhoneAuth() {
    Navigator.pushNamed(context, '/phone-verification');
  }
}