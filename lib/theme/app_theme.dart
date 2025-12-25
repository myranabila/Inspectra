import 'package:flutter/material.dart';

class AppTheme {
  // ============ iPETRO BRAND COLORS ============
  
  // Primary Red Colors (from iPETRO logo)
  static const Color primaryRed = Color(0xFFDC2626);       // iPETRO Red
  static const Color primaryRedDark = Color(0xFFB91C1C);   // Darker Red
  static const Color primaryRedLight = Color(0xFFEF4444);  // Lighter Red
  
  // Secondary Gray Colors (from iPETRO logo)
  static const Color primaryGray = Color(0xFF4B5563);      // iPETRO Gray
  static const Color primaryGrayDark = Color(0xFF374151);  // Darker Gray
  static const Color primaryGrayLight = Color(0xFF6B7280); // Lighter Gray
  
  // Primary brand color (main)
  static const Color primaryIndigo = Color(0xFFDC2626);    // Changed to iPETRO Red
  
  
  // Accent Colors (RED & YELLOW ONLY)
  static const Color accentYellow = Color(0xFFF59E0B);     // Amber/Yellow
  static const Color accentYellowLight = Color(0xFFFBBF24); // Light Yellow
  static const Color accentOrange = Color(0xFFF97316);      // Orange (red-yellow mix)
  
  // Role-specific Colors (updated to red theme)
  static const Color managerPrimary = Color(0xFF991B1B);   // Deep Red for manager
  static const Color managerAccent = Color(0xFFF87171);    // Light Red
  static const Color inspectorPrimary = Color(0xFFDC2626); // iPETRO Red
  static const Color inspectorAccent = Color(0xFFFCA5A5);  // Light Red

  // Status Colors (RED & YELLOW ONLY - NO BLUE/GREEN)
  static const Color statusScheduled = Color(0xFFF59E0B);    // Yellow/Amber
  static const Color statusInProgress = Color(0xFFF97316);   // Orange
  static const Color statusPendingReview = Color(0xFFFBBF24); // Light Yellow
  static const Color statusCompleted = Color(0xFFDC2626);    // Red (approved)
  static const Color statusRejected = Color(0xFF991B1B);     // Dark Red

