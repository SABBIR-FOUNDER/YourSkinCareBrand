import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/store.dart';
import '../features/account/account_state.dart';
import 'router.dart';
import 'theme.dart';

class ShopApp extends ConsumerStatefulWidget {
  const ShopApp({super.key, this.initialLocation = '/'});
  final String initialLocation;
  @override
  ConsumerState<ShopApp> createState() => _ShopAppState();
}

class _ShopAppState extends ConsumerState<ShopApp> {
  late final GoRouter router;
  late final ProviderSubscription<String?> membership;
  @override
  void initState() {
    super.initState();
    router = createShopRouter(ref, initialLocation: widget.initialLocation);
    membership = ref.listenManual(
      accountProvider.select((v) => v.email),
      (previous, next) => ref.read(shopProvider).useAccount(next),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    membership.close();
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'YourSkinCareBrand',
    debugShowCheckedModeBanner: false,
    theme: shopTheme(),
    routerConfig: router,
  );
}
