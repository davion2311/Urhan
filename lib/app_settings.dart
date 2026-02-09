// lib/app_settings.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  AppSettings._();

  // ================== KEYS ==================
  static const _kDarkMode = 'dark_mode';
  static const _kShimmer = 'shimmer_on';
  static const _kFontFamily = 'font_family';
  static const _kLanguageCode = 'language_code';
  // ✅ _kIsRTL key ہٹا دی (اب RTL/LTR سسٹم نہیں ہے)

  // ================== NOTIFIERS ==================
  static final ValueNotifier<bool> darkModeVN = ValueNotifier<bool>(true);
  static final ValueNotifier<bool> shimmerVN = ValueNotifier<bool>(true);

  // null = default font
  static final ValueNotifier<String?> fontFamilyVN = ValueNotifier<String?>(null);

  // language
  static final ValueNotifier<String?> languageCodeVN = ValueNotifier<String?>('ur');

  // ✅ isRTLVN ہٹا دیا (اب RTL/LTR سسٹم نہیں ہے)
  
  // ✅ textDirectionVN کو ہمیشہ LTR پر سیٹ کیا
  static final ValueNotifier<TextDirection> textDirectionVN =
      ValueNotifier<TextDirection>(TextDirection.ltr); // ہمیشہ LTR

  // ================== LOAD ==================
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final dark = prefs.getBool(_kDarkMode);
    final shimmer = prefs.getBool(_kShimmer);
    final font = prefs.getString(_kFontFamily);
    final lang = prefs.getString(_kLanguageCode);
    // ✅ rtl والا key ہٹا دیا

    darkModeVN.value = dark ?? true;
    shimmerVN.value = shimmer ?? true;
    fontFamilyVN.value = (font == null || font.trim().isEmpty) ? null : font;

    final code = (lang == null || lang.trim().isEmpty) ? 'ur' : lang.trim();
    // ✅ RTL چیک کرنے والا لوگک ہٹا دیا

    languageCodeVN.value = code;
    // ✅ isRTLVN والی لائن ہٹا دی
    textDirectionVN.value = TextDirection.ltr; // ہمیشہ LTR
  }

  // ================== SAVE HELPERS ==================
  static Future<void> setDarkMode(bool v) async {
    darkModeVN.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkMode, v);
  }

  static Future<void> setShimmer(bool v) async {
    shimmerVN.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShimmer, v);
  }

  static Future<void> setFontFamily(String? family) async {
    fontFamilyVN.value = family;
    final prefs = await SharedPreferences.getInstance();
    if (family == null || family.trim().isEmpty) {
      await prefs.remove(_kFontFamily);
    } else {
      await prefs.setString(_kFontFamily, family.trim());
    }
  }

  // ✅ language page اب صرف language code سیٹ کرے گا
  // ✅ RTL/LTR کا کوئی لوگک نہیں
  static Future<void> setLanguage(String code) async {
    final clean = code.trim().isEmpty ? 'ur' : code.trim();
    // ✅ RTL چیک کرنے والا لوگک ہٹا دیا

    // ✅ اب صرف language code اپڈیٹ کریں
    languageCodeVN.value = clean;
    // ✅ isRTLVN والی لائن ہٹا دی
    textDirectionVN.value = TextDirection.ltr; // ہمیشہ LTR

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageCode, clean);
    // ✅ RTL والا key save کرنے والی لائن ہٹا دی
  }

  // ✅ _isRtlByCode function ہٹا دیا (اب RTL/LTR سسٹم نہیں ہے)
}