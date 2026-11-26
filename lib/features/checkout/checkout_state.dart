import 'package:flutter/foundation.dart';
import 'package:your_skin_care_brand/core/catalog.dart';

@immutable
class ShippingAddress {
  const ShippingAddress({
    required this.fullName,
    required this.street,
    required this.city,
    required this.postalCode,
    required this.phone,
  });
  final String fullName, street, city, postalCode, phone;
  static const empty = ShippingAddress(
    fullName: '',
    street: '',
    city: '',
    postalCode: '',
    phone: '',
  );
  static const example = ShippingAddress(
    fullName: 'Demo Shopper',
    street: '12 Example Lane',
    city: 'Sample City',
    postalCode: '0000',
    phone: '00000000000',
  );
  bool get isComplete => [
    fullName,
    street,
    city,
    postalCode,
    phone,
  ].every((field) => field.trim().isNotEmpty);
  @override
  bool operator ==(Object other) =>
      other is ShippingAddress &&
      fullName == other.fullName &&
      street == other.street &&
      city == other.city &&
      postalCode == other.postalCode &&
      phone == other.phone;
  @override
  int get hashCode => Object.hash(fullName, street, city, postalCode, phone);
}

@immutable
class CartLine {
  const CartLine(this.product, this.shade, this.quantity, this.unitPrice);
  final Product product;
  final String shade;
  final int quantity, unitPrice;
  int get lineTotal => unitPrice * quantity;
  CartLine withQuantity(int count) =>
      CartLine(product, shade, count, unitPrice);
}

enum PaymentChoice {
  cash('Cash on delivery'),
  online('Online payment · simulated');

  const PaymentChoice(this.label);
  final String label;
}

enum DemoOrderStatus {
  pending('Pending'),
  unresolved('Payment unresolved'),
  canceled('Canceled');

  const DemoOrderStatus(this.label);
  final String label;
}

@immutable
class OrderItem {
  OrderItem.fromCart(CartLine line)
    : name = line.product.name,
      shade = line.shade,
      quantity = line.quantity,
      unitPrice = line.unitPrice;
  final String name, shade;
  final int quantity, unitPrice;
  int get lineTotal => quantity * unitPrice;
}

@immutable
class DemoOrder {
  const DemoOrder._(
    this.reference,
    this.items,
    this.address,
    this.payment,
    this.status,
  );
  final String reference;
  final List<OrderItem> items;
  final ShippingAddress address;
  final PaymentChoice payment;
  final DemoOrderStatus status;
  int get subtotal => items.fold(0, (sum, line) => sum + line.lineTotal);
  DemoOrder withStatus(DemoOrderStatus value) =>
      DemoOrder._(reference, items, address, payment, value);
}

enum SubmissionKind { blocked, failed, placed }

@immutable
class Submission {
  const Submission(this.kind, [this.order]);
  final SubmissionKind kind;
  final DemoOrder? order;
}

class CheckoutState extends ChangeNotifier {
  bool get demo => true;
  final _lines = <CartLine>[];
  final _histories = <String?, List<DemoOrder>>{};
  String? _scope;
  int _sequence = 0;
  ShippingAddress _draft = ShippingAddress.empty;
  PaymentChoice _payment = PaymentChoice.cash;
  String _outcome = 'success';

  List<CartLine> get cart => List.unmodifiable(_lines);
  int get count => _lines.fold(0, (sum, line) => sum + line.quantity);
  int get subtotal => _lines.fold(0, (sum, line) => sum + line.lineTotal);
  String get outcome => _outcome;
  ShippingAddress get draft => _draft;
  PaymentChoice get payment => _payment;
  List<DemoOrder> get orders =>
      List.unmodifiable((_histories[_scope] ?? <DemoOrder>[]).reversed);

  void useAccount(String? email) {
    final next = email?.trim().toLowerCase();
    if (_scope == next) return;
    // Preserve a guest's checkout when signing in, and erase personal
    // details before another person starts shopping on the same device.
    if (_scope != null) {
      _lines.clear();
      _draft = ShippingAddress.empty;
      _payment = PaymentChoice.cash;
      _outcome = 'success';
    }
    _scope = next;
    notifyListeners();
  }

  void add(Product product, String shade) {
    final price = product.price;
    if (price == null || price < 0) return;
    final variant = shade.isEmpty && product.shades.isNotEmpty
        ? product.shades.first
        : shade;
    if (variant.isNotEmpty && !product.shades.contains(variant)) return;
    final index = _lines.indexWhere(
      (line) => line.product.id == product.id && line.shade == variant,
    );
    if (index < 0) {
      _lines.add(CartLine(product, variant, 1, price));
    } else {
      final line = _lines[index];
      _lines[index] = line.withQuantity(line.quantity + 1);
    }
    notifyListeners();
  }

  void changeQuantity(CartLine line, int delta) {
    final index = _lines.indexOf(line);
    if (index < 0 || delta.abs() != 1 || line.quantity + delta < 1) return;
    _lines[index] = line.withQuantity(line.quantity + delta);
    notifyListeners();
  }

  void remove(CartLine line) {
    if (_lines.remove(line)) notifyListeners();
  }

  void setDraft(ShippingAddress value) {
    if (value == _draft) return;
    _draft = value;
    notifyListeners();
  }

  void setPayment(PaymentChoice value) {
    if (_payment == value) return;
    _payment = value;
    notifyListeners();
  }

  void setOutcome(String value) {
    if (!demo || !const {'success', 'failure', 'unknown'}.contains(value)) {
      return;
    }
    _outcome = value;
    notifyListeners();
  }

  Submission placeDemoOrder() {
    if (!demo || _lines.isEmpty || !_draft.isComplete) {
      return const Submission(SubmissionKind.blocked);
    }
    final scenario = _outcome;
    _outcome = 'success';
    if (scenario == 'failure') {
      notifyListeners();
      return const Submission(SubmissionKind.failed);
    }
    final reference = 'DEMO-${(++_sequence).toString().padLeft(3, '0')}';
    final order = DemoOrder._(
      reference,
      List.unmodifiable(_lines.map(OrderItem.fromCart)),
      _draft,
      _payment,
      scenario == 'unknown' && _payment == PaymentChoice.online
          ? DemoOrderStatus.unresolved
          : DemoOrderStatus.pending,
    );
    _histories.putIfAbsent(_scope, () => []).add(order);
    _lines.clear();
    _draft = ShippingAddress.empty;
    _payment = PaymentChoice.cash;
    notifyListeners();
    return Submission(SubmissionKind.placed, order);
  }

  DemoOrder? lookup(String reference) {
    for (final item in _histories[_scope] ?? <DemoOrder>[]) {
      if (item.reference == reference) return item;
    }
    return null;
  }

  void reconcile(String reference) => _transition(
    reference,
    DemoOrderStatus.unresolved,
    DemoOrderStatus.pending,
  );
  void cancel(String reference) =>
      _transition(reference, DemoOrderStatus.pending, DemoOrderStatus.canceled);

  void _transition(String reference, DemoOrderStatus from, DemoOrderStatus to) {
    if (!demo) return;
    final history = _histories[_scope];
    if (history == null) return;
    final index = history.indexWhere(
      (order) => order.reference == reference && order.status == from,
    );
    if (index < 0) return;
    history[index] = history[index].withStatus(to);
    notifyListeners();
  }
}
