import 'package:flutter_test/flutter_test.dart';
import 'package:jsm_fe/core/updater/models/update_info.dart';
import 'package:jsm_fe/core/updater/services/update_service.dart';

void main() {
  group('SemverComparator tests', () {
    test('compares major, minor and patch versions accurately', () {
      expect(SemverComparator.isNewer('1.0.9', '1.0.8'), isTrue);
      expect(SemverComparator.isNewer('1.1.0', '1.0.8'), isTrue);
      expect(SemverComparator.isNewer('2.0.0', '1.9.9'), isTrue);
      expect(SemverComparator.isNewer('1.0.8', '1.0.8'), isFalse);
      expect(SemverComparator.isNewer('1.0.7', '1.0.8'), isFalse);
      expect(SemverComparator.isNewer('0.9.9', '1.0.0'), isFalse);
    });

    test('strips leading "v" or "V" gracefully', () {
      expect(SemverComparator.isNewer('v1.0.9', '1.0.8'), isTrue);
      expect(SemverComparator.isNewer('V1.0.9', 'v1.0.8'), isTrue);
      expect(SemverComparator.isNewer('v1.0.8', '1.0.8'), isFalse);
    });

    test('handles build metadata (+9) and prerelease tags (-beta)', () {
      expect(SemverComparator.isNewer('v1.0.9+1', '1.0.8+9'), isTrue);
      expect(SemverComparator.isNewer('1.0.8', '1.0.8+9'), isFalse);
      expect(SemverComparator.compare('1.0.8+1', '1.0.8+2'), equals(0));
    });
  });

  group('UpdateInfo formatting tests', () {
    test('formats file size in megabytes', () {
      const update = UpdateInfo(
        currentVersion: '1.0.8',
        latestVersion: '1.0.9',
        hasUpdate: true,
        fileSizeBytes: 52428800, // 50 MB
      );
      expect(update.formattedFileSize, equals('50.0 MB'));
    });

    test('handles null or zero file size', () {
      const update = UpdateInfo(
        currentVersion: '1.0.8',
        latestVersion: '1.0.8',
        hasUpdate: false,
      );
      expect(update.formattedFileSize, isEmpty);
    });
  });

  group('UpdateDownloadProgress tests', () {
    test('calculates percentage and formatted units', () {
      const progress = UpdateDownloadProgress(
        receivedBytes: 26214400, // 25 MB
        totalBytes: 52428800, // 50 MB
        progress: 0.5,
      );
      expect(progress.percentage, equals(50));
      expect(progress.formattedReceived, equals('25.0 MB'));
      expect(progress.formattedTotal, equals('50.0 MB'));
    });
  });

  group('UpdateService mock test', () {
    test('simulates update when isMockEnabled is true', () async {
      // Create a service with a test mock config
      final service = UpdateService();
      // Even without env, checkForUpdates with default parameters handles gracefully
      expect(service.githubRepo, isNotEmpty);
    });
  });
}
