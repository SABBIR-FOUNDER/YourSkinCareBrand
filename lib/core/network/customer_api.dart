import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config.dart';
import 'api_failure.dart';
import 'customer_request.dart';
import 'session_tokens.dart';

export 'api_failure.dart';
export 'customer_request.dart';
export 'session_tokens.dart';

/// Bind a parser after verifying the response contract for the named operation.
final class VerifiedResponse<T> {
  const VerifiedResponse(
    this.operation,
    this.decode, {
    this.acceptEmptyBody = false,
  });
  final CustomerOperation operation;
  final T Function(Object? json) decode;
  final bool acceptEmptyBody;
}

final sessionExpiryProvider = StateProvider<int>((ref) => 0);

final apiProvider = Provider<CustomerApi>((ref) {
  final api = CustomerApi(
    baseUrl: AppConfig.baseUrl,
    enabled: !AppConfig.demo,
    vault: SecureTokenVault('${AppConfig.environment}|${AppConfig.baseUrl}'),
    onSessionExpired: () => ref.read(sessionExpiryProvider.notifier).state++,
  );
  ref.onDispose(api.close);
  return api;
});

final class CustomerApi {
  CustomerApi({
    required String baseUrl,
    required TokenVault vault,
    required this.enabled,
    this.onSessionExpired,
    HttpClientAdapter? adapter,
  }) : _base = _validatedBase(baseUrl),
       sessions = SessionTokens(vault),
       _dio = Dio(
         BaseOptions(
           connectTimeout: const Duration(seconds: 12),
           sendTimeout: const Duration(seconds: 15),
           receiveTimeout: const Duration(seconds: 20),
           responseType: ResponseType.plain,
           followRedirects: false,
           maxRedirects: 0,
           validateStatus: (_) => true,
           headers: {'Accept': 'application/json'},
         ),
       ) {
    if (adapter != null) _dio.httpClientAdapter = adapter;
  }
  final Uri? _base;
  final Dio _dio;
  final SessionTokens sessions;
  final bool enabled;
  final void Function()? onSessionExpired;
  bool _submitting = false;

  static Uri? _validatedBase(String input) {
    final uri = Uri.tryParse(input.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }
    return uri;
  }

  Future<T> execute<T>(
    CustomerRequest request, {
    VerifiedResponse<T>? contract,
  }) async {
    if (!enabled ||
        contract == null ||
        contract.operation != request.operation) {
      throw ApiFailure.contract;
    }
    final base = _base;
    if (base == null) throw ApiFailure.configuration;
    final isOrder = request.operation == CustomerOperation.createOrder;
    if (isOrder && _submitting) {
      throw const ApiFailure(
        ApiProblem.inProgress,
        'An order is already being submitted.',
      );
    }
    if (isOrder) _submitting = true;
    try {
      final session = request.authenticated ? await sessions.snapshot() : null;
      final token = session?.token;
      if (request.authenticated && (token == null || token.trim().isEmpty)) {
        throw const ApiFailure(
          ApiProblem.signInRequired,
          'Please sign in to continue.',
        );
      }
      final uri = base.replace(
        pathSegments: [
          ...base.pathSegments.where((e) => e.isNotEmpty),
          ...request.path,
        ],
        queryParameters: request.query.isEmpty
            ? null
            : request.query.map(
                (key, value) => MapEntry(key, value.toString()),
              ),
      );
      final response = await _dio.requestUri<String>(
        uri,
        data: request.body,
        options: Options(
          method: request.method,
          contentType: request.body == null ? null : Headers.jsonContentType,
          headers: {'token': ?token},
        ),
      );
      final status = response.statusCode ?? 0;
      if (status == 401 &&
          session != null &&
          await sessions.expireIfCurrent(session)) {
        onSessionExpired?.call();
      }
      if (status < 200 || status >= 300) {
        if (isOrder && (status >= 500 || status == 408 || status == 409)) {
          throw ApiFailure.unknownOrder;
        }
        throw ApiFailure.fromStatus(status);
      }
      final body = response.data?.trim();
      try {
        if ((body == null || body.isEmpty) && !contract.acceptEmptyBody) {
          throw const FormatException();
        }
        return contract.decode(
          body == null || body.isEmpty ? null : jsonDecode(body),
        );
      } catch (_) {
        if (isOrder) throw ApiFailure.unknownOrder;
        throw ApiFailure.invalidResponse;
      }
    } on DioException catch (error) {
      if (isOrder) throw ApiFailure.unknownOrder;
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          throw const ApiFailure(
            ApiProblem.timeout,
            'The request timed out. Please try again.',
          );
        case DioExceptionType.connectionError:
          throw const ApiFailure(
            ApiProblem.offline,
            'The store could not be reached. Check your connection.',
          );
        case DioExceptionType.badResponse:
          throw ApiFailure.fromStatus(error.response?.statusCode ?? 0);
        default:
          throw const ApiFailure(
            ApiProblem.other,
            'The store connection could not be completed.',
          );
      }
    } finally {
      if (isOrder) _submitting = false;
    }
  }

  Future<void> signInAndStore({
    required String email,
    required String password,
    required VerifiedResponse<String> contract,
  }) async {
    if (!enabled || contract.operation != CustomerOperation.login) {
      throw ApiFailure.contract;
    }
    final original = await sessions.snapshot();
    final token = await execute(
      CustomerRequest.login(email: email, password: password),
      contract: contract,
    );
    if (!await sessions.replaceIfCurrent(original, token)) {
      throw const ApiFailure(
        ApiProblem.conflict,
        'Your sign-in session changed. Please try again.',
      );
    }
  }

  Future<void> signOutLocally() => sessions.clear();
  void close() => _dio.close(force: true);
}
