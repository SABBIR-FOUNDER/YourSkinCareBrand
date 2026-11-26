import 'api_failure.dart';

enum CustomerOperation {
  login,
  signup,
  verifyOtp,
  resendOtp,
  profile,
  editProfile,
  brands,
  brand,
  categories,
  category,
  products,
  productById,
  productBySlug,
  reviews,
  createReview,
  editReview,
  removeReview,
  cart,
  addCart,
  setQuantity,
  removeCart,
  wishlist,
  addWish,
  removeWish,
  orders,
  order,
  createOrder,
  cancelOrder,
  slides,
}

/// The supplied GET /products example includes a token. Guest access needs
/// separate, explicit evidence.
enum CatalogueAccess { tokenRequired, verifiedAnonymous }

enum StorePayment { cod, ssl }

enum RedirectPlacement { omitted, atTopLevel, inShippingAddress }

/// Pin the approved return URL in trusted deployment configuration.
final class VerifiedOrderFormat {
  VerifiedOrderFormat(this.method, this.redirectPlacement, {this.returnUrl}) {
    final uri = returnUrl;
    if (redirectPlacement == RedirectPlacement.omitted) {
      if (uri != null) throw ApiFailure.contract;
    } else if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment) {
      throw ApiFailure.contract;
    }
  }
  final StorePayment method;
  final RedirectPlacement redirectPlacement;
  final Uri? returnUrl;
}

final class DeliveryDetails {
  const DeliveryDetails({
    required this.fullName,
    required this.address,
    required this.city,
    required this.postalCode,
    required this.phone,
  });
  final String fullName, address, city, postalCode, phone;
  Map<String, String> toJson() => {
    'full_name': _required(fullName),
    'address': _required(address),
    'city': _required(city),
    'postal_code': _required(postalCode),
    'phone': _required(phone),
  };
}

const _invalidInput = ApiFailure(
  ApiProblem.validation,
  'Please check the details you entered.',
);

String _required(String value) {
  if (value.trim().isEmpty) throw _invalidInput;
  return value.trim();
}

String _password(String password) {
  if (password.isEmpty) throw _invalidInput;
  return password;
}

String _id(String id) {
  final value = _required(id);
  if (value == '.' ||
      value == '..' ||
      value.contains(RegExp(r'[/\\\x00-\x1f]'))) {
    throw _invalidInput;
  }
  return value;
}

int _positive(int n) {
  if (n < 1) throw _invalidInput;
  return n;
}

Map<String, Object> _page(int? count, int? page) => {
  if (count != null) 'count': _positive(count),
  if (page != null) 'page': _positive(page),
};

Map<String, Object> _present(Map<String, Object?> fields) => {
  for (final e in fields.entries)
    if (e.value != null) e.key: e.value!,
};

/// Customer request inventory. Response schemas are supplied separately.
final class CustomerRequest {
  CustomerRequest._(
    this.operation,
    this.method,
    List<String> path, {
    this.authenticated = true,
    Map<String, Object>? body,
    Map<String, Object>? query,
  }) : path = List.unmodifiable(path),
       body = body == null ? null : Map.unmodifiable(body),
       query = Map.unmodifiable(query ?? {});
  final CustomerOperation operation;
  final String method;
  final List<String> path;
  final bool authenticated;
  final Map<String, Object>? body;
  final Map<String, Object> query;

