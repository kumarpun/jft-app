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
      load: () async => (await auth.repo.myPackages()).where((p) => p.status != 'pending').toList(),
      isEmpty: (l) => l.isEmpty,
      emptyText: "You haven't requested any package yet.",
      builder: (c, list) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (c, i) {
          final p = list[i];
          final (label, fg, bg) = switch (p.status) {
            'active' => (timeLeft(p.secondsLeft ?? 0, suffix: false), AppColors.ok, context.pal.okSoft),
            'pending' => ('Pending approval', AppColors.warn, const Color(0xFFFFFBEB)),
            _ => ('Expired', AppColors.danger, context.pal.dangerSoft),
          };
          final active = p.status == 'active';
          return SetCard(
            heading: heading(p.tests, p.name),
            count: p.tests.length,
            days: p.days,
            extra: cats(p.tests).isEmpty ? null : Text(p.name, style: TextStyle(color: context.pal.muted, fontWeight: FontWeight.w600)),
            topRight: Row(mainAxisSize: MainAxisSize.min, children: [
              if (active)
                LiveLeft(seconds: p.secondsLeft ?? 0, builder: (l) => Pill(l, color: fg, bg: bg, icon: Icons.timer_outlined))
              else
                Pill(label, color: fg, bg: bg),
              if (p.status == 'pending') ...[
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 26),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => _resend(c, p),
                  icon: const Icon(Icons.send_rounded, size: 12),
                  label: const Text('Resend'),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 26),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => _cancel(c, p),
                  child: const Text('Cancel'),
                ),
              ],
            ]),
            emptyText: p.status == 'pending' ? 'Complete payment via WhatsApp; access unlocks once approved.' : '',
            rows: [
              if (active)
                for (final t in p.tests)
                  SetRowData(
                    title: t.title,
                    group: t.folder,
                    meta: [if (!t.isForm) '${t.questionCount} questions', if (t.durationSeconds > 0) formatDuration(t.durationSeconds)].join(' · '),
                    trailing: Icon(t.isForm ? Icons.open_in_new_rounded : Icons.play_circle_outline, color: Theme.of(context).colorScheme.primary),
                    onTap: () => _open(c, t),
                  ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _resend(BuildContext c, Purchase p) async {
    try {
      await auth.repo.resendRequest(p.id);
      if (c.mounted) toast(c, 'Request re-sent. The admin has been notified.');
    } catch (e) {
      if (c.mounted) toast(c, '$e', error: true);
    }
  }

  Future<void> _cancel(BuildContext c, Purchase p) async {
    final ok = await showDialog<bool>(
      context: c,
      builder: (d) => AlertDialog(
        title: const Text('Cancel request?'),
        content: Text('Your request for ${p.name} will be withdrawn and removed from the admin. You can request it again later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Cancel request')),
        ],
      ),
    );
    if (ok != true || !c.mounted) return;
    try {
      await auth.repo.cancelRequest(p.id);
      if (!c.mounted) return;
      toast(c, 'Request cancelled.');
      onChanged();
    } catch (e) {
      if (c.mounted) toast(c, '$e', error: true);
    }
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
