import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'theme.dart';
import 'edit_profile.dart';
import 'wishlist_page.dart';
import 'settings_page.dart';
import 'banner_changing.dart';
import 'chat_list_screen.dart';
import '../utils/cache_utils.dart';
import 'premium_plans_page.dart';
import 'services/user_service.dart';
import 'webview_test_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  bool _isLoggingOut = false;
  String _profileImageUrlFromFirestore = '';
  String? _firestoreEmail;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _listenToUserChanges();
    _listenToFirestoreUserDoc();
    _loadProfileImageUrl();
  }

  void _listenToUserChanges() {
    _authSubscription = FirebaseAuth.instance.userChanges().listen((user) {
      if (mounted) {
        setState(() {
          _user = user;
        });
      }
    });
  }

  void _listenToFirestoreUserDoc() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _userDocSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) async {
          if (doc.exists) {
            final data = doc.data();
            String? firestoreEmail = data?['email'];
            String? firestoreUsername = data?['username'];
            setState(() {
              _profileImageUrlFromFirestore = data?['profileImageUrl'] ?? '';
              _firestoreEmail = firestoreEmail;
            });
            // Update displayName if changed in Firestore
            if (firestoreUsername != null && firestoreUsername != _user?.displayName) {
              try {
                await _user?.updateDisplayName(firestoreUsername);
                await _user?.reload();
                setState(() {
                  _user = FirebaseAuth.instance.currentUser;
                });
              } catch (e) {
                // Handle error if needed
              }
            }
            // Update email if changed in Firestore
            if (firestoreEmail != null && firestoreEmail != _user?.email) {
              try {
                await _user?.updateEmail(firestoreEmail);
                await _user?.reload();
                setState(() {
                  _user = FirebaseAuth.instance.currentUser;
                });
              } on FirebaseAuthException catch (e) {
                if (e.code == 'requires-recent-login') {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please re-authenticate to update your email.'),
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                } else {
                  // Handle other errors if needed
                }
              } catch (e) {
                // Handle other errors if needed
              }
            }
          }
        });
  }

  @override
  void dispose() {
    _userDocSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadProfileImageUrl() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    if (doc.exists) {
      final data = doc.data();
      setState(() {
        _profileImageUrlFromFirestore = data?['profileImageUrl'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
        return false;
      },
      child: Scaffold(
        backgroundColor:
            isDark ? Colors.black : BuddyTheme.backgroundPrimaryColor,
        body: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 320,
                  floating: false,
                  pinned: true,
                  backgroundColor:
                      isDark ? Colors.black : BuddyTheme.backgroundPrimaryColor,
                  flexibleSpace: LayoutBuilder(
                    builder: (
                      BuildContext context,
                      BoxConstraints constraints,
                    ) {
                      return FlexibleSpaceBar(
                        collapseMode: CollapseMode.parallax,
                        background: Container(
                          color:
                              isDark
                                  ? Colors.black
                                  : BuddyTheme.backgroundPrimaryColor,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 60),
                              _buildProfileAvatar(isDark),
                              const SizedBox(height: 20),
                              _buildUserNameSection(isDark),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(child: _buildAccountSettingsSection(isDark)),
              ],
            ),
            if (_isLoggingOut)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(bool isDark) {
    return Hero(
      tag: 'profile_avatar',
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors:
                isDark
                    ? [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.1),
                    ]
                    : [
                      BuddyTheme.primaryColor.withOpacity(0.8),
                      BuddyTheme.secondaryColor.withOpacity(0.6),
                    ],
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isDark
                      ? Colors.black.withOpacity(0.2)
                      : BuddyTheme.primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl:
                  _profileImageUrlFromFirestore.isNotEmpty
                      ? _profileImageUrlFromFirestore
                      : (_user?.photoURL ?? 'https://via.placeholder.com/150'),
              fit: BoxFit.cover,
              placeholder:
                  (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.white),
                  ),
              errorWidget:
                  (context, url, error) => Container(
                    color: Colors.grey[100],
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserNameSection(bool isDark) {
    final isPhoneUser = _user?.providerData.any((p) => p.providerId == 'phone') == true;
    return Column(
      children: [
        Text(
          _user?.displayName?.isNotEmpty == true
              ? _user!.displayName!
              : (_firestoreEmail != null && _firestoreEmail!.trim().isNotEmpty)
                  ? _firestoreEmail!.split('@')[0].toUpperCase()
                  : (_user?.phoneNumber ?? 'Guest User'),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSettingsSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: BuddyTheme.spacingMd),
      decoration: BuddyTheme.cardDecoration.copyWith(
        color:
            isDark
                ? Colors.grey[900]
                : const Color.fromARGB(255, 240, 238, 238),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(BuddyTheme.spacingMd),
            child: Text(
              'Account Settings',
              style: TextStyle(
                fontSize: BuddyTheme.fontSizeLg,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          _buildMenuOption(
            icon: Icons.person_outline,
            iconColor: BuddyTheme.primaryColor,
            title: 'Edit Profile',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );
            },
            isDark: isDark,
          ),
          _buildMenuOption(
            icon: Icons.workspace_premium,
            iconColor: Colors.amber,
            title: 'Premium Plans',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PremiumPlansPage(),
                ),
              );
            },
            isDark: isDark,
          ),
          FutureBuilder<List<bool>>(
            future: Future.wait([
              UserService.hasActiveListing(),
              UserService.hasActivePlan(),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(); // Or a loading indicator if you prefer
              }
              if (snapshot.hasData && (snapshot.data![0] == true || snapshot.data![1] == true)) {
                return _buildMenuOption(
                  icon: Icons.person_outline,
                  iconColor: BuddyTheme.primaryColor,
                  title: 'Messages',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatListScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                );
              }
              return SizedBox();
            },
          ),
          // --- Add Change Price button here for admin ---
          if (FirebaseAuth.instance.currentUser?.email?.toLowerCase() ==
              'livora.app@gmail.com')
            _buildMenuOption(
              icon: Icons.price_change,
              iconColor: Colors.green,
              title: 'Change Price',
              onTap: () {
                _showChangePriceDialog(context);
              },
              isDark: isDark,
            ),
          // --- End Change Price button ---
          // --- Add Change Banner button here for admin ---
          if (FirebaseAuth.instance.currentUser?.email?.toLowerCase() ==
              'livora.app@gmail.com')
            _buildMenuOption(
              icon: Icons.photo_library,
              iconColor: Colors.deepPurple,
              title: 'Change Promo Banners',
              onTap: () {
                showBannerChangingDialog(context);
              },
              isDark: isDark,
            ),
          // --- End Change Banner button ---
          _buildMenuOption(
            icon: Icons.web,
            iconColor: Colors.blueAccent,
            title: 'Test WebView',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WebViewTestPage(),
                ),
              );
            },
            isDark: isDark,
          ),
          _buildMenuOption(
            icon: Icons.favorite_border,
            iconColor: BuddyTheme.secondaryColor,
            title: 'Wishlist',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WishlistPage()),
              );
            },
            isDark: isDark,
          ),
          _buildMenuOption(
            icon: Icons.security_outlined,
            iconColor: BuddyTheme.successColor,
            title: 'Privacy & Security',
            onTap: () {
              Navigator.pushNamed(context, '/privacyPolicy');
            },
            isDark: isDark,
          ),
          _buildMenuOption(
            icon: Icons.favorite_outline,
            iconColor: Colors.amber,
            title: 'My Listings',
            onTap: () {
              Navigator.pushNamed(context, '/myListings');
            },
            isDark: isDark,
          ),
          _buildMenuOption(
            icon: Icons.settings_outlined,
            iconColor: BuddyTheme.textSecondaryColor,
            title: 'Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
            isLast: true,
            isDark: isDark,
          ),
          Container(
            margin: const EdgeInsets.all(BuddyTheme.spacingMd),
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showLogoutDialog();
              },
              icon: const Icon(Icons.logout, size: BuddyTheme.iconSizeMd),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: BuddyTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48), // Rectangle, full width
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6), // Rectangle
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
    required bool isDark,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(BuddyTheme.spacingXs),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
            ),
            child: Icon(icon, color: iconColor, size: BuddyTheme.iconSizeMd),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: BuddyTheme.fontSizeMd,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : BuddyTheme.textPrimaryColor,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: isDark ? Colors.white54 : BuddyTheme.textSecondaryColor,
          ),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: BuddyTheme.spacingMd,
            vertical: BuddyTheme.spacingXs,
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent:
                BuddyTheme.spacingMd +
                BuddyTheme.iconSizeMd +
                BuddyTheme.spacingXs,
            endIndent: BuddyTheme.spacingMd,
            color: isDark ? Colors.white24 : BuddyTheme.dividerColor,
          ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(80, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
                ),
                side: BorderSide(color: BuddyTheme.primaryColor),
              ),
              child: const Text('Cancel', style: TextStyle(color: BuddyTheme.primaryColor)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                setState(() {
                  _isLoggingOut = true;
                });
                
                // Clear all caches before logout
                await CacheUtils.clearAllCaches();
                
                await FirebaseAuth.instance.signOut();
                setState(() {
                  _isLoggingOut = false;
                });
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/auth-options',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BuddyTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(80, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
                ),
                elevation: 0,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePriceDialog(BuildContext context) {
    final List<String> services = [
      'list_hostelpg',
      'list_room',
      'room_request',
      'list_service',
    ];
    final List<String> premiumPlans = [
      'express_hunt',
      'prime_seeker',
      'precision_pro',
    ];
    final List<String> dayOptions = ['1 day', '7 days', '15 days', '1 month'];

    String? selectedService;
    String? selectedPremiumPlan;
    String? selectedDay;
    final actualPriceController = TextEditingController();
    final discountedPriceController = TextEditingController();
    bool isPremiumPlan = false;

    Future<void> fetchPrices() async {
      if (isPremiumPlan && selectedPremiumPlan != null) {
        // Fetch premium plan prices
        final doc = await FirebaseFirestore.instance
            .collection('premium_plans')
            .doc(selectedPremiumPlan)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          actualPriceController.text = data['price']?.toString() ?? '';
          discountedPriceController.text = data['discounted_price']?.toString() ?? '';
        } else {
          actualPriceController.text = '';
          discountedPriceController.text = '';
        }
      } else if (selectedService != null && selectedDay != null) {
        // Fetch listing service prices
        final doc = await FirebaseFirestore.instance
                .collection('plan_prices')
                .doc(selectedService)
                .collection('day_wise_prices')
                .doc(selectedDay)
                .get();
        if (doc.exists) {
          final data = doc.data()!;
          actualPriceController.text = data['actual_price']?.toString() ?? '';
          discountedPriceController.text = data['discounted_price']?.toString() ?? '';
        } else {
          actualPriceController.text = '';
          discountedPriceController.text = '';
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: const Text('Change Price'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Type selection
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Listing Services'),
                              value: false,
                              groupValue: isPremiumPlan,
                              onChanged: (value) {
                                setState(() {
                                  isPremiumPlan = value!;
                                  selectedService = null;
                                  selectedPremiumPlan = null;
                                  selectedDay = null;
                                  actualPriceController.clear();
                                  discountedPriceController.clear();
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Premium Plans'),
                              value: true,
                              groupValue: isPremiumPlan,
                              onChanged: (value) {
                                setState(() {
                                  isPremiumPlan = value!;
                                  selectedService = null;
                                  selectedPremiumPlan = null;
                                  selectedDay = null;
                                  actualPriceController.clear();
                                  discountedPriceController.clear();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Service/Premium Plan Selection
                      if (!isPremiumPlan) ...[
                      DropdownButtonFormField<String>(
                        value: selectedService,
                        hint: const Text('Select Service'),
                          items: services
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) async {
                          setState(() {
                            selectedService = val;
                            selectedDay = null;
                            actualPriceController.clear();
                            discountedPriceController.clear();
                          });
                          // If both are selected, fetch prices
                          if (val != null && selectedDay != null) {
                            await fetchPrices();
                            setState(() {});
                          }
                        },
                      ),
                      ] else ...[
                        DropdownButtonFormField<String>(
                          value: selectedPremiumPlan,
                          hint: const Text('Select Premium Plan'),
                          items: premiumPlans
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p.replaceAll('_', ' ').toUpperCase()),
                                ),
                              )
                              .toList(),
                          onChanged: (val) async {
                            setState(() {
                              selectedPremiumPlan = val;
                              actualPriceController.clear();
                              discountedPriceController.clear();
                            });
                            if (val != null) {
                              await fetchPrices();
                              setState(() {});
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (!isPremiumPlan) ...[
                      DropdownButtonFormField<String>(
                        value: selectedDay,
                        hint: const Text('Select Days'),
                          items: dayOptions
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d),
                                  ),
                                )
                                .toList(),
                          onChanged: selectedService == null
                                ? null
                                : (val) async {
                                  setState(() {
                                    selectedDay = val;
                                  });
                                  if (selectedService != null && val != null) {
                                    await fetchPrices();
                                    setState(() {});
                                  }
                                },
                        disabledHint: const Text('Select Service First'),
                      ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: actualPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Actual Price',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: discountedPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Discounted Price',
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (isPremiumPlan) {
                        if (selectedPremiumPlan == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a premium plan'),
                            ),
                          );
                          return;
                        }
                        final price = double.tryParse(actualPriceController.text) ?? 0;
                        final discountedPrice = double.tryParse(discountedPriceController.text) ?? 0;
                        await FirebaseFirestore.instance
                            .collection('premium_plans')
                            .doc(selectedPremiumPlan)
                            .set({
                              'price': price,
                              'discounted_price': discountedPrice,
                            }, SetOptions(merge: true));
                      } else {
                      if (selectedService == null || selectedDay == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select service and days'),
                          ),
                        );
                        return;
                      }
                        final actualPrice = double.tryParse(actualPriceController.text) ?? 0;
                        final discountedPrice = double.tryParse(discountedPriceController.text) ?? 0;
                      await FirebaseFirestore.instance
                          .collection('plan_prices')
                          .doc(selectedService)
                          .collection('day_wise_prices')
                          .doc(selectedDay)
                          .set({
                            'actual_price': actualPrice,
                            'discounted_price': discountedPrice,
                          }, SetOptions(merge: true));
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Price updated!')),
                      );
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
        );
      },
    );
  }
}