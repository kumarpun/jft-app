import 'package:flutter/material.dart';
import '../state/auth_controller.dart';
import '../state/theme_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'announcements_tab.dart';
import 'change_password_screen.dart';
import 'my_packages_tab.dart';
import 'packages_tab.dart';
import 'tests_tab.dart';

class HomeShell extends StatefulWidget {
  final AuthController auth;
  const HomeShell({super.key, required this.auth});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _i = 0;
  // bump to force tabs to reload after buying/submitting
  int _gen = 0;
  void _refreshAll() => setState(() => _gen++);

  @override
  Widget build(BuildContext context) {
    final a = widget.auth;
    final tabs = <(String, IconData, Widget)>[
      ('Free sets', Icons.quiz_outlined, TestsTab(key: ValueKey('t$_gen'), auth: a, onChanged: _refreshAll)),
      ('Library', Icons.local_library_outlined, MyPackagesTab(key: ValueKey('m$_gen'), auth: a, onChanged: _refreshAll)),
      ('Packages', Icons.storefront_outlined, PackagesTab(key: ValueKey('p$_gen'), auth: a, onChanged: _refreshAll)),
      ('News', Icons.campaign_outlined, AnnouncementsTab(key: ValueKey('n$_gen'), auth: a)),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            boxShadow: AppColors.glow,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            child: Stack(children: [
              Positioned(right: -30, top: -40, child: _ring(150, .10)),
              Positioned(right: 60, bottom: -50, child: _ring(100, .07)),
              Positioned(left: -40, bottom: -60, child: _ring(130, .06)),
            ]),
          ),
        ),
        toolbarHeight: 72,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: .3),
        title: Row(children: [const BrandLogo(size: 34), const SizedBox(width: 12), Text(tabs[_i].$1)]),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white, size: 28),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (v) async {
              if (v == 'theme') {
                final dark = Theme.of(context).brightness == Brightness.dark;
                themeController.set(dark ? ThemeMode.light : ThemeMode.dark);
              } else if (v == 'pw') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordScreen(auth: a)));
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
                const PopupMenuDivider(),
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
                destinations: [for (final t in tabs) NavigationDestination(icon: Icon(t.$2), label: t.$1.split(' ').first)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _ring(double d, double a) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: a)),
      );
}
