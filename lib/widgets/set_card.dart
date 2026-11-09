import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ui.dart';

class SetRowData {
  final String title, meta;
  final Widget? trailing;
  final VoidCallback? onTap;
  const SetRowData({required this.title, this.meta = '', this.trailing, this.onTap});
}

/// Green-bordered card: "N sets" pill, heading, optional [extra] under it,
/// an expandable list of numbered sets, and an optional [footer].
class SetCard extends StatefulWidget {
  final String heading;
  final List<SetRowData> rows;
  final Widget? topRight, extra, footer;
  final String emptyText;
  final double headingSize, pad;
  const SetCard({super.key, required this.heading, required this.rows, this.topRight, this.extra, this.footer, this.emptyText = '', this.headingSize = 24, this.pad = 16});
  @override
  State<SetCard> createState() => _SetCardState();
}

class _SetCardState extends State<SetCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.rows.length;
    return FadeSlide(child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [context.pal.surface, context.pal.primarySoft]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: .30), width: 1.2),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: .16), blurRadius: 22, offset: const Offset(0, 10)),
          BoxShadow(color: Colors.black.withValues(alpha: .03), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      padding: EdgeInsets.all(widget.pad),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(12), boxShadow: AppColors.glow),
            child: Text('$n ${n == 1 ? 'set' : 'sets'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const Spacer(),
          if (widget.topRight != null) widget.topRight!,
        ]),
        const SizedBox(height: 12),
        Container(width: 30, height: 3, decoration: BoxDecoration(gradient: AppColors.accentGradient, borderRadius: BorderRadius.circular(3))),
        const SizedBox(height: 8),
        Text(widget.heading, style: TextStyle(fontSize: widget.headingSize, fontWeight: FontWeight.w800, letterSpacing: -.3, color: context.pal.text)),
        if (widget.extra != null) ...[const SizedBox(height: 6), widget.extra!],
        if (n > 0) ...[
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_open ? 'Hide sets' : 'View sets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.pal.text)),
                const SizedBox(width: 10),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 2)),
                  child: Icon(_open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.primary),
                ),
              ]),
            ),
          ),
        ] else if (widget.emptyText.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(widget.emptyText, style: TextStyle(color: context.pal.muted)),
        ],
        if (_open) ...[
          const SizedBox(height: 8),
          for (var i = 0; i < n; i++) _row(i, widget.rows[i]),
        ],
        if (widget.footer != null) ...[const SizedBox(height: 14), widget.footer!],
      ]),
    ));
  }

  Widget _row(int i, SetRowData r) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Material(
          color: context.pal.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: r.onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text.rich(TextSpan(children: [
                      TextSpan(text: '${(i + 1).toString().padLeft(2, '0')} ', style: TextStyle(color: context.pal.muted, fontWeight: FontWeight.w500)),
                      TextSpan(text: r.title, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
                    ]), style: const TextStyle(fontSize: 16)),
                    if (r.meta.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(r.meta, style: TextStyle(color: context.pal.muted, fontSize: 13)),
                    ],
                  ]),
                ),
                if (r.trailing != null) r.trailing!,
              ]),
            ),
          ),
        ),
      );
}

/// Distinct non-empty category names of [tests], in order.
List<String> cats(Iterable<dynamic> tests) =>
    {for (final t in tests) if ((t.category ?? '').toString().isNotEmpty) t.category.toString()}.toList();

/// Card heading: category name(s) of [tests], else [fallback].
String heading(Iterable<dynamic> tests, String fallback) {
  final c = cats(tests);
  return c.isEmpty ? fallback : c.join(' · ');
}
