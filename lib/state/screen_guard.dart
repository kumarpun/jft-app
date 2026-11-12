import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';

/// Applies the admin's "block screenshots" switch to the native window.
/// Blocked is the default: until the server says otherwise (or if it can't be reached and nothing is cached).
class ScreenGuard with WidgetsBindingObserver {
  static const _channel = MethodChannel('jftsensei/secure');
  static const _key = 'screenshots_blocked';

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    final prefs = await SharedPreferences.getInstance();
    await _apply(prefs.getBool(_key) ?? true); // last known value, works offline
    await refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  Future<void> refresh() async {
    try {
      final data = await ApiClient().request('GET', '/config');
      final blocked = data['screenshotsBlocked'] != false;
      (await SharedPreferences.getInstance()).setBool(_key, blocked);
      await _apply(blocked);
    } catch (_) {
      // keep whatever is currently applied
    }
  }

  Future<void> _apply(bool blocked) async {
    try {
      await _channel.invokeMethod('setSecure', blocked);
    } catch (_) {}
  }
}