  static CustomerRequest login({
    required String email,
    required String password,
  }) => CustomerRequest._(
    CustomerOperation.login,
    'POST',
    ['auth', 'login'],
    authenticated: false,
    body: {'email': _required(email), 'password': _password(password)},
  );
  static CustomerRequest signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
    String? avatarUrl,
    String? address,
    String? city,
  }) => CustomerRequest._(
    CustomerOperation.signup,
    'POST',
    ['auth', 'signup'],
    authenticated: false,
    body: _present({
      'first_name': _required(firstName),
      'last_name': _required(lastName),
      'email': _required(email),
      'password': _password(password),
      'phone': phone,
      'avatar_url': avatarUrl,
      'address': address,
      'city': city,
    }),
  );
  static CustomerRequest verifyOtp({
    required String email,
    required String otp,
  }) => CustomerRequest._(
    CustomerOperation.verifyOtp,
    'POST',
    ['auth', 'verify-otp'],
    authenticated: false,
    body: {'email': _required(email), 'otp': _required(otp)},
  );
  static CustomerRequest resendOtp(String email) => CustomerRequest._(
    CustomerOperation.resendOtp,
    'POST',
    ['auth', 'resend-otp'],
    authenticated: false,
    body: {'email': _required(email)},
  );
  static CustomerRequest profile() =>
      CustomerRequest._(CustomerOperation.profile, 'GET', ['auth', 'profile']);
  static CustomerRequest editProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
    String? address,
    String? city,
  }) {
    final fields = _present({
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'address': address,
      'city': city,
    });
    if (fields.isEmpty) throw _invalidInput;
    return CustomerRequest._(CustomerOperation.editProfile, 'PATCH', [
      'auth',
      'profile',
    ], body: fields);
  }

  static CustomerRequest brands({int? count, int? page}) => CustomerRequest._(
    CustomerOperation.brands,
    'GET',
    ['brands'],
    authenticated: false,
    query: _page(count, page),
  );
  static CustomerRequest brand(String id) => CustomerRequest._(
    CustomerOperation.brand,
    'GET',
    ['brands', _id(id)],
    authenticated: false,
  );
  static CustomerRequest categories({int? count, int? page}) =>
      CustomerRequest._(
        CustomerOperation.categories,
        'GET',
        ['categories'],
        authenticated: false,
        query: _page(count, page),
      );
  static CustomerRequest category(String id) => CustomerRequest._(
    CustomerOperation.category,
    'GET',
    ['categories', _id(id)],
    authenticated: false,
  );
  static CustomerRequest products({
    int? count,
    int? page,
    String? brand,
    String? category,
    String? tag,
    CatalogueAccess access = CatalogueAccess.tokenRequired,
  }) => CustomerRequest._(
    CustomerOperation.products,
    'GET',
    ['products'],
    authenticated: access == CatalogueAccess.tokenRequired,
    query: {
      ..._page(count, page),
      ..._present({'brand': brand, 'category': category, 'tag': tag}),
    },
  );
  static CustomerRequest productById(String id) => CustomerRequest._(
    CustomerOperation.productById,
    'GET',
    ['products', 'id', _id(id)],
    authenticated: false,
  );
  static CustomerRequest productBySlug(String slug) => CustomerRequest._(
    CustomerOperation.productBySlug,
    'GET',
    ['products', _id(slug)],
    authenticated: false,
  );
  static CustomerRequest reviews({String? product, int? count, int? page}) =>
      CustomerRequest._(
        CustomerOperation.reviews,
        'GET',
        ['reviews'],
        query: {
          ..._page(count, page),
          if (product != null) 'product': _id(product),
        },
      );
  static CustomerRequest createReview({
    required String product,
    required String comment,
    num? rating,
  }) => CustomerRequest._(
    CustomerOperation.createReview,
    'POST',
    ['review'],
    body: _present({
      'product': _id(product),
      'comment': _required(comment),
      'rating': rating,
    }),
  );
  static CustomerRequest editReview(String id, {String? comment, num? rating}) {
    if (comment == null && rating == null) throw _invalidInput;
    return CustomerRequest._(
      CustomerOperation.editReview,
      'PATCH',
      ['reviews', _id(id)],
      body: _present({'comment': comment, 'rating': rating}),
    );
  }

  static CustomerRequest removeReview(String id) => CustomerRequest._(
    CustomerOperation.removeReview,
    'DELETE',
    ['reviews', _id(id)],
  );

  static CustomerRequest cart({int? count, int? page}) => CustomerRequest._(
    CustomerOperation.cart,
    'GET',
    ['cart'],
    query: _page(count, page),
  );
  static CustomerRequest addCart({
    required String product,
    int? quantity,
    String? color,
    String? size,
  }) => CustomerRequest._(
    CustomerOperation.addCart,
    'POST',
    ['cart'],
    body: _present({
      'product': _id(product),
      'quantity': quantity == null ? null : _positive(quantity),
      'color': color,
      'size': size,
    }),
  );
  static CustomerRequest setQuantity(String cartItemId, int quantity) =>
      CustomerRequest._(
        CustomerOperation.setQuantity,
        'PATCH',
        ['cart', _id(cartItemId)],
        body: {'quantity': _positive(quantity)},
      );
  static CustomerRequest removeCart(String cartItemId) => CustomerRequest._(
    CustomerOperation.removeCart,
    'DELETE',
    ['cart', _id(cartItemId)],
  );
  static CustomerRequest wishlist({int? count, int? page}) => CustomerRequest._(
    CustomerOperation.wishlist,
    'GET',
    ['wishlist'],
    query: _page(count, page),
  );
  static CustomerRequest addWish(String product) => CustomerRequest._(
    CustomerOperation.addWish,
    'POST',
    ['wishlist'],
    body: {'product': _id(product)},
  );
  static CustomerRequest removeWish(String wishlistItemId) => CustomerRequest._(
    CustomerOperation.removeWish,
    'DELETE',
    ['wishlist', _id(wishlistItemId)],
  );
  static CustomerRequest orders({int? count, int? page}) => CustomerRequest._(
    CustomerOperation.orders,
    'GET',
    ['orders'],
    query: _page(count, page),
  );
  static CustomerRequest order(String orderId) => CustomerRequest._(
    CustomerOperation.order,
    'GET',
    ['orders', _id(orderId)],
  );
  static CustomerRequest createOrder({
    required StorePayment method,
    required DeliveryDetails delivery,
    VerifiedOrderFormat? format,
  }) {
    if (format == null || format.method != method) throw ApiFailure.contract;
    final address = delivery.toJson();
    if (format.redirectPlacement == RedirectPlacement.inShippingAddress) {
      address['redirect_url'] = format.returnUrl!.toString();
    }
    return CustomerRequest._(
      CustomerOperation.createOrder,
      'POST',
      ['order'],
      body: {
        'payment_method': method.name,
        'shipping_address': Map<String, String>.unmodifiable(address),
        if (format.redirectPlacement == RedirectPlacement.atTopLevel)
          'redirect_url': format.returnUrl!.toString(),
      },
    );
  }

  static CustomerRequest cancelOrder(
    String orderId, {
    required bool serverAllowsCancellation,
  }) {
    if (!serverAllowsCancellation) throw ApiFailure.contract;
    return CustomerRequest._(CustomerOperation.cancelOrder, 'PATCH', [
      'orders',
      _id(orderId),
      'cancel',
    ]);
  }

  static CustomerRequest slides({int? count, int? page}) => CustomerRequest._(
    CustomerOperation.slides,
    'GET',
    ['slides'],
    authenticated: false,
    query: _page(count, page),
  );
}