  // Neutral Colors (refined)
  static const Color backgroundGrey = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFCBD5E1);
  
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF1C1917);   // Warmer dark
  static const Color darkSurface = Color(0xFF292524);
  static const Color darkCard = Color(0xFF44403C);

  // ============ GRADIENTS ============
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryRed, primaryRedDark],
  );
  
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFDC2626),  // iPETRO Red
      Color(0xFFB91C1C),  // Dark Red
      Color(0xFF7F1D1D),  // Deeper Red
    ],
  );
  
  static const LinearGradient sidebarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1C1917),  // Dark warm gray
      Color(0xFF0C0A09),  // Almost black
    ],
  );
  
  static const LinearGradient managerSidebarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF991B1B),  // Deep red
      Color(0xFF450A0A),  // Very dark red
    ],
  );
  
  
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],  // Red gradient for success
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
  );
  
  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDC2626), Color(0xFFF87171)],
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
  );

  // ============ SHADOWS ============
  
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF64748B).withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: const Color(0xFF64748B).withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];
  
  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: const Color(0xFF64748B).withValues(alpha: 0.15),
      blurRadius: 32,
      offset: const Offset(0, 12),
      spreadRadius: -8,
    ),
    BoxShadow(
      color: const Color(0xFF64748B).withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> coloredShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.25),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];
  
  static List<BoxShadow> get redShadow => [
    BoxShadow(
      color: primaryRed.withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];
  
  // Backwards compatibility
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

  // ============ BORDER RADIUS ============
  
  static BorderRadius get radiusXS => BorderRadius.circular(6);
  static BorderRadius get radiusSM => BorderRadius.circular(8);
  static BorderRadius get radiusMD => BorderRadius.circular(12);
  static BorderRadius get radiusLG => BorderRadius.circular(16);
  static BorderRadius get radiusXL => BorderRadius.circular(24);
  static BorderRadius get radiusFull => BorderRadius.circular(100);
  
  // Backwards compatibility
  static BorderRadius get cardBorderRadius => BorderRadius.circular(16);
  static BorderRadius get buttonBorderRadius => BorderRadius.circular(12);
  static BorderRadius get badgeBorderRadius => BorderRadius.circular(20);

  // ============ TYPOGRAPHY ============
  
  static const String fontFamily = 'Inter';
  
  static TextStyle get displayLarge => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  static TextStyle get displayMedium => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.3,
    height: 1.25,
  );
  
  static TextStyle get headingLarge => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static TextStyle get headingMedium => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.1,
    height: 1.35,
  );

  static TextStyle get headingSmall => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0,
    height: 1.4,
  );

  static TextStyle get bodyLarge => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.5,
  );

  static TextStyle get bodySmall => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.5,
  );

  static TextStyle get caption => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textMuted,
    height: 1.4,
    letterSpacing: 0.2,
  );
  
  static TextStyle get labelSmall => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    letterSpacing: 0.5,
    height: 1.3,
  );

  // ============ APP BAR THEME ============
  
  static AppBarTheme appBarTheme(Color color) => AppBarTheme(
    elevation: 0,
    backgroundColor: color,
    foregroundColor: Colors.white,
    centerTitle: false,
    titleTextStyle: const TextStyle(
      fontFamily: fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: Colors.white,
    ),
  );

  // ============ BUTTON STYLES ============
  
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    backgroundColor: primaryRed,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: radiusMD),
    elevation: 0,
    animationDuration: const Duration(milliseconds: 200), // Smooth transitions
    textStyle: const TextStyle(
      fontFamily: fontFamily,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    ),
  ).copyWith(
    overlayColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.pressed)) return Colors.white.withValues(alpha: 0.2);
      if (states.contains(MaterialState.hovered)) return Colors.white.withValues(alpha: 0.1);
      return null;
    }),
    elevation: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.hovered) || states.contains(MaterialState.focused)) return 4;
      if (states.contains(MaterialState.pressed)) return 2;
      return 0;
    }),
    shadowColor: MaterialStateProperty.all(primaryRed.withValues(alpha: 0.4)),
  );
  
  static ButtonStyle get secondaryButton => ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFF1F5F9),
    foregroundColor: textPrimary,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: radiusMD),
    elevation: 0,
    animationDuration: const Duration(milliseconds: 200), // Smooth transitions
    textStyle: const TextStyle(
      fontFamily: fontFamily,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
  ).copyWith(
    overlayColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.pressed)) return primaryGray.withValues(alpha: 0.2);
      if (states.contains(MaterialState.hovered)) return primaryGray.withValues(alpha: 0.1);
      return null;
    }),
    backgroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.hovered)) return const Color(0xFFE2E8F0);
      if (states.contains(MaterialState.pressed)) return const Color(0xFFCBD5E1);
      return const Color(0xFFF1F5F9);
    }),
    elevation: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.hovered)) return 2;
      return 0;
    }),
  );

  static ButtonStyle get outlinedButton => OutlinedButton.styleFrom(
    foregroundColor: primaryRed,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: radiusMD),
    side: const BorderSide(color: border, width: 1.5),
    animationDuration: const Duration(milliseconds: 150), // Smooth transitions
    textStyle: const TextStyle(
      fontFamily: fontFamily,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
  ).copyWith(
    overlayColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.pressed)) return primaryRed.withValues(alpha: 0.15);
      if (states.contains(MaterialState.hovered)) return primaryRed.withValues(alpha: 0.08);
      return null;
    }),
    side: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.pressed)) return const BorderSide(color: primaryRed, width: 2);
      if (states.contains(MaterialState.hovered)) return const BorderSide(color: primaryRed, width: 1.5);
      return const BorderSide(color: border, width: 1.5);
    }),
    backgroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.pressed)) return primaryRed.withValues(alpha: 0.05);
      return Colors.transparent;
    }),
  );
  
  static ButtonStyle get ghostButton => TextButton.styleFrom(
    foregroundColor: textSecondary,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: radiusSM),
    animationDuration: const Duration(milliseconds: 150), // Smooth transitions
    textStyle: const TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
  ).copyWith(
    overlayColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.pressed)) return textSecondary.withValues(alpha: 0.15);
      if (states.contains(MaterialState.hovered)) return textSecondary.withValues(alpha: 0.08);
      return null;
    }),
  );

  // ============ INPUT DECORATION ============
  
  static InputDecoration inputDecoration(String label, {IconData? icon, String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null 
            ? Icon(icon, size: 20, color: textMuted) 
            : null,
        border: OutlineInputBorder(
          borderRadius: radiusMD,
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusMD,
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMD,
          borderSide: const BorderSide(color: primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusMD,
          borderSide: const BorderSide(color: statusRejected),
        ),
        filled: true,
        fillColor: surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: bodyMedium,
        hintStyle: bodyMedium.copyWith(color: textMuted),
      );
  
  // Modern floating input decoration
  static InputDecoration modernInputDecoration({
    required String label,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixTap,
  }) => InputDecoration(
    labelText: label,
    prefixIcon: prefixIcon != null 
        ? Icon(prefixIcon, size: 22, color: textMuted) 
        : null,
    suffixIcon: suffixIcon != null
        ? IconButton(
            icon: Icon(suffixIcon, size: 22, color: textMuted),
            onPressed: onSuffixTap,
          )
        : null,
    border: OutlineInputBorder(
      borderRadius: radiusMD,
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: radiusMD,
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radiusMD,
      borderSide: const BorderSide(color: primaryRed, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: radiusMD,
      borderSide: const BorderSide(color: statusRejected, width: 1.5),
    ),
    filled: true,
    fillColor: const Color(0xFFF1F5F9),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    labelStyle: bodyMedium,
    floatingLabelStyle: const TextStyle(
      color: primaryRed,
      fontWeight: FontWeight.w600,
    ),
  );

  // ============ STATUS BADGE ============

  static Widget statusBadge(String status, {bool large = false}) {
    Color color;
    IconData icon;
    
    switch (status.toLowerCase()) {
      case 'scheduled':
        color = statusScheduled;
        icon = Icons.schedule_rounded;
        break;
      case 'pending_review':
        color = statusPendingReview;
        icon = Icons.hourglass_top_rounded;
        break;
      case 'completed':
        color = statusCompleted;
        icon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        color = statusRejected;
        icon = Icons.cancel_rounded;
        break;
      default:
        color = textMuted;
        icon = Icons.help_outline_rounded;
    }

    String displayText = status;
    if (status == 'rejected') {
      displayText = 'REJECTED';
    } else if (status == 'pending_review') {
      displayText = 'UNDER REVIEW';
    } else {
      displayText = status.replaceAll('_', ' ').toUpperCase();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 12,
        vertical: large ? 10 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: radiusFull,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: large ? 16 : 12, color: color),
          const SizedBox(width: 6),
          Text(
            displayText,
            style: TextStyle(
              color: color,
              fontSize: large ? 13 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============ SECTION HEADER ============

  static Widget sectionHeader(String title, Color color, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color, color.withValues(alpha: 0.5)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Text(title, style: headingLarge),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Text(subtitle, style: bodyMedium),
          ),
        ],
      ],
    );
  }

  // ============ STATUS HELPERS ============
  
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return statusScheduled;
      case 'pending_review':
        return statusPendingReview;
      case 'completed':
        return statusCompleted;
      case 'rejected':
        return statusRejected;
      case 'in_progress':
        return statusInProgress;
      default:
        return textMuted;
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Icons.schedule_rounded;
      case 'pending_review':
        return Icons.hourglass_top_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'in_progress':
        return Icons.play_circle_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  // ============ STAT CARD ============
  
  static Widget statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: radiusLG,
        boxShadow: softShadow,
        border: Border.all(color: divider.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radiusLG,
        child: InkWell(
          onTap: onTap,
          borderRadius: radiusLG,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: caption.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.15),
                            color.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: radiusMD,
                      ),
                      child: Icon(icon, size: 22, color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  value,
                  style: displayMedium.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: caption.copyWith(color: color),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // ============ GLASSMORPHISM DECORATION ============
  
  static BoxDecoration get glassDecoration => BoxDecoration(
    color: Colors.white.withValues(alpha: 0.85),
    borderRadius: radiusXL,
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.5),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 32,
        offset: const Offset(0, 8),
      ),
    ],
  );
  
  static BoxDecoration glassDarkDecoration(Color tint) => BoxDecoration(
    color: tint.withValues(alpha: 0.1),
    borderRadius: radiusXL,
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.15),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
  );

  // ============ STANDARDIZED NAVIGATION COMPONENTS ============
  // These ensure consistent HCI design across all pages
  
  /// Standard back button - use on all pages for consistency
  /// Size: 44x44, BorderRadius: 14, Icon size: 22
  static Widget standardBackButton({
    required VoidCallback onPressed,
    bool isLight = false, // true for dark backgrounds
    String? tooltip,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isLight ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLight ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade200,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          hoverColor: isLight ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
          child: Center(
            child: Icon(
              Icons.arrow_back_rounded,
              color: isLight ? Colors.white : textPrimary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  /// Standard page header icon container
  /// Size: 56x56, BorderRadius: 16
  static Widget standardHeaderIcon({
    required IconData icon,
    Color? color,
    bool hasGlow = false,
  }) {
    final iconColor = color ?? primaryRed;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: hasGlow ? [
          BoxShadow(color: iconColor.withValues(alpha: 0.3), blurRadius: 16, spreadRadius: -2),
          BoxShadow(color: Colors.white.withValues(alpha: 0.8), blurRadius: 1, spreadRadius: 1),
        ] : softShadow,
      ),
      child: Icon(icon, color: iconColor, size: 28),
    );
  }

  /// Standard sidebar logo container
  /// Size: 56x56, BorderRadius: 16
  static Widget standardSidebarLogo({bool hasGlow = true}) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: hasGlow ? [
          BoxShadow(color: primaryRed.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: -2),
          BoxShadow(color: Colors.white.withValues(alpha: 0.1), blurRadius: 1, spreadRadius: 1),
        ] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/ipetro_logo.png',
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => Icon(Icons.business_rounded, color: primaryRed, size: 28),
        ),
      ),
    );
  }

  /// Standard narrow sidebar (for sub-pages like tasks, workflow, etc.)
  /// Width: 88px
  static Widget standardNarrowSidebar({
    required VoidCallback onBack,
    IconData? pageIcon,
    String? backTooltip,
  }) {
    return Container(
      width: 88,
      decoration: BoxDecoration(
        gradient: sidebarGradient,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(4, 0)),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          standardSidebarLogo(),
          const SizedBox(height: 40),
          // Decorative line
          Container(
            width: 32, height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.3),
                Colors.white.withValues(alpha: 0.1),
              ]),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Spacer(),
          // Back button
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 22),
              color: Colors.white,
              tooltip: backTooltip ?? 'Go Back',
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  /// Standard action button for toolbars
  /// Size: 40x40, BorderRadius: 12
  static Widget standardActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    bool isActive = false,
    bool isPrimary = false,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isPrimary 
            ? primaryRed.withValues(alpha: 0.1) 
            : (isActive ? primaryRed.withValues(alpha: 0.1) : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPrimary || isActive 
              ? primaryRed.withValues(alpha: 0.2) 
              : Colors.grey.shade200,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        color: isPrimary || isActive ? primaryRed : textSecondary,
      ),
    );
  }

  /// Standard page title style
  static TextStyle get pageTitleStyle => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  /// Standard page title style (light - for dark backgrounds)
  static TextStyle get pageTitleStyleLight => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: -0.5,
  );

  /// Standard page subtitle style
  static TextStyle get pageSubtitleStyle => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  /// Standard page subtitle style (light)
  static TextStyle get pageSubtitleStyleLight => TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white.withValues(alpha: 0.8),
  );

  /// Standard loading state widget
  static Widget standardLoadingState({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryRed.withValues(alpha: 0.1), primaryRed.withValues(alpha: 0.05)]),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: CircularProgressIndicator(strokeWidth: 3, color: primaryRed, strokeCap: StrokeCap.round),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            message ?? 'Loading...',
            style: const TextStyle(fontFamily: fontFamily, color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please wait',
            style: TextStyle(fontFamily: fontFamily, color: textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// Standard error state widget
  static Widget standardErrorState({
    required String error,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        margin: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: softShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFEE2E2), Color(0xFFFECACA)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.error_outline_rounded, size: 44, color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 28),
            const Text(
              'Something went wrong',
              style: TextStyle(fontFamily: fontFamily, fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary),
            ),
            const SizedBox(height: 10),
            Text(
              error,
              style: const TextStyle(fontFamily: fontFamily, fontSize: 14, color: textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Standard empty state widget
  static Widget standardEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        margin: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: softShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.grey.shade100, Colors.grey.shade50]),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(icon, size: 52, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              style: const TextStyle(fontFamily: fontFamily, fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: const TextStyle(fontFamily: fontFamily, color: textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
