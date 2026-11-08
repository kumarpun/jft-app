import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../api/repository.dart';
import '../models.dart';

class AuthController extends ChangeNotifier {
  final ApiClient api = ApiClient();
  late final Repository repo = Repository(api);
  User? user;
  bool ready = false;
  String? notice; // shown on login screen after forced logout

  static const _key = 'token';

  Future<void> init() async {
    api.onUnauthorized = () {
      notice = 'Signed out: session expired or replaced by a newer login.';
      _clear();
    };
    final prefs = await SharedPreferences.getInstance();
    api.token = prefs.getString(_key);
    if (api.token != null) {
      try {
        user = await repo.me();
      } on ApiException catch (e) {
        if (e.unauthorized) api.token = null;
        // offline: keep token, stay on login until reachable
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<void> _store(String token, User u) async {
    api.token = token;
    user = u;
    notice = null;
    (await SharedPreferences.getInstance()).setString(_key, token);
    notifyListeners();
  }

  Future<void> login(String identifier, String password) async {
    final (t, u) = await repo.login(identifier, password);
    await _store(t, u);
  }

  Future<void> signup(String name, String email, String password) async {
    final (t, u) = await repo.signup(name, email, password);
    await _store(t, u);
  }

  Future<void> logout() async {
    await repo.logout();
    await _clear();
  }

  Future<void> _clear() async {
    api.token = null;
    user = null;
    (await SharedPreferences.getInstance()).remove(_key);
    notifyListeners();
  }
}
