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

  Future<void> _buy(BuildContext c, Package p) async {
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
          final names = {...p.setCategories, for (final k in p.categories) k.$1}.toList();
          return SetCard(
            heading: names.isEmpty ? p.name : names.join(', '),
            topRight: Row(mainAxisSize: MainAxisSize.min, children: [
              if (p.originalPrice != null && p.originalPrice! > p.price) ...[
                Text('रु ${_num(p.originalPrice!)}', style: const TextStyle(color: AppColors.muted, fontSize: 12, decoration: TextDecoration.lineThrough)),
                const SizedBox(width: 5),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(10)),
                child: Text('रु ${_num(p.price)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF3A2A06))),
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
                style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600, fontSize: 13)),
            rows: [
              for (final t in p.tests)
                SetRowData(
                  title: t.title,
                  meta: t.isForm
                      ? 'Google Form · ${formatDuration(t.durationSeconds)}'
                      : '${t.questionCount} questions · ${formatDuration(t.durationSeconds)}',
                  trailing: const Pill('Paid', color: AppColors.muted, bg: Colors.white),
                ),
            ],
          );
        },
      ),
    );
  }
}

String _num(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
