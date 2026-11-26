import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: kReleaseMode ? 'production' : 'development',
  );
  static const demo =
      !kReleaseMode &&
      environment == 'development' &&
      bool.fromEnvironment('DEMO_MODE', defaultValue: true);
  static const checkoutReturnUrl = String.fromEnvironment(
    'CHECKOUT_RETURN_URL',
  );
  static const baseUrl = String.fromEnvironment('API_BASE_URL');
}
