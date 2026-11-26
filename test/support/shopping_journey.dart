import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_skin_care_brand/app/app.dart';

/// Exercise the same application and navigation stack on the widget runner and
/// on a device. The checkout deliberately signs in after the bag is populated.
Future<void> shoppingJourney(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: ShopApp()));
  await tester.pumpAndSettle();
  Future<void> tap(Finder target) async {
    final control = target.last;
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    await tester.tap(control);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  final serum = find.text('Petal Serum');
  await tester.scrollUntilVisible(
    serum,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tap(serum);
  await tap(find.textContaining('Add to bag'));
  await tap(find.widgetWithText(FilledButton, 'Checkout'));
  await tap(find.text('Fill sample address'));
  await tap(find.text('Sign in to this demo'));
  await tap(find.text('Sign in to demo'));
  expect(find.widgetWithText(TextFormField, 'Demo Shopper'), findsWidgets);
  await tap(find.text('Continue to payment'));
  await tap(find.widgetWithText(FilledButton, 'Review order'));
  expect(find.text('12 Example Lane'), findsOneWidget);
  await tap(find.text('Place demo order'));
  await tap(find.text('View order'));
  expect(find.textContaining('DEMO-001'), findsWidgets);
  await tap(find.text('Cancel demo order'));
  await tap(find.text('Confirm cancellation'));
  expect(find.textContaining('Canceled'), findsWidgets);
  expect(find.text('Cancel demo order'), findsNothing);
}
