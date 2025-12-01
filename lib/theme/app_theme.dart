import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color managerPrimary = Color(0xFF1976D2);
  static const Color managerAccent = Color(0xFF42A5F5);
  static const Color inspectorPrimary = Color(0xFF2E7D32);
  static const Color inspectorAccent = Color(0xFF66BB6A);

  // Status Colors
  static const Color statusScheduled = Color(0xFF2196F3);
  static const Color statusInProgress = Color(0xFFFF9800);
  static const Color statusPendingReview = Color(0xFF9C27B0);
  static const Color statusCompleted = Color(0xFF4CAF50);
  static const Color statusRejected = Color(0xFFF44336);

  // Neutral Colors
  static final Color backgroundGrey = Colors.grey.shade50;
  static final Color cardWhite = Colors.white;
  static final Color textPrimary = Colors.grey.shade900;
  static final Color textSecondary = Colors.grey.shade600;
  static final Color divider = Colors.grey.shade200;

  // Shadows
  static BoxShadow get cardShadow => BoxShadow(
    color: Colors.black.withValues(alpha: 0.05),
    blurRadius: 10,
    offset: const Offset(0, 4),
  );

  static List<BoxShadow> get elevatedCardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 15,
      offset: const Offset(0, 6),
    ),
  ];

  // Border Radius
  static BorderRadius get cardBorderRadius => BorderRadius.circular(16);
  static BorderRadius get buttonBorderRadius => BorderRadius.circular(12);
  static BorderRadius get badgeBorderRadius => BorderRadius.circular(20);

  // Text Styles
  static TextStyle get headingLarge => TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: 0.3,
  );

  static TextStyle get headingMedium => TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: 0.3,
  );

  static TextStyle get headingSmall => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: 0.2,
  );

  static TextStyle get bodyLarge =>
      TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary);

  static TextStyle get bodyMedium => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static TextStyle get bodySmall => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static TextStyle get caption => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  // App Bar Theme
  static AppBarTheme appBarTheme(Color color) => AppBarTheme(
    elevation: 0,
    backgroundColor: color,
    foregroundColor: Colors.white,
    titleTextStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: Colors.white,
    ),
  );

  // Button Styles
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: buttonBorderRadius),
    elevation: 0,
  );

  static ButtonStyle get outlinedButton => OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: buttonBorderRadius),
  );

  // Input Decoration
  static InputDecoration inputDecoration(String label, {IconData? icon}) =>
      InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        border: OutlineInputBorder(
          borderRadius: buttonBorderRadius,
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: buttonBorderRadius,
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: buttonBorderRadius,
          borderSide: const BorderSide(color: managerPrimary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      );

  // Status Badge Widget
  static Widget statusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'scheduled':
        color = statusScheduled;
        break;
      case 'in_progress':
        color = statusInProgress;
        break;
      case 'pending_review':
        color = statusPendingReview;
        break;
      case 'completed':
        color = statusCompleted;
        break;
      case 'rejected':
        color = statusRejected;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: badgeBorderRadius,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Section Header Widget
  static Widget sectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(title, style: headingLarge),
      ],
    );
  }
}
