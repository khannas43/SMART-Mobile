import 'package:flutter/material.dart';

/// SMART Rajasthan design tokens (aligned with smart_frontend tailwind.config.js).
const kPrimaryRoyal = Color(0xFF1B3F92);
const kPrimaryDeep = Color(0xFF0B5FB0);
const kCitizenOrange = Color(0xFFFF9200);
const kCitizenOrangeLight = Color(0xFFFFF7ED);
const kDeptNavy = Color(0xFF021B33);
const kDeptNavyMid = Color(0xFF064882);

// Legacy aliases used across existing widgets
const kInk = kDeptNavy;
const kInk2 = kDeptNavyMid;
const kIndigo = kPrimaryRoyal;
const kIndigoL = Color(0xFFE9EFF8);
const kBlue = kPrimaryRoyal;
const kBlueL = Color(0xFFE9EFF8);
const kGreen = Color(0xFF1F9D55);
const kGreenL = Color(0xFFE3F5EC);
const kPurple = Color(0xFF55669F);
const kPurpleL = Color(0xFFE9ECF7);
const kAmber = Color(0xFFB87333);
const kAmberL = Color(0xFFF5EADD);
const kBrand = kPrimaryRoyal;
const kSaffron = kCitizenOrange;
const kBg = Color(0xFFF2F5FA);
const kCard = Colors.white;
const kBorder = Color(0xFFE2E7F0);
const kText = Color(0xFF1B2740);
const kMuted = Color(0xFF6A7385);

ThemeData buildSmartTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimaryRoyal,
      primary: kPrimaryRoyal,
    ),
    fontFamily: 'Roboto',
    fontFamilyFallback: const [
      'Noto Sans Devanagari',
      'sans-serif',
    ],
    scaffoldBackgroundColor: kBg,
    useMaterial3: true,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: const TextStyle(color: kMuted, fontSize: 14),
      labelStyle: const TextStyle(color: kMuted, fontSize: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kIndigo, width: 1.5),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kPrimaryRoyal,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: kPrimaryRoyal,
      unselectedItemColor: kMuted,
      type: BottomNavigationBarType.fixed,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );
}

Color shellAccentFor(SmartPanelTheme panel) => switch (panel) {
      SmartPanelTheme.citizen => kCitizenOrange,
      SmartPanelTheme.department => kDeptNavyMid,
    };

enum SmartPanelTheme { citizen, department }

SmartPanelTheme themeForPanel(String roleHeader) => switch (roleHeader) {
      'DEPARTMENT' => SmartPanelTheme.department,
      _ => SmartPanelTheme.citizen,
    };
