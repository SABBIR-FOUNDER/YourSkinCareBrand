enum ApiProblem {
  contract,
  configuration,
  validation,
  signInRequired,
  forbidden,
  missing,
  conflict,
  rateLimited,
  server,
  offline,
  timeout,
  badPayload,
  redirect,
  storage,
  unknownOrder,
  inProgress,
  other,
}

final class ApiFailure implements Exception {
  const ApiFailure(this.problem, this.message);
  final ApiProblem problem;
  final String message;

  static const contract = ApiFailure(
    ApiProblem.contract,
    'This feature is waiting for a verified store connection.',
  );
  static const configuration = ApiFailure(
    ApiProblem.configuration,
    'The store connection has not been configured.',
  );
  static const invalidResponse = ApiFailure(
    ApiProblem.badPayload,
    'The store returned an unreadable response. Please try again later.',
  );
  static const unknownOrder = ApiFailure(
    ApiProblem.unknownOrder,
    'Order status is unknown. Check your existing order before trying again.',
  );
  static const storage = ApiFailure(
    ApiProblem.storage,
    'Your secure session could not be accessed. Please try again.',
  );

  static ApiFailure fromStatus(int status) {
    if (status >= 300 && status < 400) {
      return const ApiFailure(
        ApiProblem.redirect,
        'The store redirected this request.',
      );
    }
    if (status >= 500 && status != 504) {
      return const ApiFailure(
        ApiProblem.server,
        'The store is temporarily unavailable.',
      );
    }
    return switch (status) {
      400 || 422 => const ApiFailure(
        ApiProblem.validation,
        'Please check your details and try again.',
      ),
      401 => const ApiFailure(
        ApiProblem.signInRequired,
        'Please sign in to continue.',
      ),
      403 => const ApiFailure(
        ApiProblem.forbidden,
        'This action is unavailable for your account.',
      ),
      404 => const ApiFailure(
        ApiProblem.missing,
        'This item could not be found.',
      ),
      408 ||
      504 => const ApiFailure(ApiProblem.timeout, 'The request timed out.'),
      409 => const ApiFailure(
        ApiProblem.conflict,
        'The store record changed. Refresh to see its current state.',
      ),
      429 => const ApiFailure(
        ApiProblem.rateLimited,
        'Too many requests. Please try again later.',
      ),
      _ => const ApiFailure(
        ApiProblem.other,
        'The request could not be completed.',
      ),
    };
  }

  @override
  String toString() => message;
}
