part of 'checkout.dart';

class _Review extends ConsumerStatefulWidget {
  const _Review(this.store);
  final ShopStore store;
  @override
  ConsumerState<_Review> createState() => _ReviewState();
}

class _ReviewState extends ConsumerState<_Review> {
  bool _attempted = false;
  void _submit() {
    if (_attempted) return;
    setState(() => _attempted = true);
    final result = widget.store.placeDemoOrder();
    if (result.kind == SubmissionKind.failed) {
      context.replace('/checkout/failed');
    } else if (result.order case final order?) {
      context.go('/result/${Uri.encodeComponent(order.reference)}');
    } else {
      setState(() => _attempted = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final signedIn = ref.watch(accountProvider).email != null;
    final button = store.demo
        ? FilledButton(
            onPressed: _attempted ? null : _submit,
            child: const Text('Place demo order'),
          )
        : signedIn
        ? const FilledButton(
            onPressed: null,
            child: Text('Checkout unavailable'),
          )
        : FilledButton(
            onPressed: () => context.push('/signin?next=checkout'),
            child: const Text('Sign in to continue'),
          );
    return _Page(
      footer: button,
      children: [
        const _Steps(2),
        const _Title('Review order'),
        const _Section('Items'),
        for (final line in store.cart)
          _Amount(
            _lineTitle(line.product.name, line.shade, line.quantity),
            money(line.lineTotal),
          ),
        _Amount('Item subtotal', money(store.subtotal)),
        _Section(
          'Deliver to',
          action: TextButton(
            onPressed: () => context.push('/checkout/address'),
            child: const Text('Edit address'),
          ),
        ),
        _AddressPanel(store.draft),
        _Section(
          'Payment',
          action: TextButton(
            onPressed: () => context.push('/checkout/payment'),
            child: const Text('Edit payment'),
          ),
        ),
        Text(store.demo ? store.payment.label : 'Payment options unavailable'),
        _Note(
          store.demo
              ? 'Demo order only. The subtotal covers sample items. Delivery, tax and any final charge are unavailable.'
              : 'A confirmed final total and payment method are required before an order can be placed.',
        ),
      ],
    );
  }
}

String _lineTitle(String name, String shade, int quantity) =>
    '${[name, if (shade.isNotEmpty) shade].join(' · ')} × $quantity';

class _Failure extends StatelessWidget {
  const _Failure({required this.demo});
  final bool demo;
  @override
  Widget build(BuildContext context) => _Page(
    children: [
      const _Title('Order not submitted'),
      _Note(
        demo
            ? 'This simulated attempt failed before an order was created. Your bag is ready to retry.'
            : 'Checkout is unavailable.',
      ),
      if (demo)
        FilledButton(
          onPressed: () => context.replace('/checkout/review'),
          child: const Text('Review and retry'),
        ),
    ],
  );
}

class _OrderResult extends StatelessWidget {
  const _OrderResult(this.order);
  final DemoOrder order;
  @override
  Widget build(BuildContext context) {
    final unknown = order.status == DemoOrderStatus.unresolved;
    return _Page(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: CircleAvatar(
            backgroundColor: _blush,
            foregroundColor: _rose,
            child: Icon(unknown ? Icons.info_outline : Icons.check),
          ),
        ),
        const SizedBox(height: 11),
        _Title(
          unknown ? 'Payment status unknown' : 'Demo order placed',
          order.reference,
        ),
        if (unknown)
          const _Note(
            'The payment result is unknown. Open this order to check its simulated status before trying again.',
          )
        else
          const Text('Your sample order is saved for this session.'),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: () =>
              context.push('/order/${Uri.encodeComponent(order.reference)}'),
          child: const Text('View order'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => context.go('/'),
          child: const Text('Continue shopping'),
        ),
      ],
    );
  }
}

class _History extends StatelessWidget {
  const _History(this.store);
  final ShopStore store;
  @override
  Widget build(BuildContext context) => _Page(
    children: [
      const _Title('Orders'),
      if (!store.demo)
        const _Note(
          'Order history is unavailable until the store connects its order service.',
        )
      else if (store.orders.isEmpty)
        _Empty(
          Icons.receipt_long_outlined,
          'No orders yet',
          'Completed demo orders appear here.',
          OutlinedButton(
            onPressed: () => context.push('/products'),
            child: const Text('Browse all products'),
          ),
        )
      else
        for (final order in store.orders)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(order.reference),
            subtitle: Text('${order.status.label} · ${money(order.subtotal)}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                context.push('/order/${Uri.encodeComponent(order.reference)}'),
          ),
    ],
  );
}

class _OrderDetail extends StatelessWidget {
  const _OrderDetail(this.store, this.order);
  final ShopStore store;
  final DemoOrder order;
  @override
  Widget build(BuildContext context) => _Page(
    children: [
      _Title(order.reference, order.status.label),
      const _Section('Items'),
      for (final line in order.items)
        _Amount(
          _lineTitle(line.name, line.shade, line.quantity),
          money(line.lineTotal),
        ),
      _Amount('Item subtotal', money(order.subtotal)),
      const _Section('Delivery'),
      _AddressPanel(order.address),
      _Amount('Payment', order.payment.label),
      const SizedBox(height: 18),
      if (order.status == DemoOrderStatus.pending)
        OutlinedButton(
          onPressed: () =>
              context.push('/cancel/${Uri.encodeComponent(order.reference)}'),
          child: const Text('Cancel demo order'),
        ),
      if (order.status == DemoOrderStatus.unresolved)
        FilledButton(
          onPressed: () => store.reconcile(order.reference),
          child: const Text('Check demo payment status'),
        ),
    ],
  );
}

class _Cancellation extends StatelessWidget {
  const _Cancellation(this.store, this.order);
  final ShopStore store;
  final DemoOrder order;
  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/order/${Uri.encodeComponent(order.reference)}');
    }
  }

  @override
  Widget build(BuildContext context) => _Page(
    children: [
      _Title('Cancel this order?', order.reference),
      const Text('The demo order will be marked canceled.'),
      const SizedBox(height: 18),
      OutlinedButton(
        onPressed: () => _back(context),
        child: const Text('Keep order'),
      ),
      const SizedBox(height: 9),
      OutlinedButton(
        onPressed: () {
          store.cancel(order.reference);
          _back(context);
        },
        child: const Text('Confirm cancellation'),
      ),
    ],
  );
}
