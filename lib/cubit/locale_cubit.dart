import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App language, English ⇄ Arabic. Shared/domain state (the whole tree — layout
/// direction, every label — reacts to it), so it's a cubit, not local widget
/// state. The choice is persisted so it survives a relaunch.
class LocaleCubit extends Cubit<Locale> {
  static const en = Locale('en');
  static const ar = Locale('ar');
  static const _prefsKey = 'locale';

  LocaleCubit([super.initial = en]);

  bool get isArabic => state.languageCode == 'ar';

  /// Read the saved language (if any) before the app builds, so we open in the
  /// user's last choice with no flash of the wrong direction. Defaults to [en].
  static Future<Locale> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey) == 'ar' ? ar : en;
  }

  void toggle() => setLocale(isArabic ? en : ar);

  void setLocale(Locale locale) {
    if (locale == state) return;
    emit(locale);
    _persist(locale);
  }

  Future<void> _persist(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }
}
