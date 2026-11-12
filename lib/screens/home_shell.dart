import 'dart:async';
import 'package:flutter/material.dart';
import '../models.dart';
import '../state/auth_controller.dart';
import '../state/theme_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'announcements_tab.dart';
import 'change_password_screen.dart';
import 'my_packages_tab.dart';
import 'notifications_screen.dart';
import 'packages_tab.dart';
import 'support_screen.dart';
import 'tests_tab.dart';

class HomeShell extends StatefulWidget {
  final AuthController auth;
  const HomeShell({super.key, required this.auth});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _i = 0;
  int _unread = 0, _lastSeen = -1;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _check());
  }

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _check();
  }

  // Poll the inbox; toast anything new and reload the tabs when a request was decided.
  Future<void> _check() async {
    try {
      final (list, unread) = await widget.auth.repo.notifications();
      if (!mounted) return;
      final maxId = list.isEmpty ? 0 : list.first.id;
      final fresh = _lastSeen < 0 ? <Notif>[] : list.where((n) => n.id > _lastSeen && !n.read).toList();
      _lastSeen = maxId;
      setState(() => _unread = unread);
      if (fresh.isNotEmpty) {
        toast(context, fresh.first.title);
        if (fresh.any((n) => n.kind == 'approved' || n.kind == 'rejected')) _refreshAll();
      }
    } catch (_) {}
  }

  Future<void> _openInbox() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen(auth: widget.auth)));
    if (mounted) _check();
  }
  // bump to force tabs to reload after buying/submitting
  int _gen = 0;
  void _refreshAll() => setState(() => _gen++);

  @override
  Widget build(BuildContext context) {
    final a = widget.auth;
    final tabs = <(String, IconData, Widget)>[
      ('Free sets', Icons.quiz_outlined, TestsTab(key: ValueKey('t$_gen'), auth: a, onChanged: _refreshAll)),
      ('My Packages', Icons.local_library_outlined, MyPackagesTab(key: ValueKey('m$_gen'), auth: a, onChanged: _refreshAll)),
      ('Buy Packages', Icons.storefront_outlined, PackagesTab(key: ValueKey('p$_gen'), auth: a, onChanged: _refreshAll)),
      ('News', Icons.campaign_outlined, AnnouncementsTab(key: ValueKey('n$_gen'), auth: a)),
    ];
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: pal.text,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: pal.surface,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            boxShadow: [BoxShadow(color: primary.withValues(alpha: .14), blurRadius: 18, offset: const Offset(0, 6))],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            child: Stack(children: [
              Positioned(right: -30, top: -60, child: _ring(190, primary.withValues(alpha: .16))),
              Positioned(right: 70, bottom: -60, child: _ring(110, primary.withValues(alpha: .07))),
            ]),
          ),
        ),
        toolbarHeight: 72,
        titleTextStyle: TextStyle(color: pal.text, fontSize: 22, fontWeight: FontWeight.w900),
        titleSpacing: 16,
        title: _greeting(a, pal),
        actions: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _openInbox,
            child: _action(
              Badge(
                isLabelVisible: _unread > 0,
                label: Text(_unread > 9 ? '9+' : '$_unread'),
                child: Icon(Icons.notifications_none_rounded, color: pal.text, size: 26),
              ),
              pal,
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: Padding(padding: const EdgeInsets.only(right: 8), child: _action(Icon(Icons.settings_outlined, color: pal.text, size: 26), pal)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (v) async {
              if (v == 'theme') {
                final dark = Theme.of(context).brightness == Brightness.dark;
                themeController.set(dark ? ThemeMode.light : ThemeMode.dark);
              } else if (v == 'pw') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordScreen(auth: a)));
              } else if (v == 'support') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => SupportScreen(auth: a)));
              } else if (v == 'out') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Sign out?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sign out')),
                    ],
                  ),
                );
                if (ok == true) a.logout();
              } else if (v == 'delete') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    icon: const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 36),
                    title: const Text('Delete account?'),
                    content: const Text(
                        'This permanently deletes your account, purchases, test attempts and results. This cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  try {
                    await a.deleteAccount();
                  } catch (e) {
                    if (context.mounted) toast(context, '$e', error: true);
                  }
                }
              }
            },
            itemBuilder: (ctx) {
              final pal = ctx.pal;
              final name = a.user?.name ?? '';
              final isDark = Theme.of(ctx).brightness == Brightness.dark;
              PopupMenuItem<String> item(String value, IconData icon, String label, {Color? color, Widget? trailing}) =>
                  PopupMenuItem(
                    value: value,
                    child: Row(children: [
                      Icon(icon, size: 21, color: color ?? pal.muted),
                      const SizedBox(width: 14),
                      Expanded(child: Text(label, style: TextStyle(color: color ?? pal.text, fontWeight: FontWeight.w600))),
                      ?trailing,
                    ]),
                  );
              return [
                PopupMenuItem(
                  enabled: false,
                  child: Row(children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: pal.primarySoft,
                      child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 17)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: pal.text, fontWeight: FontWeight.w800, fontSize: 15)),
                        Text(a.user?.email ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: pal.muted, fontSize: 12.5)),
                      ]),
                    ),
                  ]),
                ),
                const PopupMenuDivider(),
                item(
                  'theme',
                  isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  'Dark mode',
                  trailing: IgnorePointer(child: Switch(value: isDark, onChanged: (_) {})),
                ),
                item('pw', Icons.lock_outline_rounded, 'Change password'),
                item('support', Icons.support_agent_rounded, 'Support'),
                const PopupMenuDivider(),
                item('delete', Icons.delete_forever_outlined, 'Delete account', color: AppColors.danger),
                item('out', Icons.logout_rounded, 'Sign out', color: AppColors.danger),
              ];
            },
          ),
        ],
      ),
      body: IndexedStack(index: _i, children: [for (final t in tabs) t.$3]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.pal.surface,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .18), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: NavigationBar(
                height: 68,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedIndex: _i,
                onDestinationSelected: (i) => setState(() => _i = i),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [for (final t in tabs) NavigationDestination(icon: Icon(t.$2), label: t.$1)],
              ),
            ),
          ),
        ),
      ),
    ),
    ]));
  }

  // "Hi, Name" with the email underneath, shown on every tab.
  Widget _greeting(AuthController a, Pal pal) {
    final name = (a.user?.name ?? '').trim();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text.rich(
        TextSpan(children: [
          TextSpan(text: 'Hi, ', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          TextSpan(text: name.isEmpty ? 'there' : name),
        ]),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: pal.text, fontSize: 22, fontWeight: FontWeight.w900),
      ),
      if ((a.user?.email ?? '').isNotEmpty)
        Text(a.user!.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: pal.muted, fontSize: 12.5, fontWeight: FontWeight.w500)),
    ]);
  }

  // Icon-only header action.
  static Widget _action(Widget icon, Pal pal) => Padding(padding: const EdgeInsets.all(10), child: icon);

  static Widget _ring(double d, Color c) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c),
      );
}
