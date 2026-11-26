part of 'catalogue.dart';

class _Page extends StatelessWidget {
  const _Page(
    this.id, {
    required this.children,
    this.products = const [],
    this.store,
  });
  final String id;
  final List<Widget> children;
  final List<Product> products;
  final ShopStore? store;
  @override
  Widget build(BuildContext context) => CustomScrollView(
    key: PageStorageKey('catalogue-$id'),
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    slivers: [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(17, id == 'home' ? 13 : 19, 17, 0),
        sliver: SliverList.list(children: children),
      ),
      if (products.isNotEmpty && store != null)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 17),
          sliver: SliverLayoutBuilder(
            builder: (context, bounds) {
              final count = _columns(context, bounds.crossAxisExtent);
              return SliverList.builder(
                itemCount: (products.length / count).ceil(),
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 17),
                  child: _CardRow(products, count, i * count, store!),
                ),
              );
            },
          ),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: 26)),
    ],
  );
}

int _columns(BuildContext ctx, double width) =>
    width < 280 || MediaQuery.textScalerOf(ctx).scale(15) >= 24 ? 1 : 2;

class _CardRow extends StatelessWidget {
  const _CardRow(this.products, this.columns, this.start, this.store);
  final List<Product> products;
  final int columns, start;
  final ShopStore store;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < columns; i++) ...[
        if (i > 0) const SizedBox(width: 11),
        Expanded(
          child: start + i < products.length
              ? _Card(products[start + i], store)
              : const SizedBox.shrink(),
        ),
      ],
    ],
  );
}

Widget _photo(
  String source, {
  required bool demo,
  double? width,
  double? height,
  String? label,
}) {
  Widget fallback() => Container(
    width: width,
    height: height,
    color: _blush,
    alignment: Alignment.center,
    child: Icon(
      Icons.image_outlined,
      color: _muted,
      semanticLabel: label == null ? null : '$label · Image unavailable',
    ),
  );
  if (demo && source.startsWith('assets/')) {
    return Image.asset(
      source,
      width: width,
      height: height,
      fit: BoxFit.cover,
      semanticLabel: label,
      excludeFromSemantics: label == null,
      errorBuilder: (_, _, _) => fallback(),
    );
  }
  final uri = Uri.tryParse(source);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return fallback();
  }
  return Image.network(
    source,
    width: width,
    height: height,
    fit: BoxFit.cover,
    semanticLabel: label,
    excludeFromSemantics: label == null,
    errorBuilder: (_, _, _) => fallback(),
  );
}

class _Heart extends StatelessWidget {
  const _Heart(this.p, this.store);
  final Product p;
  final ShopStore store;
  @override
  Widget build(BuildContext context) {
    final saved = store.wish.contains(p.id);
    return Semantics(
      toggled: saved,
      child: IconButton(
        tooltip: saved
            ? 'Remove ${p.name} from wishlist'
            : 'Save ${p.name} to wishlist',
        onPressed: () => store.toggleWish(p.id),
        icon: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xF5FFFDFC),
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(
              saved ? Icons.favorite : Icons.favorite_border,
              color: saved ? _rose : _cocoa,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

Widget _eyebrow(String value) => Text(
  value.toUpperCase(),
  style: const TextStyle(
    fontSize: 10,
    letterSpacing: 1.3,
    color: _muted,
    fontWeight: FontWeight.w700,
  ),
);

class _Price extends StatelessWidget {
  const _Price(this.p, {this.large = false, this.showFormer = false});
  final Product p;
  final bool large, showFormer;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 2,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(
        p.currencyCode?.trim().isNotEmpty == true
            ? p.priceLabel
            : 'Price unavailable',
        style: TextStyle(
          fontSize: large ? 18 : 13,
          fontWeight: FontWeight.w700,
          color: _cocoa,
        ),
      ),
      if (showFormer &&
          p.price != null &&
          p.currencyCode?.trim().isNotEmpty == true &&
          p.formerPrice != null &&
          p.formerPrice! > p.price!)
        Semantics(
          label: 'Former price ${p.formerPriceLabel}',
          excludeSemantics: true,
          child: Text(
            p.formerPriceLabel,
            style: _caption.copyWith(decoration: TextDecoration.lineThrough),
          ),
        ),
    ],
  );
}

class _Card extends StatelessWidget {
  const _Card(this.p, this.store);
  final Product p;
  final ShopStore store;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Semantics(
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push(_path('product', p.id)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1 / .94,
                  child: _photo(p.image, demo: store.demo),
                ),
              ),
              const SizedBox(height: 9),
              if (p.brand.isNotEmpty) _eyebrow(p.brand),
              const SizedBox(height: 2),
              Text(
                p.name,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.4,
                  color: _cocoa,
                ),
              ),
              const SizedBox(height: 4),
              _Price(p, showFormer: store.demo),
            ],
          ),
        ),
      ),
      Positioned(top: 3, right: 3, child: _Heart(p, store)),
    ],
  );
}

