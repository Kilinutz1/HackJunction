import 'package:flutter_test/flutter_test.dart';
import 'package:my_proud_space/streak_reminder.dart';

void main() {
  test('No reminder for a missing or expired streak', () {
    final now = DateTime(2026, 11, 14, 12);
    expect(nextStreakReminder([], now), isNull);
    expect(nextStreakReminder(['2026-11-12'], now), isNull);
  });
  test('Yesterday active: remind today at 22, never late', () {
    expect(
      nextStreakReminder(['2026-11-13'], DateTime(2026, 11, 14, 12)),
      DateTime(2026, 11, 14, 22),
    );
    expect(
      nextStreakReminder(['2026-11-13'], DateTime(2026, 11, 14, 22, 1)),
      isNull,
    );
  });
  test(
    'Activity today replaces tonight with tomorrow, across year boundary',
    () {
      expect(
        nextStreakReminder(['2026-12-31'], DateTime(2026, 12, 31, 23)),
        DateTime(2027, 1, 1, 22),
      );
    },
  );
}
