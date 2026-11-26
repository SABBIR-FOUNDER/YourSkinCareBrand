import '../catalog.dart';
import 'customer_api.dart';

typedef StoreCartItem = ({
  String id,
  String productId,
  String title,
  int quantity,
  int? price,
  String? color,
  String? size,
});

typedef StoreCartPage = ({List<StoreCartItem> items, int total});
typedef StoreOrder = ({
  String id,
  String status,
  String paymentMethod,
  String paymentStatus,
  int total,
});

Map _data(Object? json, int expectedCode) {
  if (json case {
    'code': final int code,
    'status': 'success',
    'data': final Map data,
  } when code == expectedCode) {
    return data;
  }
  throw const FormatException('Invalid store response');
}

String _text(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value;
  throw const FormatException('Missing required text');
}

StoreCartPage decodeCart(Object? json) {
  final data = _data(json, 200);
  if (data case {
    'results': final List rows,
    'total': final int total,
  } when total >= rows.length) {
    final items = <StoreCartItem>[];
    for (final row in rows) {
      if (row case {
        '_id': final String id,
        'product': {
          '_id': final String productId,
          'title': final String title,
          'current_price': final Object? price,
        },
        'quantity': final int qty,
        'color': final String? color,
        'size': final String? size,
      } when qty > 0) {
        items.add((
          id: _text(id),
          productId: _text(productId),
          title: _text(title),
          quantity: qty,
          price: wholeTaka(price),
          color: color,
          size: size,
        ));
      } else {
        throw const FormatException('Invalid bag item');
      }
    }
    return (items: List.unmodifiable(items), total: total);
  }
  throw const FormatException('Invalid bag');
}

VerifiedResponse<String> addedCartItem(String productId) =>
    VerifiedResponse(CustomerOperation.addCart, (json) {
      final data = _data(json, 201);
      if (data['product'] != productId || data['quantity'] != 1) {
        throw const FormatException('Unexpected bag item');
      }
      return _text(data['_id']);
    });

StoreOrder _order(Map data) {
  final total = wholeTaka(data['total_price']);
  if (total == null) throw const FormatException('Missing order total');
  return (
    id: _text(data['_id']),
    status: _text(data['status']),
    paymentMethod: _text(data['payment_method']),
    paymentStatus: _text(data['payment_status']),
    total: total,
  );
}

VerifiedResponse<StoreOrder> orderDetails(String id) =>
    VerifiedResponse(CustomerOperation.order, (json) {
      final order = _order(_data(json, 200));
      if (order.id != id) throw const FormatException('Unexpected order');
      return order;
    });

StoreOrder decodeCodReceipt(Object? json) {
  final order = _order(_data(json, 201));
  if (order.paymentMethod != 'cod') {
    throw const FormatException('Unexpected payment method');
  }
  return order;
}

Uri decodeSandboxGateway(Object? json) {
  final url = Uri.parse(_text(_data(json, 200)['gateway_url']));
  if (url.scheme != 'https' ||
      url.host != 'sandbox.sslcommerz.com' ||
      url.port != 443 ||
      url.userInfo.isNotEmpty ||
      !url.path.startsWith('/EasyCheckOut/') ||
      url.hasFragment) {
    throw const FormatException('Unexpected sandbox payment destination');
  }
  return url;
}

List<StoreOrder> decodeOrderList(Object? json) {
  if (json case {
    'code': 200,
    'status': 'success',
    'data': final Object? data,
  }) {
    final rows = switch (data) {
      final List list => list,
      {'results': final List list} => list,
      _ => throw const FormatException('Invalid order list'),
    };
    return [for (final row in rows) _order(row as Map)];
  }
  throw const FormatException('Invalid order list');
}
