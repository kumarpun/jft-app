import 'package:flutter/material.dart';
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
                      style: TextStyle(color: strong ? AppColors.primary : pal.text, fontSize: strong ? 17 : 14.5, fontWeight: strong ? FontWeight.w900 : FontWeight.w700)),
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
      final r = await auth.repo.requestPackage(p.id);
      if (!c.mounted) return;
      if (r.whatsappUrl != null) await openUrl(c, r.whatsappUrl!);
      if (c.mounted) toast(c, r.status == 'active' ? 'Package activated' : 'Request sent. Finish payment on WhatsApp.');
      onChanged();
    } catch (e) {
      if (c.mounted) toast(c, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadView<List<Package>>(
      load: auth.repo.packages,
      isEmpty: (l) => l.isEmpty,
      emptyText: 'No packages on sale right now.',
      builder: (c, list) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (c, i) {
          final p = list[i];
          final status = p.myStatus;
          final names = _names(p);
          return SetCard(
            heading: names.isEmpty ? p.name : names.join(', '),
            topRight: Row(mainAxisSize: MainAxisSize.min, children: [
              if (p.originalPrice != null && p.originalPrice! > p.price) ...[
                Text('रु ${_num(p.originalPrice!)}', style: TextStyle(color: context.pal.muted, fontSize: 12, decoration: TextDecoration.lineThrough)),
                const SizedBox(width: 5),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(gradient: AppColors.accentGradient, borderRadius: BorderRadius.circular(10)),
                child: Text('रु ${_num(p.price)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0B1B3F))),
              ),
              const SizedBox(width: 10),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: status == null ? () => _buy(c, p) : null,
                child: Text(status == null ? 'Buy Now' : (status == 'active' ? 'Active' : 'Requested')),
              ),
            ]),
            extra: Text(names.isEmpty ? '${p.days} days' : '${p.name} · ${p.days} days',
                style: TextStyle(color: context.pal.muted, fontWeight: FontWeight.w600, fontSize: 13)),
            rows: [
              for (final t in p.tests)
                SetRowData(
                  title: t.title,
                  meta: t.isForm
                      ? 'Google Form · ${formatDuration(t.durationSeconds)}'
                      : '${t.questionCount} questions · ${formatDuration(t.durationSeconds)}',
                  trailing: Pill('Paid', color: context.pal.muted, bg: context.pal.surface),
                ),
            ],
          );
        },
      ),
    );
  }
}

String _num(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
