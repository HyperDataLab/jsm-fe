import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../constants/app_constants.dart';
import '../models/update_info.dart';

class UpdateService {
  final http.Client _client;

  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  /// Gets the configured GitHub repository name (e.g. "ResearchPulse/jsm-fe").
  String get githubRepo {
    const fromEnv = String.fromEnvironment(
      'GITHUB_UPDATE_REPO',
      defaultValue: '',
    );
    if (fromEnv.isNotEmpty) return fromEnv;

    if (dotenv.isInitialized) {
      final repo = dotenv.maybeGet('GITHUB_UPDATE_REPO')?.trim();
      if (repo != null && repo.isNotEmpty) return repo;
    }
    return AppConstants.defaultGithubRepo;
  }

  /// Checks whether mock updates are enabled for local testing.
  bool get isMockEnabled {
    const fromEnv = bool.fromEnvironment('MOCK_UPDATE_ENABLED', defaultValue: false);
    if (fromEnv) return true;

    if (dotenv.isInitialized) {
      final mock = dotenv.maybeGet('MOCK_UPDATE_ENABLED')?.trim().toLowerCase();
      if (mock == 'true' || mock == '1') return true;
    }
    return false;
  }

  /// Checks for available updates from GitHub Releases.
  Future<UpdateInfo> checkForUpdates({String? currentVersion}) async {
    final current = currentVersion ?? AppConstants.appVersion;

    if (isMockEnabled) {
      // Simulation mode for testing UI and update flow
      return UpdateInfo(
        currentVersion: current,
        latestVersion: '1.0.9',
        hasUpdate: true,
        releaseName: 'HyperDataLab JSM v1.0.9',
        releaseNotes:
            '• Tính năng cập nhật trực tiếp (Auto Update) ngay trên phần mềm.\n'
            '• Tối ưu hóa hiệu năng sidecar backend và giao tiếp API cục bộ.\n'
            '• Cải thiện giao diện kiểm tra bản thảo và lịch sử đánh giá.\n'
            '• Sửa lỗi tương thích bộ ký tự và xuất bản báo cáo.',
        publishedAt: DateTime.now(),
        downloadUrl: 'https://example.com/mock-jsm-setup.exe',
        assetName: 'JSM-Setup.exe',
        fileSizeBytes: 54200000,
      );
    }

    final repo = githubRepo;
    final uri = Uri.parse('https://api.github.com/repos/$repo/releases/latest');

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'HyperDataLab-JSM-Updater',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 404) {
        // No releases have been published yet in the repository
        return UpdateInfo(
          currentVersion: current,
          latestVersion: current,
          hasUpdate: false,
          releaseNotes:
              'Chưa có bản phát hành mới nào trên kho lưu trữ $repo.',
        );
      }

