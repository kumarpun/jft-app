import 'package:flutter/material.dart';
import '../models.dart';
import '../state/auth_controller.dart';
import '../theme/app_theme.dart';
import '../util.dart';
import '../widgets/load_view.dart';
import '../widgets/ui.dart';
import 'result_screen.dart';

class ResultsTab extends StatelessWidget {
  final AuthController auth;
  const ResultsTab({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return LoadView<List<ResultSummary>>(
      load: auth.repo.results,
      isEmpty: (l) => l.isEmpty,
      emptyText: 'No attempts yet. Take a set to see results.',
      builder: (c, list) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (c, i) {
          final r = list[i];
          return LuxCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${formatDate(r.submittedAt)}${r.timedOut ? ' · timed out' : ''}'),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${r.percent}%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: percentColor(r.percent))),
                Text('${r.score}/${r.total}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ]),
              onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => ResultScreen(auth: auth, id: r.id))),
            ),
          );
        },
      ),
    );
  }
}
