import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage_service.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('ar')) {
    _load();
  }

  Future<void> _load() async {
    final code = await StorageService.getLocaleCode();
    if (code == null || code.isEmpty) return;
    state = Locale(code);
  }

  Future<void> setLanguageCode(String code) async {
    state = Locale(code);
    await StorageService.saveLocaleCode(code);
  }
}
