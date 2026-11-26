import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:your_skin_care_brand/core/catalog.dart';
import 'package:your_skin_care_brand/core/network/api_failure.dart';
import 'package:your_skin_care_brand/core/network/catalogue_repository.dart';
import 'package:your_skin_care_brand/core/store.dart';
import 'package:your_skin_care_brand/features/catalogue/catalogue.dart';

class _Catalogue implements CatalogueRepository {
  int calls = 0;
  final data = Completer<List<Product>>();
  @override
  Future<List<Product>> loadProducts() async {
    calls++;
    if (calls == 1) {
      throw const ApiFailure(
        ApiProblem.offline,
        'The store connection was interrupted.',
      );
    }
    return data.future;
  }
}

Future<({GoRouter router, ShopStore store})> open(
  WidgetTester tester,
  String route, {
  Size size = const Size(390, 844),
  double scale = 1,
  bool demo = true,
  CatalogueRepository? repository,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final c = ProviderContainer(
    overrides: [
      shopProvider.overrideWith(
        (ref) => ShopStore(demo: demo, catalogueRepository: repository),
      ),
    ],
  );
  addTearDown(c.dispose);
  final router = GoRouter(
    initialLocation: route,
    routes: [
      for (final page in [
        'home',
        'categories',
        'brands',
        'products',
        'edit',
        'search',
        'sale',
        'wishlist',
      ])
        GoRoute(
          path: '/$page',
          builder: (_, _) => Scaffold(body: CatalogueScreen(page: page)),
        ),
      for (final page in ['brand', 'category', 'product'])
        GoRoute(
          path: '/$page/:value',
          builder: (_, s) => Scaffold(
            body: CatalogueScreen(
              page: page,
              value: s.pathParameters['value']!,
            ),
          ),
        ),
      GoRoute(
        path: '/bag',
        builder: (_, _) => const Scaffold(body: Text('Bag destination')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(
        routerConfig: router,
        builder: (ctx, child) => MediaQuery(
          data: MediaQuery.of(
            ctx,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (router: router, store: c.read(shopProvider));
}

void main() {
  testWidgets('home edit, category filter and manufacturer collection', (
    tester,
  ) async {
    final app = await open(tester, '/home');
    expect(find.text('The skincare\nedit'), findsOneWidget);
    await tester.tap(find.text('Shop the edit'));
    await tester.pumpAndSettle();
    expect(find.text('3 products'), findsOneWidget);
    app.router.go('/category/Serums');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Studio 02'));
    await tester.pumpAndSettle();
    expect(find.text('No products found'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();
    expect(find.text('Petal Serum'), findsOneWidget);
    app.router.go('/brand/Studio%2002');
    await tester.pumpAndSettle();
    expect(find.text('Daily Face Cream'), findsOneWidget);
    expect(find.text('Soft Cream Cleanser'), findsOneWidget);
  });

  testWidgets('search preserves query on back and resets empty results', (
    tester,
  ) async {
    final app = await open(tester, '/search');
    await tester.enterText(find.byType(TextField), 'Studio 01');
    await tester.pump(const Duration(milliseconds: 240));
    expect(find.text('2 products'), findsOneWidget);
    await tester.tap(find.text('Petal Serum'));
    await tester.pumpAndSettle();
    expect(find.text('Product details'), findsOneWidget);
    app.router.pop();
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Studio 01',
    );
    await tester.enterText(find.byType(TextField), 'nonexistent');
    await tester.pump(const Duration(milliseconds: 240));
    expect(find.text('No products found'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Browse categories'), findsOneWidget);
  });

  testWidgets(
    'unknown price disables purchase and wishlist remains available',
    (tester) async {
      final app = await open(tester, '/product/cleanser');
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip('Save Soft Cream Cleanser to wishlist'));
      await tester.pumpAndSettle();
      app.router.go('/wishlist');
      await tester.pumpAndSettle();
      expect(find.text('Soft Cream Cleanser'), findsOneWidget);
      await tester.tap(
        find.byTooltip('Remove Soft Cream Cleanser from wishlist'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Your wishlist is empty'), findsOneWidget);
      expect(app.store.wish, isEmpty);
    },
  );

  testWidgets('catalogue and sale recover from preview loading or errors', (
    tester,
  ) async {
    final app = await open(tester, '/sale');
    expect(find.text('Rose Satin Lipstick'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Clearance'));
    await tester.pumpAndSettle();
    expect(find.text('No clearance items'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Sale'));
    await tester.pumpAndSettle();
    app.store.setOffers('empty');
    await tester.pump();
    expect(find.text('No current offers'), findsOneWidget);
    app.store.setOffers('error');
    await tester.pump();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Rose Satin Lipstick'), findsOneWidget);
    app.router.go('/products');
    await tester.pumpAndSettle();
    app.store.setCatalogue('loading');
    await tester.pump();
    expect(find.text('Loading products…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('4 products'), findsOneWidget);
    app.store.setCatalogue('error');
    await tester.pump();
    expect(find.text('Products couldn’t load'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('4 products'), findsOneWidget);
  });

  testWidgets('selected shade reaches shopping bag', (tester) async {
    final app = await open(tester, '/product/lip');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Mauve'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Mauve'))
          .selected,
      isTrue,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add to bag · BDT 760'));
    await tester.pumpAndSettle();
    expect(find.text('Bag destination'), findsOneWidget);
    expect(app.store.cart.single.shade, 'Mauve');
    expect(app.store.cart.single.quantity, 1);
  });

  testWidgets(
    'live retry loads verified data with safe image, local wish and blocked purchase',
    (tester) async {
      final repo = _Catalogue();
      final app = await open(tester, '/home', demo: false, repository: repo);
      expect(
        find.text('The store connection was interrupted.'),
        findsOneWidget,
      );
      expect(find.text('Petal Serum'), findsNothing);
      expect(find.text('The skincare\nedit'), findsNothing);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(repo.calls, 2);
      expect(find.text('Loading products…'), findsOneWidget);
      repo.data.complete(const [
        Product(
          id: 'live',
          name: 'Test Cleansing Balm',
          brand: 'Test Brand',
          category: 'Balms',
          size: '',
          description: '',
          image: 'assets/serum.webp',
          price: 42,
          currencyCode: 'USD',
          sale: true,
          formerPrice: 199,
        ),
        Product(
          id: 'no-price',
          name: 'Unknown currency product',
          brand: '',
          category: '',
          size: '',
          description: '',
          image: 'http://example.invalid/no',
          price: 79,
        ),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Test Cleansing Balm'), findsOneWidget);
      expect(find.text('USD 42'), findsOneWidget);
      expect(find.text('USD 199'), findsNothing);
      expect(find.byType(Image), findsNothing);
      app.router.go('/product/live');
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(find.text('Purchasing unavailable'), findsOneWidget);
      await tester.tap(find.byTooltip('Save Test Cleansing Balm to wishlist'));
      await tester.pumpAndSettle();
      app.router.go('/wishlist');
      await tester.pumpAndSettle();
      expect(find.text('1 saved in this session'), findsOneWidget);
      app.router.go('/sale');
      await tester.pumpAndSettle();
      expect(find.text('No current offers'), findsOneWidget);
      app.router.go('/product/no-price');
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(FilledButton, 'Price unavailable'),
        findsOneWidget,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(app.store.cart, isEmpty);
      expect(repo.calls, 2);
    },
  );

  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(430, 932),
    const Size(768, 1024),
    const Size(1024, 768),
    const Size(844, 390),
  ]) {
    testWidgets('catalogue fits ${size.width} × ${size.height} at 200% text', (
      tester,
    ) async {
      final app = await open(tester, '/home', size: size, scale: 2);
      expect(tester.takeException(), isNull);
      for (final page in [
        '/categories',
        '/products',
        '/product/lip',
        '/sale',
        '/wishlist',
        '/search',
      ]) {
        app.router.go(page);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: page);
      }
    });
  }
}
