import 'package:flutter/material.dart';
import '../models.dart';
import '../state/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/load_view.dart';
import '../widgets/net_image.dart';
import '../widgets/ui.dart';

// Section bar colours from the web result page.
const _secColors = [Color(0xFF0F2A5C), Color(0xFF4F7FD8), Color(0xFF081A3E), Color(0xFF7FA8F0), Color(0xFF2F4F9E)];

class ResultScreen extends StatelessWidget {
  final AuthController auth;
  final int id;
  const ResultScreen({super.key, required this.auth, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: topBar(context, 'My results'),
      body: LoadView<ResultDetail>(
        load: () => auth.repo.result(id),
        builder: (c, r) {
          final wrong = r.answers.length - r.correct - r.skipped;
          return ListView(padding: const EdgeInsets.all(16), children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _card(context),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Result', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text('Your Exam Results', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
                    )),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
                      decoration: BoxDecoration(color: context.pal.surface2, borderRadius: BorderRadius.circular(10)),
                      child: Column(children: [
                        Text('${r.score} / ${r.total}', style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(r.passed ? '🎉 PASSED' : 'NOT PASSED',
                            style: TextStyle(fontWeight: FontWeight.w700, color: r.passed ? AppColors.ok : AppColors.danger)),
                        if (r.timedOut)
                          Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Pill('Incomplete · time limit exceeded', color: AppColors.danger, bg: context.pal.dangerSoft),
                          ),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Wrap(spacing: 8, runSpacing: 6, alignment: WrapAlignment.center, children: [
                        Pill('${r.percent}%', color: context.pal.muted, bg: context.pal.surface2),
                        Pill('${r.correct} correct', color: AppColors.ok, bg: context.pal.okSoft),
                        Pill('$wrong wrong', color: AppColors.danger, bg: context.pal.dangerSoft),
                        Pill('${r.skipped} not answered', color: context.pal.muted, bg: context.pal.surface2),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Text(r.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    if (r.submittedAt.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Submitted ${_when(r.submittedAt)}', style: TextStyle(color: context.pal.muted)),
                      ),
                    if (r.sections.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Text('Section Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      for (var i = 0; i < r.sections.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Expanded(child: Text(r.sections[i].name, style: const TextStyle(fontSize: 13.5))),
                              Text('${r.sections[i].percent.toStringAsFixed(1)}%',
                                  style: TextStyle(fontSize: 13.5, color: context.pal.muted)),
                            ]),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: (r.sections[i].percent / 100).clamp(0, 1).toDouble(),
                                minHeight: 14,
                                backgroundColor: context.pal.surface2,
                                color: _secColors[i % _secColors.length],
                              ),
                            ),
                          ]),
                        ),
                    ],
                  ]),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 24, 0, 12),
              child: Text('Review', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            ),
            for (var i = 0; i < r.answers.length; i++) _AnswerCard(auth: auth, n: i + 1, a: r.answers[i]),
          ]);
        },
      ),
    );
  }

  static BoxDecoration _card(BuildContext context) => BoxDecoration(
        color: context.pal.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.pal.border),
      );

  static String _when(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    String t(int v) => v.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year}, ${t(d.hour)}:${t(d.minute)}';
  }
}

class _AnswerCard extends StatelessWidget {
  final AuthController auth;
  final int n;
  final AnswerReview a;
  const _AnswerCard({required this.auth, required this.n, required this.a});

  @override
  Widget build(BuildContext context) {
    final status = a.isCorrect ? 'Correct' : (a.selected != null ? 'Wrong' : 'Not answered');
    final statusColor = a.isCorrect ? AppColors.ok : (a.selected != null ? AppColors.danger : context.pal.muted);
    final statusBg = a.isCorrect ? context.pal.okSoft : (a.selected != null ? context.pal.dangerSoft : context.pal.surface2);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: ResultScreen._card(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: context.pal.primarySoft, shape: BoxShape.circle),
            child: Text('$n', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(a.text, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4)),
          )),
          const SizedBox(width: 8),
          Pill(status, color: statusColor, bg: statusBg),
        ]),
        if (a.imageUrl != null && a.imageUrl!.isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 14), child: NetImage(api: auth.api, url: a.imageUrl)),
        if (a.videoId != null && a.videoId!.isNotEmpty) VideoBox(videoId: a.videoId!),
        const SizedBox(height: 14),
        for (final k in ['A', 'B', 'C', 'D'])
          if ((a.options[k] ?? '').isNotEmpty) _option(context, k),
        if (a.feedback != null && a.feedback!.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.pal.surface2,
              border: Border(left: BorderSide(color: Theme.of(context).colorScheme.primary, width: 3)),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Text.rich(TextSpan(children: [
              const TextSpan(text: 'Feedback: ', style: TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: a.feedback),
            ])),
          ),
      ]),
    );
  }

  Widget _option(BuildContext context, String k) {
    final correct = k == a.correctOption;
    final wrong = k == a.selected && !correct;
    final mine = k == a.selected;
    final tag = correct ? (mine ? 'Your answer ✓' : 'Correct answer') : (mine ? 'Your answer' : '');
    final tagColor = correct ? AppColors.ok : AppColors.danger;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: correct ? context.pal.okSoft : (wrong ? context.pal.dangerSoft : context.pal.surface),
        border: Border.all(color: correct ? AppColors.ok : (wrong ? AppColors.danger : context.pal.border)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        SizedBox(width: 18, child: Text(k, style: TextStyle(fontWeight: FontWeight.w700, color: context.pal.muted))),
        const SizedBox(width: 12),
        Expanded(child: Text(a.options[k]!, style: const TextStyle(fontSize: 15))),
        if (tag.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(tag, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tagColor)),
        ],
      ]),
    );
  }
}
