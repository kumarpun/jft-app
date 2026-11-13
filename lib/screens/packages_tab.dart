import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models.dart';
import '../state/auth_controller.dart';
import '../theme/app_theme.dart';
import '../util.dart';
import '../widgets/load_view.dart';
import '../widgets/set_card.dart';
import '../widgets/ui.dart';

class PackagesTab extends StatelessWidget {
  final AuthController auth;
  final VoidCallback onChanged;
  const PackagesTab({super.key, required this.auth, required this.onChanged});

  static List<String> _names(Package p) => {...p.setCategories, for (final k in p.categories) k.$1}.toList();

  Future<void> _buy(BuildContext c, Package p) async {
    final cats = _names(p);
    final ok = await showDialog<bool>(
      context: c,
      builder: (d) {
        final pal = d.pal;
        Widget row(String label, String value, {bool strong = false}) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 78, child: Text(label, style: TextStyle(color: pal.muted, fontSize: 13.5, fontWeight: FontWeight.w600))),
                Expanded(
                  child: Text(value,
                      style: TextStyle(color: strong ? Theme.of(d).colorScheme.primary : pal.text, fontSize: strong ? 17 : 14.5, fontWeight: strong ? FontWeight.w900 : FontWeight.w700)),
                ),
              ]),
            );
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(gradient: AppColors.heroGradient, shape: BoxShape.circle, boxShadow: AppColors.glow),
                  child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 26),
                ),
              ),
              const SizedBox(height: 14),
              Text('Confirm purchase', textAlign: TextAlign.center, style: TextStyle(color: pal.text, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: pal.surface2, borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  if (cats.isNotEmpty) row('Category', cats.join(', ')),
                  row('Package', '${p.name} · ${p.days} days'),
                  row('Price', 'रु ${_num(p.price)}', strong: true),
                ]),
              ),
              const SizedBox(height: 14),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.chat_outlined, size: 17, color: pal.muted),
                const SizedBox(width: 8),
                Expanded(child: Text('You will finish the payment on WhatsApp.', style: TextStyle(color: pal.muted, fontSize: 13, height: 1.35))),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(onPressed: () => Navigator.pop(d, false), child: const Text('No')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Yes, buy')),
                ),
              ]),
            ]),
          ),
        );
      },
    );
    if (ok != true || !c.mounted) return;
    try {
      final r = await auth.repo.requestPackage(p.id, category: p.category);
      if (!c.mounted) return;
      if (r.whatsappUrl != null) await openUrl(c, r.whatsappUrl!);
      if (c.mounted) toast(c, r.status == 'active' ? 'Package activated' : 'Request sent. Finish payment on WhatsApp.');
      onChanged();
    } catch (e) {
      if (c.mounted) toast(c, '$e', error: true);
    }
  }

  Future<void> _cancel(BuildContext c, Package p) async {
    final ok = await showDialog<bool>(
      context: c,
      builder: (d) => AlertDialog(
        title: const Text('Cancel request?'),
        content: Text('Your request for ${p.name} will be withdrawn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Cancel request')),
        ],
      ),
    );
    if (ok != true || !c.mounted) return;
    try {
      var ids = p.pendingIds;
      if (ids.isEmpty) {
        // older server: find the pending purchase(s) for this package ourselves
        final mine = await auth.repo.myPackages();
        final tids = {for (final t in p.tests) t.id};
        ids = [for (final m in mine) if (m.status == 'pending' && (m.packageId == p.id || m.tests.any((t) => tids.contains(t.id)))) m.id];
      }
      if (ids.isEmpty) throw ApiException('No pending request found.');
      for (final id in ids) {
        await auth.repo.cancelRequest(id);
      }
      if (c.mounted) toast(c, 'Request cancelled');
      onChanged();
    } catch (e) {
      if (c.mounted) toast(c, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadView<List<Package>>(
      // Purchased (active) packages live under My Packages; only show what can still be bought here.
      load: () async => [for (final p in await auth.repo.packages()) if (p.myStatus != 'active') p],
      isEmpty: (l) => l.isEmpty,
      emptyText: 'No packages to buy right now. Your purchased packages are under My Packages.',
      builder: (c, all) => _Filtered(
        all: all,
        labelOf: (p) {
          final n = _names(p);
          return n.isEmpty ? p.name : n.join(', ');
        },
        builder: (c, list) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (c, i) {
          final sorted = [...list.where((x) => x.myStatus != 'active'), ...list.where((x) => x.myStatus == 'active')];
          final p = sorted[i];
          final status = p.myStatus;
          final names = _names(p);
          return SetCard(
            heading: names.isEmpty ? p.name : names.join(', '),
            days: p.days,
            tint: status == 'active' ? AppColors.ok : null,
            topRight: Row(mainAxisSize: MainAxisSize.min, children: [
              if (p.originalPrice != null && p.originalPrice! > p.price) ...[
                Text('रु ${_num(p.originalPrice!)}', style: TextStyle(color: context.pal.muted, fontSize: 12, fontWeight: FontWeight.w900, decoration: TextDecoration.lineThrough, decorationThickness: 2)),
                const SizedBox(width: 5),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFF5B83D)]), borderRadius: BorderRadius.circular(10)),
                child: Text('रु ${_num(p.price)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF3D2A00))),
              ),
            ]),
            footer: Row(children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: status == 'active' ? AppColors.ok.withValues(alpha: .14) : context.pal.primarySoft,
                    disabledForegroundColor: status == 'active' ? AppColors.ok : Theme.of(c).colorScheme.primary,
                    elevation: 0,
                    minimumSize: const Size(0, 40),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  onPressed: status == null ? () => _buy(c, p) : null,
                  child: status == 'active'
                      ? const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle_rounded, size: 18), SizedBox(width: 6), Text('Purchased')])
                      : status == 'pending'
                          ? const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.schedule_rounded, size: 17), SizedBox(width: 6), Text('Requested')])
                          : const Text('Buy Now'),
                ),
              ),
              if (status == 'pending') ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: BorderSide(color: AppColors.danger.withValues(alpha: .5)),
                      minimumSize: const Size(0, 40),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    onPressed: () => _cancel(c, p),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Cancel request'),
                  ),
                ),
              ],
            ]),
            extra: names.isEmpty ? null : Text(p.name, style: TextStyle(color: context.pal.muted, fontWeight: FontWeight.w600, fontSize: 11.5)),
            rows: [
              for (final t in p.tests)
                SetRowData(
                  title: t.title,
                  group: t.folder,
                    meta: [if (!t.isForm) '${t.questionCount} questions', if (t.durationSeconds > 0) formatDuration(t.durationSeconds)].join(' · '),
                  trailing: Pill('🔒 Premium'),
                ),
            ],
          );
        },
      )),
    );
  }
}

/// "Search category" field above a list of packages; [builder] gets the filtered list.
class _Filtered extends StatefulWidget {
  final List<Package> all;
  final String Function(Package) labelOf;
  final Widget Function(BuildContext, List<Package>) builder;
  const _Filtered({required this.all, required this.labelOf, required this.builder});
  @override
  State<_Filtered> createState() => _FilteredState();
}

class _FilteredState extends State<_Filtered> {
  @override
  Widget build(BuildContext context) => SearchHost(
      options: {for (final p in widget.all) widget.labelOf(p)}.toList(),
      builder: (c, q, sel, box) {
        final shown = widget.all
            .where((p) => (sel == null || widget.labelOf(p) == sel) && (q.isEmpty || widget.labelOf(p).toLowerCase().contains(q) || p.name.toLowerCase().contains(q)))
            .toList();
        return Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: box),
          Expanded(child: shown.isEmpty ? Center(child: Text('No matching category.', style: TextStyle(color: context.pal.muted))) : widget.builder(c, shown)),
        ]);
      });
}

String _num(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
