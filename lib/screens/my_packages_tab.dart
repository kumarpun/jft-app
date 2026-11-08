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

class MyPackagesTab extends StatelessWidget {
  final AuthController auth;
  final VoidCallback onChanged;
  const MyPackagesTab({super.key, required this.auth, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LoadView<List<Purchase>>(
      load: auth.repo.myPackages,
      isEmpty: (l) => l.isEmpty,
      emptyText: "You haven't requested any package yet.",
      builder: (c, list) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (c, i) {
          final p = list[i];
          final (label, fg, bg) = switch (p.status) {
            'active' => (timeLeft(p.secondsLeft ?? 0), AppColors.ok, AppColors.okSoft),
            'pending' => ('Pending approval', AppColors.warn, const Color(0xFFFFFBEB)),
            _ => ('Expired', AppColors.danger, AppColors.dangerSoft),
          };
          final active = p.status == 'active';
          return SetCard(
            heading: heading(p.tests, p.name),
            extra: cats(p.tests).isEmpty ? null : Text(p.name, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
            topRight: Pill(label, color: fg, bg: bg),
            emptyText: p.status == 'pending' ? 'Complete payment via WhatsApp; access unlocks once approved.' : '',
            rows: [
              if (active)
                for (final t in p.tests)
                  SetRowData(
                    title: t.title,
                    meta: t.isForm
                        ? 'Google Form · ${formatDuration(t.durationSeconds)}'
                        : '${t.questionCount} questions · ${formatDuration(t.durationSeconds)}',
                    trailing: Icon(t.isForm ? Icons.open_in_new_rounded : Icons.play_circle_outline, color: AppColors.primary),
                    onTap: () => _open(c, t),
                  ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _open(BuildContext c, PackageTest t) async {
    if (t.isForm) {
      await Navigator.push(c, MaterialPageRoute(builder: (_) => FormScreen(title: t.title, url: t.formUrl!, durationSeconds: t.durationSeconds)));
      return;
    }
    await Navigator.push(c, MaterialPageRoute(builder: (_) => TakeTestScreen(auth: auth, testId: t.id)));
    onChanged();
  }
}
