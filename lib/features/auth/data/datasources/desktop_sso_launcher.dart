import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/auth_provider.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/usecases/auth_launcher.dart';
import 'browser_sso_seam.dart';
import 'oidc_auth.dart';
import 'sso_auth_launcher.dart';
import 'sso_session_store.dart';
import 'sso_session_store_io.dart';

typedef BrowserLauncher = Future<bool> Function(String url);

/// Exit future for the dedicated Windows Edge window, when available.
Future<void>? _defaultBrowserExit;
Process? _defaultSsoBrowserProcess;

void _closeDefaultSsoBrowser() {
  final process = _defaultSsoBrowserProcess;
  _defaultSsoBrowserProcess = null;
  if (process != null) {
    try {
      process.kill();
    } catch (_) {}
  }
}

/// Launches the browser on Desktop platforms using pure dart:io (no native plugin needed).
/// On Windows, it attempts to launch Edge in app mode for a clean embedded-window appearance.
Future<bool> defaultDesktopBrowserLauncher(String url) async {
  _defaultBrowserExit = null;
  _defaultSsoBrowserProcess = null;
  if (Platform.isWindows) {
    // 1. Try launching Microsoft Edge in app mode (frameless window)
    const edgePaths = [
      r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
      r'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
      'msedge.exe',
    ];
    for (final edgePath in edgePaths) {
      try {
        if (edgePath == 'msedge.exe' || File(edgePath).existsSync()) {
          // An isolated profile keeps this Edge process tied to the SSO
          // window. Its exit tells the app when the user closes that window.
          final profile = await Directory.systemTemp.createTemp('jsm_sso_');
          final process = await Process.start(edgePath, [
            '--user-data-dir=${profile.path}',
            '--inprivate',
            '--disable-background-mode',
            '--no-first-run',
            '--app=$url',
            '--window-size=520,720',
          ]);
          _defaultSsoBrowserProcess = process;
          final processExit = process.exitCode.then((_) async {
            try {
              await profile.delete(recursive: true);
            } catch (_) {}
          });
          // Edge can keep a background process alive after its app window is
          // closed. Watch the top-level window as well as the process handle.
          _defaultBrowserExit = Future.any<void>([
            processExit,
            _watchWindowsBrowserWindow(process),
          ]);
          return true;
        }
      } catch (_) {}
    }

    // 2. Fallback to rundll32 url.dll,FileProtocolHandler (preserves '&' and query parameters)
    try {
      final res = await Process.run('rundll32', [
        'url.dll,FileProtocolHandler',
        url,
      ]);
      if (res.exitCode == 0) return true;
    } catch (_) {}

    // 3. Fallback to cmd.exe start with properly escaped ampersands (^&)
    try {
      final escapedUrl = url.replaceAll('&', '^&');
      await Process.run('cmd.exe', ['/c', 'start', '', escapedUrl]);
      return true;
    } catch (_) {
      return false;
    }
  } else if (Platform.isMacOS) {
    try {
      await Process.run('open', [url]);
      return true;
    } catch (_) {
      return false;
    }
  } else if (Platform.isLinux) {
    try {
      await Process.run('xdg-open', [url]);
      return true;
    } catch (_) {
      return false;
    }
  }
  return false;
}

Future<void> _watchWindowsBrowserWindow(Process process) async {
  var hasSeenWindow = false;
  var consecutiveMissingChecks = 0;
  while (true) {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    try {
      final script =
          '\$p = Get-Process -Id ${process.pid} -ErrorAction SilentlyContinue; '
          'if (\$null -eq \$p) { Write-Output CLOSED } '
          'elseif (\$p.MainWindowHandle -ne 0) { Write-Output OPEN } '
          'else { Write-Output WAIT }';
      final result = await Process.run('powershell.exe', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        script,
      ]);
      final status = (result.stdout as String).trim();
      if (status == 'CLOSED') return;
      if (status == 'OPEN') {
        hasSeenWindow = true;
        consecutiveMissingChecks = 0;
      } else if (hasSeenWindow && ++consecutiveMissingChecks >= 3) {
        return;
      }
    } catch (_) {
      // The process exit future remains as a fallback if window polling fails.
      return;
    }
  }
}

/// Desktop implementation of the Central SSO flow:
/// 1. builds the same PKCE/S256 authorize URL as the web launcher,
/// 2. opens the user's browser in standalone app mode,
/// 3. runs a one-shot loopback HTTP server on localhost:5173 that receives
///    the SSO redirect at /auth/callback (the configured SSO_REDIRECT_URI),
/// 4. completes the token exchange + userinfo with the shared launcher code.
class DesktopSsoLauncher extends SsoAuthLauncher {
  final int listenPort;
  final BrowserLauncher browserLauncher;

  DesktopSsoLauncher({
    int? listenPort,
    super.apiClient,
    SsoSessionStore? store,
    BrowserLauncher? browserLauncher,
  }) : listenPort = listenPort ?? _defaultPort(),
       browserLauncher = browserLauncher ?? defaultDesktopBrowserLauncher,
       super(store: store ?? MemorySsoSessionStore());

