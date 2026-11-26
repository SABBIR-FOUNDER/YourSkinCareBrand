import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:your_skin_care_brand/core/catalog.dart';
import 'package:your_skin_care_brand/core/store.dart';

import '../../core/network/customer_api.dart';
import '../../core/network/shopping_responses.dart';
import '../account/account_state.dart';

part 'components.dart';
part 'browse.dart';
part 'product_detail.dart';

const _rose = Color(0xFFA34864),
    _blush = Color(0xFFF5E4E8),
    _petal = Color(0xFFFFF7F8),
    _cocoa = Color(0xFF34272B),
    _muted = Color(0xFF68595E),
    _taupe = Color(0xFFE6D8D3);
const _title = TextStyle(
  fontSize: 32,
  height: 1.12,
  fontWeight: FontWeight.w600,
  letterSpacing: -1.2,
  color: _cocoa,
);
const _section = TextStyle(
  fontSize: 22,
  height: 1.15,
  fontWeight: FontWeight.w600,
  letterSpacing: -.8,
  color: _cocoa,
);
const _caption = TextStyle(fontSize: 12, color: _muted);
final _queryProvider = StateProvider<String>((ref) => '');
String _path(String kind, String value) =>
    '/$kind/${Uri.encodeComponent(value)}';
bool _ready(ShopStore s) => s.catalogueState == (s.demo ? 'sample' : 'ready');

class CatalogueScreen extends ConsumerWidget {
  const CatalogueScreen({super.key, required this.page, this.value = ''});
  final String page, value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(shopProvider);
    if (page == 'edit' && !store.demo) {
      return _Page(
        page,
        children: [
          _notice(
            Icons.collections_outlined,
            'Collection unavailable',
            'Browse the catalogue to see available products.',
            _browse(context),
          ),
        ],
      );
    }
    switch (page) {
      case 'home':
        return _Home(store);
      case 'categories':
      case 'brands':
        return _Directory(page, store);
      case 'search':
        return _Search(store);
      case 'wishlist':
        return _Wishlist(store);
      case 'sale':
        return _Sale(store);
      case 'product':
        if (!store.demo && !_ready(store)) {
          return _Page(
            page + value,
            children: [
              _status(store) ??
                  _notice(
                    Icons.info_outline,
                    'Product unavailable',
                    'Check back for product details.',
                    _browse(context),
                  ),
            ],
          );
        }
        final product = store.products.where((p) => p.id == value).firstOrNull;
        return product == null
            ? _Page(
                page + value,
                children: [
                  _notice(
                    Icons.info_outline,
                    'Product unavailable',
                    'This product is unavailable in the current catalogue.',
                    _browse(context),
                  ),
                ],
              )
            : _Detail(key: ValueKey(value), store: store, product: product);
      default:
        return _Collection(
          key: ValueKey((page, value)),
          page: page,
          value: value,
          store: store,
        );
    }
  }
}
