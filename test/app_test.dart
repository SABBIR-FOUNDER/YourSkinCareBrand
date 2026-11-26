import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_skin_care_brand/app/app.dart';
import 'package:your_skin_care_brand/core/config.dart';
import 'support/shopping_journey.dart';

void main() {
  if (AppConfig.demo) {
    testWidgets(
      'Home to bag, member checkout, order details and cancellation',
      shoppingJourney,
    );
  }
  testWidgets('empty checkout link opens bag', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ShopApp(initialLocation: '/checkout/review')),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Shopping bag, 0 items'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Place demo order'), findsNothing);
    expect(find.text('Browse all products'), findsWidgets);
  });
  for (final size in const [
    Size(360, 800),
    Size(390, 844),
    Size(430, 932),
    Size(768, 1024),
    Size(1024, 768),
    Size(800, 360),
  ]) {
    testWidgets('app shell at ${size.width} × ${size.height} with 200% text', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(const ProviderScope(child: ShopApp()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Sale').last);
      await tester.pumpAndSettle();
      expect(find.text('Clearance'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
