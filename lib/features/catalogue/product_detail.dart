part of 'catalogue.dart';

class _Detail extends ConsumerStatefulWidget {
  const _Detail({super.key, required this.store, required this.product});
  final ShopStore store;
  final Product product;
  @override
  ConsumerState<_Detail> createState() => _DetailState();
}

class _DetailState extends ConsumerState<_Detail> {
  String? selected;
  bool adding = false;
  Future<void> addToServer(Product product) async {
    if (adding) return;
    if (ref.read(accountProvider).email == null) {
      context.push('/signin');
      return;
    }
    setState(() => adding = true);
    try {
      await ref
          .read(apiProvider)
          .execute(
            CustomerRequest.addCart(product: product.id, quantity: 1),
            contract: addedCartItem(product.id),
          );
      if (mounted) context.push('/bag');
    } on ApiFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${error.message} Check your bag before adding again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final s = widget.store;
    final shade = p.shades.contains(selected)
        ? selected!
        : p.shades.firstOrNull ?? '';
    final hasPrice =
        p.price != null && p.currencyCode?.trim().isNotEmpty == true;
    final canBuy = hasPrice && (s.demo || p.canAddSingle);
    return Column(
      children: [
        Expanded(
          child: ListView(
            key: PageStorageKey('product-${p.id}'),
            padding: EdgeInsets.zero,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 247,
                    width: double.infinity,
                    child: _photo(p.image, demo: s.demo, label: p.name),
                  ),
                  Positioned(top: 10, right: 10, child: _Heart(p, s)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(17, 18, 17, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p.brand.isNotEmpty) _eyebrow(p.brand),
                    _heading(p.name),
                    const SizedBox(height: 10),
                    _Price(p, large: true, showFormer: s.demo),
                    if (p.size.isNotEmpty) _fact('Size', p.size),
                    if (p.shades.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const Text(
                        'Shade',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 7,
                        runSpacing: 4,
                        children: [
                          for (final v in p.shades)
                            _chip(
                              v,
                              shade,
                              (v) => setState(() => selected = v),
                            ),
                        ],
                      ),
                    ],
                    if (p.description.isNotEmpty ||
                        p.category.isNotEmpty ||
                        p.brand.isNotEmpty)
                      _subhead('Product details'),
                    if (p.description.isNotEmpty) Text(p.description),
                    if (p.category.isNotEmpty) _fact('Category', p.category),
                    if (p.brand.isNotEmpty)
                      TextButton(
                        onPressed: () => context.push(_path('brand', p.brand)),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: Text('Explore ${p.brand}'),
                      ),
                    if (!canBuy)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: _petal,
                          border: Border(
                            left: BorderSide(color: _rose, width: 3),
                          ),
                        ),
                        child: Text(
                          !hasPrice
                              ? 'The price is unavailable. You can save this item to your wishlist.'
                              : 'Purchasing is currently unavailable. You can still save this item to your wishlist.',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: _taupe)),
          ),
          child: FilledButton(
            onPressed: canBuy && !adding
                ? () {
                    if (!s.demo) {
                      addToServer(p);
                      return;
                    }
                    s.add(p, shade);
                    context.push('/bag');
                  }
                : null,
            child: Text(
              !hasPrice
                  ? 'Price unavailable'
                  : canBuy
                  ? 'Add to bag · ${p.priceLabel}'
                  : 'Purchasing unavailable',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

Widget _fact(String name, String value) => Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(vertical: 10),
  decoration: const BoxDecoration(
    border: Border(bottom: BorderSide(color: _taupe)),
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: Text(name, style: const TextStyle(fontSize: 14))),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    ],
  ),
);
