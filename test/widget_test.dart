import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:kaamsetu/main.dart';
import 'package:kaamsetu/screens/splash_screen.dart';
import 'package:kaamsetu/widgets/splash_elements.dart';

void main() {
  testWidgets('launches on the KaamSetu splash screen',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const KaamSetuApp());

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(SplashBackdrop), findsOneWidget);
  });
}
