import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/local_data/local_data_transfer.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_notification.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class LocalDataBackupCard extends StatefulWidget {
  const LocalDataBackupCard({super.key});

  @override
  State<LocalDataBackupCard> createState() => _LocalDataBackupCardState();
}

class _LocalDataBackupCardState extends State<LocalDataBackupCard> {
  final TextEditingController _pathController = TextEditingController();
  bool _working = false;

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    setState(() => _working = true);
    try {
      final path = await exportLocalData(_token);
      if (mounted) {
        AppNotification.showSuccess(
          context,
          '${context.l10n.isVietnamese ? 'Đã lưu bản sao lưu tại' : 'Backup saved to'}\n$path',
          title: context.l10n.success,
        );
      }
    } catch (error) {
      if (mounted) {
        AppNotification.showError(
          context,
          error.toString().replaceFirst('Bad state: ', ''),
          title: context.l10n.error,
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<String?> _token() => context.read<AuthRepository>().currentToken();

  Future<void> _import() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          context.l10n.isVietnamese
              ? 'Khôi phục dữ liệu?'
              : 'Restore local data?',
        ),
        content: Text(
          context.l10n.isVietnamese
              ? 'Dữ liệu hiện tại sẽ được thay bằng dữ liệu trong tệp sao lưu. Một bản dự phòng hiện tại vẫn được giữ lại.'
              : 'This replaces the current local database and documents. A backup of the current data will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.confirm),
          ),
        ],
      ),
    );
    if (accepted != true) return;

    setState(() => _working = true);
    try {
      await importLocalData(path, _token);
      if (mounted) {
        AppNotification.showSuccess(
          context,
          context.l10n.isVietnamese
              ? 'Đã khôi phục dữ liệu. Bản sao lưu trước đó vẫn nằm trong hồ sơ Windows của bạn.'
              : 'Data restored. The previous data backup is retained in your Windows profile.',
          title: context.l10n.success,
        );
      }
    } catch (error) {
      if (mounted) {
        AppNotification.showError(
          context,
          error.toString().replaceFirst('Bad state: ', ''),
          title: context.l10n.error,
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!const bool.fromEnvironment('JSM_LOCAL_DESKTOP')) {
      return const SizedBox.shrink();
    }
    final vi = context.l10n.isVietnamese;
    return Card(
      margin: const EdgeInsets.only(top: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vi ? 'Dữ liệu cục bộ và sao lưu' : 'Local data and backup',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              vi
                  ? 'Dữ liệu chỉ nằm trên máy này. Phiên đã đăng nhập cho phép xem dữ liệu ngoại tuyến tối đa 7 ngày.'
                  : 'Data stays on this machine. Your signed-in session allows offline viewing for up to 7 days.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _working ? null : _export,
              icon: const Icon(Icons.download_rounded),
              label: Text(vi ? 'Xuất dữ liệu' : 'Export data'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _pathController,
              enabled: !_working,
              decoration: InputDecoration(
                labelText: vi ? 'Đường dẫn tệp sao lưu' : 'Backup file path',
                hintText: r'C:\Users\you\AppData\Local\HyperDataLab\JSM\exports\backup.zip',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _working ? null : _import,
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(vi ? 'Nhập và khôi phục' : 'Import and restore'),
            ),
            if (_working) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
