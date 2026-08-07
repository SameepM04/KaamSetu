import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaamsetu/screens/onboarding_one.dart';
import 'package:kaamsetu/screens/onboarding_three.dart';
import 'package:kaamsetu/screens/onboarding_two.dart';
import 'package:kaamsetu/theme/app_theme.dart';

void main() {
  Future<void> setPhoneSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  Widget appFor(Widget screen) =>
      MaterialApp(theme: AppTheme.light, home: screen);

  testWidgets('onboarding one visual baseline', (tester) async {
    await setPhoneSurface(tester);
    await tester.pumpWidget(appFor(const OnboardingOne()));
    await tester.pump(const Duration(milliseconds: 760));
    await expectLater(find.byType(OnboardingOne),
        matchesGoldenFile('goldens/onboarding_one.png'));
  });

  testWidgets('onboarding two visual baseline', (tester) async {
    await setPhoneSurface(tester);
    await tester.pumpWidget(appFor(const OnboardingTwo()));
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(find.byType(OnboardingTwo),
        matchesGoldenFile('goldens/onboarding_two.png'));
  });

  testWidgets('onboarding three visual baseline', (tester) async {
    await setPhoneSurface(tester);
    await tester.pumpWidget(appFor(const OnboardingThree()));
    await tester.pump(const Duration(milliseconds: 2600));
    await expectLater(find.byType(OnboardingThree),
        matchesGoldenFile('goldens/onboarding_three.png'));
  });
}
