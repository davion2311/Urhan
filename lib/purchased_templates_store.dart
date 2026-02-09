// lib/purchased_templates_store.dart
// ✅ Saves FULL template (asset + placed texts) to SharedPreferences (JSON list)
// ✅ Load list for ReceiptPage

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'receipt_template_page.dart';

const String kSavedReceiptTemplatesKey = 'saved_receipt_templates_v2';

class PurchasedTemplatesStore {
  PurchasedTemplatesStore._();

  static Future<List<SavedReceiptTemplate>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(kSavedReceiptTemplatesKey) ?? <String>[];

    final out = <SavedReceiptTemplate>[];
    for (final s in raw) {
      try {
        final j = jsonDecode(s) as Map<String, dynamic>;
        out.add(SavedReceiptTemplate.fromJson(j));
      } catch (_) {}
    }
    return out;
  }

  static Future<void> addSavedTemplate(SavedReceiptTemplate tpl) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(kSavedReceiptTemplatesKey) ?? <String>[];

    final encoded = jsonEncode(tpl.toJson());

    // ✅ avoid duplicates by signature (asset + texts signature)
    final sig = tpl.signature;
    final filtered = <String>[];
    for (final item in raw) {
      try {
        final j = jsonDecode(item) as Map<String, dynamic>;
        final t = SavedReceiptTemplate.fromJson(j);
        if (t.signature != sig) filtered.add(item);
      } catch (_) {
        filtered.add(item);
      }
    }

    filtered.add(encoded);
    await prefs.setStringList(kSavedReceiptTemplatesKey, filtered);
  }

  static Future<void> removeBySignature(String signature) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(kSavedReceiptTemplatesKey) ?? <String>[];

    final keep = <String>[];
    for (final item in raw) {
      try {
        final j = jsonDecode(item) as Map<String, dynamic>;
        final t = SavedReceiptTemplate.fromJson(j);
        if (t.signature != signature) keep.add(item);
      } catch (_) {
        // keep unknown
        keep.add(item);
      }
    }

    await prefs.setStringList(kSavedReceiptTemplatesKey, keep);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kSavedReceiptTemplatesKey);
  }
}