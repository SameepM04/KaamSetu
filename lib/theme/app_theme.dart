import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.mist,
      splashFactory: InkSparkle.splashFactory,
      // Inter everywhere: this is the fallback fontFamily used by any
      // TextStyle below (button/appBar/dialog/snackbar styles, etc.) that
      // doesn't set its own fontFamily. textTheme/primaryTextTheme get
      // Inter explicitly further down via GoogleFonts.interTextTheme so
      // every size/weight/color already defined here is preserved exactly
      // — only the typeface changes.
      fontFamily: GoogleFonts.inter().fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.blue,
          brightness: Brightness.light,
          primary: AppColors.blue,
          secondary: AppColors.orange,
          surface: Colors.white,
        ),

        // ---------------------------------------------------------------
        // Typography — one consistent scale used everywhere. Keep this the
        // single source of truth for text styles instead of hard-coding
        // sizes/weights inline on new screens.
        // ---------------------------------------------------------------
        textTheme: const TextTheme(
          // Screen titles
          headlineLarge: TextStyle(
            color: AppColors.navy,
            fontSize: 45,
            height: .99,
            letterSpacing: -1.8,
            fontWeight: FontWeight.w800,
          ),
          headlineMedium: TextStyle(
            color: AppColors.navy,
            fontSize: 35,
            height: 1.05,
            letterSpacing: -1.2,
            fontWeight: FontWeight.w800,
          ),
          headlineSmall: TextStyle(
            color: AppColors.navy,
            fontSize: 22,
            height: 1.1,
            letterSpacing: -0.6,
            fontWeight: FontWeight.w800,
          ),
          // Section titles
          titleLarge: TextStyle(
            color: AppColors.navy,
            fontSize: 18,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
          // Card titles / worker names
          titleMedium: TextStyle(
            color: AppColors.navy,
            fontSize: 15,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: TextStyle(
            color: AppColors.navy,
            fontSize: 13,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
          // Descriptions / body copy
          bodyLarge: TextStyle(
            color: AppColors.inkMuted,
            fontSize: 18,
            height: 1.36,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            color: AppColors.inkMuted,
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w400,
          ),
          // Metadata / secondary text
          bodySmall: TextStyle(
            color: AppColors.inkMuted,
            fontSize: 12,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
          // Buttons
          labelLarge: TextStyle(
            fontSize: 14.5,
            height: 1.1,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          labelMedium: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.inkMuted,
          ),
        ),

        // ---------------------------------------------------------------
        // Buttons — ripple + press scale come from AppButton wrapper
        // widgets; this sets the shared shape/elevation/padding baseline
        // so every FilledButton/OutlinedButton looks the same by default.
        // ---------------------------------------------------------------
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.blue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.line,
            disabledForegroundColor: Colors.white.withValues(alpha: .7),
            minimumSize: const Size(64, 52),
            padding: const EdgeInsets.symmetric(horizontal: 22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
            elevation: 0,
          ).copyWith(
            elevation: const WidgetStatePropertyAll(0),
            overlayColor: WidgetStatePropertyAll(
              Colors.white.withValues(alpha: .12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.blue,
            minimumSize: const Size(64, 52),
            padding: const EdgeInsets.symmetric(horizontal: 22),
            side: const BorderSide(color: AppColors.line, width: 1.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: AppColors.navy,
            minimumSize: const Size(44, 44),
          ),
        ),

        // ---------------------------------------------------------------
        // Cards — soft elevation on white surfaces, 20px rounding.
        // ---------------------------------------------------------------
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.line.withValues(alpha: .55)),
          ),
        ),

        // ---------------------------------------------------------------
        // Chips — used for filters and status pills; animated color state
        // is handled by AnimatedStatusChip, this sets shared shape/size.
        // ---------------------------------------------------------------
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.paleBlue,
          selectedColor: AppColors.blue,
          disabledColor: AppColors.line.withValues(alpha: .4),
          labelStyle: const TextStyle(
            color: AppColors.navy,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
          secondaryLabelStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
            side: BorderSide.none,
          ),
          side: BorderSide.none,
          showCheckmark: false,
        ),

        // ---------------------------------------------------------------
        // Snackbars — floating, rounded, spaced off the edges.
        // ---------------------------------------------------------------
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.navy,
          contentTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
          behavior: SnackBarBehavior.floating,
          insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 4,
        ),

        // ---------------------------------------------------------------
        // Dialogs — M3 rounding, fade/scale handled by the default M3
        // dialog transition (already provided by useMaterial3: true).
        // ---------------------------------------------------------------
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titleTextStyle: const TextStyle(
            color: AppColors.navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
          contentTextStyle: const TextStyle(
            color: AppColors.inkMuted,
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),

        // ---------------------------------------------------------------
        // Bottom sheets — rounded top corners + drag handle styling.
        // ---------------------------------------------------------------
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          modalElevation: 8,
          dragHandleColor: AppColors.line,
          dragHandleSize: const Size(40, 4),
          // NOTE: left off (existing sheets already draw their own drag
          // handle inline — enabling this would double it up). New sheets
          // that don't build a manual handle can opt in per-call via
          // `showModalBottomSheet(showDragHandle: true, ...)`.
          showDragHandle: false,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),

        dividerTheme: DividerThemeData(
          color: AppColors.line.withValues(alpha: .6),
          thickness: 1,
          space: 1,
        ),

        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.blue,
          linearTrackColor: AppColors.paleBlue,
          circularTrackColor: AppColors.paleBlue,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.mist,
          foregroundColor: AppColors.navy,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.navy,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

    // Apply Inter to every named text style while preserving each style's
    // existing size/height/letterSpacing/weight/color exactly as defined
    // above — GoogleFonts.interTextTheme only swaps the fontFamily (and its
    // platform-specific package) on each TextStyle via copyWith.
    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      primaryTextTheme: GoogleFonts.interTextTheme(base.primaryTextTheme),
    );
  }
}
