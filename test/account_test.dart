import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:your_skin_care_brand/features/account/account.dart';
import 'package:your_skin_care_brand/features/account/account_state.dart';
import 'package:your_skin_care_brand/features/checkout/checkout_state.dart';

void main() {
  test(
    'registration requires the demo identity and successful verification',
    () {
      final state = AccountState(demo: true);
      addTearDown(state.dispose);
      expect(state.verify(AccountState.exampleCode), isNotNull);
      expect(
        state.register(
          '',
          'Shopper',
          AccountState.exampleEmail,
          AccountState.examplePassword,
        ),
        isNotNull,
      );
      expect(
        state.signIn('wrong@example.invalid', AccountState.examplePassword),
        isNotNull,
      );
      expect(state.signIn(AccountState.exampleEmail, 'wrong'), isNotNull);
      expect(
        state.register(
          'Ane',
          'Rahman',
          AccountState.exampleEmail,
          AccountState.examplePassword,
        ),
        isNull,
      );
      expect(state.verify('000000'), isNotNull);
      expect(state.email, isNull);
      expect(state.resend(), contains(AccountState.exampleCode));
      expect(state.verify(AccountState.exampleCode), isNull);
      expect(state.profile?.fullName, 'Ane Rahman');
      expect(state.verify(AccountState.exampleCode), isNotNull);
    },
  );
  test(
    'address book is member-only, restored on sign-in, editable and removable',
    () {
      final state = AccountState(demo: true);
      addTearDown(state.dispose);
      const address = ShippingAddress(
        fullName: 'Ane',
        street: '12 Example Lane',
        city: 'Sample City',
        postalCode: '0000',
        phone: '00000000000',
      );
      expect(() => state.saveAddress(address), throwsStateError);
      state.signIn(AccountState.exampleEmail, AccountState.examplePassword);
      state.saveAddress(address);
      state.updateProfile(
        const MemberProfile(firstName: 'Ane', lastName: 'Tester'),
      );
      state.signOut();
      expect(state.addresses, isEmpty);
      expect(state.profile, isNull);
      state.signIn(AccountState.exampleEmail, AccountState.examplePassword);
      expect(state.addresses.single.street, '12 Example Lane');
      expect(state.profile?.fullName, 'Ane Tester');
      state.saveAddress(
        const ShippingAddress(
          fullName: 'Ane',
          street: '14 Example Lane',
          city: 'Sample City',
          postalCode: '0000',
          phone: '00000000000',
        ),
        index: 0,
      );
      expect(state.addresses.single.street, '14 Example Lane');
      state.removeAddress(0);
      expect(state.addresses, isEmpty);
    },
  );
  test('production account state rejects all fixture credentials', () {
    final state = AccountState(demo: false);
    addTearDown(state.dispose);
    expect(
      state.signIn(AccountState.exampleEmail, AccountState.examplePassword),
      AccountState.unavailable,
    );
    expect(
      state.register(
        'A',
        'B',
        AccountState.exampleEmail,
        AccountState.examplePassword,
      ),
      AccountState.unavailable,
    );
    expect(state.verify(AccountState.exampleCode), AccountState.unavailable);
    expect(state.email, isNull);
  });
  testWidgets('protected screen prompts for sign-in and resumes profile', (
    tester,
  ) async {
    await _mount(tester, '/profile');
    expect(find.text('Sign in to demo'), findsOneWidget);
    await _tapText(tester, 'Sign in to demo');
    expect(find.text('Demo Shopper'), findsOneWidget);
    await _tapText(tester, 'Edit profile');
    await tester.enterText(
      find.byKey(const ValueKey('account-field-first')),
      'Ane',
    );
    await _tapText(tester, 'Save changes');
    expect(find.text('Ane Shopper'), findsOneWidget);
  });
  testWidgets(
    'registration handles wrong OTP and resend and resumes checkout',
    (tester) async {
      await _mount(tester, '/signin?next=checkout');
      await _tapText(tester, 'Create a demo account');
      await _tapText(tester, 'Continue to verification');
      expect(find.text('Verify your email'), findsOneWidget);
      final code = find.byKey(const ValueKey('account-field-code'));
      await tester.enterText(code, '111111');
      await _tapText(tester, 'Verify code');
      expect(find.text('Enter the displayed demo code.'), findsOneWidget);
      await _tapText(tester, 'Resend demo code');
      expect(find.text('Demo code reissued · 246810'), findsOneWidget);
      await tester.enterText(code, AccountState.exampleCode);
      await _tapText(tester, 'Verify code');
      expect(find.text('Delivery address'), findsOneWidget);
    },
  );
  testWidgets(
    'live sign-in does not collect credentials while setup is pending',
    (tester) async {
      await _mount(tester, '/signin', demo: false);
      expect(find.text(AccountState.unavailable), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    },
  );
  testWidgets('address form can fill, save, edit and remove a saved address', (
    tester,
  ) async {
    await _mount(tester, '/addresses', member: true);
    expect(find.text('No saved addresses'), findsOneWidget);
    await _tapText(tester, 'Add address');
    await _tapText(tester, 'Fill sample address');
    await _tapText(tester, 'Save address');
    expect(find.text('12 Example Lane'), findsOneWidget);
    await _tapText(tester, 'Edit');
    await tester.enterText(
      find.byKey(const ValueKey('account-field-street')),
      '18 Example Lane',
    );
    await _tapText(tester, 'Save address');
    expect(find.text('18 Example Lane'), findsOneWidget);
    await _tapText(tester, 'Remove');
    expect(find.text('No saved addresses'), findsOneWidget);
  });
  testWidgets('address form remains operable with keyboard and enlarged text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _mount(tester, '/addresses/new', member: true);
    await _tapText(tester, 'Fill sample address');
    await _tapText(tester, 'Save address');
    expect(find.text('Saved addresses'), findsOneWidget);
    expect(find.text('12 Example Lane'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _tapText(WidgetTester tester, String label) async {
  final target = find.text(label).last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _mount(
  WidgetTester tester,
  String path, {
  bool demo = true,
  bool member = false,
}) async {
  final router = GoRouter(
    initialLocation: path,
    routes: [
      for (final entry in {
        '/account': 'account',
        '/signin': 'signin',
        '/register': 'register',
        '/verify': 'verify',
        '/profile': 'profile',
        '/profile/edit': 'editProfile',
        '/addresses': 'addresses',
        '/addresses/new': 'addAddress',
        '/addresses/:index/edit': 'editAddress',
      }.entries)
        GoRoute(
          path: entry.key,
          builder: (_, state) => Scaffold(
            body: AccountScreen(
              page: entry.value,
              value: state.pathParameters['index'] ?? '',
              next: state.uri.queryParameters['next'] ?? '',
            ),
          ),
        ),
      GoRoute(
        path: '/checkout/address',
        builder: (_, _) => const Scaffold(body: Text('Delivery address')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        accountProvider.overrideWith((_) {
          final state = AccountState(demo: demo);
          if (member) {
            state.signIn(
              AccountState.exampleEmail,
              AccountState.examplePassword,
            );
          }
          return state;
        }),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}
