Future<String> exportLocalData(Future<String?> Function() tokenProvider) async =>
    throw UnsupportedError('Local data export is available in the Windows app.');

Future<void> importLocalData(
  String archivePath,
  Future<String?> Function() tokenProvider,
) async =>
    throw UnsupportedError('Local data import is available in the Windows app.');
