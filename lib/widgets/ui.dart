import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

void toast(BuildContext c, String msg, {bool error = false}) {
  // Fixed high-contrast colours so the message reads the same in light and dark themes.
  final bg = error ? const Color(0xFFB91C1C) : const Color(0xFF15803D);
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: Duration(seconds: error ? 4 : 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white24)),
      content: Row(children: [
        Icon(error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: Colors.white, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, height: 1.3))),
      ]),
    ));
}

Future<void> openUrl(BuildContext c, String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && c.mounted) toast(c, 'Could not open link', error: true);
}

Future<void> openVideo(BuildContext c, String id) => openUrl(c, 'https://www.youtube.com/watch?v=$id');

class Pill extends StatelessWidget {
  final String text;
  final Color? color; // defaults to the theme's readable primary (navy in light, sky blue in dark)
  final Color? bg; // defaults to the theme's soft primary tint
  final IconData? icon;
  const Pill(this.text, {super.key, this.color, this.bg, this.icon});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(color: bg ?? context.pal.primarySoft, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 12, color: color ?? Theme.of(context).colorScheme.primary), const SizedBox(width: 4)],
          Text(text, style: TextStyle(color: color ?? Theme.of(context).colorScheme.primary, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: .2)),
        ]),
      );
}

class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 72});
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(size * .035),
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          borderRadius: BorderRadius.circular(size * .3),
          boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: .45), blurRadius: size * .4, spreadRadius: size * .02), BoxShadow(color: Colors.black.withValues(alpha: .25), blurRadius: size * .25, offset: Offset(0, size * .08))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * .27),
          child: Image.asset('assets/logo.jpg', width: size, height: size, fit: BoxFit.cover),
        ),
      );
}

Color percentColor(int p) => p >= 50 ? AppColors.ok : AppColors.danger;

/// Deep wine-to-venetian-red backdrop with soft rings and a gold hairline glow.
class CrimsonBackdrop extends StatelessWidget {
  final Widget child;
  const CrimsonBackdrop({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3F85), AppColors.primary, Color(0xFF081A3E), Color(0xFF040C20)],
            stops: [0, .35, .78, 1],
          ),
        ),
        child: Stack(children: [
          Positioned(right: -70, top: -60, child: _ring(260, .10)),
          Positioned(right: 30, top: 120, child: _dot(14, .22)),
          Positioned(left: -90, bottom: -80, child: _ring(300, .07)),
          Positioned(left: 40, bottom: 140, child: _dot(8, .25)),
          Positioned(left: 0, right: 0, top: 0, child: Container(height: 2, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, AppColors.accent, Colors.transparent])))),
          child,
        ]),
      );
  static Widget _ring(double d, double a) => Container(
      width: d, height: d, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: a), width: 26)));
  static Widget _dot(double d, double a) => Container(
      width: d, height: d, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent.withValues(alpha: a)));
}

/// Fades and slides its child up on first build; [index] staggers list items.
class FadeSlide extends StatelessWidget {
  final Widget child;
  final int index;
  const FadeSlide({super.key, required this.child, this.index = 0});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 420 + (index > 6 ? 6 : index) * 70),
        curve: Curves.easeOutCubic,
        builder: (_, t, c) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, (1 - t) * 22), child: c)),
        child: child,
      );
}

/// Full-width gradient call-to-action button with glow.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  const GradientButton({super.key, required this.label, required this.onPressed, this.busy = false});
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: onPressed == null ? .6 : 1,
        child: Container(
          decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.glow),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onPressed,
              child: SizedBox(
                height: 54,
                child: Center(
                  child: busy
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                      : Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: .6)),
                ),
              ),
            ),
          ),
        ),
      );
}

/// Elevated auth card with a gold accent line on top.
class AuthCard extends StatelessWidget {
  final Widget child;
  const AuthCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: context.pal.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .38), blurRadius: 50, offset: const Offset(0, 22))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(height: 5, decoration: const BoxDecoration(gradient: AppColors.accentGradient)),
            Padding(padding: const EdgeInsets.all(24), child: child),
          ]),
        ),
      );
}

