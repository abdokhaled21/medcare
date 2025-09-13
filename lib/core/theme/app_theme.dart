import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF5B6CFF); // bluish purple for actions
  static const Color primaryDark = Color(0xFF4B3CFF);
  static const Color purpleTop = Color(0xFF6F7EFF);
  static const Color purpleBottom = Color(0xFF6B2EFF);
  static const Color lightBg = Color(0xFFF5EDF9); // very light purple (onboarding bg)
  static const Color textDark = Color(0xFF2D2D2D);
  static const Color textLight = Color(0xFFA2A2A7);
  static const Color border = Color(0xFFE4E4E7);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light();
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textLight,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 4,
          shadowColor: AppColors.primary.withOpacity(.35),
        ),
      ),
    );
  }

  static LinearGradient get appGradient => const LinearGradient(
        colors: [Color(0xFF5A71E4), Color(0xFF6B4399)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
}

class AppDecorations {
  static BoxDecoration get gradientBackground => BoxDecoration(
        gradient: AppTheme.appGradient,
      );

  static BoxDecoration roundedIconContainer({double radius = 28}) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      );

  // Stronger shadow variant for splash icon card
  static BoxDecoration roundedIconContainerStrong({double radius = 28}) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          // primary deep shadow
          BoxShadow(
            color: Colors.black.withOpacity(.24),
            blurRadius: 36,
            spreadRadius: 2,
            offset: const Offset(0, 14),
          ),
          // soft ambient shadow
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      );

  // Circular variant with same strong shadow
  static BoxDecoration get circleIconContainerStrong => BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.24),
            blurRadius: 36,
            spreadRadius: 2,
            offset: Offset(0, 14),
          ),
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      );
}
