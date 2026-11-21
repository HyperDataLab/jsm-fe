import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../localization/app_localizations.dart';
import '../../models/update_info.dart';
import '../../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateService? updateService;
  final bool autoCheck;

  const UpdateDialog({
    super.key,
    this.updateService,
    this.autoCheck = true,
  });

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const UpdateDialog(),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  late final UpdateService _updateService;
  bool _isChecking = true;
  bool _isDownloading = false;
  bool _isDownloaded = false;
  String? _errorMessage;
  UpdateInfo? _updateInfo;
  UpdateDownloadProgress? _downloadProgress;
  String? _downloadedFilePath;

  @override
  void initState() {
    super.initState();
    _updateService = widget.updateService ?? UpdateService();
    if (widget.autoCheck) {
      _checkForUpdates();
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      final info = await _updateService.checkForUpdates();
      if (!mounted) return;
      setState(() {
        _isChecking = false;
        _updateInfo = info;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isChecking = false;
        _errorMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      });
    }
  }

  Future<void> _startDownload() async {
    final info = _updateInfo;
    if (info == null || info.downloadUrl == null) return;

    setState(() {
      _isDownloading = true;
      _errorMessage = null;
      _downloadProgress = const UpdateDownloadProgress(
        receivedBytes: 0,
        totalBytes: 0,
        progress: 0.0,
      );
    });

    try {
      final filePath = await _updateService.downloadUpdate(
        info,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _downloadProgress = progress;
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _isDownloaded = true;
        _downloadedFilePath = filePath;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _errorMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      });
    }
  }

  Future<void> _installAndRestart() async {
    final path = _downloadedFilePath;
    if (path == null) return;

    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.isVietnamese
                  ? 'Mô phỏng cập nhật thành công! Trên Windows Desktop, ứng dụng sẽ tự động đóng và khởi động lại với bản mới.'
                  : 'Simulation complete! On Windows Desktop, the application will restart with the new version.',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    try {
      await _updateService.executeSilentUpdateAndRestart(path);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 520,
        constraints: const BoxConstraints(maxHeight: 640),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDialogHeader(context, l10n),
            const Divider(color: AppColors.borderSoft, height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildDialogBody(context, l10n),
              ),
            ),
            const Divider(color: AppColors.borderSoft, height: 1),
            _buildDialogFooter(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.system_update_alt_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.checkUpdate,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Manrope',
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 20),
            color: AppColors.textSubtle,
            tooltip: l10n.close,
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildDialogBody(BuildContext context, AppLocalizations l10n) {
    if (_isChecking) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.checkingForUpdates,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontFamily: 'Manrope',
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.updateFailed,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Manrope',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontFamily: 'Manrope',
              ),
            ),
          ],
        ),
      );
    }

    final info = _updateInfo;
    if (info == null || !info.hasUpdate) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.green50,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.green100, width: 1.5),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 38,
                color: AppColors.green700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.upToDateTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Manrope',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.upToDateDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontFamily: 'Manrope',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '${l10n.currentVersionLabel}: v${info?.currentVersion ?? "1.0.8"}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Manrope',
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Has update available!
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Update notification banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.blue100),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.new_releases_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.updateAvailable,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue700,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'v${info.currentVersion}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate600,
                            fontFamily: 'Manrope',
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'v${info.latestVersion}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ),
                        if (info.formattedFileSize.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(${info.formattedFileSize})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.slate600,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Release notes container
        if (info.releaseNotes.isNotEmpty) ...[
          Text(
            l10n.releaseNotesLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 180),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                info.releaseNotes,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: AppColors.textPrimary,
                  fontFamily: 'Manrope',
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],

        // Download progress or readiness indicator
        if (_isDownloading) ...[
          Text(
            l10n.downloadingUpdate,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _downloadProgress?.progress ?? 0.0,
              minHeight: 8,
              backgroundColor: AppColors.slate100,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_downloadProgress?.formattedReceived ?? "0 MB"} / ${_downloadProgress?.formattedTotal ?? "-- MB"}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Manrope',
                ),
              ),
              Text(
                '${_downloadProgress?.percentage ?? 0}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
        ] else if (_isDownloaded) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.green50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.green100),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.green700,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.downloadComplete,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green700,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.restartAndUpdateDesc,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDialogFooter(BuildContext context, AppLocalizations l10n) {
    if (_isChecking) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(l10n.close),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _checkForUpdates,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final info = _updateInfo;
    if (info == null || !info.hasUpdate) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(l10n.close),
            ),
          ],
        ),
      );
    }

    // Has update
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!_isDownloading && !_isDownloaded) ...[
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(l10n.later),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _startDownload,
              icon: const Icon(Icons.download_rounded, size: 16),
              label: Text(l10n.updateNow),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ] else if (_isDownloading) ...[
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(l10n.close),
            ),
          ] else if (_isDownloaded) ...[
            ElevatedButton.icon(
              onPressed: _installAndRestart,
              icon: const Icon(Icons.restart_alt_rounded, size: 16),
              label: Text(l10n.restartAndUpdate),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green700,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
