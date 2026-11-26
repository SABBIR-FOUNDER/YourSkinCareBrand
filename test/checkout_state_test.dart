import 'package:flutter_test/flutter_test.dart';
import 'package:your_skin_care_brand/core/catalog.dart';
import 'package:your_skin_care_brand/features/checkout/checkout_state.dart';

void main() {
  late CheckoutState state;
  final serum = demoProducts.firstWhere((p) => p.id == 'serum');
  final lip = demoProducts.firstWhere((p) => p.id == 'lip');
  final cleanser = demoProducts.firstWhere((p) => p.id == 'cleanser');
  setUp(() => state = CheckoutState());
  tearDown(() => state.dispose());
  void prepare() {
    state.add(serum, '');
    state.setDraft(ShippingAddress.example);
  }

  test(
    'merges matching shades, preserves other shades and enforces quantity floor',
    () {
      state.add(lip, 'Mauve');
      state.add(lip, 'Mauve');
      state.add(lip, 'Rose');
      expect(state.count, 3);
      expect(state.cart.length, 2);
      expect(state.cart.first.lineTotal, 1520);
      state.changeQuantity(state.cart.first, -1);
      state.changeQuantity(state.cart.first, -1);
      expect(state.cart.first.quantity, 1);
      state.remove(state.cart.first);
      expect(state.cart.single.shade, 'Rose');
      state.remove(state.cart.single);
      expect(state.count, 0);
    },
  );
  test(
    'unavailable price, invalid variant and incomplete address cannot be purchased',
    () {
      state.add(cleanser, '');
      state.add(lip, 'Undefined shade');
      expect(state.cart, isEmpty);
      state.add(serum, '');
      expect(state.placeDemoOrder().kind, SubmissionKind.blocked);
      expect(state.orders, isEmpty);
    },
  );
  test('a known failure retains cart and address, retry is single-use', () {
    prepare();
    state.setOutcome('failure');
    expect(state.placeDemoOrder().kind, SubmissionKind.failed);
    expect(state.orders, isEmpty);
    expect(state.count, 1);
    expect(state.draft.isComplete, isTrue);
    expect(state.placeDemoOrder().kind, SubmissionKind.placed);
    expect(state.placeDemoOrder().kind, SubmissionKind.blocked);
    expect(state.orders.single.subtotal, 1250);
  });
  test(
    'unresolved payment checks the same reference and cancellation is terminal',
    () {
      prepare();
      state.setPayment(PaymentChoice.online);
      state.setOutcome('unknown');
      final ref = state.placeDemoOrder().order!.reference;
      expect(state.lookup(ref)!.status, DemoOrderStatus.unresolved);
      state.cancel(ref);
      expect(state.lookup(ref)!.status, DemoOrderStatus.unresolved);
      state.reconcile(ref);
      state.reconcile(ref);
      expect(state.orders.length, 1);
      expect(state.lookup(ref)!.status, DemoOrderStatus.pending);
      state.cancel(ref);
      expect(state.lookup(ref)!.status, DemoOrderStatus.canceled);
      expect(state.count, 0);
    },
  );
  test(
    'checkout draft survives sign-in, snapshots and histories are isolated',
    () {
      prepare();
      state.useAccount('simone@example.invalid');
      expect(state.draft.street, ShippingAddress.example.street);
      state.add(serum, '');
      final order = state.placeDemoOrder().order!;
      state.setDraft(
        const ShippingAddress(
          fullName: 'Another name',
          street: '99 Example',
          city: 'Other',
          postalCode: '123',
          phone: '011',
        ),
      );
      state.add(lip, 'Mauve');
      expect(order.address.street, ShippingAddress.example.street);
      expect(order.items.single.quantity, 2);
      expect(order.subtotal, 2500);
      state.useAccount(null);
      expect(state.lookup(order.reference), isNull);
      expect(state.draft.isComplete, isFalse);
      state.useAccount('other@example.invalid');
      expect(state.lookup(order.reference), isNull);
      state.useAccount('simone@example.invalid');
      expect(state.lookup(order.reference)?.subtotal, 2500);
    },
  );
  test('live configuration never produces a simulated order', () {
    final live = _LiveCheckout();
    addTearDown(live.dispose);
    live.add(serum, '');
    live.setDraft(ShippingAddress.example);
    expect(live.placeDemoOrder().kind, SubmissionKind.blocked);
    expect(live.orders, isEmpty);
  });
}

class _LiveCheckout extends CheckoutState {
  @override
  bool get demo => false;
}
