import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

Future<void> startLocalBackend() async {
  if (!Platform.isWindows || !kReleaseMode) return;

  const port = 8000;
  final healthUri = Uri.parse('http://127.0.0.1:$port/health');
  if (await _isHealthy(healthUri)) return;

  final executableDirectory = File(Platform.resolvedExecutable).parent;
  final backend = File(
    '${executableDirectory.path}${Platform.pathSeparator}backend'
    '${Platform.pathSeparator}jsm_backend.exe',
  );
  if (!await backend.exists()) {
    throw StateError('Local backend was not found next to the installed app.');
  }

  final environment = Map<String, String>.from(Platform.environment)
    ..['LOCAL_DATA_DIR'] =
        '${Platform.environment['LOCALAPPDATA'] ?? Platform.environment['USERPROFILE'] ?? executableDirectory.path}'
        '${Platform.pathSeparator}HyperDataLab${Platform.pathSeparator}JSM'
    ..['LOCAL_MODE'] = 'true'
    ..['DEBUG'] = 'false'
    ..['ENVIRONMENT'] = 'desktop'
    ..['API_PORT'] = '$port'
    ..['SSO_ISSUER_URL'] = const String.fromEnvironment(
      'SSO_ISSUER_URL',
      defaultValue: 'https://auth-api.hyperdatalab.org',
    )
    ..['JSM_PARENT_PID'] = '${pid}';

  final process = await Process.start(
    backend.path,
    const [],
    workingDirectory: executableDirectory.path,
    environment: environment,
    runInShell: false,
  );
  process.stdout.transform(utf8.decoder).listen((line) {
    debugPrint('[local-api] $line');
  });
  process.stderr.transform(utf8.decoder).listen((line) {
    debugPrint('[local-api] $line');
  });

  final deadline = DateTime.now().add(const Duration(seconds: 45));
  while (DateTime.now().isBefore(deadline)) {
    if (await _isHealthy(healthUri)) return;
    if (await process.exitCode.timeout(
          const Duration(milliseconds: 50),
          onTimeout: () => -1,
        ) !=
        -1) {
      throw StateError('The local backend stopped before becoming ready.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }
  throw StateError('The local backend did not become ready within 45 seconds.');
}

Future<bool> _isHealthy(Uri uri) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 1);
  try {
    final request = await client
        .getUrl(uri)
        .timeout(const Duration(seconds: 2));
    final response = await request.close().timeout(const Duration(seconds: 2));
    final body = await response.transform(utf8.decoder).join();
    final health = jsonDecode(body);
    return response.statusCode == HttpStatus.ok &&
        health is Map<String, dynamic> &&
        health['local_mode'] == true;
  } catch (_) {
    return false;
  } finally {
    client.close(force: true);
  }
}
