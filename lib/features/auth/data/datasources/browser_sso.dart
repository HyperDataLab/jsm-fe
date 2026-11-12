import 'dart:async';

import 'package:web/web.dart' as web;

import '../../../../core/constants/api_endpoints.dart';

/// Browser-only helpers for the SSO flow. Keep all `window` usage in this
/// file (plus browser_*.dart) -- never in widgets or business logic.
/// The redirect URI is configurable (SSO_REDIRECT_URI); when the app is
/// actually served from the configured origin we use the live origin so
/// dev ports other than the default still work.
String currentRedirectUri() {
  final origin = web.window.location.origin;
  if (origin.isNotEmpty && origin != 'null') {
    return '$origin/auth/callback';
  }
  return ApiEndpoints.ssoRedirectUri;
}

Uri currentBrowserUri() => Uri.parse(web.window.location.href);

/// Replaces the callback query parameters and path in browser history
/// and closes the popup window if running inside one.
void cleanCallbackFromHistory() {
  if (web.window.opener != null) {
    try {
      web.window.close();
      return;
    } catch (_) {}
  }
  web.window.history.replaceState(null, '', '/');
}

/// Opens the SSO authorize URL in a dedicated popup window and awaits its closure.
Future<void> navigateToUrl(String url) async {
  final popup = web.window.open(
    url,
    'sso_auth_popup',
    'width=600,height=750,menubar=no,toolbar=no,location=no,status=no',
  );

  if (popup == null) {
    // Popup was blocked by browser, fallback to full page redirect
    web.window.location.href = url;
    return;
  }

  final completer = Completer<void>();
  Timer.periodic(const Duration(milliseconds: 300), (timer) {
    if (popup.closed) {
      timer.cancel();
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  });

  return completer.future;
}
