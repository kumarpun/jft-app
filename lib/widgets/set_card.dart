import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ui.dart';

class SetRowData {
  final String title, meta;
  final String? group; // folder name; rows sharing it are listed together under a header
  final Widget? trailing;
  final VoidCallback? onTap;
  const SetRowData({required this.title, this.meta = '', this.group, this.trailing, this.onTap});
}

/// Green-bordered card: "N sets" pill, heading, optional [extra] under it,
/// an expandable list of numbered sets, and an optional [footer].
class SetCard extends StatefulWidget {
  final String heading;
  final List<SetRowData> rows;
  final Widget? topRight, extra, footer;
  final String emptyText;
  final int? count; // overrides the set count in the pill (e.g. locked rows not listed)
  final Color? tint; // highlight colour (e.g. green for purchased)
  final int? days; // shown in the pill as "N sets · D days"
  final double headingSize, pad;
  const SetCard({super.key, required this.heading, required this.rows, this.topRight, this.extra, this.footer, this.emptyText = '', this.count, this.days, this.tint, this.headingSize = 18, this.pad = 12});
  @override
  State<SetCard> createState() => _SetCardState();
}

class _SetCardState extends State<SetCard> {
  static const _pageSize = 10; // rows loaded per page
  static const _viewHeight = 250.0; // about 5 rows visible, the rest scroll
  bool _open = false;
  final _openFolders = <String>{}; // folders start collapsed; tap header to expand
  int _visible = _pageSize;
  final _scroll = ScrollController();
  ScrollableState? _outer; // the page list; takes over once the inner list hits an edge

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_visible < widget.rows.length && _scroll.position.pixels >= _scroll.position.maxScrollExtent - 40) {
        setState(() => _visible += _pageSize);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // Inner list is at its end and the finger keeps dragging that way: scroll the page instead of dead-ending.
  void _chain(PointerMoveEvent e) {
    final o = _outer?.position;
    if (o == null || !_scroll.hasClients) return;
    final i = _scroll.position, dy = e.delta.dy;
    final atEnd = dy < 0 && i.pixels >= i.maxScrollExtent;
    final atStart = dy > 0 && i.pixels <= i.minScrollExtent;
    if (atEnd || atStart) o.jumpTo((o.pixels - dy).clamp(o.minScrollExtent, o.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    _outer = Scrollable.maybeOf(context);
    final n = widget.count ?? widget.rows.length;
    return FadeSlide(child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [context.pal.surface, widget.tint?.withValues(alpha: .16) ?? context.pal.primarySoft]),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: widget.tint?.withValues(alpha: .7) ?? context.pal.border, width: widget.tint != null ? 1.6 : 1.2),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .10), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      padding: EdgeInsets.all(widget.pad + 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _pill('$n ${n == 1 ? 'set' : 'sets'}'),
          if (widget.days != null) ...[
            const SizedBox(width: 6),
            _pill('${widget.days} ${widget.days == 1 ? 'day' : 'days'}', icon: Icons.timer_outlined, colors: const [Color(0xFF2563EB), Color(0xFF3B82F6)]),
          ],
          const Spacer(),
          if (widget.topRight != null) widget.topRight!,
        ]),
        const SizedBox(height: 8),
        Container(width: 24, height: 3, decoration: BoxDecoration(gradient: AppColors.accentGradient, borderRadius: BorderRadius.circular(3))),
        const SizedBox(height: 6),
        Text(widget.heading, style: TextStyle(fontSize: widget.headingSize, fontWeight: FontWeight.w800, letterSpacing: -.3, color: context.pal.text)),
        if (widget.extra != null) ...[const SizedBox(height: 3), widget.extra!],
        if (widget.rows.isNotEmpty) ...[
          const SizedBox(height: 4),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_open ? 'Hide sets' : 'View sets', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.pal.text)),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1.6)),
                  child: Icon(_open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 17, color: Theme.of(context).colorScheme.primary),
                ),
              ]),
            ),
          ),
        ] else if (widget.emptyText.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(widget.emptyText, style: TextStyle(color: context.pal.muted)),
        ],
        if (_open) ...[
          const SizedBox(height: 2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: _viewHeight),
            child: Listener(
              onPointerMove: _chain,
              child: Scrollbar(
                controller: _scroll,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scroll,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _grouped()),
                ),
              ),
            ),
          ),
        ],
        if (widget.footer != null) ...[const SizedBox(height: 14), widget.footer!],
      ]),
    ));
  }

  Widget _pill(String t, {IconData? icon, List<Color>? colors}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
            gradient: colors == null ? AppColors.brandGradient : LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(20),
            boxShadow: colors == null ? AppColors.glow : [BoxShadow(color: colors.first.withValues(alpha: .3), blurRadius: 8, offset: const Offset(0, 3))]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 12, color: Colors.white), const SizedBox(width: 4)],
          Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
        ]),
      );

  // Rows grouped by folder (first-appearance order); ungrouped rows come first, numbering restarts per group.
  // Folders are collapsible (collapsed by default); only expanded folders list rows.
  List<Widget> _grouped() {
    final groups = <String?, List<SetRowData>>{};
    for (final r in widget.rows) {
      groups.putIfAbsent((r.group ?? '').isEmpty ? null : r.group, () => []).add(r);
    }
    final keys = [...groups.keys.where((k) => k == null), ...groups.keys.where((k) => k != null)];
    return [
      for (final k in keys) ...[
        if (k != null) _folderHeader(k, groups[k]!.length),
        if (k == null || _openFolders.contains(k))
          for (var i = 0; i < groups[k]!.take(_visible).length; i++) _row(i, groups[k]![i]),
      ],
    ];
  }

  Widget _folderHeader(String name, int count) {
    final open = _openFolders.contains(name);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => open ? _openFolders.remove(name) : _openFolders.add(name)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Row(children: [
            Icon(open ? Icons.folder_open_rounded : Icons.folder_rounded, size: 18, color: context.pal.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: .3, color: context.pal.text)),
                  TextSpan(text: '  ($count)', style: TextStyle(fontSize: 11, color: context.pal.muted)),
                ]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 20, color: context.pal.muted),
          ]),
        ),
      ),
    );
  }

  Widget _row(int i, SetRowData r) => Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Material(
          color: context.pal.surface,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: r.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text.rich(TextSpan(children: [
                      TextSpan(text: '${(i + 1).toString().padLeft(2, '0')} ', style: TextStyle(color: context.pal.muted, fontWeight: FontWeight.w500)),
                      TextSpan(text: r.title, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
                    ]), style: const TextStyle(fontSize: 12.5)),
                    if (r.meta.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(r.meta, style: TextStyle(color: context.pal.muted, fontSize: 10.5)),
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
