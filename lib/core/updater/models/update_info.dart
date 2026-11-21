class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final bool hasUpdate;
  final String releaseName;
  final String releaseNotes;
  final DateTime? publishedAt;
  final String? downloadUrl;
  final String? assetName;
  final int? fileSizeBytes;

  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.hasUpdate,
    this.releaseName = '',
    this.releaseNotes = '',
    this.publishedAt,
    this.downloadUrl,
    this.assetName,
    this.fileSizeBytes,
  });

  String get formattedFileSize {
    if (fileSizeBytes == null || fileSizeBytes! <= 0) return '';
    final mb = fileSizeBytes! / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

class UpdateDownloadProgress {
  final int receivedBytes;
  final int totalBytes;
  final double progress; // 0.0 to 1.0

  const UpdateDownloadProgress({
    required this.receivedBytes,
    required this.totalBytes,
    required this.progress,
  });

  String get formattedReceived {
    final mb = receivedBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  String get formattedTotal {
    if (totalBytes <= 0) return '-- MB';
    final mb = totalBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  int get percentage => (progress * 100).clamp(0, 100).toInt();
}

class SemverComparator {
  SemverComparator._();

  /// Returns 1 if v1 > v2, -1 if v1 < v2, 0 if v1 == v2
  static int compare(String v1, String v2) {
    final parts1 = _normalize(v1);
    final parts2 = _normalize(v2);

    final maxLength =
        parts1.length > parts2.length ? parts1.length : parts2.length;
    for (var i = 0; i < maxLength; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  static bool isNewer(String latest, String current) {
    return compare(latest, current) > 0;
  }

  static List<int> _normalize(String version) {
    var clean = version.trim();
    if (clean.startsWith('v') || clean.startsWith('V')) {
      clean = clean.substring(1);
    }
    if (clean.contains('+')) {
      clean = clean.split('+').first;
    }
    if (clean.contains('-')) {
      clean = clean.split('-').first;
    }
    final segments = clean.split('.');
    final result = <int>[];
    for (final seg in segments) {
      final val = int.tryParse(seg);
      if (val != null) {
        result.add(val);
      }
    }
    return result.isEmpty ? [0] : result;
  }
}
