import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // SystemSound کے لیے

import 'app_settings.dart';
import 'ui_kit.dart';
import 'settings_header.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  bool get _isDark => AppSettings.darkModeVN.value;
  bool get _shimmerOn => AppSettings.shimmerVN.value;

  Color get _pageBg => _isDark ? Colors.black : Colors.white;

  // ================== LANGUAGE LIST ==================
  // ✅ تمام کوڈ app_localizations.dart کے supportedLocales سے مطابقت رکھتے ہیں
  // ✅ ہر زبان کے سامنے flag icon ہے
  static const List<_LangItem> _languages = [
    // ======= TOP PRIORITY (سب سے اوپر) =======
    _LangItem('ur', 'اردو', '🇵🇰'),
    _LangItem('ar', 'العربية', '🇸🇦'),
    _LangItem('en', 'English', '🇺🇸'),
    _LangItem('hi', 'हिन्दी', '🇮🇳'),
    _LangItem('bn', 'बাংলा', '🇧🇩'),

    // ======= SOUTH ASIA (جنوبی ایشیا) =======
    _LangItem('pa', 'ਪੰਜਾਬੀ', '🇮🇳'),
    _LangItem('ta', 'தமிழ்', '🇮🇳'),
    _LangItem('te', 'తెలుగు', '🇮🇳'),
    _LangItem('mr', 'मराठी', '🇮🇳'),
    _LangItem('gu', 'ગુજરાતી', '🇮🇳'),
    _LangItem('ml', 'മലയാളം', '🇮🇳'),
    _LangItem('kn', 'ಕನ್ನಡ', '🇮🇳'),
    _LangItem('si', 'සිංහල', '🇱🇰'),
    _LangItem('th', 'ไทย', '🇹🇭'),
    _LangItem('vi', 'Tiếng Việt', '🇻🇳'),

    // ======= EAST ASIA (مشرقی ایشیا) =======
    _LangItem('zh', '中文', '🇨🇳'), // ✅ Simplified/Traditional دونوں کے لیے ایک کوڈ
    _LangItem('ja', '日本語', '🇯🇵'),
    _LangItem('ko', '한국어', '🇰🇷'),

    // ======= MIDDLE EAST / CENTRAL ASIA (مشرق وسطی/وسطی ایشیا) =======
    _LangItem('fa', 'فارسی', '🇮🇷'),
    _LangItem('ps', 'پښتو', '🇦🇫'),
    _LangItem('tr', 'Türkçe', '🇹🇷'),
    _LangItem('uz', 'Oʻzbek', '🇺🇿'),

    // ======= EUROPE (یورپ) =======
    _LangItem('fr', 'Français', '🇫🇷'),
    _LangItem('de', 'Deutsch', '🇩🇪'),
    _LangItem('es', 'Español', '🇪🇸'),
    _LangItem('it', 'Italiano', '🇮🇹'),
    _LangItem('pt', 'Português', '🇵🇹'),
    _LangItem('ru', 'Русский', '🇷🇺'),
    _LangItem('uk', 'Українська', '🇺🇦'),

    // ======= AFRICA (افریقہ) =======
    _LangItem('sw', 'Kiswahili', '🇰🇪'),
    _LangItem('ha', 'Hausa', '🇳🇬'),

    // ======= OTHERS (دیگر) =======
    _LangItem('ms', 'Bahasa Melayu', '🇲🇾'),
    _LangItem('id', 'Bahasa Indonesia', '🇮🇩'),
    _LangItem('tl', 'Filipino', '🇵🇭'),
  ];

  String get _currentLang => AppSettings.languageCodeVN.value ?? 'ur';

  // ✅ RTL/LTR چیک کرنے والا فنکشن مکمل طور پر ختم
  // اب صرف LTR رہے گا

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    _syncAnim();
    AppSettings.shimmerVN.addListener(_syncAnim);

    // rebuild on these changes
    AppSettings.darkModeVN.addListener(_rebuild);
    AppSettings.languageCodeVN.addListener(_rebuild);
  }

  void _syncAnim() {
    if (!mounted) return;

    if (_shimmerOn) {
      if (!_anim.isAnimating) _anim.repeat();
    } else {
      if (_anim.isAnimating) _anim.stop();
      _anim.value = 0.0;
    }
    setState(() {});
  }

  void _rebuild() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    AppSettings.shimmerVN.removeListener(_syncAnim);
    AppSettings.darkModeVN.removeListener(_rebuild);
    AppSettings.languageCodeVN.removeListener(_rebuild);
    _anim.dispose();
    super.dispose();
  }

  Future<void> _selectLanguage(_LangItem lang) async {
    // ✅ sound effect
    SystemSound.play(SystemSoundType.click);

    // ✅ AppSettings.setLanguage کو صرف code بھیجیں
    await AppSettings.setLanguage(lang.code);

    if (!mounted) return;

    // ✅ success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Language set to ${lang.title} ✅'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ہمیشہ LTR رہے گا - RTL کا کوئی سسٹم نہیں
    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: Column(
          children: [
            // ✅ Header
            SettingsHeader(
              onBack: () => Navigator.pop(context),
            ),

            // ✅ List/Body - ہمیشہ LTR
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 22),
                child: Column(
                  children: _languages.map((lang) {
                    final selected = lang.code == _currentLang;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _GoldCapsuleSettingTile(
                        anim: _anim,
                        shimmerOn: _shimmerOn,
                        flagIcon: lang.flag,
                        title: lang.title,
                        trailing: selected
                            ? const Icon(Icons.check_circle_rounded,
                                color: Colors.black, size: 22)
                            : const Icon(Icons.circle_outlined,
                                color: Colors.black, size: 22),
                        onTap: () => _selectLanguage(lang),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= DATA MODEL =================

class _LangItem {
  final String code;
  final String title;
  final String flag; // ✅ flag icon (emoji)

  const _LangItem(this.code, this.title, this.flag);
}

// ================= GOLD CAPSULE TILE (updated) =================

class _GoldCapsuleSettingTile extends StatelessWidget {
  final AnimationController anim;
  final bool shimmerOn;
  final String flagIcon; // ✅ flag as emoji
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  const _GoldCapsuleSettingTile({
    required this.anim,
    required this.shimmerOn,
    required this.flagIcon,
    required this.title,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = shimmerOn ? anim.value : 0.0;

    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: CustomPaint(
            painter: BorderShimmerPainter(
              t: t,
              radius: 999,
              strokeWidth: 3.2,
            ),
            child: Container(
              height: 62,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  colors: masterGoldGradient,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ✅ Flag icon (emoji)
                  Container(
                    width: 30,
                    alignment: Alignment.center,
                    child: Text(
                      flagIcon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15.2,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  trailing,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}