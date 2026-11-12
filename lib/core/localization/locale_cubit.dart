import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'locale_storage.dart';

class LocaleCubit extends Cubit<Locale> {
  final LocaleStorage _storage;

  LocaleCubit({LocaleStorage? storage})
    : _storage = storage ?? LocaleStorage(),
      super(const Locale('en')) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final savedCode = await _storage.loadLocale();
      if (savedCode == 'vi') {
        emit(const Locale('vi'));
      } else if (savedCode == 'en') {
        emit(const Locale('en'));
      }
    } catch (_) {}
  }

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode == state.languageCode) return;
    emit(locale);
    try {
      await _storage.saveLocale(locale.languageCode);
    } catch (_) {}
  }

  Future<void> toggleLocale() async {
    final newLocale = state.languageCode == 'en'
        ? const Locale('vi')
        : const Locale('en');
    await setLocale(newLocale);
  }
}
