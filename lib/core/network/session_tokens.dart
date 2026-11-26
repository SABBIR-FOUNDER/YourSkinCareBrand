import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_failure.dart';

abstract interface class TokenVault {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

final class SecureTokenVault implements TokenVault {
  SecureTokenVault(String scope, {FlutterSecureStorage? storage})
    : _key = 'customer.session.${Uri.encodeComponent(scope)}',
      _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.unlocked_this_device,
            ),
          );
  final String _key;
  final FlutterSecureStorage _storage;
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);
  @override
  Future<void> clear() => _storage.delete(key: _key);
}

typedef SessionSnapshot = ({int generation, String? token});

/// A late response sent with the previous token cannot erase a newer login.
final class SessionTokens {
  SessionTokens(this._vault);
  final TokenVault _vault;
  Future<void> _previous = Future.value();
  int _generation = 0;

  Future<T> _serial<T>(Future<T> Function() action) {
    final next = _previous.then<T>((_) async {
      try {
        return await action();
      } on ApiFailure {
        rethrow;
      } catch (_) {
        throw ApiFailure.storage;
      }
    });
    _previous = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  Future<SessionSnapshot> snapshot() => _serial(
    () async => (generation: _generation, token: await _vault.read()),
  );

  Future<bool> replaceIfCurrent(SessionSnapshot expected, String token) =>
      _serial(() async {
        if (token.trim().isEmpty ||
            token.contains(RegExp(r'[\x00-\x1f\x7f]'))) {
          throw ApiFailure.invalidResponse;
        }
        if (expected.generation != _generation ||
            expected.token != await _vault.read()) {
          return false;
        }
        await _vault.write(token);
        _generation++;
        return true;
      });

  Future<bool> expireIfCurrent(SessionSnapshot expected) => _serial(() async {
    if (expected.token == null ||
        expected.generation != _generation ||
        expected.token != await _vault.read()) {
      return false;
    }
    await _vault.clear();
    _generation++;
    return true;
  });

  Future<void> clear() => _serial(() async {
    await _vault.clear();
    _generation++;
  });
}
