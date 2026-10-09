import 'package:flutter_test/flutter_test.dart';
import 'package:karbon_kita_app/core/utils/mission_steps.dart';

void main() {
  group('getMissionSteps', () {
    test('mobility returns 5 steps with interpolated target', () {
      final steps = getMissionSteps(
        category: 'mobility',
        targetDistanceKm: 2.0,
      );

      expect(steps, hasLength(5));
      expect(steps[2].title, contains('2.0 KM'));
    });

    test('mobility falls back to 0.1 KM without target', () {
      final steps = getMissionSteps(category: 'mobility');

      expect(steps, hasLength(5));
      expect(steps[2].title, contains('0.1 KM'));
    });

    test('waste returns 5 foto/pilah steps', () {
      final steps = getMissionSteps(category: 'waste');

      expect(steps, hasLength(5));
      expect(steps.first.title.toLowerCase(), contains('pilah'));
    });

    test('unknown category returns generic single step', () {
      expect(getMissionSteps(category: 'quiz'), hasLength(1));
    });
  });

  group('activityTypeFromTitle', () {
    test('detects cycling keywords', () {
      expect(activityTypeFromTitle('Pejuang Pedal 2Km'), 'cycling');
      expect(activityTypeFromTitle('Sepeda Pagi Hari'), 'cycling');
    });

    test('defaults to walking', () {
      expect(activityTypeFromTitle('Jalan Kaki 3Km'), 'walking');
    });
  });
}
