import 'dart:async';
import 'package:flutter/material.dart';
import '../models.dart';
import '../state/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/net_image.dart';
import '../widgets/ui.dart';
import 'result_screen.dart';

// Colours taken from the web exam UI (.exam in globals.css).
const _examGreen = Color(0xFF0F2A5C);
const _examGreenDark = Color(0xFF081A3E);
const _examBlue = Color(0xFFE3ECFB);
const _examGrey = Color(0xFF9CA3AF);
const _sectionSize = 12;

class TakeTestScreen extends StatefulWidget {
  final AuthController auth;
  final int testId;
  const TakeTestScreen({super.key, required this.auth, required this.testId});
  @override
  State<TakeTestScreen> createState() => _TakeTestScreenState();
}

class _TakeTestScreenState extends State<TakeTestScreen> {
  TestPaper? _paper;
  String? _error;
  final Map<int, String> _answers = {};
  final _strip = ScrollController();
  int _index = 0;
  int _left = 0;
  DateTime? _end;
  Timer? _timer;
  bool _submitting = false;
  bool _timeUp = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final p = await widget.auth.repo.test(widget.testId);
      if (!mounted) return;
      setState(() {
        _paper = p;
        _left = p.durationSeconds;
      });
      if (p.durationSeconds > 0) {
        _end = DateTime.now().add(Duration(seconds: p.durationSeconds));
        _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
          final r = _end!.difference(DateTime.now()).inSeconds;
          final rem = r < 0 ? 0 : r;
          if (rem == 0) {
            _timer?.cancel();
            setState(() {
              _left = 0;
              _timeUp = true;
            });
          } else if (rem != _left) {
            setState(() => _left = rem);
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _strip.dispose();
    super.dispose();
  }

  Future<bool> _confirm(String title, String body, String ok) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: Text(ok)),
          ],
        ),
      ) ??
      false;

  Future<void> _submit({bool timedOut = false}) async {
    final p = _paper!;
    if (_submitting) return;
    if (!timedOut) {
      final left = p.questions.length - _answers.length;
      if (left > 0 && !await _confirm('Finish test', 'You have $left unanswered question(s). Submit anyway?', 'Submit')) return;
    }
    setState(() => _submitting = true);
    _timer?.cancel();
    try {
      final id = await widget.auth.repo.submit(p.id, _answers, timedOut: timedOut);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ResultScreen(auth: widget.auth, id: id)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      toast(context, '$e', error: true);
    }
  }

  Future<void> _leave() async {
    if (_submitting) return;
    final leave = await _confirm('Leave test?', 'Your answers will be lost.', 'Leave');
    if (!mounted || !leave) return;
    Navigator.pop(context);
  }

  void _go(int i) {
    setState(() => _index = i);
    if (_strip.hasClients) {
      final target = (i * 50.0 - 80).clamp(0.0, _strip.position.maxScrollExtent);
      _strip.animateTo(target, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  String get _clockText {
    final s = _left < 0 ? 0 : _left;
    String t(int v) => v.toString().padLeft(2, '0');
    return '${t(s ~/ 3600)}:${t((s % 3600) ~/ 60)}:${t(s % 60)}';
  }

  bool _sectionEnd(TestPaper p, int i) {
    final hasSections = p.questions.any((q) => q.section != null && q.section!.isNotEmpty);
    if (!hasSections) return (i + 1) % _sectionSize == 0;
    final next = i + 1 < p.questions.length ? p.questions[i + 1].section : null;
    return p.questions[i].section != next;
  }

  @override
  Widget build(BuildContext context) {
    final p = _paper;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: _error == null
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    OutlinedButton(onPressed: _load, child: const Text('Retry')),
                  ]),
                ),
        ),
      );
    }
    final q = p.questions[_index];
    final last = _index == p.questions.length - 1;
    final low = p.durationSeconds > 0 && _left <= 60;
    final secEnd = _sectionEnd(p, _index);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        _leave();
      },
      child: Scaffold(
        backgroundColor: context.pal.surface,
        body: Stack(children: [
          Column(children: [
            // Black top bar: question / section, clock, finish button.
            Container(
              color: Colors.black,
              padding: EdgeInsets.fromLTRB(12, MediaQuery.of(context).padding.top + 8, 12, 8),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Exit test',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: _leave,
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 3,
                  child: DefaultTextStyle(
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text.rich(TextSpan(children: [
                        const TextSpan(text: 'Question: ', style: TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: '${_index + 1}'),
                      ])),
                      if (q.section != null && q.section!.isNotEmpty)
                        Text.rich(
                          TextSpan(children: [
                            const TextSpan(text: 'Section: ', style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: q.section),
                          ]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ]),
                  ),
                ),
                if (p.durationSeconds > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text('◷', style: TextStyle(color: Colors.white, fontSize: 24, height: 1)),
                      const SizedBox(width: 6),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Time Remaining', style: TextStyle(color: Colors.white, fontSize: 11)),
                        Text(_clockText,
                            style: TextStyle(
                                color: low ? const Color(0xFFFF7B7B) : Colors.white,
                                fontSize: 13,
                                fontWeight: low ? FontWeight.w700 : FontWeight.w400,
                                fontFeatures: const [FontFeature.tabularFigures()])),
                      ]),
                    ]),
                  ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFB5CEF7),
                    foregroundColor: const Color(0xFF0B1B3F),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  onPressed: _submitting ? null : _submit,
                  child: const Text('Finish Test', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ]),
            ),
            // Green bar: test title + candidate.
            Container(
              width: double.infinity,
              color: _examGreen,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white, fontSize: 13),
                child: Wrap(spacing: 12, runSpacing: 2, alignment: WrapAlignment.spaceBetween, children: [
                  Text.rich(TextSpan(children: [
                    const TextSpan(text: 'Test: ', style: TextStyle(fontWeight: FontWeight.w800)),
                    TextSpan(text: p.title),
                  ])),
                  Text.rich(TextSpan(children: [
                    const TextSpan(text: 'Candidate: ', style: TextStyle(fontWeight: FontWeight.w800)),
                    TextSpan(text: widget.auth.user?.name ?? ''),
                  ])),
                ]),
              ),
            ),
            // Question number strip.
            Container(
              height: 48,
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.pal.border))),
              child: ListView.builder(
                controller: _strip,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                itemCount: p.questions.length,
                itemBuilder: (c, i) {
                  final cur = i == _index;
                  final done = _answers.containsKey(p.questions[i].id);
                  final color = cur ? _examGreen : (done ? _examGreenDark : _examGrey);
                  return GestureDetector(
                    onTap: () => _go(i),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: CustomPaint(
                        painter: _NumPainter(color, cur),
                        child: SizedBox(
                          width: cur ? 58 : 44,
                          height: 32,
                          child: Padding(
                            padding: EdgeInsets.only(right: cur ? 14 : 0),
                            child: Center(
                              child: Text('${i + 1}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Question body.
            Expanded(
              child: ListView(padding: const EdgeInsets.all(12), children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: _examBlue, borderRadius: BorderRadius.circular(4)),
                  child: Text(q.text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.4)),
                ),
                if (q.imageUrl != null && q.imageUrl!.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 18), child: NetImage(api: widget.auth.api, url: q.imageUrl)),
                if (q.videoId != null && q.videoId!.isNotEmpty) VideoBox(videoId: q.videoId!),
                const SizedBox(height: 14),
                for (final k in ['A', 'B', 'C', 'D'])
                  if ((q.options[k] ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ExamOption(
                        letter: k,
                        text: q.options[k]!,
                        selected: _answers[q.id] == k,
                        onTap: () => setState(() => _answers[q.id] = k),
                      ),
                    ),
              ]),
            ),
            // Sticky actions.
            Container(
              decoration: BoxDecoration(color: context.pal.surface, border: Border(top: BorderSide(color: context.pal.border))),
              padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 10),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${_answers.length}/${p.questions.length} answered',
                      style: TextStyle(fontSize: 12, color: context.pal.muted)),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _index == 0 ? null : () => _go(_index - 1),
                      child: const Text('← Previous'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: last
                        ? FilledButton(
                            onPressed: _submitting ? null : _submit,
                            child: Text(_submitting ? 'Submitting…' : 'Submit test'))
                        : FilledButton(
                            style: secEnd ? FilledButton.styleFrom(backgroundColor: AppColors.primaryDark) : null,
                            onPressed: () => _go(_index + 1),
                            child: Text(secEnd ? 'Finish section' : 'Next →')),
                  ),
                ]),
              ]),
            ),
          ]),
          if (_timeUp)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: context.pal.surface, borderRadius: BorderRadius.circular(16)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    CircleAvatar(radius: 28, backgroundColor: context.pal.dangerSoft, child: Text('⏱', style: TextStyle(fontSize: 26))),
                    const SizedBox(height: 12),
                    const Text('Time limit exceeded', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: 'You needed to complete the test within the time limit. Your attempt will be submitted as '),
                        TextSpan(text: 'incomplete', style: TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: ', and unanswered questions will be marked as not answered.'),
                      ]),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.pal.muted),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submitting ? null : () => _submit(timedOut: true),
                        child: Text(_submitting ? 'Submitting…' : 'View result'),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

/// Question number chip; the current one has an arrow on its right edge (web `.exam-num.current::after`).
class _NumPainter extends CustomPainter {
  final Color color;
  final bool current;
  _NumPainter(this.color, this.current);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    if (!current) {
      canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6)), paint);
      return;
    }
    const arrow = 14.0;
    final body = size.width - arrow;
    final path = Path()
      ..moveTo(6, 0)
      ..lineTo(body, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(body, size.height)
      ..lineTo(6, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - 6)
      ..lineTo(0, 6)
      ..quadraticBezierTo(0, 0, 6, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_NumPainter o) => o.color != color || o.current != current;
}

class _ExamOption extends StatelessWidget {
  final String letter, text;
  final bool selected;
  final VoidCallback onTap;
  const _ExamOption({required this.letter, required this.text, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? context.pal.primarySoft : context.pal.surface,
            border: Border.all(color: selected ? _examGreen : context.pal.text, width: 2),
          ),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: '$letter. ', style: const TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: text),
            ]),
            style: TextStyle(fontSize: 17, height: 1.35, color: context.pal.text),
          ),
        ),
      );
}