/// 16:9 black box standing in for the web's embedded YouTube player; tap opens the video.
class VideoBox extends StatelessWidget {
  final String videoId;
  const VideoBox({super.key, required this.videoId});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Material(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => openVideo(context, videoId),
                  child: const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.play_circle_fill, color: AppColors.accent, size: 56),
                      SizedBox(height: 6),
                      Text('Tap to play audio / video', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

/// Owns the search state; [builder] gets the lowercase trimmed query and the search box widget to place wherever it wants.
class SearchHost extends StatefulWidget {
  final List<String> options; // dropdown entries (besides "All"); empty hides the dropdown
  final Widget Function(BuildContext, String query, String? selected, Widget box) builder;
  const SearchHost({super.key, this.options = const [], required this.builder});
  @override
  State<SearchHost> createState() => _SearchHostState();
}

class _SearchHostState extends State<SearchHost> {
  final _c = TextEditingController();
  String? _sel; // null = All

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    if (_sel != null && !widget.options.contains(_sel)) _sel = null;
    BoxDecoration shell() => BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: primary.withValues(alpha: .10), blurRadius: 14, offset: const Offset(0, 5))],
        );
    final field = Container(
          height: 46,
          decoration: shell(),
          child: TextField(
            controller: _c,
            onChanged: (_) => setState(() {}),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.pal.text),
            decoration: InputDecoration(
              hintText: 'Search category',
              hintStyle: TextStyle(fontSize: 13.5, color: context.pal.muted),
              prefixIcon: Icon(Icons.search_rounded, size: 20, color: context.pal.muted),
              suffixIcon: _c.text.isEmpty
                  ? null
                  : IconButton(icon: const Icon(Icons.close_rounded, size: 16), color: context.pal.muted, onPressed: () => setState(_c.clear)),
              isDense: true,
              filled: true,
              fillColor: context.pal.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: context.pal.border, width: 1.2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: primary, width: 1.6)),
            ),
          ),
        );
    final box = widget.options.isEmpty
        ? field
        : Row(children: [
            Expanded(flex: 5, child: field),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: Container(
                height: 46,
                padding: const EdgeInsets.only(left: 16, right: 8),
                decoration: shell().copyWith(color: context.pal.surface, border: Border.all(color: context.pal.border, width: 1.2)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _sel,
                    isExpanded: true,
                    isDense: true,
                    icon: Icon(Icons.arrow_drop_down_rounded, color: primary),
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: primary),
                    dropdownColor: context.pal.surface,
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('All categories', overflow: TextOverflow.ellipsis)),
                      for (final o in widget.options) DropdownMenuItem<String?>(value: o, child: Text(o, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => setState(() => _sel = v),
                  ),
                ),
              ),
            ),
          ]);
    return widget.builder(context, _c.text.trim().toLowerCase(), _sel, box);
  }
}

/// Pill-shaped input with a soft shadow, used on the auth screens.
class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;
  final Iterable<String>? autofillHints;
  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.capitalization = TextCapitalization.none,
    this.autofillHints,
  });
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    OutlineInputBorder ob(Color c, [double w = 1.2]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: c, width: w));
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: .10), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        autofillHints: autofillHints,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.pal.text),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: context.pal.muted, fontWeight: FontWeight.w500, fontSize: 14),
          prefixIcon: Padding(padding: const EdgeInsets.only(left: 6), child: Icon(icon, size: 20, color: context.pal.muted)),
          suffixIcon: suffix,
          filled: true,
          fillColor: context.pal.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
          border: ob(context.pal.border),
          enabledBorder: ob(context.pal.border),
          focusedBorder: ob(primary, 1.6),
        ),
      ),
    );
  }
}

/// Light auth page: big soft gradient circle top-right, optional back arrow, left-aligned content.
class AuthPage extends StatelessWidget {
  final Widget child;
  final bool back;
  const AuthPage({super.key, required this.child, this.back = false});
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    // content starts near the top (forms are tall now)
    final top = (MediaQuery.sizeOf(context).height * .07 -(back ? 48 : 40) - MediaQuery.paddingOf(context).top).clamp(8.0, 400.0);
    return Scaffold(
      backgroundColor: context.pal.surface,
      body: Stack(children: [
        Positioned(
          right: -90,
          top: -110,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [primary.withValues(alpha: .28), primary.withValues(alpha: 0)]),
            ),
          ),
        ),
        SafeArea(
          child: Column(children: [
            if (back)
              Align(alignment: Alignment.centerLeft, child: IconButton(icon: Icon(Icons.arrow_back_rounded, color: context.pal.text), onPressed: () => Navigator.maybePop(context)))
            else
              const SizedBox(height: 40),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(28, top, 28, 24),
                  child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: child),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// Rounded gradient action button with trailing icon, meant to sit on the right.
class AuthPillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool busy;
  final VoidCallback? onPressed;
  const AuthPillButton({super.key, required this.label, required this.onPressed, this.icon = Icons.login_rounded, this.busy = false});
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: onPressed == null ? .6 : 1,
        child: Container(
          decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(28), boxShadow: AppColors.glow),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                child: busy
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 10),
                        Icon(icon, color: Colors.white, size: 20),
                      ]),
              ),
            ),
          ),
        ),
      );
}

