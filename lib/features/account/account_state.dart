import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../core/network/customer_api.dart';
import '../checkout/checkout_state.dart';

final accountProvider = ChangeNotifierProvider<AccountState>((ref) {
  final state = AccountState(
    demo: AppConfig.demo,
    api: !AppConfig.demo && AppConfig.baseUrl.isNotEmpty
        ? ref.watch(apiProvider)
        : null,
  );
  ref.listen(sessionExpiryProvider, (_, _) => state.clearIdentity());
  return state;
});

/// Fixture identities and address books are session-scoped. Only the backend
/// can authenticate a live account.
class AccountState extends ChangeNotifier {
  AccountState({required this.demo, this.api});
  final CustomerApi? api;
  final bool demo;
  static const exampleEmail = 'shopper@example.invalid';
  static const examplePassword = 'sample-only';
  static const exampleCode = '246810';
  static const unavailable = 'Account access is awaiting store configuration.';

  String? _email;
  String? get email => _email;
  MemberProfile _profile = const MemberProfile(
    firstName: 'Demo',
    lastName: 'Shopper',
    phone: '00000000000',
  );
  MemberProfile? _pending;
  bool get verificationPending => demo && _pending != null;
  MemberProfile? get profile => _email == null ? null : _profile;
  final List<ShippingAddress> _book = [];
  List<ShippingAddress> get addresses =>
      _email == null ? const [] : List.unmodifiable(_book);

  bool _validCredentials(String email, String password) =>
      demo &&
      email.trim().toLowerCase() == exampleEmail &&
      password == examplePassword;

  String? signIn(String email, String password) {
    if (!demo) return unavailable;
    if (!_validCredentials(email, password)) {
      return 'Use the example email and demo password.';
    }
    _pending = null;
    _email = exampleEmail;
    notifyListeners();
    return null;
  }

  Future<String?> signInOnline(String email, String password) async {
    final service = api;
    if (demo || service == null) return unavailable;
    late MemberProfile member;
    late String identity;
    try {
      await service.signInAndStore(
        email: email,
        password: password,
        contract: VerifiedResponse(CustomerOperation.login, (json) {
          if (json
              case {
                'code': 200,
                'status': 'success',
                'data': {
                  'token': final String token,
                  'user': {
                    '_id': final String id,
                    'email': final String address,
                    'first_name': final String first,
                    'last_name': final String last,
                    'phone': final String? phone,
                    'address': final String? street,
                    'city': final String? city,
                  },
                },
              }
              when id.isNotEmpty &&
                  address.trim().toLowerCase() == email.trim().toLowerCase()) {
            identity = address.trim();
            member = MemberProfile(
              firstName: first,
              lastName: last,
              phone: phone ?? '',
              street: street ?? '',
              city: city ?? '',
            );
            return token;
          }
          throw const FormatException('Invalid sign-in response');
        }),
      );
    } on ApiFailure catch (failure) {
      return failure.problem == ApiProblem.signInRequired
          ? 'Check your email and password.'
          : failure.message;
    }
    _email = identity;
    _profile = member;
    notifyListeners();
    return null;
  }

  String? register(
    String firstName,
    String lastName,
    String email,
    String password,
  ) {
    if (!demo) return unavailable;
    if (firstName.trim().isEmpty || lastName.trim().isEmpty) {
      return 'Enter both names.';
    }
    if (!_validCredentials(email, password)) {
      return 'Use the example email and demo password.';
    }
    _pending = MemberProfile(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      phone: _profile.phone,
      street: _profile.street,
      city: _profile.city,
    );
    notifyListeners();
    return null;
  }

  String? verify(String code) {
    if (!demo) return unavailable;
    final pending = _pending;
    if (pending == null) return 'Start registration to verify your email.';
    if (code.trim() != exampleCode) return 'Enter the displayed demo code.';
    _profile = pending;
    _pending = null;
    _email = exampleEmail;
    notifyListeners();
    return null;
  }

  String resend() => verificationPending
      ? 'Demo code reissued · $exampleCode'
      : 'Start registration to request a code.';

  Future<void> signOut() async {
    if (api != null) await api!.signOutLocally();
    clearIdentity();
  }

  void clearIdentity() {
    if (!demo) _profile = const MemberProfile(firstName: '', lastName: '');
    _email = null;
    _pending = null;
    notifyListeners();
  }

  void updateProfile(MemberProfile value) {
    _requireMember();
    if (value.firstName.trim().isEmpty || value.lastName.trim().isEmpty) {
      throw ArgumentError('Both names are required.');
    }
    _profile = value;
    notifyListeners();
  }

  void saveAddress(ShippingAddress address, {int? index}) {
    _requireMember();
    if (!address.isComplete) {
      throw ArgumentError('Complete all address fields.');
    }
    if (index == null) {
      _book.add(address);
    } else {
      _book[index] = address;
    }
    notifyListeners();
  }

  void removeAddress(int index) {
    _requireMember();
    _book.removeAt(index);
    notifyListeners();
  }

  void _requireMember() {
    if (!demo || _email == null) throw StateError('Sign in first.');
  }
}

@immutable
class MemberProfile {
  const MemberProfile({
    required this.firstName,
    required this.lastName,
    this.phone = '',
    this.street = '',
    this.city = '',
  });
  final String firstName;
  final String lastName;
  final String phone;
  final String street;
  final String city;
  String get fullName => '$firstName $lastName';
}
