import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:your_skin_care_brand/core/catalog.dart';
import 'package:your_skin_care_brand/core/store.dart';
import 'package:your_skin_care_brand/features/account/account_state.dart';
import 'package:your_skin_care_brand/features/checkout/checkout.dart';
import 'package:your_skin_care_brand/features/checkout/checkout_state.dart';

Future<GoRouter> mount(
  WidgetTester tester,
  ShopStore store,
  String route, {
  AccountState? account,
  double scale = 1,
}) async {
  final router = GoRouter(
    initialLocation: route,
    routes: [
      for (final (path, page) in const [
        ('/bag', 'bag'),
        ('/checkout/address', 'address'),
        ('/checkout/payment', 'payment'),
        ('/checkout/review', 'review'),
        ('/checkout/failed', 'failed'),
        ('/result/:id', 'result'),
        ('/orders', 'orders'),
        ('/order/:id', 'order'),
        ('/cancel/:id', 'cancel'),
      ])
        GoRoute(
          path: path,
          builder: (context, state) => Scaffold(
            body: CheckoutScreen(
              page: page,
              value: state.pathParameters['id'] ?? '',
            ),
          ),
        ),
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Home')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        shopProvider.overrideWith((ref) => store),
        accountProvider.overrideWith(
          (ref) => account ?? AccountState(demo: true),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<void> press(WidgetTester tester, String label) async {
  final visible = find.text(label);
  final target = visible.evaluate().isEmpty
      ? find.text(label, skipOffstage: false).last
      : visible;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'bag, validation, sample address, snapshot, cancellation and keep action',
    (tester) async {
      final store = ShopStore(demo: true)..add(demoProducts.first, '');
      await mount(tester, store, '/bag');
      await tester.tap(find.byTooltip('Increase Petal Serum quantity'));
      await tester.pumpAndSettle();
      expect(store.subtotal, 2500);
      await press(tester, 'Checkout');
      await press(tester, 'Continue to payment');
      expect(find.text('Enter full name'), findsOneWidget);
      await press(tester, 'Fill sample address');
      await press(tester, 'Continue to payment');
      await press(tester, 'Review order');
      await press(tester, 'Place demo order');
      expect(find.text('Demo order placed'), findsOneWidget);
      await press(tester, 'View order');
      expect(find.text('12 Example Lane'), findsOneWidget);
      await press(tester, 'Cancel demo order');
      await press(tester, 'Keep order');
      expect(store.orders.single.status, DemoOrderStatus.pending);
      await press(tester, 'Cancel demo order');
      await press(tester, 'Confirm cancellation');
      expect(find.text('Canceled'), findsOneWidget);
      expect(find.text('Cancel demo order'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'known failure rejects duplicate taps; unknown payment reconciles existing reference',
    (tester) async {
      final store = ShopStore(demo: true)
        ..add(demoProducts.first, '')
        ..setDraft(ShippingAddress.example)
        ..setOutcome('failure');
      await mount(tester, store, '/checkout/payment');
      await press(tester, 'Online payment · simulated');
      await press(tester, 'Review order');
      final submit = find.widgetWithText(FilledButton, 'Place demo order');
      await tester.tap(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(store.orders, isEmpty);
      expect(find.text('Order not submitted'), findsOneWidget);
      expect(store.count, 1);
      await press(tester, 'Review and retry');
      store.setOutcome('unknown');
      await tester.pump();
      await press(tester, 'Place demo order');
      expect(find.text('Payment status unknown'), findsOneWidget);
      await press(tester, 'View order');
      await press(tester, 'Check demo payment status');
      expect(find.text('Pending'), findsOneWidget);
      expect(store.orders.single.reference, 'DEMO-001');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('deep links redirect and an owned address is selectable', (
    tester,
  ) async {
    final store = ShopStore(demo: true);
    final account = AccountState(demo: true);
    account.signIn(AccountState.exampleEmail, AccountState.examplePassword);
    account.saveAddress(ShippingAddress.example);
    final router = await mount(
      tester,
      store,
      '/checkout/review',
      account: account,
    );
    expect(find.text('Your bag is empty'), findsOneWidget);
    store.add(demoProducts.first, '');
    router.go('/checkout/review');
    await tester.pumpAndSettle();
    expect(find.text('Delivery address'), findsOneWidget);
    await press(tester, 'Use 12 Example Lane');
    expect(find.text('Payment method'), findsOneWidget);
    expect(store.draft, ShippingAddress.example);
    router.go('/order/nonexistent');
    await tester.pumpAndSettle();
    expect(find.text('No orders yet'), findsOneWidget);
  });
  testWidgets(
    'small phone at 200% with keyboard keeps address fields and action reachable',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final store = ShopStore(demo: true)..add(demoProducts.first, '');
      await mount(tester, store, '/checkout/address', scale: 2);
      await press(tester, 'Fill sample address');
      await press(tester, 'Continue to payment');
      expect(find.text('Payment method'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