Widget _heading(String text) =>
    Semantics(header: true, child: Text(text, style: _title));
Widget _subhead(String text, [Widget? action]) => Padding(
  padding: const EdgeInsets.only(top: 20, bottom: 9),
  child: LayoutBuilder(
    builder: (context, bounds) {
      final heading = Semantics(
        header: true,
        child: Text(text, style: _section),
      );
      if (action == null) return heading;
      if (MediaQuery.textScalerOf(context).scale(15) > 23 ||
          bounds.maxWidth < 280) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [heading, action],
        );
      }
      return Row(
        children: [
          Expanded(child: heading),
          const SizedBox(width: 8),
          action,
        ],
      );
    },
  ),
);

Widget _notice(IconData icon, String title, String text, [Widget? action]) =>
    Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
      decoration: BoxDecoration(
        color: _petal,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _taupe),
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: _blush,
            foregroundColor: _rose,
            radius: 22,
            child: Icon(icon, size: 22),
          ),
          const SizedBox(height: 10),
          Semantics(
            header: true,
            child: Text(title, style: _section, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: _muted),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: action),
          ],
        ],
      ),
    );

Widget _browse(BuildContext ctx) => OutlinedButton(
  onPressed: () => ctx.push('/products'),
  child: const Text('Browse all products'),
);

Widget? _status(ShopStore s) {
  if (s.catalogueState == 'error') {
    return _notice(
      Icons.info_outline,
      'Products couldn’t load',
      s.demo
          ? 'Your saved items and bag are still available.'
          : s.catalogueMessage,
      OutlinedButton(onPressed: s.resetCatalogue, child: const Text('Retry')),
    );
  }
  if (s.catalogueState != 'loading') return null;
  return Semantics(
    liveRegion: true,
    container: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text('Loading products…'),
        ),
        Row(
          children: [
            for (int i = 0; i < 2; i++)
              Expanded(
                child: Container(
                  height: 170,
                  margin: EdgeInsets.only(
                    left: i == 1 ? 5 : 0,
                    right: i == 0 ? 5 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: _blush,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

Widget _chip(String text, String selected, ValueChanged<String> choose) =>
    ChoiceChip(
      label: Text(text),
      selected: selected == text,
      showCheckmark: false,
      onSelected: (_) => choose(text),
      shape: const StadiumBorder(),
      backgroundColor: Colors.white,
      selectedColor: _blush,
      side: BorderSide(color: selected == text ? _rose : _taupe),
      labelStyle: TextStyle(
        fontSize: 13,
        color: selected == text ? const Color(0xFF733148) : _cocoa,
        fontWeight: selected == text ? FontWeight.w700 : FontWeight.w400,
      ),
    );

class _PhotoRow extends StatelessWidget {
  const _PhotoRow(
    this.label,
    this.route,
    this.image,
    this.demo, {
    this.subtitle,
  });
  final String label, route, image;
  final String? subtitle;
  final bool demo;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: _taupe)),
    ),
    child: InkWell(
      onTap: () => context.push(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: _photo(image, demo: demo, width: 70, height: 64),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (subtitle != null) Text(subtitle!, style: _caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    ),
  );
}

Widget _count(int value) => Padding(
  padding: const EdgeInsets.only(top: 8, bottom: 17),
  child: Text('$value ${value == 1 ? 'product' : 'products'}', style: _caption),
);
