import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../core/store.dart';
import 'theme.dart';

const _tabs = [
  ('Home', '/', Icons.home_outlined),
  ('Categories', '/categories', Icons.grid_view),
  ('Sale', '/sale', Icons.sell_outlined),
  ('Wishlist', '/wishlist', Icons.favorite_border),
  ('Account', '/account', Icons.person_outline),
];

int? _tabFor(String path) => switch (path.split('/').elementAtOrNull(1)) {
  '' => 0,
  'categories' || 'brands' || 'brand' || 'category' => 1,
  'sale' => 2,
  'wishlist' => 3,
  'account' ||
  'orders' ||
  'order' ||
  'cancel' ||
  'profile' ||
  'addresses' ||
  'policy' ||
  'signin' ||
  'register' ||
  'verify' => 4,
  _ => null,
};

int? _activeTab(List<RouteMatchBase> matches) {
  for (final match in matches.reversed) {
    if (match is ShellRouteMatch) {
      final tab = _activeTab(match.matches);
      if (tab != null) return tab;
    } else if (match is RouteMatch) {
      final tab = _tabFor(match.matchedLocation);
      if (tab != null) return tab;
    }
  }
  return null;
}

class StoreShell extends ConsumerWidget {
  const StoreShell({required this.child, required this.location, super.key});
  final Widget child;
  final Uri location;
  String get section => location.pathSegments.firstOrNull ?? '';
  String get header => switch (section) {
    'product' => 'Product details',
    'products' => 'Products',
    'edit' => 'Collection',
    'bag' => 'Shopping bag',
    'checkout' => 'Checkout',
    'result' || 'cancel' => 'Order',
    'order' => 'Order details',
    'orders' => 'Orders',
    'policy' => 'Help & policies',
    'demo' => 'Design preview',
    'verify' => 'Verification',
    'signin' => 'Sign in',
    'register' => 'Create an account',
    'addresses' => 'Saved addresses',
    'profile' => 'Profile',
    'brand' => 'Brand',
    'category' => 'Category',
    'brands' => 'Brands',
    'search' => 'Search',
    _ => 'YourSkinCareBrand',
  };
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(shopProvider.select((s) => s.count));
    final demo = ref.watch(shopProvider.select((s) => s.demo));
    final router = GoRouter.of(context);
    final primary = _tabs.any((t) => t.$2 == location.path);
    final tab =
        _tabFor(location.path) ??
        _activeTab(router.routerDelegate.currentConfiguration.matches) ??
        0;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return ColoredBox(
      color: const Color(0xffece5e3),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Scaffold(
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Material(
                    color: Brand.petal,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 54),
                      child: Row(
                        children: [
                          if (primary)
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () => context.go('/'),
                                  child: Semantics(
                                    label: 'YourSkinCareBrand home',
                                    excludeSemantics: true,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SvgPicture.asset(
                                          'assets/ribbon-rose.svg',
                                          width: 28,
                                          height: 28,
                                        ),
                                        const SizedBox(width: 4),
                                        const Flexible(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              'YourSkinCareBrand',
                                              maxLines: 1,
                                              style: TextStyle(
                                                fontSize: 17,
                                                letterSpacing: -.8,
                                                fontWeight: FontWeight.w700,
                                                color: Brand.cocoa,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else ...[
                            IconButton(
                              tooltip: 'Back',
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/');
                                }
                              },
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                size: 20,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                header,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          if (demo)
                            TextButton(
                              onPressed: () => context.push('/demo'),
                              child: const Text('Demo'),
                            ),
                          IconButton(
                            tooltip: 'Shopping bag, $count items',
                            onPressed: section == 'bag'
                                ? null
                                : () => context.push('/bag'),
                            icon: Badge(
                              isLabelVisible: count > 0,
                              label: Text('$count'),
                              child: const Icon(Icons.shopping_bag_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  Expanded(child: child),
                ],
              ),
            ),
            bottomNavigationBar: keyboard
                ? null
                : Material(
                    color: Brand.paper,
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Divider(),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final (i, item) in _tabs.indexed)
                                Expanded(
                                  child: Semantics(
                                    selected: i == tab,
                                    button: true,
                                    label: item.$1,
                                    excludeSemantics: true,
                                    child: InkWell(
                                      onTap: () => context.go(item.$2),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 5,
                                          horizontal: 1,
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: i == tab
                                                    ? Brand.blush
                                                    : null,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 11,
                                                    vertical: 3,
                                                  ),
                                              child: Icon(
                                                item.$3,
                                                color: i == tab
                                                    ? Brand.rose
                                                    : Brand.muted,
                                                size: 20,
                                              ),
                                            ),
                                            Text(
                                              item.$1,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: i == tab
                                                    ? Brand.rose
                                                    : Brand.muted,
                                                fontSize: 11,
                                                fontWeight: i == tab
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
