import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFFC80815); // venetian red
  static const primaryDark = Color(0xFF8A050F); // deep venetian red
  static const primaryLight = Color(0xFFE5303C);
  static const primarySoft = Color(0xFFFDEBEC); // rose tint
  static const gold = Color(0xFFC9A24B); // champagne gold accent
  static const goldSoft = Color(0xFFF7EDD2);
  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFEF2F2);
  static const ok = Color(0xFF15803D);
  static const okSoft = Color(0xFFECFDF3);
  static const warn = Color(0xFFB45309);
  static const muted = Color(0xFF7B6F73);
  static const border = Color(0xFFEFE3E4);
  static const bg = Color(0xFFFBF8F7); // warm ivory
  static const text = Color(0xFF1C1214);
  static const ink = Color(0xFF14090B);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary, primaryDark],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE6C875), gold, Color(0xFFA8812F)],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE5303C), primary, Color(0xFF6E040C)],
    stops: [0, .5, 1],
  );

  static List<BoxShadow> glow = [
    BoxShadow(color: primary.withValues(alpha: .35), blurRadius: 18, offset: const Offset(0, 8)),
  ];

  static List<BoxShadow> softShadow = [
    BoxShadow(color: primaryDark.withValues(alpha: .08), blurRadius: 20, offset: const Offset(0, 8)),
    BoxShadow(color: Colors.black.withValues(alpha: .03), blurRadius: 4, offset: const Offset(0, 1)),
  ];
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.gold,
    surface: Colors.white,
  );
  OutlineInputBorder ob(Color c, [double w = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(color: AppColors.text, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: .2),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: ob(AppColors.border),
      enabledBorder: ob(AppColors.border),
      focusedBorder: ob(AppColors.primary, 1.6),
      labelStyle: const TextStyle(color: AppColors.muted),
      floatingLabelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, letterSpacing: .3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: AppColors.primary)),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    snackBarTheme: SnackBarThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: AppColors.primarySoft,
      iconTheme: WidgetStateProperty.resolveWith((s) =>
          IconThemeData(color: s.contains(WidgetState.selected) ? AppColors.primary : AppColors.muted, size: 24)),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontSize: 11.5,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? AppColors.primary : AppColors.muted,
          )),
    ),
  );
}

/// Elevated, rounded white card used across tabs.
class LuxCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  const LuxCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(18)});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.softShadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(borderRadius: BorderRadius.circular(20), onTap: onTap, child: Padding(padding: padding, child: child)),
        ),
      );
}
