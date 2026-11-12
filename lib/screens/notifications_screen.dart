import 'package:flutter/material.dart';
import '../models.dart';
import '../state/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/load_view.dart';
import '../widgets/ui.dart';

class NotificationsScreen extends StatefulWidget {
  final AuthController auth;
  const NotificationsScreen({super.key, required this.auth});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  AuthController get auth => widget.auth;
  List<Notif> _items = [];
  int _gen = 0;

  Future<List<Notif>> _load() async {
    final (list, unread) = await auth.repo.notifications();
    if (unread > 0) await auth.repo.markNotificationsRead();
    _items = [...list];
    return _items;
  }

  Future<bool> _confirmDelete() async =>
      await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: const Text('Delete notification?'),
          content: const Text('This permanently deletes it and cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Delete')),
          ],
        ),
      ) ==
      true;

  Future<void> _delete(Notif n) async {
    setState(() => _items.removeWhere((x) => x.id == n.id));
    try {
      await auth.repo.deleteNotification(n.id);
    } catch (e) {
      if (mounted) {
        toast(context, '$e', error: true);
        setState(() => _gen++);
      }
    }
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text('This permanently deletes all of them and cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Clear all')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await auth.repo.clearNotifications();
      if (mounted) setState(() => _items = []);
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    }
  }

  String _ago(DateTime? t) {
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final primary = Theme.of(context).colorScheme.primary;
    return ColoredBox(
      color: pal.bg,
      child: Stack(children: [
        Positioned(
          right: -90,
          top: -110,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [primary.withValues(alpha: .28), primary.withValues(alpha: 0)]),
            ),
          ),
        ),
        Scaffold(
      backgroundColor: Colors.transparent,
      appBar: topBar(context, 'Notifications', actions: [
        if (_items.isNotEmpty) IconButton(tooltip: 'Clear all', icon: Icon(Icons.delete_sweep_outlined, color: pal.text, size: 26), onPressed: _clearAll),
        const SizedBox(width: 4),
      ]),
      body: LoadView<List<Notif>>(
        key: ValueKey(_gen),
        load: _load,
        isEmpty: (_) => _items.isEmpty,
        emptyText: 'No notifications yet.',
        builder: (c, _) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          itemCount: _items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (c, i) {
            final n = _items[i];
            final ok = n.kind == 'approved';
            final color = ok ? AppColors.ok : AppColors.danger;
            return Dismissible(
              key: ValueKey(n.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => _confirmDelete(),
              onDismissed: (_) => _delete(n),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 22),
                decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(28)),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [pal.surface, n.read ? pal.surface : pal.primarySoft]),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: pal.border, width: 1.2),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .10), blurRadius: 18, offset: const Offset(0, 6))],
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: .12),
                  child: Icon(ok ? Icons.check_circle_outline : Icons.cancel_outlined, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(n.title, style: TextStyle(color: pal.text, fontWeight: FontWeight.w800, fontSize: 15)),
                    if (n.body.isNotEmpty) ...[const SizedBox(height: 3), Text(n.body, style: TextStyle(color: pal.muted, fontSize: 13, height: 1.3))],
                    const SizedBox(height: 6),
                    Text(_ago(n.createdAt), style: TextStyle(color: pal.muted, fontSize: 11.5)),
                  ]),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Delete',
                  icon: Icon(Icons.close_rounded, size: 18, color: pal.muted),
                  onPressed: () async {
                    if (await _confirmDelete()) _delete(n);
                  },
                ),
              ]),
            ));
          },
        ),
      ),
    )]));
  }
}
