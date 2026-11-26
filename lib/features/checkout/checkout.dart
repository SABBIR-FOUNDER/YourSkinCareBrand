import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:your_skin_care_brand/core/catalog.dart';
import 'package:your_skin_care_brand/core/store.dart';
import 'package:your_skin_care_brand/features/account/account_state.dart';
import 'checkout_state.dart';
import 'server_bag.dart';
import '../../core/config.dart';

part 'delivery_form.dart';
part 'order_views.dart';

const _rose = Color(0xffa34864);
const _petal = Color(0xfffff7f8);
const _blush = Color(0xfff5e4e8);
const _taupe = Color(0xffe6d8d3);
const _muted = Color(0xff68595e);

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key, required this.page, this.value = ''});
  final String page, value;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(shopProvider);
    if (!store.demo &&
        AppConfig.baseUrl.isNotEmpty &&
        {'bag', 'orders', 'order'}.contains(page)) {
      final owner = ref.watch(accountProvider.select((a) => a.email));
      if (owner == null) return const ServerSignIn();
      if (page == 'bag') return ServerBag(key: ValueKey(owner));
      return ServerOrderLookup(key: ValueKey((owner, value)), id: value);
    }
    if (const {'address', 'payment', 'review', 'failed'}.contains(page)) {
      if (store.cart.isEmpty) return const _Redirect('/bag');
      if (page != 'address' && !store.draft.isComplete) {
        return const _Redirect('/checkout/address');
      }
    }
    final order = store.lookup(value);
    return switch (page) {
      'bag' => _Bag(store),
      'address' => const _DeliveryForm(),
      'payment' => _Payment(store),
      'review' => _Review(store),
      'failed' => _Failure(demo: store.demo),
      'orders' => _History(store),
      'result' ||
      'order' ||
      'cancel' when order == null => const _Redirect('/orders'),
      'result' => _OrderResult(order!),
      'order' => _OrderDetail(store, order!),
      'cancel' when order!.status == DemoOrderStatus.pending => _Cancellation(
        store,
        order,
      ),
      'cancel' => _Redirect('/order/${Uri.encodeComponent(value)}'),
      _ => const _Redirect('/bag'),
    };
  }
}

class _Redirect extends StatefulWidget {
  const _Redirect(this.path);
  final String path;
  @override
  State<_Redirect> createState() => _RedirectState();
}

class _RedirectState extends State<_Redirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? true)) {
        context.replace(widget.path);
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _Page extends StatelessWidget {
  const _Page({required this.children, this.footer});
  final List<Widget> children;
  final Widget? footer;
  @override
  Widget build(BuildContext context) {
    final body = ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(17, 19, 17, 26),
      children: children,
    );
    if (footer == null) return body;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight < 205) {
          return ListView(
            padding: const EdgeInsets.all(17),
            children: [...children, const SizedBox(height: 16), footer!],
          );
        }
        return Column(
          children: [
            Expanded(child: body),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: _taupe)),
              ),
              child: footer,
            ),
          ],
        );
      },
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text, [this.subtitle]);
  final String text;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 32,
              letterSpacing: -1.3,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(subtitle!, style: const TextStyle(color: _muted)),
          ),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section(this.text, {this.action});
  final String text;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 9),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -.7,
              ),
            ),
          ),
        ),
        ?action,
      ],
    ),
  );
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 12),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: const BoxDecoration(
      color: _petal,
      border: Border(left: BorderSide(color: _rose, width: 3)),
    ),
    child: Semantics(
      liveRegion: true,
      child: Text(text, style: const TextStyle(fontSize: 13)),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty(this.icon, this.heading, this.body, this.action);
  final IconData icon;
  final String heading, body;
  final Widget action;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
          child: Icon(icon),
        ),
        const SizedBox(height: 10),
        Text(
          heading,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 7),
        Text(
          body,
          style: const TextStyle(color: _muted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        action,
      ],
    ),
  );
}

class _Amount extends StatelessWidget {
  const _Amount(this.label, this.amount);
  final String label, amount;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: _taupe)),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 10,
      runSpacing: 4,
      children: [
        Text(label),
        Text(amount, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _Bag extends StatelessWidget {
  const _Bag(this.store);
  final ShopStore store;
  @override
  Widget build(BuildContext context) {
    if (store.cart.isEmpty) {
      return _Page(
        children: [
          const _Title('Shopping bag'),
          _Empty(
            Icons.shopping_bag_outlined,
            'Your bag is empty',
            'Explore the catalogue to add your first product.',
            OutlinedButton(
              onPressed: () => context.push('/products'),
              child: const Text('Browse all products'),
            ),
          ),
        ],
      );
    }
    return _Page(
      footer: FilledButton(
        onPressed: () => context.push('/checkout/address'),
        child: const Text('Checkout'),
      ),
      children: [
        _Title(
          'Shopping bag',
          '${store.count} ${store.count == 1 ? 'item' : 'items'}',
        ),
        for (final line in store.cart) _BagLine(store, line),
        _Amount('Item subtotal', money(store.subtotal)),
        const SizedBox(height: 12),
        Text(
          store.demo
              ? 'Sample prices in Bangladeshi taka. Delivery and tax are outside this demo.'
              : 'Item subtotal excludes any final delivery charge or tax.',
          style: const TextStyle(fontSize: 12, color: _muted),
        ),
      ],
    );
  }
}

class _BagLine extends StatelessWidget {
  const _BagLine(this.store, this.line);
  final ShopStore store;
  final CartLine line;
  @override
  Widget build(BuildContext context) {
    final p = line.product;
    Widget fallback(BuildContext context, Object error, StackTrace? stack) =>
        const ColoredBox(color: _blush, child: Icon(Icons.image_outlined));
    final asset = p.image;
    final photo = asset.startsWith('https://')
        ? Image.network(
            asset,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: fallback,
          )
        : asset.startsWith('assets/')
        ? Image.asset(
            asset,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: fallback,
          )
        : fallback(context, '', null);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _taupe)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: SizedBox(width: 65, height: 73, child: photo),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.brand.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.3,
                    color: _muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: () =>
                      context.push('/product/${Uri.encodeComponent(p.id)}'),
                  child: Text(p.name),
                ),
                Text(
                  [
                    line.shade.isNotEmpty ? line.shade : p.size,
                    '${money(line.unitPrice)} each',
                  ].where((s) => s.isNotEmpty).join(' · '),
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: _taupe),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Decrease ${p.name} quantity',
                            onPressed: line.quantity > 1
                                ? () => store.changeQuantity(line, -1)
                                : null,
                            icon: const Icon(Icons.remove, size: 18),
                          ),
                          Text('${line.quantity}'),
                          IconButton(
                            tooltip: 'Increase ${p.name} quantity',
                            onPressed: () => store.changeQuantity(line, 1),
                            icon: const Icon(Icons.add, size: 18),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => store.remove(line),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
                Text(
                  'Line total · ${money(line.lineTotal)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps(this.active);
  final int active;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, label) in ['Address', 'Payment', 'Review'].indexed)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              padding: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: i <= active ? _rose : _taupe,
                    width: 3,
                  ),
                ),
              ),
              child: Semantics(
                label: 'Step ${i + 1} of 3',
                selected: i == active,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: i <= active ? _rose : _muted,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
