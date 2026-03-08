import 'package:flutter/material.dart';

/// 🌿 THE FRESH GARDEN — Mint & Clean Green
/// Vibe: Refreshing, calm, and nature-forward.
/// Best for: Wellness reads, nature writing, self-help, or eco-conscious book communities.
class AppColors {
  // ===== PRIMARY COLORS (Fresh Mint) =====
  static const Color primary = Color(0xFF3EB489);        // Fresh Mint - Main Brand
  static const Color primaryDark = Color(0xFF1A6B50);    // Deep Forest - Dark Brand
  static const Color primaryLight = Color(0xFFE8F8F2);   // Pale Mint - Light Brand BG

  // ===== ACCENT COLORS (Emerald Pop) =====
  static const Color accent = Color(0xFF00C9A7);         // Emerald Pop - Key Accent
  static const Color accentDark = Color(0xFF00A085);     // Darker Emerald
  static const Color accentLight = Color(0xFFD4F7EF);    // Soft Aqua Tint - Light Accent

  // ===== SECONDARY COLORS =====
  static const Color secondary = Color(0xFF1A6B50);      // Deep Forest
  static const Color secondaryDark = Color(0xFF0F4233);  // Dark Forest
  static const Color secondaryLight = Color(0xFF2E9B78); // Mid Forest

  // ===== SUCCESS & POSITIVE =====
  static const Color success = Color(0xFF3EB489);        // Mint (theme-matched)
  static const Color successLight = Color(0xFFE8F8F2);   // Pale Mint

  // ===== ERROR & NEGATIVE =====
  static const Color error = Color(0xFFEF4444);          // Red Error
  static const Color errorLight = Color(0xFFFEE2E2);     // Light Error

  // ===== WARNING =====
  static const Color warning = Color(0xFFF59E0B);        // Amber Warning
  static const Color warningLight = Color(0xFFFEF3C7);   // Light Warning

  // ===== TEXT COLORS =====
  static const Color darkText = Color(0xFF1A3D2E);       // Deep Green-Black - Primary Text
  static const Color darkTextAlt = Color(0xFF0F2A1E);    // Darkest Green - Headers
  static const Color mediumText = Color(0xFF4A8870);     // Mid Sage - Secondary Text
  static const Color lightText = Color(0xFF8ABFAD);      // Light Sage - Helper Text
  static const Color hintText = Color(0xFFB8D9CE);       // Pale Sage - Hints

  // ===== BACKGROUNDS =====
  static const Color background = Color(0xFFF2FCF8);     // Icy Mint White - Main BG
  static const Color backgroundAlt = Color(0xFFE4F6EF);  // Soft Mint - Alt BG
  static const Color surface = Color(0xFFFFFFFF);        // Pure White - Cards
  static const Color surfaceWarm = Color(0xFFF7FDFB);    // Barely-there Mint - Form Fields

  // ===== BORDERS & DIVIDERS =====
  static const Color border = Color(0xFFCCEEE2);         // Mint Border
  static const Color borderLight = Color(0xFFE0F5EE);    // Lighter Mint Border
  static const Color divider = Color(0xFFBFE8DA);        // Divider

  // ===== GRADIENTS =====
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1A6B50), Color(0xFF3EB489)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF3EB489), Color(0xFF00C9A7)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFF00C9A7), Color(0xFF1A6B50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===== BOOK MOOD COLORS =====
  static const Color moodHappy = Color(0xFF00C9A7);
  static const Color moodInspirational = Color(0xFF8B5CF6);
  static const Color moodDark = Color(0xFF1A3D2E);
  static const Color moodRomantic = Color(0xFFF472B6);
  static const Color moodAdventurous = Color(0xFF3EB489);
  static const Color moodMysterious = Color(0xFF1A6B50);
  static const Color moodScary = Color(0xFF9F1239);
  static const Color moodPhilosophical = Color(0xFF4A8870);

  // ===== SHADOWS =====
  static const List<BoxShadow> smallShadow = [
    BoxShadow(
      color: Color(0x0F1A6B50),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Color(0x151A6B50),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> largeShadow = [
    BoxShadow(
      color: Color(0x1A1A6B50),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static List<BoxShadow> glowShadow = [
    BoxShadow(
      color: const Color(0xFF00C9A7).withOpacity(0.35),
      blurRadius: 14,
      offset: const Offset(0, 5),
    ),
  ];
}