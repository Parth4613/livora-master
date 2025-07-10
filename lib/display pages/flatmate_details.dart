import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme.dart';
import '../chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../widgets/premium_plan_prompt_sheet.dart';
import '../utils/cache_utils.dart';

class FlatmateDetailsPage extends StatefulWidget {
  final Map<String, dynamic> flatmateData;

  const FlatmateDetailsPage({Key? key, required this.flatmateData})
    : super(key: key);

  @override
  State<FlatmateDetailsPage> createState() => _FlatmateDetailsPageState();
}

class _FlatmateDetailsPageState extends State<FlatmateDetailsPage> {
  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'Flexible';
    try {
      if (dateValue is Timestamp) {
        final dt = dateValue.toDate();
        return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
      } else if (dateValue is DateTime) {
        return '${dateValue.day.toString().padLeft(2, '0')}-${dateValue.month.toString().padLeft(2, '0')}-${dateValue.year}';
      } else if (dateValue is String && dateValue.isNotEmpty) {
        final dt = DateTime.tryParse(dateValue);
        if (dt != null) {
          return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
        }
        // fallback: try to format as DD-MM-YYYY if string is already in that format
        final parts = dateValue.split('T')[0].split('-');
        if (parts.length == 3) {
          return '${parts[2]}-${parts[1]}-${parts[0]}'; // DD-MM-YYYY
        }
        return dateValue;
      }
      return dateValue.toString();
    } catch (e) {
      return dateValue.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(BuddyTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(theme),
            const SizedBox(height: BuddyTheme.spacingLg),
            _buildSectionHeader(theme, 'Basic Information'),
            _buildBasicInformation(theme),
            const SizedBox(height: BuddyTheme.spacingLg),
            _buildSectionHeader(theme, 'Budget & Timeline'),
            _buildBudgetAndMoveIn(theme),
            const SizedBox(height: BuddyTheme.spacingLg),
            _buildSectionHeader(theme, 'Room Preferences'),
            _buildRoomPreferences(theme),
            const SizedBox(height: BuddyTheme.spacingLg),
            _buildSectionHeader(theme, 'Flatmate Preferences'),
            _buildFlatmatePreferences(theme),
            const SizedBox(height: BuddyTheme.spacingLg),
            _buildSectionHeader(theme, 'Lifestyle Preferences'),
            _buildLifestylePreferences(theme),
            const SizedBox(height: BuddyTheme.spacingLg),
            if (widget.flatmateData['bio']?.isNotEmpty ?? false) ...[
              _buildSectionHeader(theme, 'About'),
              _buildAboutSection(theme),
              const SizedBox(height: BuddyTheme.spacingXl),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;
    return Padding(
      padding: const EdgeInsets.only(bottom: BuddyTheme.spacingSm),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark
            ? Color.alphaBlend(
              Colors.white.withOpacity(0.06),
              theme.cardColor,
        )
            : Color.alphaBlend(
              Colors.black.withOpacity(0.04),
              theme.cardColor,
        );
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.black54;

    // Debug logging for image URL
    final String? imageUrl = widget.flatmateData['profilePhotoUrl'] as String?;
    print('Flatmate Details photo URL: $imageUrl');
    print('Flatmate Details data: ${widget.flatmateData.toString()}');

    // Validate and fix the image URL
    final String? validatedImageUrl = CacheUtils.validateImageUrl(imageUrl);
    if (validatedImageUrl != imageUrl) {
      print('Flatmate Details Image URL validated/fixed: $validatedImageUrl');
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
      ),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Row(
        children: [
          validatedImageUrl != null && validatedImageUrl.isNotEmpty
              ? FutureBuilder<bool>(
                  future: CacheUtils.isImageUrlAccessible(validatedImageUrl),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: BuddyTheme.secondaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      );
                    }
                    
                    final isAccessible = snapshot.data ?? false;
                    if (!isAccessible) {
                      print('Flatmate details image not accessible, showing placeholder');
                      return CircleAvatar(
            radius: 40,
            backgroundColor: BuddyTheme.secondaryColor,
                        child: Text(
                          widget.flatmateData['name']?.substring(0, 1).toUpperCase() ?? 'U',
                          style: TextStyle(
                            fontSize: BuddyTheme.fontSizeXl,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSecondary,
                          ),
                        ),
                      );
                    }
                    
                    return ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: validatedImageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 80,
                          height: 80,
                          color: BuddyTheme.secondaryColor,
                          child: Text(
                            widget.flatmateData['name']?.substring(0, 1).toUpperCase() ?? 'U',
                            style: TextStyle(
                              fontSize: BuddyTheme.fontSizeXl,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSecondary,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          print('Flatmate Details CachedNetworkImage error for URL: $url');
                          print('Error: $error');
                          return Container(
                            width: 80,
                            height: 80,
                            color: BuddyTheme.secondaryColor,
                            child: Text(
                              widget.flatmateData['name']?.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        fontSize: BuddyTheme.fontSizeXl,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSecondary,
                      ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                    )
              : CircleAvatar(
                  radius: 40,
                  backgroundColor: BuddyTheme.secondaryColor,
                  child: Text(
                    widget.flatmateData['name']?.substring(0, 1).toUpperCase() ?? 'U',
                    style: TextStyle(
                      fontSize: BuddyTheme.fontSizeXl,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondary,
                    ),
                  ),
          ),
          const SizedBox(width: BuddyTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.flatmateData['name'] ?? 'Unknown',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: BuddyTheme.spacingXxs),
                Text(
                  '${widget.flatmateData['age'] ?? 'N/A'} • ${widget.flatmateData['occupation'] ?? 'N/A'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: BuddyTheme.spacingXs),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: BuddyTheme.iconSizeSm,
                      color: textSecondary,
                    ),
                    const SizedBox(width: BuddyTheme.spacingXxs),
                    Expanded(
                      child: Text(
                        widget.flatmateData['location'] ?? 'Location not specified',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInformation(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            theme: theme,
            icon: Icons.person,
            title: 'Gender',
            value: widget.flatmateData['gender'] ?? 'Not specified',
            iconColor: BuddyTheme.primaryColor,
          ),
        ),
        const SizedBox(width: BuddyTheme.spacingMd),
        Expanded(
          child: _buildInfoCard(
            theme: theme,
            icon: Icons.work,
            title: 'Occupation',
            value: widget.flatmateData['occupation'] ?? 'Not specified',
            iconColor: BuddyTheme.accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetAndMoveIn(ThemeData theme) {
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.black54;

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: BuddyTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            ),
            padding: const EdgeInsets.all(BuddyTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budget Range',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: BuddyTheme.spacingXs),
                Text(
                  '₹${widget.flatmateData['minBudget'] ?? '0'} - ₹${widget.flatmateData['maxBudget'] ?? '0'}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: BuddyTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: BuddyTheme.spacingMd),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: BuddyTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            ),
            padding: const EdgeInsets.all(BuddyTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Move-in Date',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: BuddyTheme.spacingXs),
                Text(
                  _formatDate(widget.flatmateData['moveInDate']),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: BuddyTheme.successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomPreferences(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            theme: theme,
            icon: Icons.bed,
            title: 'Room Type',
            value: widget.flatmateData['preferredRoomType'] ?? 'Any',
            iconColor: BuddyTheme.primaryColor,
          ),
        ),
        const SizedBox(width: BuddyTheme.spacingMd),
        Expanded(
          child: _buildInfoCard(
            theme: theme,
            icon: Icons.chair,
            title: 'Furnishing',
            value: widget.flatmateData['furnishingPreference'] ?? 'Any',
            iconColor: BuddyTheme.accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFlatmatePreferences(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            theme: theme,
            icon: Icons.group,
            title: 'Number of Flatmates',
            value: widget.flatmateData['preferredFlatmates']?.toString() ?? 'Any',
            iconColor: BuddyTheme.primaryColor,
          ),
        ),
        const SizedBox(width: BuddyTheme.spacingMd),
        Expanded(
          child: _buildInfoCard(
            theme: theme,
            icon: Icons.people,
            title: 'Flatmate Gender',
            value: widget.flatmateData['preferredFlatmateGender'] ?? 'Any',
            iconColor: BuddyTheme.secondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLifestylePreferences(ThemeData theme) {
    // Use this for all cardColor assignments in your widgets
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Color.alphaBlend(
              Colors.white.withOpacity(0.06),
              theme.cardColor,
            ) // lighter in dark mode
            : Color.alphaBlend(
              Colors.black.withOpacity(0.04),
              theme.cardColor,
            ); // darker in light mode

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
      ),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        children: [
          _buildPreferenceRow(
            theme,
            Icons.restaurant,
            'Food Preference',
            widget.flatmateData['foodPreference'] ?? 'No preference',
          ),
          Divider(height: BuddyTheme.spacingLg),
          _buildPreferenceRow(
            theme,
            Icons.smoking_rooms,
            'Smoking',
            widget.flatmateData['smokingPreference'] ?? 'No preference',
          ),
          Divider(height: BuddyTheme.spacingLg),
          _buildPreferenceRow(
            theme,
            Icons.local_bar,
            'Drinking',
            widget.flatmateData['drinkingPreference'] ?? 'No preference',
          ),
          Divider(height: BuddyTheme.spacingLg),
          _buildPreferenceRow(
            theme,
            Icons.bedroom_parent,
            'Flat Size Preference',
            widget.flatmateData['preferredRoomSize'] ?? 'No preference',
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(ThemeData theme) {
    final cardColor = theme.cardColor;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      width: double.infinity,
      child: Text(
        widget.flatmateData['bio']!,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: textPrimary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    // Use this for all cardColor assignments in your widgets
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Color.alphaBlend(
              Colors.white.withOpacity(0.06),
              theme.cardColor,
            ) // lighter in dark mode
            : Color.alphaBlend(
              Colors.black.withOpacity(0.04),
              theme.cardColor,
            ); // darker in light mode
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
      ),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(BuddyTheme.spacingXs),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
            ),
            child: Icon(icon, color: iconColor, size: BuddyTheme.iconSizeMd),
          ),
          const SizedBox(height: BuddyTheme.spacingXs),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: BuddyTheme.fontSizeXs,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: BuddyTheme.spacingXxs),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceRow(
    ThemeData theme,
    IconData icon,
    String title,
    String value,
  ) {
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.black54;

    return Row(
      children: [
        Icon(icon, color: BuddyTheme.primaryColor, size: BuddyTheme.iconSizeMd),
        const SizedBox(width: BuddyTheme.spacingMd),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(color: textSecondary),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  if (!await UserService.hasActivePlan()) {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (ctx) => const PremiumPlanPromptSheet(),
                    );
                    return;
                  }
                  final Uri phoneUri = Uri(
                    scheme: 'tel',
                    path: widget.flatmateData['phone'] ?? '',
                  );
                  await launchUrl(phoneUri);
                },
                icon: const Icon(Icons.phone),
                label: const Text('Call'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BuddyTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: BuddyTheme.spacingMd),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (!await UserService.hasActivePlan()) {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (ctx) => const PremiumPlanPromptSheet(),
                    );
                    return;
                  }
                  final otherUserId = widget.flatmateData['userId'];
                  final otherUserName = widget.flatmateData['name'] ?? 'User';
                  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                  if (otherUserId == null || otherUserId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No user ID found for this user.')),
                    );
                    return;
                  }
                  if (currentUserId == otherUserId) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You cannot chat with yourself.')),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        otherUserId: otherUserId,
                        otherUserName: otherUserName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat),
                label: const Text('Message'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
