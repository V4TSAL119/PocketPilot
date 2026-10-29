import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Available themes in PocketPilot
enum AppThemePreset {
  nordicNavy,
  forestSage,
  obsidianDark,
  warmAmber,
}

class AppTheme {
  // ===========================================================================
  // PALETTE 1: NORDIC NAVY (Executive Navy & Mint Emerald)
  // ===========================================================================
  static const Color lightBackground = Color(0xFFF7F9FC); // User requested
  static const Color lightCard = Color(0xFFFFFFFF); // User requested
  static const Color lightSurfaceSecondary = Color(0xFFEDF2F7);
  static const Color lightBorderSubtle = Color(0xFFE2E8F0);
  static const Color lightBorderFocused = Color(0xFF142D4E);
  static const Color lightTextPrimary = Color(0xFF172033); // User requested
  static const Color lightTextSecondary = Color(0xFF5C6B82);
  static const Color lightTextMuted = Color(0xFF8491A5); // User requested

  static const Color primaryNavy = Color(0xFF142D4E); // User requested primary
  static const Color primaryNavyDark = Color(0xFF0E1F36);
  static const Color primaryNavyLight = Color(0xFF1E3A8A);

  static const Color emeraldGreen = Color(0xFF10B981); // User requested accent
  static const Color emeraldGreenDark = Color(0xFF065F46);
  static const Color emeraldGreenGlow = Color(0x2E10B981);

  // ===========================================================================
  // PALETTE 2: FOREST SAGE (Organic Pine & Mineral Sage - User Requested)
  // ===========================================================================
  static const Color sageBackground = Color(0xFFF7F6F0); // User requested #F7F6F0
  static const Color sageCard = Color(0xFFFFFFFF); // User requested #FFFFFF
  static const Color sageSurfaceSecondary = Color(0xFFEDF1EC);
  static const Color sageBorderSubtle = Color(0xFFE2E7E0);
  static const Color sageBorderFocused = Color(0xFF365747);
  static const Color sageTextPrimary = Color(0xFF26352D); // User requested #26352D
  static const Color sageTextSecondary = Color(0xFF53665A);
  static const Color sageTextMuted = Color(0xFF89968C); // User requested #89968C

  static const Color sagePrimary = Color(0xFF365747); // User requested #365747
  static const Color sagePrimaryDark = Color(0xFF243B30);
  static const Color sagePrimaryLight = Color(0xFF4A725E);

  static const Color sageAccent = Color(0xFF84A98C); // User requested #84A98C
  static const Color sageAccentDark = Color(0xFF5B8264);
  static const Color sageAccentGlow = Color(0x3384A98C);

  // ===========================================================================
  // PALETTE 3: OBSIDIAN DARK (Midnight Slate & Emerald Glow)
  // ===========================================================================
  static const Color darkBackground = Color(0xFF0B0F17);
  static const Color darkCard = Color(0xFF151E2E);
  static const Color darkSurfaceSecondary = Color(0xFF1E293B);
  static const Color darkBorderSubtle = Color(0xFF26334D);
  static const Color darkBorderFocused = Color(0xFF10B981);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Shared semantic colors
  static const Color tastefulRed = Color(0xFFEF4444);
  static const Color redDark = Color(0xFF991B1B);
  static const Color redGlow = Color(0x2EEF4444);

  // ===========================================================================
  // PALETTE 4: WARM AMBER (Earthy Professional - Agent Choice)
  // ===========================================================================
  static const Color warmBackground = Color(0xFFFFFBF5);
  static const Color warmCard = Color(0xFFFFFFFF);
  static const Color warmSurfaceSecondary = Color(0xFFFEF3E2);
  static const Color warmBorderSubtle = Color(0xFFF0E6D3);
  static const Color warmBorderFocused = Color(0xFF92400E);
  static const Color warmTextPrimary = Color(0xFF1C1917);
  static const Color warmTextSecondary = Color(0xFF57534E);
  static const Color warmTextMuted = Color(0xFF78716C);

  static const Color warmPrimary = Color(0xFF92400E);
  static const Color warmPrimaryDark = Color(0xFF78350F);
  static const Color warmPrimaryLight = Color(0xFFB45309);

