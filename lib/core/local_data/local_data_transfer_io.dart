import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/api_endpoints.dart';

Future<String> exportLocalData(Future<String?> Function() tokenProvider) async {
  final token = await tokenProvider();
  if (token == null || token.isEmpty) throw StateError('Sign in again to export local data.');

  final client = http.Client();
  try {
    final response = await client
        .send(
          http.Request('GET', Uri.parse('${ApiEndpoints.baseUrl}/local-data/export'))
            ..headers['Authorization'] = 'Bearer $token',
        )
        .timeout(const Duration(minutes: 5));
    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw StateError(_errorMessage(body, response.statusCode));
    }

    final profile = Platform.environment['USERPROFILE'] ??
        Platform.environment['LOCALAPPDATA'] ??
        Directory.current.path;
    final exportDirectory = Directory(
      '$profile${Platform.pathSeparator}Documents${Platform.pathSeparator}'
      'HyperDataLab${Platform.pathSeparator}JSM Exports',
    );
    await exportDirectory.create(recursive: true);
    final file = File(
      '${exportDirectory.path}${Platform.pathSeparator}'
      'jsm-local-data-${DateTime.now().toUtc().millisecondsSinceEpoch}.zip',
    );
    await response.stream.pipe(file.openWrite());
    return file.path;
  } finally {
    client.close();
  }
}

Future<void> importLocalData(
  String archivePath,
  Future<String?> Function() tokenProvider,
) async {
  final token = await tokenProvider();
  if (token == null || token.isEmpty) throw StateError('Sign in again to import local data.');
  final normalizedPath = archivePath.trim().replaceAll(RegExp(r'^"|"$'), '');
  final archive = File(normalizedPath);
  if (!await archive.exists()) throw const FileSystemException('Archive file not found.');

  final request = http.MultipartRequest(
    'POST',
    Uri.parse('${ApiEndpoints.baseUrl}/local-data/import'),
  )
    ..headers['Authorization'] = 'Bearer $token'
    ..fields['replace_existing'] = 'true'
    ..files.add(await http.MultipartFile.fromPath('archive_file', archive.path));
  final client = http.Client();
  try {
    final response = await client.send(request).timeout(const Duration(minutes: 10));
    final body = await response.stream.bytesToString();
    if (response.statusCode != 200) {
      throw StateError(_errorMessage(body, response.statusCode));
    }
  } finally {
    client.close();
  }
}

String _errorMessage(String body, int statusCode) {
  try {
    final detail = (jsonDecode(body) as Map<String, dynamic>)['detail'];
    if (detail is String && detail.isNotEmpty) return detail;
  } catch (_) {}
  return 'Local data transfer failed (HTTP $statusCode).';
}