/// Shared top bar for pushed pages: white rounded-bottom bar with soft rings, back button and bold title.
PreferredSizeWidget topBar(BuildContext context, String title, {List<Widget>? actions}) {
  final pal = context.pal;
  final primary = Theme.of(context).colorScheme.primary;
  Widget ring(double d, Color c) => Container(width: d, height: d, decoration: BoxDecoration(shape: BoxShape.circle, color: c));
  return AppBar(
    backgroundColor: Colors.transparent,
    foregroundColor: pal.text,
    surfaceTintColor: Colors.transparent,
    toolbarHeight: 72,
    titleSpacing: 0,
    title: Text(title),
    titleTextStyle: TextStyle(color: pal.text, fontSize: 22, fontWeight: FontWeight.w900),
    actions: actions,
    flexibleSpace: Container(
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: .14), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        child: Stack(children: [
          Positioned(right: -30, top: -60, child: ring(190, primary.withValues(alpha: .16))),
          Positioned(right: 70, bottom: -60, child: ring(110, primary.withValues(alpha: .07))),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primary, primary.withValues(alpha: .25)]),
              ),
            ),
          ),
        ]),
      ),
    ),
  );
}

/// Ticks every second from [seconds] down to 0 and rebuilds with the formatted time left.
class LiveLeft extends StatefulWidget {
  final int seconds;
  final Widget Function(String label) builder;
  const LiveLeft({super.key, required this.seconds, required this.builder});
  @override
  State<LiveLeft> createState() => _LiveLeftState();
}

class _LiveLeftState extends State<LiveLeft> {
  late DateTime _end = DateTime.now().add(Duration(seconds: widget.seconds));
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void didUpdateWidget(LiveLeft old) {
    super.didUpdateWidget(old);
    if (old.seconds != widget.seconds) _end = DateTime.now().add(Duration(seconds: widget.seconds));
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _end.difference(DateTime.now()).inSeconds.clamp(0, 1 << 31);
    String two(int n) => n.toString().padLeft(2, '0');
    final d = s ~/ 86400, h = (s % 86400) ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
    return widget.builder('${d > 0 ? '${d}d ' : ''}${two(h)}:${two(m)}:${two(sec)}');
  }
}


/// "or" divider followed by a full-width raised pill "Log in with Google" button.
class GoogleAuthButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback? onPressed;
  const GoogleAuthButton({super.key, this.label = 'Log in with Google', this.busy = false, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final line = Expanded(child: Divider(color: pal.muted.withValues(alpha: 0.3)));
    return Column(children: [
      Row(children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: TextStyle(color: pal.muted, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        line,
      ]),
      const SizedBox(height: 18),
      Semantics(
        button: true,
        label: label,
        child: Material(
          color: pal.surface,
          shape: const StadiumBorder(),
          elevation: 6,
          shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: .35),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: busy ? null : onPressed,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: Center(
                child: busy
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        ShaderMask(
                          shaderCallback: (r) => const SweepGradient(
                            colors: [Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFFBBC05), Color(0xFFEA4335), Color(0xFF4285F4)],
                            stops: [0.0, 0.3, 0.5, 0.75, 1.0],
                          ).createShader(r),
                          blendMode: BlendMode.srcIn,
                          child: const Text('G', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                        const SizedBox(width: 10),
                        Text(label, style: TextStyle(color: pal.text, fontSize: 15, fontWeight: FontWeight.w800)),
                      ]),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

/// Centered "Don't have an account? Sign Up" style footer link.
class AuthSwitchLink extends StatelessWidget {
  final String text, action;
  final VoidCallback onTap;
  const AuthSwitchLink({super.key, required this.text, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text.rich(TextSpan(text: '$text ', style: TextStyle(color: context.pal.muted, fontSize: 14), children: [
            TextSpan(text: action, style: TextStyle(color: primary, fontWeight: FontWeight.w800)),
          ])),
        ),
      ),
    );
  }
}