      if (response.statusCode != 200) {
        throw HttpException(
          'GitHub API returned HTTP ${response.statusCode}: ${response.body}',
        );
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      final rawTag = (data['tag_name'] as String?)?.trim() ?? '';
      final releaseName = (data['name'] as String?) ?? rawTag;
      final releaseNotes = (data['body'] as String?) ?? '';
      final publishedAtStr = data['published_at'] as String?;
      final publishedAt =
          publishedAtStr != null ? DateTime.tryParse(publishedAtStr) : null;

      // Extract installer asset (prefer *.exe with "setup" in name, or any *.exe)
      final assets = (data['assets'] as List<dynamic>?) ?? [];
      Map<String, dynamic>? selectedAsset;

      for (final asset in assets) {
        if (asset is Map<String, dynamic>) {
          final name = (asset['name'] as String?)?.toLowerCase() ?? '';
          if (name.endsWith('.exe')) {
            if (name.contains('setup') || selectedAsset == null) {
              selectedAsset = asset;
            }
          }
        }
      }

      final assetName = selectedAsset?['name'] as String?;
      final downloadUrl = selectedAsset?['browser_download_url'] as String?;
      final fileSizeBytes = selectedAsset?['size'] as int?;

      final cleanLatestVersion =
          rawTag.startsWith('v') || rawTag.startsWith('V')
              ? rawTag.substring(1)
              : rawTag;

      final hasUpdate = SemverComparator.isNewer(cleanLatestVersion, current);

      return UpdateInfo(
        currentVersion: current,
        latestVersion: cleanLatestVersion.isNotEmpty ? cleanLatestVersion : current,
        hasUpdate: hasUpdate,
        releaseName: releaseName,
        releaseNotes: releaseNotes,
        publishedAt: publishedAt,
        downloadUrl: downloadUrl,
        assetName: assetName ?? 'JSM-Setup.exe',
        fileSizeBytes: fileSizeBytes,
      );
    } on SocketException {
      throw const SocketException(
        'Không thể kết nối đến máy chủ cập nhật. Vui lòng kiểm tra kết nối mạng.',
      );
    } on TimeoutException {
      throw TimeoutException('Quá thời gian kết nối đến máy chủ cập nhật.');
    }
  }

  /// Downloads the update installer with stream progress.
  Future<String> downloadUpdate(
    UpdateInfo update, {
    required void Function(UpdateDownloadProgress progress) onProgress,
  }) async {
    if (kIsWeb || !Platform.isWindows) {
      throw UnsupportedError('Tự động tải cập nhật chỉ hỗ trợ trên Windows.');
    }

    final downloadUrl = update.downloadUrl;
    if (downloadUrl == null || downloadUrl.isEmpty) {
      throw StateError('Không tìm thấy liên kết tải file cài đặt.');
    }

    // Ensure temp directory exists
    final tempBase = Platform.environment['TEMP'] ?? Directory.systemTemp.path;
    final updateDir = Directory('$tempBase\\HyperDataLab_JSM_Update');
    if (!await updateDir.exists()) {
      await updateDir.create(recursive: true);
    }

    final fileName = update.assetName ?? 'JSM-Setup.exe';
    final targetFile = File('${updateDir.path}\\$fileName');

    if (isMockEnabled && downloadUrl.contains('example.com')) {
      // Simulate download progress smoothly
      const totalSteps = 30;
      final total = update.fileSizeBytes ?? 54200000;
      for (var i = 1; i <= totalSteps; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 70));
        final received = (total * (i / totalSteps)).toInt();
        onProgress(
          UpdateDownloadProgress(
            receivedBytes: received,
            totalBytes: total,
            progress: i / totalSteps,
          ),
        );
      }
      await targetFile.writeAsString('mock setup installer');
      return targetFile.path;
    }

    final request = http.Request('GET', Uri.parse(downloadUrl));
    final response = await _client.send(request);

    if (response.statusCode >= 400) {
      throw HttpException('Tải bản cập nhật thất bại (HTTP ${response.statusCode}).');
    }

    final totalBytes = response.contentLength ?? (update.fileSizeBytes ?? 0);
    var receivedBytes = 0;

    final sink = targetFile.openWrite();
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        final progress =
            totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;
        onProgress(
          UpdateDownloadProgress(
            receivedBytes: receivedBytes,
            totalBytes: totalBytes,
            progress: progress,
          ),
        );
      }
      await sink.flush();
    } finally {
      await sink.close();
    }

    return targetFile.path;
  }

  /// Executes the downloaded installer silently and restarts the app.
  Future<void> executeSilentUpdateAndRestart(String installerPath) async {
    if (kIsWeb || !Platform.isWindows) {
      throw UnsupportedError('Cài đặt tự động chỉ hỗ trợ trên Windows.');
    }

    final installerFile = File(installerPath);
    if (!await installerFile.exists()) {
      throw StateError('Không tìm thấy file cài đặt: $installerPath');
    }

    final localAppData = Platform.environment['LOCALAPPDATA'];
    final defaultInstalledExe = localAppData != null
        ? File('$localAppData\\Programs\\HyperDataLab\\JSM\\jsm_fe.exe')
        : null;

    final appExePath =
        (defaultInstalledExe != null && await defaultInstalledExe.exists())
            ? defaultInstalledExe.path
            : Platform.resolvedExecutable;

    final tempBase = Platform.environment['TEMP'] ?? Directory.systemTemp.path;
    final batFile = File('$tempBase\\HyperDataLab_JSM_Update\\run_update.bat');

    // Create the batch script that waits for Flutter to terminate,
    // terminates any remaining backend sidecar, executes the silent installer,
    // and restarts the newly installed application.
    final batContent = '''
@echo off
chcp 65001 >nul
echo [HyperDataLab JSM] Preparing to update...
timeout /t 2 /nobreak >nul

:: Terminate running processes to ensure clean overwrite
taskkill /F /IM jsm_backend.exe >nul 2>&1
taskkill /F /IM jsm_fe.exe >nul 2>&1
timeout /t 1 /nobreak >nul

:: Execute Inno Setup silently
echo [HyperDataLab JSM] Running silent installer...
"${installerFile.path}" /SILENT /SP- /SUPPRESSMSGBOXES /FORCECLOSEAPPLICATIONS

:: Relaunch the application
echo [HyperDataLab JSM] Restarting application...
start "" "$appExePath"
exit
''';

    await batFile.writeAsString(batContent, encoding: utf8);

    // Launch batch runner detached
    await Process.start(
      'cmd.exe',
      ['/c', batFile.path],
      mode: ProcessStartMode.detached,
    );

    // Clean exit of current process
    exit(0);
  }

  void dispose() {
    _client.close();
  }
}
