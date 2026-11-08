class User {
  final int id;
  final String name, email, role;
  User({required this.id, required this.name, required this.email, required this.role});
  factory User.fromJson(Map<String, dynamic> j) =>
      User(id: j['id'], name: j['name'] ?? '', email: j['email'] ?? '', role: j['role'] ?? 'customer');
}

class TestSummary {
  final int id, durationSeconds, questionCount;
  final String title, description, category;
  final String? formUrl;
  final int? bestPercent;
  bool get isForm => formUrl != null && formUrl!.isNotEmpty && questionCount == 0;
  TestSummary.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        title = j['title'] ?? '',
        description = j['description'] ?? '',
        category = j['category'] ?? '',
        durationSeconds = j['durationSeconds'] ?? 0,
        formUrl = j['formUrl'],
        questionCount = j['questionCount'] ?? 0,
        bestPercent = j['bestPercent'];
}

class Announcement {
  final int id, secondsLeft;
  final String title, body;
  final String? imageUrl;
  Announcement.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        title = j['title'] ?? '',
        body = j['body'] ?? '',
        imageUrl = j['imageUrl'],
        secondsLeft = (j['secondsLeft'] ?? 0).toInt();
}

class PackageTest {
  final int id;
  final String title;
  final String? category;
  final String? formUrl; // set (with no questions) => a Google Form to open instead of a test
  final int questionCount, durationSeconds;
  PackageTest.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        title = j['title'] ?? '',
        category = j['category'],
        formUrl = j['formUrl'],
        questionCount = j['questionCount'] ?? 0,
        durationSeconds = j['durationSeconds'] ?? 0;
  bool get isForm => formUrl != null && formUrl!.isNotEmpty && questionCount == 0;
}

class Package {
  final int id, days;
  final String name, description;
  final double price;
  final double? originalPrice;
  final List<PackageTest> tests;
  final String? myStatus; // pending | active | null
  /// Whole categories sold in this package: (sub-category name, set count).
  final List<(String, int)> categories;
  /// Sub-category names of individually added sets (card heading).
  final List<String> setCategories;
  Package.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        name = j['name'] ?? '',
        description = j['description'] ?? '',
        days = j['days'] ?? 0,
        price = (j['price'] ?? 0).toDouble(),
        originalPrice = j['originalPrice']?.toDouble(),
        tests = [for (final t in j['tests'] ?? []) PackageTest.fromJson(t)],
        myStatus = j['myStatus'],
        setCategories = [for (final c in j['setCategories'] ?? []) c.toString()],
        categories = [for (final c in j['categories'] ?? []) (c['name'] as String, (c['sets'] as num).toInt())];
}

class Purchase {
  final int id, packageId, days;
  final String name, status; // active | pending | expired
  final int? secondsLeft;
  final List<PackageTest> tests;
  Purchase.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        packageId = j['packageId'],
        name = j['name'] ?? '',
        days = j['days'] ?? 0,
        status = j['status'] ?? 'expired',
        secondsLeft = (j['secondsLeft'] as num?)?.toInt(),
        tests = [for (final t in j['tests'] ?? []) PackageTest.fromJson(t)];
}

class Question {
  final int id, marks;
  final String text;
  final Map<String, String?> options;
  final String? section, videoId, imageUrl;
  Question.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        text = j['text'] ?? '',
        marks = j['marks'] ?? 1,
        section = (j['section'] as String?)?.isEmpty == true ? null : j['section'],
        videoId = (j['videoId'] as String?)?.isEmpty == true ? null : j['videoId'],
        imageUrl = j['imageUrl'],
        options = {for (final k in ['A', 'B', 'C', 'D']) k: (j['options'] ?? {})[k] as String?};
}

class TestPaper {
  final int id, durationSeconds;
  final String title;
  final List<Question> questions;
  TestPaper({required this.id, required this.title, required this.durationSeconds, required this.questions});
}

class ResultSummary {
  final int id, score, total, percent;
  final String title, submittedAt;
  final bool timedOut;
  ResultSummary.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        title = j['title'] ?? '',
        score = j['score'] ?? 0,
        total = j['total'] ?? 0,
        percent = j['percent'] ?? 0,
        timedOut = j['timedOut'] ?? false,
        submittedAt = '${j['submittedAt'] ?? ''}';
}

class SectionScore {
  final String name;
  final num got, total, percent;
  SectionScore.fromJson(Map<String, dynamic> j)
      : name = j['name'] ?? 'General',
        got = j['got'] ?? 0,
        total = j['total'] ?? 0,
        percent = j['percent'] ?? 0;
}

class AnswerReview {
  final int questionId;
  final String text;
  final Map<String, String?> options;
  final String? selected, correctOption, section, imageUrl, videoId, feedback;
  final bool isCorrect;
  AnswerReview.fromJson(Map<String, dynamic> j)
      : questionId = j['questionId'],
        text = j['text'] ?? '',
        options = {for (final k in ['A', 'B', 'C', 'D']) k: (j['options'] ?? {})[k] as String?},
        selected = j['selected'],
        correctOption = j['correctOption'],
        isCorrect = j['isCorrect'] ?? false,
        section = j['section'],
        imageUrl = j['imageUrl'],
        videoId = j['videoId'],
        feedback = j['feedback'];
}

class ResultDetail {
  final int id, score, total, percent, correct, skipped;
  final String title, submittedAt;
  final bool passed, timedOut;
  final List<SectionScore> sections;
  final List<AnswerReview> answers;
  ResultDetail.fromJson(Map<String, dynamic> j)
      : id = j['result']['id'],
        title = j['result']['title'] ?? '',
        submittedAt = j['result']['submittedAt']?.toString() ?? '',
        score = j['result']['score'] ?? 0,
        total = j['result']['total'] ?? 0,
        percent = j['result']['percent'] ?? 0,
        passed = j['result']['passed'] ?? false,
        timedOut = j['result']['timedOut'] ?? false,
        correct = j['result']['correct'] ?? 0,
        skipped = j['result']['skipped'] ?? 0,
        sections = [for (final s in j['result']['sections'] ?? []) SectionScore.fromJson(s)],
        answers = [for (final a in j['answers'] ?? []) AnswerReview.fromJson(a)];
}

class PurchaseRequest {
  final String status; // pending | active
  final String? whatsappUrl;
  PurchaseRequest(this.status, this.whatsappUrl);
}
