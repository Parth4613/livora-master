import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BuddyTheme {
  // Primary colors
  static const Color primaryColor = Color(0xFF3D82F2);  // Blue color from the app images
  static const Color secondaryColor = Color(0xFF6BBBF7);  // Lighter blue for secondary elements
  static const Color accentColor = Color(0xFF2D9CDB);  // Accent color for highlights

  // Text colors
  static const Color textPrimaryColor = Color(0xFF2C3A47);  // Dark color for primary text
  static const Color textSecondaryColor = Color(0xFF7F8C8D);  // Gray for secondary text
  static const Color textLightColor = Color(0xFFFFFFFF);  // White text for dark backgrounds

  // Background colors
  static const Color backgroundPrimaryColor = Color(0xFFFFFFFF);  // White for primary background
  static const Color backgroundSecondaryColor = Color(0xFFF5F6FA);  // Light gray for secondary background
  static const Color cardColor = Color(0xFFFFFFFF);  // White for cards

  // Status colors
  static const Color successColor = Color(0xFF2ECC71);  // Green for success states
  static const Color warningColor = Color(0xFFF1C40F);  // Yellow for warning states
  static const Color errorColor = Color(0xFFE74C3C);  // Red for error states
  static const Color infoColor = Color(0xFF3498DB);  // Blue for information states

  // Border and divider colors
  static const Color borderColor = Color(0xFFE0E0E0);  // Light gray for borders
  static const Color dividerColor = Color(0xFFECECEC);  // Lighter gray for dividers

  // Button colors
  static const Color buttonPrimaryColor = primaryColor;
  static const Color buttonTextColor = textLightColor;

  // Spacing values
  static const double spacingXxs = 4.0;
  static const double spacingXs = 8.0;
  static const double spacingSm = 12.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // Border radius values
  static const double borderRadiusXs = 4.0;
  static const double borderRadiusSm = 8.0;
  static const double borderRadiusMd = 12.0;
  static const double borderRadiusLg = 16.0;
  static const double borderRadiusXl = 24.0;
  static const double borderRadiusXxl = 32.0;
  static const double borderRadiusCircular = 100.0;

  // Elevation values
  static const double elevationXs = 2.0;
  static const double elevationSm = 4.0;
  static const double elevationMd = 8.0;
  static const double elevationLg = 16.0;
  static const double elevationXl = 24.0;

  // Font sizes
  static const double fontSizeXs = 12.0;
  static const double fontSizeSm = 14.0;
  static const double fontSizeMd = 16.0;
  static const double fontSizeLg = 18.0;
  static const double fontSizeXl = 20.0;
  static const double fontSizeXxl = 24.0;
  static const double fontSizeDisplay = 32.0;

  // Icon sizes
  static const double iconSizeSm = 16.0;
  static const double iconSizeMd = 24.0;
  static const double iconSizeLg = 32.0;
  static const double iconSizeXl = 48.0;

  // Validation colors
  static const Color validationSuccessColor = Color(0xFF27AE60);  // Darker green for success
  static const Color validationErrorColor = Color(0xFFE74C3C);    // Red for errors
  static const Color validationWarningColor = Color(0xFFF39C12);  // Orange for warnings
  static const Color validationInfoColor = Color(0xFF3498DB);     // Blue for info
  static const Color validationNeutralColor = Color(0xFF95A5A6);  // Gray for neutral states

  // Validation background colors
  static const Color validationSuccessBgColor = Color(0xFFD5F4E6);  // Light green background
  static const Color validationErrorBgColor = Color(0xFFFADBD8);    // Light red background
  static const Color validationWarningBgColor = Color(0xFFFDEAA7);  // Light orange background
  static const Color validationInfoBgColor = Color(0xFFD6EAF8);     // Light blue background

  // Validation border colors
  static const Color validationSuccessBorderColor = Color(0xFFA9DFBF);
  static const Color validationErrorBorderColor = Color(0xFFF5B7B1);
  static const Color validationWarningBorderColor = Color(0xFFF8C471);
  static const Color validationInfoBorderColor = Color(0xFFA9CCE3);

  // Validation text colors
  static const Color validationSuccessTextColor = Color(0xFF1E8449);
  static const Color validationErrorTextColor = Color(0xFFC0392B);
  static const Color validationWarningTextColor = Color(0xFFD68910);
  static const Color validationInfoTextColor = Color(0xFF2874A6);

  // Get the app theme data
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        background: backgroundPrimaryColor,
      ),
      scaffoldBackgroundColor: backgroundPrimaryColor,
      fontFamily: 'Roboto',
      textTheme: _buildTextTheme(),
      appBarTheme: _buildAppBarTheme(),
      cardTheme: _buildCardTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(),
      dividerTheme: _buildDividerTheme(),
      iconTheme: _buildIconTheme(),
      bottomNavigationBarTheme: _buildBottomNavigationBarTheme(),
      tabBarTheme: _buildTabBarTheme(),
      floatingActionButtonTheme: _buildFloatingActionButtonTheme(),
    );
  }

  // Dark theme variant
  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        background: const Color(0xFF121212),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      fontFamily: 'Roboto',
      textTheme: _buildDarkTextTheme(),
      appBarTheme: _buildDarkAppBarTheme(),
      cardTheme: _buildDarkCardTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildDarkOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      inputDecorationTheme: _buildDarkInputDecorationTheme(),
      dividerTheme: _buildDarkDividerTheme(),
      iconTheme: _buildDarkIconTheme(),
      bottomNavigationBarTheme: _buildDarkBottomNavigationBarTheme(),
      tabBarTheme: _buildDarkTabBarTheme(),
      floatingActionButtonTheme: _buildFloatingActionButtonTheme(),
    );
  }

  // Build text theme
  static TextTheme _buildTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(
        fontSize: fontSizeDisplay,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      displayMedium: TextStyle(
        fontSize: fontSizeXxl,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      displaySmall: TextStyle(
        fontSize: fontSizeXl,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      headlineMedium: TextStyle(
        fontSize: fontSizeLg,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      headlineSmall: TextStyle(
        fontSize: fontSizeMd,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      titleLarge: TextStyle(
        fontSize: fontSizeMd,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      titleMedium: TextStyle(
        fontSize: fontSizeSm,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      titleSmall: TextStyle(
        fontSize: fontSizeXs,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      bodyLarge: TextStyle(
        fontSize: fontSizeMd,
        color: textPrimaryColor,
      ),
      bodyMedium: TextStyle(
        fontSize: fontSizeSm,
        color: textPrimaryColor,
      ),
      bodySmall: TextStyle(
        fontSize: fontSizeXs,
        color: textSecondaryColor,
      ),
      labelLarge: TextStyle(
        fontSize: fontSizeSm,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
    );
  }

  // Build dark text theme
  static TextTheme _buildDarkTextTheme() {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: fontSizeDisplay,
        fontWeight: FontWeight.bold,
        color: Colors.white.withOpacity(0.87),
      ),
      displayMedium: TextStyle(
        fontSize: fontSizeXxl,
        fontWeight: FontWeight.bold,
        color: Colors.white.withOpacity(0.87),
      ),
      displaySmall: TextStyle(
        fontSize: fontSizeXl,
        fontWeight: FontWeight.bold,
        color: Colors.white.withOpacity(0.87),
      ),
      headlineMedium: TextStyle(
        fontSize: fontSizeLg,
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(0.87),
      ),
      headlineSmall: TextStyle(
        fontSize: fontSizeMd,
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(0.87),
      ),
      titleLarge: TextStyle(
        fontSize: fontSizeMd,
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(0.87),
      ),
      titleMedium: TextStyle(
        fontSize: fontSizeSm,
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(0.87),
      ),
      titleSmall: TextStyle(
        fontSize: fontSizeXs,
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(0.87),
      ),
      bodyLarge: TextStyle(
        fontSize: fontSizeMd,
        color: Colors.white.withOpacity(0.87),
      ),
      bodyMedium: TextStyle(
        fontSize: fontSizeSm,
        color: Colors.white.withOpacity(0.87),
      ),
      bodySmall: TextStyle(
        fontSize: fontSizeXs,
        color: Colors.white.withOpacity(0.60),
      ),
      labelLarge: TextStyle(
        fontSize: fontSizeSm,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
    );
  }

  // Build app bar theme
  static AppBarTheme _buildAppBarTheme() {
    return const AppBarTheme(
      color: backgroundPrimaryColor,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: textPrimaryColor),
      titleTextStyle: TextStyle(
        color: textPrimaryColor,
        fontSize: fontSizeLg,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // Build dark app bar theme
  static AppBarTheme _buildDarkAppBarTheme() {
    return AppBarTheme(
      color: const Color(0xFF121212),
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: Colors.white.withOpacity(0.87)),
      titleTextStyle: TextStyle(
        color: Colors.white.withOpacity(0.87),
        fontSize: fontSizeLg,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // Build card theme
  static CardThemeData _buildCardTheme() {
    return CardThemeData(
      color: cardColor,
      elevation: elevationXs,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusMd),
      ),
      margin: const EdgeInsets.all(spacingXs),
    );
  }

  // Build dark card theme
  static CardThemeData _buildDarkCardTheme() {
    return CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: elevationXs,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusMd),
      ),
      margin: const EdgeInsets.all(spacingXs),
    );
  }

  // Build elevated button theme
  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonPrimaryColor,
        foregroundColor: buttonTextColor,
        elevation: elevationXs,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusSm),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: spacingSm,
          horizontal: spacingMd,
        ),
        textStyle: const TextStyle(
          fontSize: fontSizeSm,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Build outlined button theme
  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusSm),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: spacingSm,
          horizontal: spacingMd,
        ),
        textStyle: const TextStyle(
          fontSize: fontSizeSm,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Build dark outlined button theme
  static OutlinedButtonThemeData _buildDarkOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusSm),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: spacingSm,
          horizontal: spacingMd,
        ),
        textStyle: const TextStyle(
          fontSize: fontSizeSm,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Build text button theme
  static TextButtonThemeData _buildTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusSm),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: spacingXs,
          horizontal: spacingSm,
        ),
        textStyle: const TextStyle(
          fontSize: fontSizeSm,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Build input decoration theme
  static InputDecorationTheme _buildInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade200,
      contentPadding: const EdgeInsets.symmetric(
        vertical: spacingSm,
        horizontal: spacingMd,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusSm),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusSm),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusSm),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusSm),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      hintStyle: TextStyle(
        color: textSecondaryColor.withOpacity(0.7),
        fontSize: fontSizeSm,
      ),
      labelStyle: const TextStyle(
        color: textSecondaryColor,
        fontSize: fontSizeSm,
      ),
      errorStyle: const TextStyle(
        color: errorColor,
        fontSize: fontSizeXs,
      ),
    );
  }

  // Build dark input decoration theme
  static InputDecorationTheme _buildDarkInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      contentPadding: const EdgeInsets.symmetric(
        vertical: spacingSm,
        horizontal: spacingMd,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusSm),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusSm),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusSm),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusSm),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: fontSizeSm,
      ),
      labelStyle: TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontSize: fontSizeSm,
      ),
      errorStyle: const TextStyle(
        color: errorColor,
        fontSize: fontSizeXs,
      ),
    );
  }

  // Build divider theme
  static DividerThemeData _buildDividerTheme() {
    return const DividerThemeData(
      color: dividerColor,
      space: spacingMd,
      thickness: 1,
    );
  }

  // Build dark divider theme
  static DividerThemeData _buildDarkDividerTheme() {
    return DividerThemeData(
      color: Colors.white.withOpacity(0.1),
      space: spacingMd,
      thickness: 1,
    );
  }

  // Build icon theme
  static IconThemeData _buildIconTheme() {
    return const IconThemeData(
      color: textPrimaryColor,
      size: iconSizeMd,
    );
  }

  // Build dark icon theme
  static IconThemeData _buildDarkIconTheme() {
    return IconThemeData(
      color: Colors.white.withOpacity(0.87),
      size: iconSizeMd,
    );
  }

  // Bottom navigation bar theme
  static BottomNavigationBarThemeData _buildBottomNavigationBarTheme() {
    return const BottomNavigationBarThemeData(
      backgroundColor: backgroundPrimaryColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondaryColor,
      selectedLabelStyle: TextStyle(
        fontSize: fontSizeXs,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: fontSizeXs,
        fontWeight: FontWeight.w500,
      ),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: elevationMd,
    );
  }

  // Dark bottom navigation bar theme
  static BottomNavigationBarThemeData _buildDarkBottomNavigationBarTheme() {
    return BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.white.withOpacity(0.6),
      selectedLabelStyle: const TextStyle(
        fontSize: fontSizeXs,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: fontSizeXs,
        fontWeight: FontWeight.w500,
      ),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: elevationMd,
    );
  }

  // Tab bar theme
  static TabBarThemeData _buildTabBarTheme() {
    return const TabBarThemeData(
      labelColor: primaryColor,
      unselectedLabelColor: textSecondaryColor,
      indicatorColor: primaryColor,
      labelStyle: TextStyle(
        fontSize: fontSizeSm,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: fontSizeSm,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // Dark tab bar theme
  static TabBarThemeData _buildDarkTabBarTheme() {
    return TabBarThemeData(
      labelColor: primaryColor,
      unselectedLabelColor: Colors.white.withOpacity(0.6),
      indicatorColor: primaryColor,
      labelStyle: const TextStyle(
        fontSize: fontSizeSm,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: fontSizeSm,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // Floating action button theme
  static FloatingActionButtonThemeData _buildFloatingActionButtonTheme() {
    return const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: textLightColor,
      elevation: elevationSm,
      highlightElevation: elevationMd,
    );
  }

  // Card decorations
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(borderRadiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get featuredCardDecoration => BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(borderRadiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration get fabShadowDecoration => BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  // Custom search field decoration based on the images
  static InputDecoration searchInputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: textSecondaryColor.withOpacity(0.7),
        fontSize: fontSizeMd,
      ),
      prefixIcon: const Icon(Icons.search, color: textSecondaryColor),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMd),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: spacingSm,
        horizontal: spacingMd,
      ),
    );
  }

  // Room card decoration based on image 1
  static BoxDecoration get roomCardDecoration {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(borderRadiusMd),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Room available tag decoration based on image 1
  static BoxDecoration get roomAvailableTagDecoration {
    return BoxDecoration(
      color: successColor,
      borderRadius: BorderRadius.circular(borderRadiusXs),
    );
  }
  // Post ad button style based on image 2

  // Post ad button style based on image 2
  static ButtonStyle get postAdButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: textLightColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusSm),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: spacingSm,
        horizontal: spacingMd,
      ),
    );
  }

  // Floating action button style based on both images
  static BoxDecoration get fabDecoration {
    return const BoxDecoration(
      shape: BoxShape.circle,
      color: primaryColor,
    );
  }
}