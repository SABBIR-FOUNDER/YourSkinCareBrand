import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/checkout/checkout_state.dart';
import 'catalog.dart';
import 'config.dart';
import 'network/api_failure.dart';
import 'network/catalogue_repository.dart';

final shopProvider = ChangeNotifierProvider<ShopStore>(
  (ref) => ShopStore(
    catalogueRepository: AppConfig.demo
        ? null
        : ref.watch(catalogueRepositoryProvider),
  ),
);

class ShopStore extends CheckoutState {
  ShopStore({
    this.demo = AppConfig.demo,
    CatalogueRepository? catalogueRepository,
  }) : _repository = catalogueRepository {
    if (!demo && _repository != null) unawaited(_loadProducts());
  }
  @override
  final bool demo;
  final CatalogueRepository? _repository;
  List<Product> _verified = const [];
  final _saved = <String?, Set<String>>{};
  String? _owner;
  Set<String> get _wish => _saved.putIfAbsent(_owner, () => <String>{});
  String _catalogue = 'sample', _offers = 'sample', _remote = 'error';
  String catalogueMessage = 'The store catalogue is currently unavailable.';
  Timer? _loading;
  bool _closed = false;
  List<Product> get products => demo ? demoProducts : _verified;
  Set<String> get wish => Set.unmodifiable(_wish);
  String get catalogueState => demo ? _catalogue : _remote;
  String get offerState => demo ? _offers : 'empty';
  @override
  void useAccount(String? email) {
    final owner = email?.trim().toLowerCase();
    if (owner == _owner) return;
    _owner = owner;
    super.useAccount(email);
  }

  void toggleWish(String id) {
    if (products.every((p) => p.id != id)) return;
    if (!_wish.remove(id)) _wish.add(id);
    notifyListeners();
  }

  @override
  void add(Product product, String shade) {
    if (demo && products.contains(product)) super.add(product, shade);
  }

  void setCatalogue(String value) {
    if (!demo) return;
    _loading?.cancel();
    _catalogue = value;
    if (value == 'loading') {
      _loading = Timer(const Duration(milliseconds: 1400), resetCatalogue);
    }
    notifyListeners();
  }

  void setOffers(String value) {
    if (!demo) return;
    _offers = value;
    notifyListeners();
  }

  void resetCatalogue() {
    if (demo) {
      setCatalogue('sample');
    } else {
      unawaited(_loadProducts());
    }
  }

  void resetOffers() => setOffers('sample');
  Future<void> _loadProducts() async {
    if (_closed || _repository == null || _remote == 'loading') return;
    _remote = 'loading';
    notifyListeners();
    try {
      final loaded = await _repository.loadProducts();
      if (_closed) return;
      _verified = List.unmodifiable(loaded);
      _remote = 'ready';
    } on ApiFailure catch (e) {
      if (_closed) return;
      catalogueMessage = e.message;
      _remote = 'error';
    } catch (_) {
      if (_closed) return;
      catalogueMessage = 'Products could not be loaded. Please try again.';
      _remote = 'error';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _closed = true;
    _loading?.cancel();
    super.dispose();
  }
}
