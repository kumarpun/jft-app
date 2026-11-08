import 'package:flutter_test/flutter_test.dart';
import 'package:jftsensei_app/util.dart';

void main() {
  test('formatDuration', () {
    expect(formatDuration(0), 'No time limit');
    expect(formatDuration(3600), '1h');
    expect(formatDuration(90), '1m 30s');
  });
  test('clock', () => expect(clock(3725), '1:02:05'));
}
