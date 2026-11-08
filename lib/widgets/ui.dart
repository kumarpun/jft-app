import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

void toast(BuildContext c, String msg, {bool error = false}) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: error ? AppColors.primaryDark : AppColors.ink, behavior: SnackBarBehavior.floating));
}

Future<void> openUrl(BuildContext c, String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && c.mounted) toast(c, 'Could not open link', error: true);
}

Future<void> openVideo(BuildContext c, String id) => openUrl(c, 'https://www.youtube.com/watch?v=$id');

class Pill extends StatelessWidget {
  final String text;
  final Color color, bg;
  const Pill(this.text, {super.key, this.color = AppColors.primary, this.bg = AppColors.primarySoft});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .2)),
      );
}

class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 72});
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(size * .035),
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(size * .3),
          boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: .45), blurRadius: size * .4, spreadRadius: size * .02), BoxShadow(color: Colors.black.withValues(alpha: .25), blurRadius: size * .25, offset: Offset(0, size * .08))],
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
            colors: [Color(0xFFE5303C), AppColors.primary, Color(0xFF5A030A), Color(0xFF2A0105)],
            stops: [0, .35, .78, 1],
          ),
        ),
        child: Stack(children: [
          Positioned(right: -70, top: -60, child: _ring(260, .10)),
          Positioned(right: 30, top: 120, child: _dot(14, .22)),
          Positioned(left: -90, bottom: -80, child: _ring(300, .07)),
          Positioned(left: 40, bottom: 140, child: _dot(8, .25)),
          Positioned(left: 0, right: 0, top: 0, child: Container(height: 2, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, AppColors.gold, Colors.transparent])))),
          child,
        ]),
      );
  static Widget _ring(double d, double a) => Container(
      width: d, height: d, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: a), width: 26)));
  static Widget _dot(double d, double a) => Container(
      width: d, height: d, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withValues(alpha: a)));
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .38), blurRadius: 50, offset: const Offset(0, 22))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(height: 5, decoration: const BoxDecoration(gradient: AppColors.goldGradient)),
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
                      Icon(Icons.play_circle_fill, color: AppColors.gold, size: 56),
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
