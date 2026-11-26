import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_skin_care_brand/app/app.dart';
import 'package:your_skin_care_brand/core/config.dart';

void main() {
  testWidgets(
    'production launch hides demo access and fixture content',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: ShopApp(initialLocation: '/demo')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Demo'), findsNothing);
      expect(find.text('Demo controls'), findsNothing);
      expect(find.text('Petal Serum'), findsNothing);
      expect(find.textContaining('BDT'), findsNothing);
      await tester.tap(find.text('Sale').last);
      await tester.pumpAndSettle();
      expect(find.text('Clearance'), findsOneWidget);
      expect(find.text('Rose Satin Lipstick'), findsNothing);
      expect(find.byType(Scaffold), findsWidgets);
      expect(tester.takeException(), isNull);
    },
    skip: AppConfig.demo,
  );
}