  static const Color warmAccent = Color(0xFFD97706);
  static const Color warmAccentDark = Color(0xFFB45309);
  static const Color warmAccentGlow = Color(0x33D97706);

  // ===========================================================================
  // THEME CONTROLLERS & STATE
  // ===========================================================================
  static final ValueNotifier<AppThemePreset> currentThemeNotifier =
      ValueNotifier<AppThemePreset>(AppThemePreset.nordicNavy);

  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static AppThemePreset get currentTheme => currentThemeNotifier.value;
  static bool get isDark => currentTheme == AppThemePreset.obsidianDark;

  /// Human-readable title of current active theme
  static String get currentThemeTitle {
    switch (currentTheme) {
      case AppThemePreset.nordicNavy:
        return 'Nordic Navy';
      case AppThemePreset.forestSage:
        return 'Forest Sage';
      case AppThemePreset.obsidianDark:
        return 'Obsidian Dark';
      case AppThemePreset.warmAmber:
        return 'Warm Amber';
    }
  }

  /// Compact 1-word label for pills and buttons
  static String get currentThemePillLabel {
    switch (currentTheme) {
      case AppThemePreset.nordicNavy:
        return 'Navy';
      case AppThemePreset.forestSage:
        return 'Sage';
      case AppThemePreset.obsidianDark:
        return 'Dark';
      case AppThemePreset.warmAmber:
        return 'Amber';
    }
  }

  /// Subtitle description of active theme
  static String get currentThemeDescription {
    switch (currentTheme) {
      case AppThemePreset.nordicNavy:
        return 'Executive Navy #142D4E & Emerald #10B981';
      case AppThemePreset.forestSage:
        return 'Organic Pine #365747 & Mineral Sage #84A98C';
      case AppThemePreset.obsidianDark:
        return 'Midnight Slate #0B0F17 & Emerald Glow';
      case AppThemePreset.warmAmber:
        return 'Earthy Amber #92400E & Golden #D97706';
    }
  }

