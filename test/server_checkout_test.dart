import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_skin_care_brand/core/config.dart';
import 'package:your_skin_care_brand/core/network/customer_api.dart';
import 'package:your_skin_care_brand/core/network/shopping_responses.dart';
import 'package:your_skin_care_brand/features/account/account_state.dart';
import 'package:your_skin_care_brand/features/checkout/server_bag.dart';
import 'network_test.dart' show TransportFixture, MemoryVault, answer;

void main() {
  final cod = {
    'code': 201,
    'status': 'success',
    'data': {
      '_id': 'order-one',
      'tran_id': null,
      'total_price': 12000,
      'payment_method': 'cod',
      'payment_status': 'pending',
      'status': 'pending',
    },
  };
  test('COD response retains whole taka, order ID and pending status', () {
    final order = decodeCodReceipt(cod);
    expect(
      (order.id, order.total, order.paymentStatus),
      ('order-one', 12000, 'pending'),
    );
    expect(
      () => orderDetails('other').decode({...cod, 'code': 200}),
      throwsFormatException,
    );
  });
  test('online response supplies only a sandbox payment destination', () {
    Map<String, Object> body(String url) => {
      'code': 200,
      'status': 'success',
      'data': {'gateway_url': url},
    };
    expect(
      decodeSandboxGateway(
        body('https://sandbox.sslcommerz.com/EasyCheckOut/test'),
      ).scheme,
      'https',
    );
    expect(
      () => decodeSandboxGateway(
        body('https://example.invalid/EasyCheckOut/test'),
      ),
      throwsFormatException,
    );
  });
  testWidgets(
    'uncertain COD stays blocked across bag reopen without another POST',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      var posts = 0;
      final transport = TransportFixture((r) {
        if (r.method == 'GET') {
          return answer(
            '{"code":200,"status":"success","data":{"total":1,"results":[{"_id":"line","product":{"_id":"product","title":"Item","current_price":12000},"quantity":1,"color":null,"size":null}]}}',
          );
        }
        posts++;
        expect(r.data['payment_method'], 'cod');
        expect(r.data['redirect_url'], AppConfig.checkoutReturnUrl);
        expect(r.data['shipping_address']['postal_code'], '1207');
        return answer('{}', 503);
      });
      final api = CustomerApi(
        baseUrl: 'https://store.invalid/api',
        vault: MemoryVault('test-session'),
        enabled: true,
        adapter: transport,
      );
      addTearDown(api.close);
      final state = AccountState(demo: true)
        ..signIn(AccountState.exampleEmail, AccountState.examplePassword);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiProvider.overrideWithValue(api),
            accountProvider.overrideWith((_) => state),
          ],
          child: const MaterialApp(home: Scaffold(body: ServerBag())),
        ),
      );
      await tester.pumpAndSettle();
      for (var attempt = 0; attempt < 2; attempt++) {
        await tester.tap(find.text('Test cash on delivery'));
        await tester.pumpAndSettle();
        for (var i = 0; i < 5; i++) {
          await tester.enterText(
            find.byType(TextFormField).at(i),
            ['Test', 'Street', 'City', '1207', '0000'][i],
          );
        }
        await tester.ensureVisible(find.text('Place test order'));
        await tester.tap(find.text('Place test order'));
        await tester.pumpAndSettle();
        expect(find.textContaining('needs store confirmation'), findsOneWidget);
        expect(posts, 1);
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
    },
    skip:
        AppConfig.environment != 'staging' ||
        AppConfig.checkoutReturnUrl.isEmpty,
  );
}
