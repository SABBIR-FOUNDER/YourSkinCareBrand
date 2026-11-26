import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/config.dart';
import '../core/store.dart';
import '../features/account/account.dart';
import '../features/account/account_state.dart';
import '../features/catalogue/catalogue.dart';
import '../features/checkout/checkout.dart';
import 'demo.dart';
import 'shell.dart';

const browsePages = {
  '/': 'home',
  '/categories': 'categories',
  '/brands': 'brands',
  '/brand/:value': 'brand',
  '/category/:value': 'category',
  '/products': 'products',
  '/edit': 'edit',
  '/search': 'search',
  '/product/:value': 'product',
  '/sale': 'sale',
  '/wishlist': 'wishlist',
};
const memberPages = {
  '/account': 'account',
  '/signin': 'signin',
  '/register': 'register',
  '/verify': 'verify',
  '/profile': 'profile',
  '/profile/edit': 'editProfile',
  '/addresses': 'addresses',
  '/addresses/new': 'addAddress',
  '/addresses/:value/edit': 'editAddress',
  '/policy/:value': 'policy',
};
const purchasePages = {
  '/bag': 'bag',
  '/checkout/address': 'address',
  '/checkout/payment': 'payment',
  '/checkout/review': 'review',
  '/checkout/failed': 'failed',
  '/result/:value': 'result',
  '/orders': 'orders',
  '/order/:value': 'order',
  '/cancel/:value': 'cancel',
};

GoRouter createShopRouter(WidgetRef ref, {String initialLocation = '/'}) =>
    GoRouter(
      initialLocation: initialLocation,
      redirect: (_, state) {
        final path = state.uri.path;
        final member = ref.read(accountProvider).email != null;
        final store = ref.read(shopProvider);
        if (path == '/demo' && !AppConfig.demo) return '/';
        if (!member &&
            (path.startsWith('/profile') || path.startsWith('/addresses'))) {
          return path.startsWith('/profile')
              ? '/signin?next=profile'
              : '/signin?next=addresses';
        }
        if (const {
          '/checkout/address',
          '/checkout/payment',
          '/checkout/review',
        }.contains(path)) {
          if (store.cart.isEmpty) return '/bag';
          if (!store.demo && !member) return '/signin?next=checkout';
          if (path != '/checkout/address' && !store.draft.isComplete) {
            return '/checkout/address';
          }
        }
        return null;
      },
      routes: [
        ShellRoute(
          builder: (_, s, child) => StoreShell(location: s.uri, child: child),
          routes: [
            for (final e in browsePages.entries)
              GoRoute(
                path: e.key,
                builder: (_, s) => CatalogueScreen(
                  page: e.value,
                  value: s.pathParameters['value'] ?? '',
                ),
              ),
            for (final e in memberPages.entries)
              GoRoute(
                path: e.key,
                builder: (_, s) => AccountScreen(
                  page: e.value,
                  value: s.pathParameters['value'] ?? '',
                  next: s.uri.queryParameters['next'] ?? '',
                ),
              ),
            for (final e in purchasePages.entries)
              GoRoute(
                path: e.key,
                builder: (_, s) => CheckoutScreen(
                  page: e.value,
                  value: s.pathParameters['value'] ?? '',
                ),
              ),
            GoRoute(path: '/demo', builder: (_, _) => const DemoControls()),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('This page is unavailable.'),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
