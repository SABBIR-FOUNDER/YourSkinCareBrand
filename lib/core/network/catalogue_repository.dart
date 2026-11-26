import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog.dart';
import '../config.dart';
import 'customer_api.dart';

abstract interface class CatalogueRepository {
  Future<List<Product>> loadProducts();
}

// The staging collection exposes its first product page without a session.
final catalogueResponseProvider = Provider<VerifiedResponse<List<Product>>?>(
  (ref) => AppConfig.environment == 'staging'
      ? const VerifiedResponse(CustomerOperation.products, decodeCataloguePage)
      : null,
);

final catalogueAccessProvider = Provider<CatalogueAccess>(
  (ref) => AppConfig.environment == 'staging'
      ? CatalogueAccess.verifiedAnonymous
      : CatalogueAccess.tokenRequired,
);

List<Product> decodeCataloguePage(Object? json) {
  if (json case {
    'code': 200,
    'status': 'success',
    'data': {'results': final List rows},
  }) {
    return [for (final row in rows) _decodeProduct(row)];
  }
  throw const FormatException('Invalid catalogue page');
}

Product _decodeProduct(Object? row) {
  if (row is! Map) throw const FormatException('Invalid product');
  if (row case {
    '_id': final String id,
    'title': final String title,
  } when id.trim().isNotEmpty && title.trim().isNotEmpty) {
    final brand = row['brand'];
    final categories = row['categories'];
    return Product(
      id: id,
      name: title.trim(),
      brand: brand is Map && brand['title'] is String ? brand['title'] : '',
      category: categories is List
          ? categories
                .whereType<Map>()
                .map((c) => c['title'])
                .whereType<String>()
                .join(', ')
          : '',
      size: '',
      description: '',
      image: '',
      price: wholeTaka(row['current_price']),
      currencyCode: 'BDT',
      canAddSingle: _simpleInStock(row),
    );
  }
  throw const FormatException('Invalid product identity');
}

final catalogueRepositoryProvider = Provider<CatalogueRepository>((ref) {
  return RemoteCatalogueRepository(
    ref.watch(apiProvider),
    ref.watch(catalogueResponseProvider),
    access: ref.watch(catalogueAccessProvider),
  );
});

final class RemoteCatalogueRepository implements CatalogueRepository {
  RemoteCatalogueRepository(
    this._api,
    this._response, {
    this.access = CatalogueAccess.tokenRequired,
  });
  final CatalogueAccess access;
  final CustomerApi _api;
  final VerifiedResponse<List<Product>>? _response;

  @override
  Future<List<Product>> loadProducts() async {
    final products = await _api.execute(
      CustomerRequest.products(access: access),
      contract: _response,
    );
    return List.unmodifiable(products);
  }
}

bool _simpleInStock(Map row) => switch (row) {
  {'quantity': final int stock, 'colors': [], 'sizes': []} => stock > 0,
  _ => false,
};
