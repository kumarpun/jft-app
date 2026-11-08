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
    return LoadView<List<TestSummary>>(
      load: auth.repo.freeTests,
      isEmpty: (l) => l.isEmpty,
      emptyText: 'No free sets right now.\nCheck Packages for more.',
      builder: (c, tests) {
        final groups = <String, List<TestSummary>>{};
        for (final t in tests) {
          groups.putIfAbsent(t.category.isEmpty ? 'General' : t.category, () => []).add(t);
        }
        final names = groups.keys.toList();
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: names.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (c, i) => SetCard(
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
                      Pill('Best ${t.bestPercent}%', color: percentColor(t.bestPercent!), bg: t.bestPercent! >= 50 ? AppColors.okSoft : AppColors.dangerSoft),
                      const SizedBox(width: 6),
                    ],
                    const Pill('Free', color: AppColors.muted, bg: Colors.white),
                  ]),
                  onTap: () => _open(c, t),
                ),
            ],
          ),
        );
      },
    );
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
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: AppColors.muted, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                if (category.isNotEmpty) Pill(category),
                Text(meta, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                if (best != null)
                  Pill('Best $best%', color: percentColor(best!), bg: best! >= 50 ? AppColors.okSoft : AppColors.dangerSoft),
              ]),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
        ]),
      );
}
