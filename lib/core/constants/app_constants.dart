import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  static bool get isProduction {
    if (kReleaseMode) {
      return true;
    }
    if (dotenv.isInitialized) {
      final envVal = dotenv.maybeGet('IS_PRODUCTION');
      if (envVal != null) {
        return envVal.toLowerCase() == 'true';
      }
    }
    return const bool.fromEnvironment('IS_PRODUCTION', defaultValue: false);
  }

  static const String appName = 'Journal Publication Trend';
  static const int connectTimeoutSeconds = 30;
  static const int receiveTimeoutSeconds = 30;

  /// Central SSO redirect path served by this app at
  /// `http://localhost:<current-port>/auth/callback`.
  static const String ssoCallbackPath = '/auth/callback';

  /// Fallback redirect URI for non-web platforms; on web the real origin
  /// is used (see data/datasources/sso_redirect_uri.dart).
  static const String ssoDefaultRedirectUri =
      'http://localhost:3003$ssoCallbackPath';
}
