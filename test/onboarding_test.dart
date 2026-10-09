import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karbon_kita_app/ui/screens/onboarding_screen.dart';
import 'package:karbon_kita_app/ui/widgets/onboarding/onboarding_dots.dart';
import 'package:karbon_kita_app/ui/widgets/onboarding/onboarding_progress_button.dart';

void main() {
  group('OnboardingScreen', () {
    testWidgets('menampilkan halaman pertama + dots + tombol lanjut', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Selesaikan misi harian'), findsOneWidget);
      expect(find.byType(OnboardingDots), findsOneWidget);
      expect(find.byType(OnboardingProgressButton), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('tap tombol next pindah ke halaman 2', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(OnboardingProgressButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('Eco Points dan XP'), findsOneWidget);
    });

    testWidgets('swipe ke halaman 3 menampilkan ikon centang', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.textContaining('voucher diskon'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
