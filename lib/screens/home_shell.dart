import 'package:flutter/material.dart';
import '../state/auth_controller.dart';
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
      ('My packages', Icons.inventory_2_outlined, MyPackagesTab(key: ValueKey('m$_gen'), auth: a, onChanged: _refreshAll)),
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
              if (v == 'pw') {
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
            itemBuilder: (_) => [
              PopupMenuItem(enabled: false, child: Text(a.user?.name ?? '', style: const TextStyle(fontWeight: FontWeight.w700))),
              PopupMenuItem(enabled: false, child: Text(a.user?.email ?? '')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'pw', child: Text('Change password')),
              const PopupMenuItem(value: 'out', child: Text('Sign out')),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _i, children: [for (final t in tabs) t.$3]),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppColors.primary.withValues(alpha: .18), width: 1.2)),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .16), blurRadius: 28, offset: const Offset(0, -8))],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (i) => setState(() => _i = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [for (final t in tabs) NavigationDestination(icon: Icon(t.$2), label: t.$1.split(' ').first)],
      ))),
    );
  }

  static Widget _ring(double d, double a) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: a)),
      );
}