  /// Loads persisted theme preference from local storage
  static Future<void> initTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPreset = prefs.getString('app_theme_preset');
      if (savedPreset != null) {
        final preset = AppThemePreset.values.firstWhere(
          (e) => e.name == savedPreset,
          orElse: () => AppThemePreset.nordicNavy,
        );
        currentThemeNotifier.value = preset;
        themeModeNotifier.value =
            preset == AppThemePreset.obsidianDark ? ThemeMode.dark : ThemeMode.light;
      } else {
        final isDarkSaved = prefs.getBool('is_dark_theme');
        if (isDarkSaved == true) {
          currentThemeNotifier.value = AppThemePreset.obsidianDark;
          themeModeNotifier.value = ThemeMode.dark;
        }
      }
    } catch (_) {}
  }

  /// Sets the active theme preset and persists choice
  static Future<void> setPreset(AppThemePreset preset) async {
    currentThemeNotifier.value = preset;
    themeModeNotifier.value =
        preset == AppThemePreset.obsidianDark ? ThemeMode.dark : ThemeMode.light;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_theme_preset', preset.name);
      await prefs.setBool('is_dark_theme', preset == AppThemePreset.obsidianDark);
    } catch (_) {}
  }

  /// Cycles seamlessly to the next theme in sequence with a single action
  /// Nordic Navy -> Forest Sage -> Obsidian Dark -> Warm Amber -> Nordic Navy
  static Future<void> cycleTheme() async {
    final nextPreset = switch (currentTheme) {
      AppThemePreset.nordicNavy => AppThemePreset.forestSage,
      AppThemePreset.forestSage => AppThemePreset.obsidianDark,
      AppThemePreset.obsidianDark => AppThemePreset.warmAmber,
      AppThemePreset.warmAmber => AppThemePreset.nordicNavy,
    };
    await setPreset(nextPreset);
  }

  /// Compatibility toggle: cycles to next theme
  static Future<void> toggleTheme() async {
    await cycleTheme();
  }

  /// Sets ThemeMode for backward compatibility
  static Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == ThemeMode.dark) {
      await setPreset(AppThemePreset.obsidianDark);
    } else {
      if (currentTheme == AppThemePreset.obsidianDark) {
        await setPreset(AppThemePreset.nordicNavy);
      }
    }
  }

  // ===========================================================================
  // DYNAMIC CONTEXTUAL GETTERS (Adapts automatically based on active preset)
  // ===========================================================================
  static Color get background {
    switch (currentTheme) {
      case AppThemePreset.nordicNavy:
        return lightBackground;
      case AppThemePreset.forestSage:
        return sageBackground;
      case AppThemePreset.obsidianDark:
        return darkBackground;
      case AppThemePreset.warmAmber:
        return warmBackground;
    }
  }

  static Color get card {
    switch (currentTheme) {
      case AppThemePreset.nordicNavy:
        return lightCard;
      case AppThemePreset.forestSage:
        return sageCard;
      case AppThemePreset.obsidianDark:
        return darkCard;
      case AppThemePreset.warmAmber:
        return warmCard;
    }
  }

  static Color get surfaceSecondary {
    switch (currentTheme) {
      case AppThemePreset.nordicNavy:
        return lightSurfaceSecondary;
      case AppThemePreset.forestSage:
        return sageSurfaceSecondary;
      case AppThemePreset.obsidianDark:
        return darkSurfaceSecondary;
      case AppThemePreset.warmAmber:
        return warmSurfaceSecondary;
    }
  }

  static Color get borderSubtle {
    switch (currentTheme) {
      case AppThemePreset.nordicNavy:
        return lightBorderSubtle;
      case AppThemePreset.forestSage:
        return sageBorderSubtle;
      case AppThemePreset.obsidianDark:
        return darkBorderSubtle;
      case AppThemePreset.warmAmber:
        return warmBorderSubtle;
    }
  }

  static Color get borderFocused {
    switch (currentTheme) {
      case AppThemePreset.nordicNavy:
        return lightBorderFocused;
      case AppThemePreset.forestSage:
        return sageBorderFocused;
      case AppThemePreset.obsidianDark:
        return darkBorderFocused;
      case AppThemePreset.warmAmber:
        return warmBorderFocused;
    }
  }

  static Color get textPrimary {
    switch (currentTheme) {
      case AppThemePreset.nordicNavy:
        return lightTextPrimary;
      case AppThemePreset.forestSage:
        return sageTextPrimary;
      case AppThemePreset.obsidianDark:
        return darkTextPrimary;
      case AppThemePreset.warmAmber:
        return warmTextPrimary;
    }
  }

  static Color get textSecondary {
    switch (currentTheme) {
      case AppThemePreset.nordicNavy:
        return lightTextSecondary;
      case AppThemePreset.forestSage:
        return sageTextSecondary;
      case AppThemePreset.obsidianDark:
        return darkTextSecondary;
      case AppThemePreset.warmAmber:
        return warmTextSecondary;
    }
  }

  static Color get textMuted {
    switch (currentTheme) {
      case AppThemePreset.nordicNavy:
        return lightTextMuted;
      case AppThemePreset.forestSage:
        return sageTextMuted;
      case AppThemePreset.obsidianDark:
        return darkTextMuted;
      case AppThemePreset.warmAmber:
        return warmTextMuted;
    }
  }

  static Color get primaryColor {
    switch (currentTheme) {
      case AppThemePreset.nordicNavy:
        return primaryNavy;
      case AppThemePreset.forestSage:
        return sagePrimary;
      case AppThemePreset.obsidianDark:
        return emeraldGreen;
      case AppThemePreset.warmAmber:
        return warmPrimary;
    }
  }

  static Color get accentColor {
    switch (currentTheme) {
      case AppThemePreset.nordicNavy:
        return emeraldGreen;
      case AppThemePreset.forestSage:
        return sageAccent;
      case AppThemePreset.obsidianDark:
        return emeraldGreen;
      case AppThemePreset.warmAmber:
        return warmAccent;
    }
  }

  /// Returns card shadows designed for elevation depth and harmony
  static List<BoxShadow> get cardShadow {
    switch (currentTheme) {
      case AppThemePreset.obsidianDark:
        return const [
          BoxShadow(
            color: Color(0x3D000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ];
      case AppThemePreset.forestSage:
        return const [
          BoxShadow(
            color: Color(0x0C365747),
            blurRadius: 18,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Color(0x05365747),
            blurRadius: 4,
            offset: Offset(0, 1),
            spreadRadius: 0,
          ),
        ];
      case AppThemePreset.warmAmber:
        return const [
          BoxShadow(
            color: Color(0x0E92400E),
            blurRadius: 18,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Color(0x0592400E),
            blurRadius: 4,
            offset: Offset(0, 1),
            spreadRadius: 0,
          ),
        ];
      case AppThemePreset.nordicNavy:
        return const [
          BoxShadow(
            color: Color(0x0C142D4E),
            blurRadius: 18,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Color(0x05142D4E),
            blurRadius: 4,
            offset: Offset(0, 1),
            spreadRadius: 0,
          ),
        ];
    }
  }

  /// Category color palette
  static const List<Color> categoryPalette = [
    Color(0xFF10B981), // Emerald
    Color(0xFF365747), // Forest Pine
    Color(0xFF142D4E), // Navy
    Color(0xFF3B82F6), // Blue
    Color(0xFF84A98C), // Sage
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Orange
    Color(0xFF14B8A6), // Teal
    Color(0xFF6366F1), // Indigo
  ];

  // ===========================================================================
  // THEMEDATA INSTANCES
  // ===========================================================================

  /// Current active ThemeData corresponding to currentTheme
  static ThemeData get currentThemeData {
    switch (currentTheme) {
      case AppThemePreset.nordicNavy:
        return lightTheme;
      case AppThemePreset.forestSage:
        return sageTheme;
      case AppThemePreset.obsidianDark:
        return darkTheme;
      case AppThemePreset.warmAmber:
        return warmAmberTheme;
    }
  }

  // 1. Nordic Navy Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      canvasColor: lightBackground,
      cardColor: lightCard,
      primaryColor: primaryNavy,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightCard,
        modalBackgroundColor: lightCard,
        surfaceTintColor: Colors.transparent,
      ),
      colorScheme: const ColorScheme.light(
        primary: primaryNavy,
        onPrimary: Colors.white,
        secondary: emeraldGreen,
        onSecondary: Colors.white,
        surface: lightCard,
        onSurface: lightTextPrimary,
        error: tastefulRed,
        onError: Colors.white,
        outline: lightBorderSubtle,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: lightBackground,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: lightTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: lightBorderSubtle, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: lightBorderSubtle, width: 1),
        ),
        titleTextStyle: const TextStyle(
          color: lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(
          color: lightTextSecondary,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightCard,
        selectedItemColor: primaryNavy,
        unselectedItemColor: lightTextMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        selectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceSecondary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: lightTextMuted, fontSize: 14),
        labelStyle: const TextStyle(color: lightTextSecondary, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightBorderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightBorderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryNavy, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: tastefulRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: tastefulRed, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryNavy,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // 2. Forest Sage Theme (Organic Pine & Sage)
  static ThemeData get sageTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: sageBackground,
      canvasColor: sageBackground,
      cardColor: sageCard,
      primaryColor: sagePrimary,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: sageCard,
        modalBackgroundColor: sageCard,
        surfaceTintColor: Colors.transparent,
      ),
      colorScheme: const ColorScheme.light(
        primary: sagePrimary,
        onPrimary: Colors.white,
        secondary: sageAccent,
        onSecondary: Colors.white,
        surface: sageCard,
        onSurface: sageTextPrimary,
        error: tastefulRed,
        onError: Colors.white,
        outline: sageBorderSubtle,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: sageBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: sageBackground,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: sageTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: sageTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: sageCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: sageBorderSubtle, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: sageCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: sageBorderSubtle, width: 1),
        ),
        titleTextStyle: const TextStyle(
          color: sageTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(
          color: sageTextSecondary,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: sageCard,
        selectedItemColor: sagePrimary,
        unselectedItemColor: sageTextMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        selectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: sageSurfaceSecondary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: sageTextMuted, fontSize: 14),
        labelStyle: const TextStyle(color: sageTextSecondary, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: sageBorderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: sageBorderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: sagePrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: tastefulRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: tastefulRed, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: sagePrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: sagePrimary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: sagePrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      dividerTheme: const DividerThemeData(
        color: sageBorderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // 3. Obsidian Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      canvasColor: darkBackground,
      cardColor: darkCard,
      primaryColor: emeraldGreen,
      colorScheme: const ColorScheme.dark(
        primary: emeraldGreen,
        onPrimary: Colors.black,
        secondary: emeraldGreen,
        onSecondary: Colors.black,
        surface: darkCard,
        onSurface: darkTextPrimary,
        surfaceContainer: darkCard,
        surfaceContainerHigh: darkSurfaceSecondary,
        surfaceContainerHighest: darkSurfaceSecondary,
        surfaceContainerLow: darkBackground,
        surfaceContainerLowest: darkBackground,
        surfaceDim: darkBackground,
        surfaceBright: darkCard,
        error: tastefulRed,
        onError: Colors.white,
        outline: darkBorderSubtle,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkCard,
        modalBackgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceSecondary,
        disabledColor: darkSurfaceSecondary.withValues(alpha: 0.5),
        selectedColor: emeraldGreen.withValues(alpha: 0.2),
        secondarySelectedColor: emeraldGreen.withValues(alpha: 0.2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: const TextStyle(color: darkTextPrimary, fontSize: 12),
        secondaryLabelStyle: const TextStyle(color: emeraldGreen, fontSize: 12),
        brightness: Brightness.dark,
        side: const BorderSide(color: darkBorderSubtle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return emeraldGreen;
          }
          return darkTextSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return emeraldGreen.withValues(alpha: 0.35);
          }
          return darkSurfaceSecondary;
        }),
        trackOutlineColor: WidgetStateProperty.all(darkBorderSubtle),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: darkSurfaceSecondary,
        headerForegroundColor: darkTextPrimary,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.black;
          if (states.contains(WidgetState.disabled)) return darkTextMuted;
          return darkTextPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return emeraldGreen;
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.all(emeraldGreen),
        todayBorder: const BorderSide(color: emeraldGreen),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.black;
          return darkTextPrimary;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return emeraldGreen;
          return Colors.transparent;
        }),
      ),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: darkCard,
        hourMinuteColor: darkSurfaceSecondary,
        hourMinuteTextColor: darkTextPrimary,
        dayPeriodColor: darkSurfaceSecondary,
        dayPeriodTextColor: darkTextPrimary,
        dialBackgroundColor: darkSurfaceSecondary,
        dialHandColor: emeraldGreen,
        dialTextColor: darkTextPrimary,
        entryModeIconColor: darkTextSecondary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: darkBackground,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: darkBorderSubtle, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: darkBorderSubtle, width: 1),
        ),
        titleTextStyle: const TextStyle(
          color: darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(
          color: darkTextSecondary,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkCard,
        selectedItemColor: emeraldGreen,
        unselectedItemColor: darkTextMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        selectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceSecondary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: darkTextMuted, fontSize: 14),
        labelStyle: const TextStyle(color: darkTextSecondary, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: emeraldGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: tastefulRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: tastefulRed, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emeraldGreen,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkTextSecondary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: emeraldGreen,
        foregroundColor: Colors.black,
        elevation: 4,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // 4. Warm Amber Theme (Earthy Minimalist & Gold)
  static ThemeData get warmAmberTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: warmBackground,
      canvasColor: warmBackground,
      cardColor: warmCard,
      primaryColor: warmPrimary,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: warmCard,
        modalBackgroundColor: warmCard,
        surfaceTintColor: Colors.transparent,
      ),
      colorScheme: const ColorScheme.light(
        primary: warmPrimary,
        onPrimary: Colors.white,
        secondary: warmAccent,
        onSecondary: Colors.white,
        surface: warmCard,
        onSurface: warmTextPrimary,
        error: tastefulRed,
        onError: Colors.white,
        outline: warmBorderSubtle,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: warmBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: warmBackground,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: warmTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: warmTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: warmCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: warmBorderSubtle, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: warmCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: warmBorderSubtle, width: 1),
        ),
        titleTextStyle: const TextStyle(
          color: warmTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(
          color: warmTextSecondary,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: warmCard,
        selectedItemColor: warmPrimary,
        unselectedItemColor: warmTextMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        selectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: warmSurfaceSecondary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: warmTextMuted, fontSize: 14),
        labelStyle: const TextStyle(color: warmTextSecondary, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: warmBorderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: warmBorderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: warmPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: tastefulRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: tastefulRed, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: warmPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: warmPrimary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: warmPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      dividerTheme: const DividerThemeData(
        color: warmBorderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
