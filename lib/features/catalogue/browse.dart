part of 'catalogue.dart';

Map<String, Product> _groups(
  List<Product> products,
  String Function(Product) key,
) {
  final groups = <String, Product>{};
  for (final p in products) {
    final name = key(p);
    if (name.isNotEmpty) groups.putIfAbsent(name, () => p);
  }
  return groups;
}

List<Widget> _brandRows(ShopStore store) {
  final brands = _groups(store.products, (p) => p.brand);
  if (store.demo) {
    final lip = store.products.where((p) => p.id == 'lip').firstOrNull;
    if (lip != null) brands[lip.brand] = lip;
  }
  return [
    for (final e in brands.entries)
      _PhotoRow(
        e.key,
        _path('brand', e.key),
        e.value.image,
        store.demo,
        subtitle: 'View products',
      ),
  ];
}

class _Hero extends StatelessWidget {
  const _Hero();
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Stack(
      children: [
        Positioned.fill(child: _photo('assets/hero.webp', demo: true)),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF8DED9),
                  Color(0xE8F8DED9),
                  Color(0x45F8DED9),
                  Color(0x00F8DED9),
                ],
                stops: [0, .28, .55, .74],
              ),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 188),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: MediaQuery.textScalerOf(context).scale(15) > 22
                  ? 0.9
                  : 0.67,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 2, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: const Text(
                        'The skincare\nedit',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 39,
                          height: .98,
                          letterSpacing: -2.2,
                          color: _cocoa,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => context.push('/edit'),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      iconAlignment: IconAlignment.end,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(44, 48),
                        alignment: Alignment.centerLeft,
                        foregroundColor: const Color(0xFF562C37),
                      ),
                      label: const Text(
                        'Shop the edit',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w600,
                        ),
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
  );
}

