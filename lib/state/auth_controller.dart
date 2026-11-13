import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  /// Same value as GOOGLE_CLIENT_ID on the server (the Web OAuth client), so the ID token's audience matches.
  static const _googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: '168648579439-097s59m8nuqic149n9fek54ae2cdqbr4.apps.googleusercontent.com');
  static const _googleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  static bool _googleReady = false;

  /// Sign in / sign up with Google. Returns false if the user cancelled.
  Future<bool> googleLogin() async {
    if (_googleServerClientId.isEmpty) {
      throw ApiException('Google sign-in is not configured in this build.');
    }
    final g = GoogleSignIn.instance;
    if (!_googleReady) {
      await g.initialize(
        serverClientId: _googleServerClientId,
        clientId: _googleIosClientId.isEmpty ? null : _googleIosClientId,
      );
      _googleReady = true;
    }
    final GoogleSignInAccount account;
    try {
      account = await g.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      throw ApiException('Google sign-in failed. Try again.');
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) throw ApiException('Google sign-in failed. Try again.');
    final (t, u) = await repo.googleLogin(idToken);
    await _store(t, u);
    return true;
  }

  Future<void> logout() async {
    await repo.logout();
    await _clear();
  }

  /// Permanently deletes the account on the server, then signs out locally. Throws if the server refuses.
  Future<void> deleteAccount() async {
    await repo.deleteAccount();
    await _clear();
  }

  Future<void> _clear() async {
    api.token = null;
    user = null;
    (await SharedPreferences.getInstance()).remove(_key);
    notifyListeners();
  }
}
