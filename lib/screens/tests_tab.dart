import 'dart:async';
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
    return LoadView<(List<TestSummary>, List<Announcement>, List<Opening>)>(
      load: _load,
      isEmpty: (r) => r.$1.isEmpty && r.$2.isEmpty && r.$3.isEmpty,
      emptyText: 'No free sets right now.\nCheck Packages for more.',
      builder: (c, data) {
        final (tests, featured, openings) = data;
        final groups = <String, List<TestSummary>>{};
        for (final t in tests) {
          groups.putIfAbsent(t.category.isEmpty ? 'General' : t.category, () => []).add(t);
        }
        return SearchHost(options: groups.keys.toList(), builder: (c, q, sel, box) {
        final names = groups.keys.where((n) => (sel == null || n == sel) && (q.isEmpty || n.toLowerCase().contains(q))).toList();
        // banners first, then the search box, then the category cards
        final no = openings.length; // opening-date cards come first
        final nb = (featured.isEmpty ? 0 : 1) + no;
        final empty = names.isEmpty;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: nb + 1 + (empty ? 1 : names.length),
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (c, idx) {
            if (idx < no) return _OpeningCard(o: openings[idx]);
            if (idx < nb) return _FeaturedCarousel(auth: auth, items: featured);
            if (idx == nb) return box;
            if (empty) return Padding(padding: const EdgeInsets.only(top: 24), child: Center(child: Text('No matching category.', style: TextStyle(color: c.pal.muted))));
            final i = idx - nb - 1;
            return SetCard(
            heading: names[i],
            rows: [
              for (final t in groups[names[i]]!)
                SetRowData(
                  title: t.title,
                  group: t.folder,
                    meta: [if (!t.isForm) '${t.questionCount} questions', if (t.durationSeconds > 0) formatDuration(t.durationSeconds)].join(' · '),
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
        });
      },
    );
  }

  // Featured announcements show as banners above the free sets; a failure here must not hide the sets.
  Future<(List<TestSummary>, List<Announcement>, List<Opening>)> _load() async {
    final tests = auth.repo.freeTests();
    final featured = auth.repo.announcements().then((l) => l.where((a) => a.featured).toList()).catchError((_) => <Announcement>[]);
    final openings = auth.repo.openings().catchError((_) => <Opening>[]);
    return (await tests, await featured, await openings);
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

/// Opening-date notice: title, date and a live countdown. Disappears when the day starts.
class _OpeningCard extends StatefulWidget {
  final Opening o;
  const _OpeningCard({required this.o});
  @override
  State<_OpeningCard> createState() => _OpeningCardState();
}

class _OpeningCardState extends State<_OpeningCard> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  // Approximate BS calendar: anchored at 1 Mangsir 2083 = 17 Nov 2026, month lengths for 2083 / 2084.
  static const _bsMonths = ['बैशाख', 'जेठ', 'असार', 'श्रावण', 'भदौ', 'असोज', 'कार्तिक', 'मंसिर', 'पौष', 'माघ', 'फागुन', 'चैत'];
  static const _bsLen = {
    2083: [31, 31, 32, 32, 31, 30, 30, 30, 29, 30, 30, 29],
    2084: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
  };
  static String _nepali(DateTime d) {
    var diff = DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(2026, 11, 17)).inDays; // days since 1 Mangsir 2083
    var y = 2083, m = 7;
    while (diff < 0 || diff >= _bsLen[y]![m]) {
      if (diff < 0) {
        m--;
        if (m < 0) { y--; m = 11; }
        if (!_bsLen.containsKey(y)) return '';
        diff += _bsLen[y]![m];
      } else {
        diff -= _bsLen[y]![m];
        m++;
        if (m > 11) { y++; m = 0; }
        if (!_bsLen.containsKey(y)) return '';
      }
    }
    const dig = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    final day = (diff + 1).toString().padLeft(2, '0').split('').map((c) => dig[int.parse(c)]).join();
    return '${_bsMonths[m]} $day';
  }

  static const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  @override
  Widget build(BuildContext context) {
    final left = widget.o.date.difference(DateTime.now());
    if (left.inSeconds <= 0) return const SizedBox.shrink();
    final pal = context.pal;
    final primary = Theme.of(context).colorScheme.primary;
    String two(int n) => n.toString().padLeft(2, '0');
    Widget unit(String v, String l) => Column(children: [
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(v, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, fontFeatures: [FontFeature.tabularFigures()])),
          ),
          const SizedBox(height: 3),
          Text(l, style: TextStyle(color: pal.muted, fontSize: 10, fontWeight: FontWeight.w600)),
        ]);
    final d = widget.o.date;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [pal.surface, pal.primarySoft]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pal.border, width: 1.2),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: .10), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.o.label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: pal.text, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('${d.day} ${_months[d.month - 1]} ${d.year}  |  ${_nepali(d)}', textAlign: TextAlign.center, style: TextStyle(color: pal.muted, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          unit('${left.inDays}', 'days'),
          unit(two(left.inHours % 24), 'hrs'),
          unit(two(left.inMinutes % 60), 'min'),
          unit(two(left.inSeconds % 60), 'sec'),
        ]),
      ]),
    );
  }
}

/// One featured item shows as a banner; several slide as an auto-advancing carousel with dots.
class _FeaturedCarousel extends StatefulWidget {
  final AuthController auth;
  final List<Announcement> items;
  const _FeaturedCarousel({required this.auth, required this.items});
  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  final _ctrl = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    if (widget.items.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!_ctrl.hasClients) return;
        _ctrl.animateToPage((_page + 1) % widget.items.length, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.length == 1) return _FeaturedBanner(auth: widget.auth, a: items.first);
    final hasImage = items.any((a) => (a.imageUrl ?? '').isNotEmpty);
    final primary = Theme.of(context).colorScheme.primary;
    return Column(children: [
      AspectRatio(
        aspectRatio: hasImage ? 16 / 9 : 21 / 9,
        child: PageView.builder(
          controller: _ctrl,
          itemCount: items.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (c, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _FeaturedBanner(auth: widget.auth, a: items[i]),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < items.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _page ? 18 : 7,
            height: 7,
            decoration: BoxDecoration(color: i == _page ? primary : primary.withValues(alpha: .25), borderRadius: BorderRadius.circular(4)),
          ),
      ]),
    ]);
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
          Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.primary),
        ]),
      );
}
