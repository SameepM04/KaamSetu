import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaamsetu/data/job_categories.dart';
import 'package:kaamsetu/screens/all_categories_screen.dart';
import 'package:kaamsetu/screens/jobs_screen.dart';

void main() {
  const surfaces = <Size>[
    Size(320, 844),
    Size(360, 800),
    Size(393, 852),
    Size(412, 915),
    Size(768, 1024),
    Size(1024, 768),
  ];

  test('maps every preview title to exactly one category', () {
    expect(
        JobCategoryMapper.fromJobTitle('House Painting'), JobCategory.painting);
    expect(JobCategoryMapper.fromJobTitle('Bathroom Plumbing'),
        JobCategory.plumbing);
    expect(JobCategoryMapper.fromJobTitle('Tube Light Installation'),
        JobCategory.electrical);
    expect(
        JobCategoryMapper.fromJobTitle('Home Cleaning'), JobCategory.cleaning);
    expect(JobCategoryMapper.fromJobTitle('Garden Maintenance'),
        JobCategory.gardening);
    expect(JobCategoryMapper.fromJobTitle('Carpentry'), JobCategory.carpentry);
    expect(JobCategoryMapper.fromJobTitle('Delivery'), JobCategory.delivery);
    expect(JobCategoryMapper.fromJobTitle('Cook'), JobCategory.cook);
  });

  for (final size in surfaces) {
    testWidgets(
        'category UI has no layout exceptions at ${size.width}x${size.height}',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(
          home: Scaffold(
              body: JobsScreen(selectedCategory: JobCategory.painting))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
          MaterialApp(home: AllCategoriesScreen(onSelectCategory: (_) {})));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
