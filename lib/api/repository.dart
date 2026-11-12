import '../models.dart';
import 'api_client.dart';

class Repository {
  final ApiClient api;
  Repository(this.api);

  Future<(String, User)> login(String identifier, String password) async {
    final j = await api.post('/auth/login', {'identifier': identifier, 'password': password});
    return (j['token'] as String, User.fromJson(j['user']));
  }

  Future<(String, User)> signup(String name, String email, String password) async {
    final j = await api.post('/auth/signup', {'name': name, 'email': email, 'password': password});
    return (j['token'] as String, User.fromJson(j['user']));
  }

  Future<(String, User)> googleLogin(String idToken) async {
    final j = await api.post('/auth/google', {'idToken': idToken});
    return (j['token'] as String, User.fromJson(j['user']));
  }

  /// Always succeeds server-side (generic response) so accounts can't be enumerated.
  Future<String> forgotPassword(String email) async {
    final j = await api.post('/auth/forgot-password', {'email': email});
    return (j['message'] as String?) ?? 'If that email is registered, a reset link has been sent.';
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await api.post('/auth/change-password', {'currentPassword': currentPassword, 'newPassword': newPassword});
  }

  Future<void> deleteAccount() async {
    await api.post('/auth/delete-account');
  }

  Future<User> me() async => User.fromJson((await api.get('/me'))['user']);

  Future<void> logout() async {
    try {
      await api.post('/auth/logout');
    } catch (_) {}
  }

  Future<List<TestSummary>> freeTests() async =>
      [for (final t in (await api.get('/tests'))['tests']) TestSummary.fromJson(t)];

  Future<TestPaper> test(int id) async {
    final j = await api.get('/tests/$id');
    final t = j['test'];
    return TestPaper(
      id: t['id'],
      title: t['title'] ?? '',
      durationSeconds: t['durationSeconds'] ?? 0,
      questions: [for (final q in j['questions']) Question.fromJson(q)],
    );
  }

  /// Returns the attempt id.
  Future<int> submit(int testId, Map<int, String> answers, {bool timedOut = false}) async {
    final j = await api.post('/tests/$testId/submit', {
      'answers': {for (final e in answers.entries) '${e.key}': e.value},
      'timedOut': timedOut,
    });
    return j['attemptId'];
  }

  Future<List<Announcement>> announcements() async =>
      [for (final a in (await api.get('/announcements'))['announcements']) Announcement.fromJson(a)];

  Future<List<Opening>> openings() async {
    final j = await api.get('/config');
    return [for (final o in (j['openings'] as List? ?? [])) ?Opening.tryParse(o as Map<String, dynamic>)];
  }

  Future<List<Package>> packages() async =>
      [for (final p in (await api.get('/packages'))['packages']) Package.fromJson(p)];

  Future<List<Purchase>> myPackages() async =>
      [for (final p in (await api.get('/my-packages'))['purchases']) Purchase.fromJson(p)];

  Future<void> resendRequest(int purchaseId) async {
    final j = await api.post('/my-packages/$purchaseId/resend');
    if (j['ok'] != true) throw ApiException('Resend is not available on the server yet.', code: 'unsupported');
  }

  Future<void> cancelRequest(int purchaseId) async {
    final j = await api.post('/my-packages/$purchaseId/cancel');
    if (j['ok'] != true) throw ApiException('Cancel is not available on the server yet.', code: 'unsupported');
  }

  Future<(List<Notif>, int)> notifications() async {
    final j = await api.get('/notifications');
    if (j['notifications'] is! List) throw ApiException('Notifications are not available on the server yet.', code: 'unsupported');
    return ([for (final n in j['notifications']) Notif.fromJson(n)], ((j['unread'] ?? 0) as num).toInt());
  }

  Future<void> deleteNotification(int id) async => _deleted(await api.post('/notifications/delete', {'id': id}));

  Future<void> clearNotifications() async => _deleted(await api.post('/notifications/delete', {'all': true}));

  void _deleted(Map<String, dynamic> j) {
    if (j['ok'] != true) throw ApiException('Delete is not available on the server yet.', code: 'unsupported');
  }

  Future<void> markNotificationsRead() async => api.post('/notifications/read');

  Future<PurchaseRequest> requestPackage(int id, {String? category}) async {
    final j = category != null
        ? await api.post('/packages/category/request', {'category': category})
        : await api.post('/packages/$id/request');
    return PurchaseRequest(j['status'], j['whatsappUrl']);
  }

  Future<List<ResultSummary>> results() async =>
      [for (final r in (await api.get('/results'))['results']) ResultSummary.fromJson(r)];

  Future<ResultDetail> result(int id) async => ResultDetail.fromJson(await api.get('/results/$id'));
}
