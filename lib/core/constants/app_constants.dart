import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  static bool get isProduction {
    if (dotenv.isInitialized) {
      final envVal = dotenv.maybeGet('IS_PRODUCTION');
      if (envVal != null) {
        return envVal.toLowerCase() == 'true';
      }
    }
    if (const bool.hasEnvironment('IS_PRODUCTION')) {
      return const bool.fromEnvironment('IS_PRODUCTION');
    }
    if (kReleaseMode) {
      return true;
    }
    return false;
  }

  static const String appName = 'Journal Publication Trend';
  static const String appVersion = '1.0.8';
  static const String appBuildNumber = '9';
  static const String defaultGithubRepo = 'ResearchPulse/jsm-fe';
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
