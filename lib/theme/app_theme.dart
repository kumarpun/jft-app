import 'package:flutter/material.dart';


/// Theme-sensitive colours. Read with `context.pal`.
@immutable
class Pal extends ThemeExtension<Pal> {
  final Color bg, surface, surface2, text, muted, border, primarySoft, dangerSoft, okSoft, ink;
  const Pal({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.text,
    required this.muted,
    required this.border,
    required this.primarySoft,
    required this.dangerSoft,
    required this.okSoft,
    required this.ink,
  });

  static const light = Pal(
    bg: Color(0xFFF2F5FA), // cool mist
    surface: Colors.white,
    surface2: Color(0xFFEAF0FA),
    text: Color(0xFF0B1B3F),
    muted: Color(0xFF6B7A99),
    border: Color(0xFFE1E8F4),
    primarySoft: Color(0xFFE3ECFB), // pale blue
    dangerSoft: Color(0xFFFEF2F2),
    okSoft: Color(0xFFECFDF3),
    ink: Color(0xFF0B1B3F),
  );

  static const dark = Pal(
    bg: Color(0xFF08122A),
    surface: Color(0xFF101D3B),
    surface2: Color(0xFF182850),
    text: Color(0xFFF1F5FF),
    muted: Color(0xFF9AA9C7),
    border: Color(0xFF22335C),
    primarySoft: Color(0xFF1B2E5A),
    dangerSoft: Color(0xFF3B1517),
    okSoft: Color(0xFF10301D),
    ink: Color(0xFF22335C),
  );

  @override
  Pal copyWith() => this;

  @override
  Pal lerp(ThemeExtension<Pal>? other, double t) {
    if (other is! Pal) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return Pal(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surface2: l(surface2, other.surface2),
      text: l(text, other.text),
      muted: l(muted, other.muted),
      border: l(border, other.border),
      primarySoft: l(primarySoft, other.primarySoft),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      okSoft: l(okSoft, other.okSoft),
      ink: l(ink, other.ink),
    );
  }
}

extension PalContext on BuildContext {
  Pal get pal => Theme.of(this).extension<Pal>() ?? Pal.light;
}

class AppColors {
  static const primary = Color(0xFF0F2A5C); // deep navy
  static const primaryDark = Color(0xFF081A3E); // midnight navy
  static const primaryLight = Color(0xFF3B66C4);
  static const accent = Color(0xFF7FA8F0); // sky blue accent
  static const danger = Color(0xFFDC2626);
  static const ok = Color(0xFF15803D);
  static const warn = Color(0xFFB45309);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary, primaryDark],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB5CEF7), accent, Color(0xFF4F7FD8)],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3F85), primary, Color(0xFF081A3E)],
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

ThemeData buildTheme([Brightness brightness = Brightness.light]) {
  final dark = brightness == Brightness.dark;
  final p = dark ? Pal.dark : Pal.light;
  // Brand navy is too dark to read as text/outline on the dark surface.
  final accent = dark ? const Color(0xFF7FA6FF) : AppColors.primary;
  final action = dark ? const Color(0xFF3D6BEA) : AppColors.primary; // filled buttons / selected nav
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: brightness,
    primary: accent,
    secondary: AppColors.accent,
    surface: p.surface,
    onSurface: p.text,
  );
  OutlineInputBorder ob(Color c, [double w = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    extensions: [p],
    scaffoldBackgroundColor: p.bg,
    // Default Android zoom transition flashes the light scaffold between routes; slide keeps both pages opaque.
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(color: p.text, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: .2),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: p.border)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: ob(p.border),
      enabledBorder: ob(p.border),
      focusedBorder: ob(accent, 1.6),
      labelStyle: TextStyle(color: p.muted),
      floatingLabelStyle: TextStyle(color: accent, fontWeight: FontWeight.w600),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: action,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, letterSpacing: .3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: BorderSide(color: accent),
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: accent)),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    popupMenuTheme: PopupMenuThemeData(color: p.surface, surfaceTintColor: Colors.transparent),
    snackBarTheme: SnackBarThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: action,
      indicatorShape: const StadiumBorder(),
      iconTheme: WidgetStateProperty.resolveWith((s) =>
          IconThemeData(color: s.contains(WidgetState.selected) ? Colors.white : p.muted, size: 24)),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontSize: 11.5,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? p.text : p.muted,
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
          color: context.pal.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.pal.border),
          boxShadow: AppColors.softShadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(borderRadius: BorderRadius.circular(20), onTap: onTap, child: Padding(padding: padding, child: child)),
        ),
      );
}
