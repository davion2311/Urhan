// lib/control_language.dart
// ✅ Single source of truth for all UI text keys (ByDefault + future pages)
// ✅ Supports Urdu / English / Arabic (you can add more easily)
// ✅ Fixes "Member not found" errors by defining ALL keys used in by_default_page.dart
// ✅ Keeps translations SHORT so pills/capsules don't overflow

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ControlLanguage {
  ControlLanguage._();

  // =========================
  // Storage
  // =========================
  static const String _prefsLangKey = 'app_language_v1';

  // supported language codes
  static const String langUr = 'ur';
  static const String langEn = 'en';
  static const String langAr = 'ar';

  // current language (reactive)
  static final ValueNotifier<String> langVN = ValueNotifier<String>(langUr);

  static String get current => langVN.value;

  static bool get isRtl => current == langUr || current == langAr;

  static TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  /// Call once in main() before runApp()
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsLangKey);
    if (saved != null && saved.trim().isNotEmpty) {
      langVN.value = saved.trim();
    } else {
      langVN.value = langUr; // default
    }
  }

  /// Use this when user selects language in Settings
  static Future<void> setLanguage(String code) async {
    final c = code.trim();
    if (c.isEmpty) return;

    // keep only supported (fallback to ur)
    final normalized = (c == langEn || c == langAr || c == langUr) ? c : langUr;

    if (langVN.value == normalized) return;
    langVN.value = normalized;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsLangKey, normalized);
  }

  // =========================
  // Translation Getter
  // =========================
  static String t(String key) {
    final k = key.trim();
    if (k.isEmpty) return '';

    final lang = current;
    final map = _translations[lang] ?? _translations[langUr]!;
    return map[k] ?? _translations[langUr]![k] ?? k; // fallback: ur -> key
  }

  // =========================
  // TOP CAPSULE KEYS
  // =========================
  static const String cName = 'c_name';
  static const String cSerial = 'c_serial';
  static const String cPhone = 'c_phone';

  // =========================
  // MEASUREMENTS (14)
  // =========================
  static const String mLength = 'm_length';
  static const String mSleeve = 'm_sleeve';
  static const String mWidth = 'm_width';
  static const String mChest = 'm_chest';
  static const String mWaist = 'm_waist';
  static const String mNeck = 'm_neck';
  static const String mRound = 'm_round';
  static const String mHalf = 'm_half';
  static const String mShalwar = 'm_shalwar';
  static const String mPoncha = 'm_poncha';
  static const String mCuff = 'm_cuff';
  static const String mShoulder = 'm_shoulder';
  static const String mAsan = 'm_asan';
  static const String mShalwarRound = 'm_shalwar_round';

  // =========================
  // SMALL ACTIONS (18) + BIG ACTIONS (5)
  // =========================
  static const String aRound = 'a_round';
  static const String aSquare = 'a_square';

  static const String aBenHalf = 'a_ben_half';
  static const String aFullBen = 'a_full_ben';

  static const String aBenSquare = 'a_ben_square';
  static const String aBenRound = 'a_ben_round';

  static const String aNormalCollar = 'a_normal_collar';
  static const String aCollarTipS = 'a_collar_tip_s';

  static const String aBenPattiThin = 'a_ben_patti_thin';
  static const String aChakPattiKaj = 'a_chak_patti_kaj';

  static const String aSimpleDouble = 'a_simple_double';
  static const String aSilkDouble = 'a_silk_double';

  static const String aKanta = 'a_kanta';
  static const String aJali = 'a_jali';

  static const String aOpenSleeves = 'a_open_sleeves';
  static const String aFancyButton = 'a_fancy_button';

  static const String aSimplePajama = 'a_simple_pajama';
  static const String aPocketPajama = 'a_pocket_pajama';

  // Big actions (keep short to fit)
  static const String aOneFrontOneSideShalwar = 'a_1f_1s_shalwar';
  static const String aOneFrontTwoSideShalwar = 'a_1f_2s_shalwar';
  static const String aOneSideOneShalwar = 'a_1s_1_shalwar';
  static const String aTwoSideOneShalwar = 'a_2s_1_shalwar';
  static const String aTwoSide = 'a_2_side';

  // =========================
  // MESSAGES / BUTTONS
  // =========================
  static const String msgCameraDisabled = 'msg_camera_disabled';
  static const String msgViewMode = 'msg_view_mode';
  static const String msgHistoryUpdated = 'msg_history_updated';
  static const String msgSavedToHistory = 'msg_saved_to_history';
  static const String msgSaveFailed = 'msg_save_failed';

  static const String msgDeleteTitle = 'msg_delete_title';
  static const String msgDeleteConfirm = 'msg_delete_confirm';
  static const String msgDeleted = 'msg_deleted';

  static const String msgEditButtonTitle = 'msg_edit_button_title';
  static const String msgEnterNewText = 'msg_enter_new_text';

  static const String btnCancel = 'btn_cancel';
  static const String btnDelete = 'btn_delete';
  static const String btnSave = 'btn_save';

  // =========================
  // TRANSLATIONS
  // =========================
  static final Map<String, Map<String, String>> _translations = {
    // اردو (Default)
    langUr: {
      // top
      cName: 'نام',
      cSerial: 'سیریل',
      cPhone: 'فون نمبر',

      // measurements
      mLength: 'لمبائی',
      mSleeve: 'بازو',
      mWidth: 'تیرا',
      mChest: 'چھاتی',
      mWaist: 'کمر',
      mNeck: 'گلا',
      mRound: 'گھیرا',
      mHalf: 'ہاف',
      mShalwar: 'شلوار',
      mPoncha: 'پانچہ',
      mCuff: 'کف',
      mShoulder: 'کندھا',
      mAsan: 'شلوار آسن',
      mShalwarRound: 'شلوار گھیرا',

      // actions (small)
      aRound: 'گول',
      aSquare: 'چورس',
      aBenHalf: 'بین ہاف',
      aFullBen: 'فل بین',
      aBenSquare: 'بین چورس',
      aBenRound: 'بین گول',
      aNormalCollar: 'نارمل کالر',
      aCollarTipS: 'کالر نوک S',
      aBenPattiThin: 'بین پٹی باریک',
      aChakPattiKaj: 'چاک پٹی کاج',
      aSimpleDouble: 'سمپل ڈبل',
      aSilkDouble: 'ریشمی ڈبل',
      aKanta: 'کانٹا',
      aJali: 'جالی',
      aOpenSleeves: 'کھلے بازو',
      aFancyButton: 'فینس بٹن',
      aSimplePajama: 'سمپل پاجامہ',
      aPocketPajama: 'پاکٹ پاجامہ',

      // actions (big)
      aOneFrontOneSideShalwar: 'ایک سامنے ایک سائیڈ شلوار',
      aOneFrontTwoSideShalwar: 'ایک سامنے دو سائیڈ شلوار',
      aOneSideOneShalwar: 'ایک سائیڈ ایک شلوار',
      aTwoSideOneShalwar: 'دو سائیڈ ایک شلوار',
      aTwoSide: 'دو سائیڈ',

      // messages/buttons
      msgCameraDisabled: '📸 کیمرہ سکینر فی الحال دستیاب نہیں ہے',
      msgViewMode: 'View mode ہے (Edit کے لیے پینسل دبائیں)',
      msgHistoryUpdated: 'History اپڈیٹ ہو گئی ✅',
      msgSavedToHistory: 'History میں محفوظ ہو گیا ✅',
      msgSaveFailed: 'Save failed',

      msgDeleteTitle: 'Delete?',
      msgDeleteConfirm: 'کیا آپ واقعی یہ ریکارڈ ڈیلیٹ کرنا چاہتے ہیں؟',
      msgDeleted: 'ڈیلیٹ ہو گیا ✅',

      msgEditButtonTitle: 'بٹن ایڈٹ کریں',
      msgEnterNewText: 'نیا متن درج کریں',

      btnCancel: 'منسوخ',
      btnDelete: 'Delete',
      btnSave: 'محفوظ کریں',
    },

    // English (SHORT)
    langEn: {
      // top
      cName: 'Name',
      cSerial: 'Serial',
      cPhone: 'Phone',

      // measurements (keep short)
      mLength: 'Length',
      mSleeve: 'Sleeve',
      mWidth: 'Width',
      mChest: 'Chest',
      mWaist: 'Waist',
      mNeck: 'Neck',
      mRound: 'Round',
      mHalf: 'Half',
      mShalwar: 'Shalwar',
      mPoncha: 'Poncha',
      mCuff: 'Cuff',
      mShoulder: 'Shoulder',
      mAsan: 'Asan',
      mShalwarRound: 'S.Round',

      // actions
      aRound: 'Round',
      aSquare: 'Square',
      aBenHalf: 'Half Ben',
      aFullBen: 'Full Ben',
      aBenSquare: 'Ben Sq',
      aBenRound: 'Ben Rd',
      aNormalCollar: 'N.Collar',
      aCollarTipS: 'Tip S',
      aBenPattiThin: 'Thin Patti',
      aChakPattiKaj: 'Chak Kaj',
      aSimpleDouble: 'Simple D',
      aSilkDouble: 'Silk D',
      aKanta: 'Kanta',
      aJali: 'Jali',
      aOpenSleeves: 'Open Slv',
      aFancyButton: 'Fancy Btn',
      aSimplePajama: 'Pajama',
      aPocketPajama: 'Pocket Pj',

      // big actions (short)
      aOneFrontOneSideShalwar: '1F 1S Shalwar',
      aOneFrontTwoSideShalwar: '1F 2S Shalwar',
      aOneSideOneShalwar: '1S 1 Shalwar',
      aTwoSideOneShalwar: '2S 1 Shalwar',
      aTwoSide: '2 Side',

      // messages/buttons
      msgCameraDisabled: '📸 Camera scanner unavailable',
      msgViewMode: 'View mode (tap pencil to edit)',
      msgHistoryUpdated: 'History updated ✅',
      msgSavedToHistory: 'Saved to history ✅',
      msgSaveFailed: 'Save failed',

      msgDeleteTitle: 'Delete?',
      msgDeleteConfirm: 'Are you sure you want to delete this record?',
      msgDeleted: 'Deleted ✅',

      msgEditButtonTitle: 'Edit button',
      msgEnterNewText: 'Enter new text',

      btnCancel: 'Cancel',
      btnDelete: 'Delete',
      btnSave: 'Save',
    },

    // Arabic (SHORT)
    langAr: {
      // top
      cName: 'اسم',
      cSerial: 'رقم',
      cPhone: 'هاتف',

      // measurements
      mLength: 'طول',
      mSleeve: 'كم',
      mWidth: 'عرض',
      mChest: 'صدر',
      mWaist: 'خصر',
      mNeck: 'رقبة',
      mRound: 'محيط',
      mHalf: 'نصف',
      mShalwar: 'شلوار',
      mPoncha: 'بنچه',
      mCuff: 'كف',
      mShoulder: 'كتف',
      mAsan: 'آسن',
      mShalwarRound: 'محيط ش',

      // actions
      aRound: 'دائري',
      aSquare: 'مربع',
      aBenHalf: 'بن نصف',
      aFullBen: 'بن كامل',
      aBenSquare: 'بن مربع',
      aBenRound: 'بن دائري',
      aNormalCollar: 'ياقة ع',
      aCollarTipS: 'طرف S',
      aBenPattiThin: 'شريط ر',
      aChakPattiKaj: 'كاچ ش',
      aSimpleDouble: 'دبل ع',
      aSilkDouble: 'دبل حر',
      aKanta: 'كانتا',
      aJali: 'شبك',
      aOpenSleeves: 'كم مفت',
      aFancyButton: 'زر فخم',
      aSimplePajama: 'بيجاما',
      aPocketPajama: 'جيب Pj',

      // big actions
      aOneFrontOneSideShalwar: '1أم 1ج شلوار',
      aOneFrontTwoSideShalwar: '1أم 2ج شلوار',
      aOneSideOneShalwar: '1ج 1 شلوار',
      aTwoSideOneShalwar: '2ج 1 شلوار',
      aTwoSide: '2 جانب',

      // messages/buttons
      msgCameraDisabled: '📸 الماسح غير متاح',
      msgViewMode: 'وضع عرض (للتعديل اضغط القلم)',
      msgHistoryUpdated: 'تم التحديث ✅',
      msgSavedToHistory: 'تم الحفظ ✅',
      msgSaveFailed: 'فشل الحفظ',

      msgDeleteTitle: 'حذف؟',
      msgDeleteConfirm: 'هل تريد حذف هذا السجل؟',
      msgDeleted: 'تم الحذف ✅',

      msgEditButtonTitle: 'تعديل الزر',
      msgEnterNewText: 'أدخل نصاً جديداً',

      btnCancel: 'إلغاء',
      btnDelete: 'حذف',
      btnSave: 'حفظ',
    },
  };
}