  static int _defaultPort() {
    final configured = Uri.tryParse(ApiEndpoints.ssoRedirectUri)?.port;
    if (configured != null && configured > 0) return configured;
    return 5173;
  }

  HttpServer? _server;
  Completer<Uri> _callback = Completer<Uri>();
  Future<void>? _browserClosed;

  @override
  Future<void> start(AuthProvider provider) async {
    _callback = Completer<Uri>();
    _browserClosed = null;
    _defaultBrowserExit = null;
    _defaultSsoBrowserProcess = null;
    await _startLoopbackServer();
    final redirectUri = 'http://localhost:$listenPort/auth/callback';
    final pending = OidcAuthUrlBuilder.createPendingRequest();
    store.write(
      SsoSessionKeys.pendingRequest,
      jsonEncode({
        'state': pending.state,
        'code_verifier': pending.codeVerifier,
      }),
    );
    final url = urlBuilder.build(
      provider: provider,
      redirectUri: redirectUri,
      state: pending.state,
      codeChallenge: OidcAuthUrlBuilder.createCodeChallenge(
        pending.codeVerifier,
      ),
    );
    final ok = await browserLauncher(url);
    _browserClosed = _defaultBrowserExit;
    if (!ok) {
      await _server?.close(force: true);
      _server = null;
      throw const AuthLauncherException('Could not launch the login window.');
    }
  }

  /// Waits for the browser redirect, then completes the SSO exchange.
  Future<AuthResult> awaitCallbackAndComplete() async {
    try {
      final closed = _browserClosed;
      final uri =
          await (closed == null
                  ? _callback.future
                  : Future.any([
                      _callback.future,
                      closed.then<Uri>(
                        (_) => throw const AuthLauncherException(
                          'Login was cancelled.',
                        ),
                      ),
                    ]))
              .timeout(
                const Duration(minutes: 5),
                onTimeout: () => throw const AuthLauncherException(
                  'Login timed out. Please try again.',
                ),
              );
      return await completeFromLoopbackCallback(uri);
    } catch (_) {
      await _server?.close(force: true);
      _server = null;
      store.remove(SsoSessionKeys.pendingRequest);
      rethrow;
    }
  }

  Future<void> _startLoopbackServer() async {
    if (_server != null) return;
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, listenPort);
    } on SocketException {
      // Port busy: a previous server may still be running; reuse it.
      if (_server != null) return;
      throw AuthLauncherException(
        'Port $listenPort is already in use. Close other apps and retry.',
      );
    }
    _server!.listen((request) async {
      final uri = Uri.parse('http://localhost:$listenPort${request.uri}');
      final isCallback = uri.path == AppConstants.ssoCallbackPath;
      final responded = _respondBrowserPage(request, isCallback);
      if (isCallback && !_callback.isCompleted) _callback.complete(uri);
      await responded;
    });
  }

  /// Same completion logic as the web flow, but against an arbitrary loopback
  /// URI instead of the browser's current page.
  Future<AuthResult> completeFromLoopbackCallback(Uri uri) async {
    await _server?.close();
    _server = null;
    // Reuse the parent class validation/exchange by temporarily pointing the
    // browser seam at the loopback callback URI.
    BrowserSso.currentUri = () => uri;
    BrowserSso.redirectUri = () => 'http://localhost:$listenPort/auth/callback';
    BrowserSso.cleanHistory = () {};
    try {
      return await completeFromCallback();
    } finally {
      BrowserSso.resetToDefaults();
      // Edge app windows are not script-opened, so window.close() in the
      // callback page is ignored. Close the dedicated browser process after
      // callback exchange finishes instead.
      _closeDefaultSsoBrowser();
    }
  }

  /// Raw socket requests bypass TestWidgetsFlutterBinding's HTTP mock, so
  /// tests must opt out of the binding before using the loopback server.
  bool get loopbackServerRunning => _server != null;

  Future<void> _respondBrowserPage(HttpRequest request, bool success) async {
    request.response.headers.contentType = ContentType.html;
    request.response.write(
      success
          ? '<!DOCTYPE html><html><head><meta charset="utf-8">'
                '<title>Login Successful</title>'
                '<script>setTimeout(function(){window.close();}, 800);</script>'
                '</head><body style="font-family:sans-serif;text-align:center;padding-top:80px">'
                '<h2 style="color:#2e7d32;">&#10004; Đăng nhập thành công</h2>'
                '<p>Cửa sổ này sẽ tự động đóng và quay lại ứng dụng.</p>'
                '<script>window.close();</script></body></html>'
          : '<!DOCTYPE html><html><body style="font-family:sans-serif;padding-top:80px">'
                '<p>Waiting for sign-in&hellip;</p></body></html>',
    );
    await request.response.close();
  }

  @override
  void clearSession() {
    if (!_callback.isCompleted) {
      _callback.completeError(const AuthLauncherException('Login cancelled.'));
    }
    _server?.close(force: true);
    _server = null;
    super.clearSession();
  }
}
