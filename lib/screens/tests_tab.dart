import 'package:flutter/material.dart';
import '../models.dart';
import '../state/auth_controller.dart';
import '../theme/app_theme.dart';
import '../util.dart';
import '../widgets/load_view.dart';
import '../widgets/set_card.dart';
import '../widgets/ui.dart';
import 'form_screen.dart';
import 'take_test_screen.dart';

class TestsTab extends StatelessWidget {
  final AuthController auth;
  final VoidCallback onChanged;
  const TestsTab({super.key, required this.auth, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LoadView<(List<TestSummary>, List<Announcement>)>(
      load: _load,
      isEmpty: (r) => r.$1.isEmpty && r.$2.isEmpty,
      emptyText: 'No free sets right now.\nCheck Packages for more.',
      builder: (c, data) {
        final (tests, featured) = data;
        final groups = <String, List<TestSummary>>{};
        for (final t in tests) {
          groups.putIfAbsent(t.category.isEmpty ? 'General' : t.category, () => []).add(t);
        }
        final names = groups.keys.toList();
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: featured.length + names.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (c, idx) {
            if (idx < featured.length) return _FeaturedBanner(auth: auth, a: featured[idx]);
            final i = idx - featured.length;
            return SetCard(
            heading: names[i],
            rows: [
              for (final t in groups[names[i]]!)
                SetRowData(
                  title: t.title,
                  meta: t.isForm
                      ? 'Google Form · ${formatDuration(t.durationSeconds)}'
                      : '${t.questionCount} questions · ${formatDuration(t.durationSeconds)}',
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (t.bestPercent != null) ...[
                      Pill('Best ${t.bestPercent}%', color: percentColor(t.bestPercent!), bg: t.bestPercent! >= 50 ? context.pal.okSoft : context.pal.dangerSoft),
                      const SizedBox(width: 6),
                    ],
                    Pill('Free', color: context.pal.muted, bg: context.pal.surface),
                  ]),
                  onTap: () => _open(c, t),
                ),
            ],
          );
          },
        );
      },
    );
  }

  // Featured announcements show as banners above the free sets; a failure here must not hide the sets.
  Future<(List<TestSummary>, List<Announcement>)> _load() async {
    final tests = auth.repo.freeTests();
    final featured = auth.repo.announcements().then((l) => l.where((a) => a.featured).toList()).catchError((_) => <Announcement>[]);
    return (await tests, await featured);
  }

  Future<void> _open(BuildContext c, TestSummary t) async {
    if (t.isForm) {
      await Navigator.push(c, MaterialPageRoute(builder: (_) => FormScreen(title: t.title, url: t.formUrl!, durationSeconds: t.durationSeconds)));
      return;
    }
    await Navigator.push(c, MaterialPageRoute(builder: (_) => TakeTestScreen(auth: auth, testId: t.id)));
    onChanged();
  }
}

class _FeaturedBanner extends StatelessWidget {
  final AuthController auth;
  final Announcement a;
  const _FeaturedBanner({required this.auth, required this.a});

  Widget _image(BoxFit fit) {
    final abs = auth.api.absolute(a.imageUrl);
    if (abs == null) return const SizedBox.shrink();
    return Image.network(
      abs,
      headers: auth.api.needsAuth(abs) ? auth.api.authHeaders : null,
      fit: fit,
      loadingBuilder: (c, child, p) => p == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
      errorBuilder: (c, e, s) => const SizedBox.shrink(),
    );
  }

  void _open(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (d) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (a.imageUrl != null) _image(BoxFit.fitWidth),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  if (a.body.isNotEmpty) ...[const SizedBox(height: 8), Text(a.body, style: const TextStyle(height: 1.4))],
                ]),
              ),
            ]),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.black.withValues(alpha: .55),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.pop(d),
                child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.close_rounded, color: Colors.white, size: 22)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = (a.imageUrl ?? '').isNotEmpty;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: .35), borderRadius: BorderRadius.circular(99)),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.star_rounded, color: Colors.white, size: 14),
        SizedBox(width: 4),
        Text('FEATURED', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: .8)),
      ]),
    );
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), boxShadow: AppColors.glow),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: AspectRatio(
            aspectRatio: hasImage ? 16 / 9 : 21 / 9,
            child: Stack(fit: StackFit.expand, children: [
              Container(decoration: const BoxDecoration(gradient: AppColors.heroGradient)),
              if (hasImage) _image(BoxFit.cover),
              // scrim so the title stays readable on any image
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [.45, 1],
                    colors: [Colors.transparent, const Color(0xFF040C20).withValues(alpha: .88)],
                  ),
                ),
              ),
              Positioned(left: 12, top: 12, child: chip),
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.2)),
                  if (a.body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(a.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3)),
                  ],
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class TestCard extends StatelessWidget {
  final String title, description, category, meta;
  final int? best;
  final VoidCallback onTap;
  const TestCard(
      {super.key, required this.title, this.description = '', this.category = '', required this.meta, this.best, required this.onTap});

  @override
  Widget build(BuildContext context) => LuxCard(
        onTap: onTap,
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.pal.text)),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: context.pal.muted, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                if (category.isNotEmpty) Pill(category),
                Text(meta, style: TextStyle(color: context.pal.muted, fontSize: 12.5)),
                if (best != null)
                  Pill('Best $best%', color: percentColor(best!), bg: best! >= 50 ? context.pal.okSoft : context.pal.dangerSoft),
              ]),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
        ]),
      );
}