class _Shortcuts extends StatelessWidget {
  const _Shortcuts(this.store);
  final ShopStore store;
  @override
  Widget build(BuildContext context) {
    final categories = _groups(
      store.products,
      (p) => p.category,
    ).entries.take(4);
    return LayoutBuilder(
      builder: (context, bounds) {
        final columns =
            MediaQuery.textScalerOf(context).scale(15) > 21 ||
                bounds.maxWidth < 270
            ? 2
            : 4;
        const gap = 6.0;
        return Wrap(
          spacing: gap,
          runSpacing: 12,
          children: [
            for (final e in categories)
              SizedBox(
                width: (bounds.maxWidth - gap * (columns - 1)) / columns,
                child: Semantics(
                  button: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.push(_path('category', e.key)),
                    child: Column(
                      children: [
                        ClipOval(
                          child: _photo(
                            e.value.image,
                            demo: store.demo,
                            width: 60,
                            height: 60,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          e.key,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Home extends StatelessWidget {
  const _Home(this.store);
  final ShopStore store;
  @override
  Widget build(BuildContext context) {
    final items = store.products;
    final first = items.take(2).toList();
    final status = _status(store);
    Widget all(String route) => TextButton(
      onPressed: () => context.push(route),
      child: const Text('View all'),
    );
    return _Page(
      'home',
      children: [
        OutlinedButton(
          onPressed: () => context.push('/search'),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: _muted,
            side: const BorderSide(color: _taupe),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size.fromHeight(46),
            alignment: Alignment.centerLeft,
          ),
          child: const Row(
            children: [
              Icon(Icons.search, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search products or brands',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        if (store.demo) ...[const SizedBox(height: 14), const _Hero()],
        if (status != null) ...[
          _subhead('Explore products'),
          status,
        ] else if (items.isEmpty) ...[
          _subhead('Explore products'),
          _notice(
            Icons.inventory_2_outlined,
            'No products available',
            'Check back for new products.',
          ),
        ] else ...[
          if (items.any((p) => p.category.isNotEmpty)) ...[
            _subhead('Shop by category'),
            _Shortcuts(store),
          ],
          _subhead('Explore products', all('/products')),
          LayoutBuilder(
            builder: (context, bounds) {
              final cols = _columns(context, bounds.maxWidth);
              return Column(
                children: [
                  for (int i = 0; i < first.length; i += cols)
                    Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : 17),
                      child: _CardRow(first, cols, i, store),
                    ),
                ],
              );
            },
          ),
          if (items.any((p) => p.brand.isNotEmpty)) ...[
            _subhead('Shop by brand', all('/brands')),
            ..._brandRows(store),
          ],
        ],
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () => context.go('/sale'),
          icon: const Icon(Icons.arrow_forward, size: 16),
          iconAlignment: IconAlignment.end,
          label: const Text('Explore Sale'),
        ),
      ],
    );
  }
}

class _Directory extends StatelessWidget {
  const _Directory(this.page, this.store);
  final String page;
  final ShopStore store;
  @override
  Widget build(BuildContext context) {
    final categories = page == 'categories';
    final title = categories ? 'Categories' : 'Brands';
    final categoryMap = _groups(store.products, (p) => p.category);
    final brands = _brandRows(store);
    final status = _status(store);
    return _Page(
      page,
      children: [
        _heading(title),
        if (status != null)
          status
        else ...[
          if ((categories && categoryMap.isEmpty) ||
              (!categories && brands.isEmpty))
            _notice(
              Icons.inventory_2_outlined,
              'No ${title.toLowerCase()} available',
              'Check back when the catalogue is available.',
            ),
          if (categories) ...[
            for (final e in categoryMap.entries)
              _PhotoRow(
                e.key,
                _path('category', e.key),
                e.value.image,
                store.demo,
              ),
            if (brands.isNotEmpty)
              _subhead(
                'Brands',
                TextButton(
                  onPressed: () => context.push('/brands'),
                  child: const Text('View all'),
                ),
              ),
          ],
          ...brands,
        ],
      ],
    );
  }
}

class _Collection extends StatefulWidget {
  const _Collection({
    super.key,
    required this.page,
    required this.value,
    required this.store,
  });
  final String page, value;
  final ShopStore store;
  @override
  State<_Collection> createState() => _CollectionState();
}

class _CollectionState extends State<_Collection> {
  String? brand;
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final page = widget.page;
    final title = switch (page) {
      'category' || 'brand' => widget.value,
      'edit' => 'The skincare edit',
      _ => 'All products',
    };
    final available = store.products
        .where((p) {
          if (brand != null && p.brand != brand) return false;
          return switch (page) {
            'category' => p.category == widget.value,
            'brand' => p.brand == widget.value,
            'edit' => store.demo && p.category != 'Makeup',
            _ => true,
          };
        })
        .toList(growable: false);
    final status = _status(store);
    return _Page(
      '$page-${widget.value}',
      store: store,
      products: status == null ? available : const [],
      children: [
        _heading(title),
        if (status != null)
          status
        else ...[
          if (page == 'brand')
            _subhead('Products')
          else ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 7,
              runSpacing: 4,
              children: [
                _chip(
                  'All',
                  brand ?? 'All',
                  (_) => setState(() => brand = null),
                ),
                for (final name in _groups(store.products, (p) => p.brand).keys)
                  _chip(name, brand ?? 'All', (v) => setState(() => brand = v)),
              ],
            ),
          ],
          if (available.isEmpty)
            _notice(
              Icons.search,
              'No products found',
              'Try another brand or search term.',
            )
          else if (page != 'brand')
            _count(available.length),
        ],
      ],
    );
  }
}

class _Search extends ConsumerStatefulWidget {
  const _Search(this.store);
  final ShopStore store;
  @override
  ConsumerState<_Search> createState() => _SearchState();
}

class _SearchState extends ConsumerState<_Search> {
  late final TextEditingController controller;
  late String query;
  Timer? debounce;
  @override
  void initState() {
    super.initState();
    query = ref.read(_queryProvider);
    controller = TextEditingController(text: query);
  }

  @override
  void dispose() {
    debounce?.cancel();
    controller.dispose();
    super.dispose();
  }

  void change(String value) {
    ref.read(_queryProvider.notifier).state = value;
    debounce?.cancel();
    if (value.isEmpty) {
      setState(() => query = '');
      return;
    }
    debounce = Timer(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => query = value);
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.store;
    final q = query.toLowerCase().trim();
    final status = _status(s);
    final matches = q.isEmpty
        ? <Product>[]
        : s.products
              .where(
                (p) => [
                  p.name,
                  p.brand,
                  p.category,
                ].any((v) => v.toLowerCase().contains(q)),
              )
              .toList();
    return _Page(
      'search',
      store: s,
      products: status == null ? matches : const [],
      children: [
        _heading('Search'),
        const SizedBox(height: 18),
        TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: change,
          decoration: InputDecoration(
            labelText: 'Search products or brands',
            hintText: 'Product, brand or category',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      controller.clear();
                      change('');
                    },
                  ),
          ),
        ),
        const SizedBox(height: 8),
        if (status != null)
          status
        else if (q.isEmpty && s.products.any((p) => p.category.isNotEmpty)) ...[
          _subhead('Browse categories'),
          _Shortcuts(s),
        ] else if (q.isEmpty && s.products.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('Search the loaded catalogue by product or brand.'),
          )
        else if (matches.isEmpty)
          _notice(
            Icons.search,
            'No products found',
            q.isEmpty
                ? 'No products are available to search.'
                : 'Try another brand or search term.',
          )
        else
          _count(matches.length),
      ],
    );
  }
}

class _Sale extends StatefulWidget {
  const _Sale(this.store);
  final ShopStore store;
  @override
  State<_Sale> createState() => _SaleState();
}

class _SaleState extends State<_Sale> {
  String selected = 'Current offers';
  @override
  Widget build(BuildContext context) {
    final s = widget.store;
    final products =
        !s.demo || selected == 'Clearance' || s.offerState != 'sample'
        ? <Product>[]
        : s.products.where((p) => p.sale).toList();
    return _Page(
      'sale',
      store: s,
      products: products,
      children: [
        _heading('Sale'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 7,
          runSpacing: 4,
          children: [
            for (final label in ['Current offers', 'Sale', 'Clearance'])
              _chip(label, selected, (v) => setState(() => selected = v)),
          ],
        ),
        if (s.offerState == 'error')
          _notice(
            Icons.info_outline,
            'Offers couldn’t load',
            'Try loading the collection again.',
            OutlinedButton(
              onPressed: s.resetOffers,
              child: const Text('Retry'),
            ),
          )
        else if (s.offerState == 'loading')
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Loading offers…'),
          )
        else if (products.isEmpty)
          _notice(
            Icons.sell_outlined,
            selected == 'Clearance'
                ? 'No clearance items'
                : 'No current offers',
            'Browse the catalogue while this collection is empty.',
            _browse(context),
          )
        else
          _subhead(selected == 'Current offers' ? selected : 'Sale products'),
      ],
    );
  }
}

class _Wishlist extends StatelessWidget {
  const _Wishlist(this.s);
  final ShopStore s;
  @override
  Widget build(BuildContext context) {
    final byId = {for (final p in s.products) p.id: p};
    final items = s.wish.map((id) => byId[id]).whereType<Product>().toList();
    final status = !s.demo && s.wish.isNotEmpty ? _status(s) : null;
    return _Page(
      'wishlist',
      store: s,
      products: status == null ? items : const [],
      children: [
        _heading('Wishlist'),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 17),
          child: Text(
            s.demo
                ? '${s.wish.length} saved'
                : '${s.wish.length} saved in this session',
            style: const TextStyle(color: _muted),
          ),
        ),
        if (status != null)
          status
        else if (s.wish.isEmpty)
          _notice(
            Icons.favorite_border,
            'Your wishlist is empty',
            'Tap the heart on a product to save it here.',
            _browse(context),
          )
        else if (items.isEmpty)
          _notice(
            Icons.info_outline,
            'Saved products unavailable',
            'Their catalogue details are currently unavailable.',
          ),
      ],
    );
  }
}
