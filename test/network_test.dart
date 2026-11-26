import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_skin_care_brand/core/catalog.dart';
import 'package:your_skin_care_brand/features/account/account_state.dart';
import 'package:your_skin_care_brand/core/network/catalogue_repository.dart';
import 'package:your_skin_care_brand/core/network/customer_api.dart';

class MemoryVault implements TokenVault {
  MemoryVault([this.token]);
  String? token;
  int reads = 0;
  @override
  Future<String?> read() async {
    reads++;
    return token;
  }

  @override
  Future<void> clear() async {
    token = null;
  }

  @override
  Future<void> write(String value) async {
    token = value;
  }
}

class TransportFixture implements HttpClientAdapter {
  TransportFixture(this.handle);
  final FutureOr<ResponseBody> Function(RequestOptions) handle;
  final List<RequestOptions> calls = [];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    return handle(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody answer(String json, [int status = 200]) => ResponseBody.fromString(
  json,
  status,
  headers: {
    'content-type': ['application/json'],
  },
);
Matcher fails(ApiProblem problem) =>
    isA<ApiFailure>().having((f) => f.problem, 'problem', problem);
const delivery = DeliveryDetails(
  fullName: 'Test',
  address: 'Sample street',
  city: 'Sample city',
  postalCode: '0000',
  phone: '000',
);
const profileShape = VerifiedResponse(
  CustomerOperation.profile,
  _requiredObject,
);
Map<String, dynamic> _requiredObject(Object? value) =>
    value as Map<String, dynamic>;

void main() {
  late TransportFixture transport;
  late MemoryVault vault;
  late CustomerApi api;
  void connect({
    bool enabled = true,
    String base = 'https://store.invalid/v2/',
    void Function()? onExpired,
  }) {
    api = CustomerApi(
      baseUrl: base,
      enabled: enabled,
      vault: vault,
      adapter: transport,
      onSessionExpired: onExpired,
    );
    addTearDown(api.close);
  }

  setUp(() {
    transport = TransportFixture((_) => answer('{}'));
    vault = MemoryVault('example-token');
  });

  test(
    'login validates the returned identity before storing a customer token',
    () async {
      vault = MemoryVault();
      transport = TransportFixture(
        (_) => answer(
          '{"code":200,"status":"success","data":{"token":"fixture-session","user":{"_id":"customer-one","email":"customer@example.invalid","first_name":"Test","last_name":"User","phone":null,"address":null,"city":null}}}',
        ),
      );
      connect();
      final state = AccountState(demo: false, api: api);
      addTearDown(state.dispose);
      expect(
        await state.signInOnline('other@example.invalid', 'sample'),
        isNotNull,
      );
      expect(vault.token, isNull);
      expect(state.email, isNull);
      expect(
        await state.signInOnline('customer@example.invalid', 'sample'),
        isNull,
      );
      expect(state.profile?.fullName, 'Test User');
      expect(vault.token, 'fixture-session');
      await state.signOut();
      expect(vault.token, isNull);
      expect(state.email, isNull);
    },
  );

  test(
    'catalogue distinguishes missing contract, token-only and verified anonymous access',
    () async {
      vault = MemoryVault();
      transport = TransportFixture((_) => answer('["approved-id"]'));
      connect();
      await expectLater(
        RemoteCatalogueRepository(api, null).loadProducts(),
        throwsA(fails(ApiProblem.contract)),
      );
      expect(vault.reads, 0);
      final shape = VerifiedResponse<List<Product>>(
        CustomerOperation.products,
        (json) => (json as List)
            .map(
              (id) => Product(
                id: id as String,
                name: 'Fixture',
                brand: 'Test',
                category: 'Test',
                size: '',
                description: '',
                image: '',
                price: null,
              ),
            )
            .toList(),
      );
      await expectLater(
        RemoteCatalogueRepository(api, shape).loadProducts(),
        throwsA(fails(ApiProblem.signInRequired)),
      );
      expect(transport.calls, isEmpty);
      final products = await RemoteCatalogueRepository(
        api,
        shape,
        access: CatalogueAccess.verifiedAnonymous,
      ).loadProducts();
      expect(products.single.id, 'approved-id');
      expect(transport.calls.single.headers.containsKey('token'), isFalse);
      expect(() => products.clear(), throwsUnsupportedError);
    },
  );

  test('customer inventory has the documented verbs, paths and token policy', () {
    final requests = <CustomerRequest, String>{
      CustomerRequest.login(email: 'e@x.invalid', password: 'p'):
          'POST auth/login public',
      CustomerRequest.signup(
        firstName: 'F',
        lastName: 'L',
        email: 'e@x.invalid',
        password: 'p',
      ): 'POST auth/signup public',
      CustomerRequest.verifyOtp(email: 'e@x.invalid', otp: '000012'):
          'POST auth/verify-otp public',
      CustomerRequest.resendOtp('e@x.invalid'): 'POST auth/resend-otp public',
      CustomerRequest.profile(): 'GET auth/profile token',
      CustomerRequest.editProfile(phone: 'p'): 'PATCH auth/profile token',
      CustomerRequest.brands(): 'GET brands public',
      CustomerRequest.brand('b'): 'GET brands/b public',
      CustomerRequest.categories(): 'GET categories public',
      CustomerRequest.category('c'): 'GET categories/c public',
      CustomerRequest.products(): 'GET products token',
      CustomerRequest.productById('p'): 'GET products/id/p public',
      CustomerRequest.productBySlug('slug'): 'GET products/slug public',
      CustomerRequest.reviews(product: 'p'): 'GET reviews token',
      CustomerRequest.createReview(product: 'p', comment: 'c'):
          'POST review token',
      CustomerRequest.editReview('r', rating: 4): 'PATCH reviews/r token',
      CustomerRequest.removeReview('r'): 'DELETE reviews/r token',
      CustomerRequest.cart(): 'GET cart token',
      CustomerRequest.addCart(product: 'p'): 'POST cart token',
      CustomerRequest.setQuantity('line', 2): 'PATCH cart/line token',
      CustomerRequest.removeCart('line'): 'DELETE cart/line token',
      CustomerRequest.wishlist(): 'GET wishlist token',
      CustomerRequest.addWish('p'): 'POST wishlist token',
      CustomerRequest.removeWish('item'): 'DELETE wishlist/item token',
      CustomerRequest.orders(): 'GET orders token',
      CustomerRequest.order('o'): 'GET orders/o token',
      CustomerRequest.createOrder(
        method: StorePayment.cod,
        delivery: delivery,
        format: VerifiedOrderFormat(
          StorePayment.cod,
          RedirectPlacement.omitted,
        ),
      ): 'POST order token',
      CustomerRequest.cancelOrder('o', serverAllowsCancellation: true):
          'PATCH orders/o/cancel token',
      CustomerRequest.slides(): 'GET slides public',
    };
    expect(
      requests.keys.map((r) => r.operation).toSet(),
      CustomerOperation.values.toSet(),
    );
    for (final e in requests.entries) {
      final r = e.key;
      expect(
        '${r.method} ${r.path.join('/')} ${r.authenticated ? 'token' : 'public'}',
        e.value,
      );
    }
  });

  test('unverified or mismatched contracts block side effects', () async {
    connect();
    await expectLater(
      api.execute<void>(CustomerRequest.resendOtp('e@x.invalid')),
      throwsA(fails(ApiProblem.contract)),
    );
    await expectLater(
      api.execute(CustomerRequest.brands(), contract: profileShape),
      throwsA(fails(ApiProblem.contract)),
    );
    expect(transport.calls, isEmpty);
    expect(vault.reads, 0);
  });
  test('demo mode prevents even verified network requests', () async {
    connect(enabled: false);
    await expectLater(
      api.execute(CustomerRequest.profile(), contract: profileShape),
      throwsA(fails(ApiProblem.contract)),
    );
    expect(transport.calls, isEmpty);
    expect(vault.reads, 0);
  });

  for (final base in [
    '',
    'http://store.invalid',
    'https://user:pass@store.invalid',
    'https://store.invalid/?x=1',
    'https://store.invalid/#x',
  ]) {
    test(
      'unsafe or missing base URL fails before token access ($base)',
      () async {
        connect(base: base);
        await expectLater(
          api.execute(CustomerRequest.profile(), contract: profileShape),
          throwsA(fails(ApiProblem.configuration)),
        );
        expect(transport.calls, isEmpty);
        expect(vault.reads, 0);
      },
    );
  }

  test(
    'preserves base path and encodes list filters with the exact token header',
    () async {
      connect();
      await api.execute(
        CustomerRequest.products(
          page: 2,
          count: 8,
          brand: 'Studio 01',
          category: 'cream',
          tag: 'A & B',
        ),
        contract: const VerifiedResponse(
          CustomerOperation.products,
          _requiredObject,
        ),
      );
      final req = transport.calls.single;
      expect(req.uri.path, '/v2/products');
      expect(req.uri.queryParameters, {
        'page': '2',
        'count': '8',
        'brand': 'Studio 01',
        'category': 'cream',
        'tag': 'A & B',
      });
      expect(req.headers['token'], 'example-token');
      expect(
        req.headers.keys.map((k) => k.toLowerCase()),
        isNot(contains('authorization')),
      );
      expect(req.followRedirects, isFalse);
    },
  );

  test('public requests omit the token even when signed in', () async {
    connect();
    await api.execute(
      CustomerRequest.productBySlug('cream?extra=x'),
      contract: const VerifiedResponse(
        CustomerOperation.productBySlug,
        _requiredObject,
      ),
    );
    expect(transport.calls.single.uri.pathSegments.last, 'cream?extra=x');
    expect(transport.calls.single.uri.hasQuery, isFalse);
    expect(transport.calls.single.headers.containsKey('token'), isFalse);
    expect(vault.reads, 0);
    expect(
      () => CustomerRequest.productById('..'),
      throwsA(fails(ApiProblem.validation)),
    );
    expect(
      () => CustomerRequest.productById('a/b'),
      throwsA(fails(ApiProblem.validation)),
    );
  });

  test(
    'cart writes use server line IDs, positive quantities and explicit variants',
    () async {
      connect();
      expect(
        () => CustomerRequest.setQuantity('line', 0),
        throwsA(fails(ApiProblem.validation)),
      );
      expect(
        CustomerRequest.addCart(product: 'p', quantity: 2, color: 'Mauve').body,
        {'product': 'p', 'quantity': 2, 'color': 'Mauve'},
      );
      await api.execute(
        CustomerRequest.setQuantity('existing-item-id', 3),
        contract: const VerifiedResponse(
          CustomerOperation.setQuantity,
          _requiredObject,
        ),
      );
      expect(transport.calls.single.uri.path, '/v2/cart/existing-item-id');
      expect(transport.calls.single.data, {'quantity': 3});
    },
  );

  test(
    'authenticated 401 clears its own session, missing token blocks another request',
    () async {
      var notices = 0;
      transport = TransportFixture(
        (_) => answer('{"internal":"private"}', 401),
      );
      connect(onExpired: () => notices++);
      await expectLater(
        api.execute(CustomerRequest.profile(), contract: profileShape),
        throwsA(fails(ApiProblem.signInRequired)),
      );
      expect(vault.token, isNull);
      expect(notices, 1);
      await expectLater(
        api.execute(CustomerRequest.profile(), contract: profileShape),
        throwsA(fails(ApiProblem.signInRequired)),
      );
      expect(transport.calls, hasLength(1));
    },
  );

  test('late 401 cannot clear a replacement session', () async {
    final pending = Completer<ResponseBody>();
    final started = Completer<void>();
    transport = TransportFixture((_) {
      started.complete();
      return pending.future;
    });
    connect();
    final read = api.execute(CustomerRequest.profile(), contract: profileShape);
    await started.future;
    final old = await api.sessions.snapshot();
    expect(await api.sessions.replaceIfCurrent(old, 'new-token'), isTrue);
    pending.complete(answer('{}', 401));
    await expectLater(read, throwsA(fails(ApiProblem.signInRequired)));
    expect(vault.token, 'new-token');
  });

  test(
    'verified login stores its token and preserves password whitespace; local signout clears it',
    () async {
      transport = TransportFixture((_) => answer('["verified-test-token"]'));
      connect();
      await api.signInAndStore(
        email: 'u@x.invalid',
        password: ' sample password ',
        contract: VerifiedResponse(
          CustomerOperation.login,
          (v) => (v as List).first as String,
        ),
      );
      expect(vault.token, 'verified-test-token');
      expect(transport.calls.single.data['password'], ' sample password ');
      expect(transport.calls.single.headers.containsKey('token'), isFalse);
      await api.signOutLocally();
      expect(vault.token, isNull);
    },
  );

  for (final body in ['<invalid>', '', '[]']) {
    test(
      'malformed, empty or incompatible payload is handled ($body)',
      () async {
        transport = TransportFixture((_) => answer(body));
        connect();
        await expectLater(
          api.execute(CustomerRequest.profile(), contract: profileShape),
          throwsA(fails(ApiProblem.badPayload)),
        );
      },
    );
  }
  test('empty success response requires explicit adapter support', () async {
    transport = TransportFixture((_) => answer('', 204));
    connect();
    await api.execute<void>(
      CustomerRequest.removeWish('server-item'),
      contract: VerifiedResponse<void>(
        CustomerOperation.removeWish,
        (v) => expect(v, isNull),
        acceptEmptyBody: true,
      ),
    );
  });
  test('status codes map to safe errors, redirects stay blocked', () async {
    final statuses = {
      302: ApiProblem.redirect,
      400: ApiProblem.validation,
      403: ApiProblem.forbidden,
      404: ApiProblem.missing,
      408: ApiProblem.timeout,
      409: ApiProblem.conflict,
      422: ApiProblem.validation,
      429: ApiProblem.rateLimited,
      500: ApiProblem.server,
      504: ApiProblem.timeout,
    };
    for (final e in statuses.entries) {
      expect(ApiFailure.fromStatus(e.key).problem, e.value);
    }
    transport = TransportFixture(
      (_) => ResponseBody.fromString(
        'private response',
        302,
        headers: {
          'location': ['https://elsewhere.invalid'],
        },
      ),
    );
    connect();
    await expectLater(
      api.execute(CustomerRequest.profile(), contract: profileShape),
      throwsA(fails(ApiProblem.redirect)),
    );
    expect(transport.calls, hasLength(1));
  });

  test(
    'order create requires confirmed format and method, cancellation requires server eligibility',
    () {
      expect(
        () => CustomerRequest.createOrder(
          method: StorePayment.cod,
          delivery: delivery,
        ),
        throwsA(fails(ApiProblem.contract)),
      );
      expect(
        () => CustomerRequest.cancelOrder('o', serverAllowsCancellation: false),
        throwsA(fails(ApiProblem.contract)),
      );
      final verified = VerifiedOrderFormat(
        StorePayment.ssl,
        RedirectPlacement.inShippingAddress,
        returnUrl: Uri.parse('https://store.invalid/return'),
      );
      expect(
        () => CustomerRequest.createOrder(
          method: StorePayment.cod,
          delivery: delivery,
          format: verified,
        ),
        throwsA(fails(ApiProblem.contract)),
      );
      final body = CustomerRequest.createOrder(
        method: StorePayment.ssl,
        delivery: delivery,
        format: verified,
      ).body!;
      expect(body.containsKey('redirect_url'), isFalse);
      expect(
        (body['shipping_address'] as Map)['redirect_url'],
        'https://store.invalid/return',
      );
      expect(body.containsKey('amount'), isFalse);
    },
  );

  test(
    'an ambiguous order is never auto-retried and a concurrent submission is blocked',
    () async {
      final pending = Completer<ResponseBody>();
      final started = Completer<void>();
      transport = TransportFixture((_) {
        started.complete();
        return pending.future;
      });
      connect();
      final req = CustomerRequest.createOrder(
        method: StorePayment.cod,
        delivery: delivery,
        format: VerifiedOrderFormat(
          StorePayment.cod,
          RedirectPlacement.omitted,
        ),
      );
      const shape = VerifiedResponse(
        CustomerOperation.createOrder,
        _requiredObject,
      );
      final result = api.execute(req, contract: shape);
      await started.future;
      await expectLater(
        api.execute(req, contract: shape),
        throwsA(fails(ApiProblem.inProgress)),
      );
      pending.complete(answer('unavailable', 503));
      await expectLater(result, throwsA(fails(ApiProblem.unknownOrder)));
      expect(transport.calls, hasLength(1));
    },
  );
}
