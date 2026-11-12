import 'dart:convert';
import 'dart:io';

import 'sso_session_store.dart';

/// In-memory stand-in for non-web platforms. The web build (sessionStorage)
/// is the supported Central SSO target; desktop persistence is out of scope.
class MemorySsoSessionStore implements SsoSessionStore {
  final _map = <String, String>{};

  @override
  String? read(String key) => _map[key];

  @override
  void write(String key, String value) => _map[key] = value;

  @override
  void remove(String key) => _map.remove(key);
}

class FileSsoSessionStore implements SsoSessionStore {
  FileSsoSessionStore() {
    try {
      final decoded = jsonDecode(_file.readAsStringSync());
      if (decoded is Map<String, dynamic>) {
        _map.addAll(decoded.map((key, value) => MapEntry(key, value.toString())));
      }
    } catch (_) {
      // A missing or malformed local session is treated as signed out.
    }
  }

  final Map<String, String> _map = {};

  File get _file {
    final root = Platform.environment['LOCALAPPDATA'] ??
        Platform.environment['HOME'] ??
        Directory.current.path;
    return File('$root${Platform.pathSeparator}HyperDataLab'
        '${Platform.pathSeparator}JSM${Platform.pathSeparator}auth_session.json');
  }

  void _persist() {
    final file = _file;
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(_map), flush: true);
  }

  @override
  String? read(String key) => _map[key];

  @override
  void write(String key, String value) {
    _map[key] = value;
    _persist();
  }

  @override
  void remove(String key) {
    _map.remove(key);
    _persist();
  }
}

SsoSessionStore createSsoSessionStore() =>
    const bool.fromEnvironment('JSM_LOCAL_DESKTOP')
    ? FileSsoSessionStore()
    : MemorySsoSessionStore();
