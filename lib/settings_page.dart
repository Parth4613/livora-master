import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme.dart';
import '../utils/cache_utils.dart';
import '../api/firebase_api.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  User? _user;
  bool _notificationsEnabled = true;
  bool _twoFactorEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadUserSettings();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  Future<void> _loadUserSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('user_settings')
              .doc(user.uid)
              .get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _notificationsEnabled = data?['notifications_enabled'] ?? true;
          _twoFactorEnabled = data?['two_factor_enabled'] ?? false;
        });
      }
    } catch (e) {
      print('Error loading user settings: $e');
    }
  }

  Future<void> _updateNotificationSettings(bool enabled) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('user_settings')
          .doc(user.uid)
          .set({
            'notifications_enabled': enabled,
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      setState(() {
        _notificationsEnabled = enabled;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Notifications enabled successfully!'
                : 'Notifications disabled successfully!',
          ),
          backgroundColor: BuddyTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating notification settings: $e'),
          backgroundColor: BuddyTheme.errorColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? Colors.black : BuddyTheme.backgroundPrimaryColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor:
            isDark ? Colors.black : BuddyTheme.backgroundPrimaryColor,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: BuddyTheme.spacingMd),
                _buildSettingsSection(isDark),
                const SizedBox(height: BuddyTheme.spacingMd),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(bool isDark) {
    final isEmailUser = _user?.email != null && _user!.email!.isNotEmpty;
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
              'App Settings',
              style: TextStyle(
                fontSize: BuddyTheme.fontSizeLg,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          _buildNotificationSetting(isDark),
          if (isEmailUser)
            _buildMenuOption(
              icon: Icons.email_outlined,
              iconColor: Colors.blue,
              title: 'Change Email / Password',
              onTap: () => _showChangeEmailPasswordDialog(),
              isDark: isDark,
            ),
          _buildMenuOption(
            icon: Icons.bug_report_outlined,
            iconColor: Colors.orange,
            title: 'Feedback / Report a Bug',
            onTap: () => _showFeedbackDialog(),
            isDark: isDark,
          ),
          _buildMenuOption(
            icon: Icons.delete_outline,
            iconColor: BuddyTheme.errorColor,
            title: 'Delete My Account',
            onTap: () => _showDeleteAccountDialog(),
            isLast: true,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSetting(bool isDark) {
    final firebaseApi = FirebaseApi.instance;
    
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(BuddyTheme.spacingXs),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.deepPurple,
              size: BuddyTheme.iconSizeMd,
            ),
          ),
          title: Text(
            'Notification Settings',
            style: TextStyle(
              fontSize: BuddyTheme.fontSizeMd,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : BuddyTheme.textPrimaryColor,
            ),
          ),
          trailing: Switch(
            value: _notificationsEnabled,
            onChanged: _updateNotificationSettings,
            activeColor: BuddyTheme.primaryColor,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: BuddyTheme.spacingMd,
            vertical: BuddyTheme.spacingXs,
          ),
        ),
        // Notification status indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BuddyTheme.spacingMd),
          child: Row(
            children: [
              if (!firebaseApi.notificationsInitialized) ...[
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    await firebaseApi.reinitializeNotifications();
                    setState(() {}); // Refresh UI
                  },
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
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

  Widget _buildMenuOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
    required bool isDark,
    Widget? trailing,
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
          trailing:
              trailing ??
              Icon(
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

  void _showChangeEmailPasswordDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Account Security'),
            content: const Text('Choose what you want to change:'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showChangeEmailDialog();
                },
                child: const Text('Change Email'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showChangePasswordDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BuddyTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Change Password'),
              ),
            ],
          ),
    );
  }

  void _showChangeEmailDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Change Email'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'New Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (emailController.text.isEmpty ||
                      passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields')),
                    );
                    return;
                  }

                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      // Re-authenticate user
                      final credential = EmailAuthProvider.credential(
                        email: user.email!,
                        password: passwordController.text,
                      );
                      await user.reauthenticateWithCredential(credential);

                      // Update email
                      await user.updateEmail(emailController.text);
                      await user.sendEmailVerification();

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Email updated! Please verify your new email.',
                          ),
                          backgroundColor: BuddyTheme.successColor,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: BuddyTheme.errorColor,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BuddyTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Update Email'),
              ),
            ],
          ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Change Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (currentPasswordController.text.isEmpty ||
                      newPasswordController.text.isEmpty ||
                      confirmPasswordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields')),
                    );
                    return;
                  }

                  if (newPasswordController.text !=
                      confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('New passwords do not match'),
                      ),
                    );
                    return;
                  }

                  if (newPasswordController.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password must be at least 6 characters'),
                      ),
                    );
                    return;
                  }

                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      // Re-authenticate user
                      final credential = EmailAuthProvider.credential(
                        email: user.email!,
                        password: currentPasswordController.text,
                      );
                      await user.reauthenticateWithCredential(credential);

                      // Update password
                      await user.updatePassword(newPasswordController.text);

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password updated successfully!'),
                          backgroundColor: BuddyTheme.successColor,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: BuddyTheme.errorColor,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BuddyTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Update Password'),
              ),
            ],
          ),
    );
  }

  void _showTwoFactorDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Two-Factor Authentication'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _twoFactorEnabled ? Icons.security : Icons.security_outlined,
                  size: 48,
                  color:
                      _twoFactorEnabled ? BuddyTheme.successColor : Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _twoFactorEnabled
                      ? 'Two-Factor Authentication is currently enabled for your account.'
                      : 'Enable Two-Factor Authentication to add an extra layer of security to your account.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Here you would implement 2FA logic
                  // For now, we'll just toggle the state
                  await FirebaseFirestore.instance
                      .collection('user_settings')
                      .doc(_user!.uid)
                      .set({
                        'two_factor_enabled': !_twoFactorEnabled,
                        'updated_at': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));

                  setState(() {
                    _twoFactorEnabled = !_twoFactorEnabled;
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _twoFactorEnabled
                            ? '2FA enabled successfully!'
                            : '2FA disabled successfully!',
                      ),
                      backgroundColor: BuddyTheme.successColor,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _twoFactorEnabled
                          ? BuddyTheme.errorColor
                          : BuddyTheme.successColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(_twoFactorEnabled ? 'Disable 2FA' : 'Enable 2FA'),
              ),
            ],
          ),
    );
  }

  void _showFeedbackDialog() {
    final feedbackController = TextEditingController();
    String feedbackType = 'feedback';

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Feedback / Report a Bug'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          value: feedbackType,
                          items: const [
                            DropdownMenuItem(
                              value: 'feedback',
                              child: Text('General Feedback'),
                            ),
                            DropdownMenuItem(
                              value: 'bug',
                              child: Text('Bug Report'),
                            ),
                            DropdownMenuItem(
                              value: 'feature',
                              child: Text('Feature Request'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              feedbackType = value!;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            prefixIcon: Icon(Icons.category),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: feedbackController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Your message',
                            hintText:
                                'Please describe your feedback or the bug you encountered...',
                            prefixIcon: Icon(Icons.message),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      BuddyTheme.borderRadiusMd,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (feedbackController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter your feedback'),
                            ),
                          );
                          return;
                        }

                        try {
                          await FirebaseFirestore.instance
                              .collection('feedback')
                              .add({
                                'user_id': _user!.uid,
                                'user_email': _user!.email,
                                'type': feedbackType,
                                'message': feedbackController.text,
                                'timestamp': FieldValue.serverTimestamp(),
                              });

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Thank you for your feedback!'),
                              backgroundColor: BuddyTheme.successColor,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error submitting feedback: $e'),
                              backgroundColor: BuddyTheme.errorColor,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BuddyTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Submit'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Delete Account',
              style: TextStyle(color: BuddyTheme.errorColor),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning,
                  size: 48,
                  color: BuddyTheme.errorColor,
                ),
                const SizedBox(height: 16),
                const Text(
                  'This action cannot be undone. All your data will be permanently deleted.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      // Delete user data from Firestore
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .delete();

                      await FirebaseFirestore.instance
                          .collection('user_settings')
                          .doc(user.uid)
                          .delete();

                      // Clear all caches before account deletion
                      await CacheUtils.clearAllCaches();

                      // Delete user account
                      await user.delete();

                      Navigator.pop(context);
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Account deleted successfully'),
                          backgroundColor: BuddyTheme.successColor,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting account: $e'),
                        backgroundColor: BuddyTheme.errorColor,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BuddyTheme.errorColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete Account'),
              ),
            ],
          ),
    );
  }
}