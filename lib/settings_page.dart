// lib/settings_page.dart
// ✅ FINAL UPDATED (TEST MODE - ALL PRO FEATURES FREE)
// ✅ Receipt Templates button fixed (was empty)
// ✅ GoToPro میں 4 نئی چیزیں add
// ✅ Dark: masterGoldGradient | Light: white
// ✅ Shimmer + 3D buttons same
// ✅ Text always black

import 'package:flutter/material.dart';

import 'app_localizations.dart';
import 'app_settings.dart';
import 'language_page.dart';
import 'ui_kit.dart';
import 'settings_header.dart';
import 'profile_picture_frame_page.dart';

// ✅ MATCH YOUR REAL FILES
import 'receipt_page.dart';
import 'receipt_template_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  bool get _isDark => AppSettings.darkModeVN.value;
  bool get _shimmerOn => AppSettings.shimmerVN.value;
  String? get _currentFont => AppSettings.fontFamilyVN.value;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _syncAnimWithShimmer();
    AppSettings.shimmerVN.addListener(_syncAnimWithShimmer);
    AppSettings.darkModeVN.addListener(_rebuild);
    AppSettings.fontFamilyVN.addListener(_rebuild);
  }

  void _rebuild() {
    if (!mounted) return;
    setState(() {});
  }

  void _syncAnimWithShimmer() {
    if (!mounted) return;

    if (_shimmerOn) {
      if (!_anim.isAnimating) _anim.repeat();
    } else {
      if (_anim.isAnimating) _anim.stop();
      _anim.value = 0.0;
    }

    setState(() {});
  }

  @override
  void dispose() {
    AppSettings.shimmerVN.removeListener(_syncAnimWithShimmer);
    AppSettings.darkModeVN.removeListener(_rebuild);
    AppSettings.fontFamilyVN.removeListener(_rebuild);
    _anim.dispose();
    super.dispose();
  }

  void _openGeneral() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GeneralSettingsPage()),
    );
  }

  void _openContact() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ContactUsPage()),
    );
  }

  void _openAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AboutAppPage()),
    );
  }

  void _openGoToPro() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GoToProPage()),
    );
  }

  void _logout() {
    final loc = AppLocalizations.t(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${loc.logout} (coming soon)',
          style: TextStyle(fontFamily: _currentFont, color: Colors.black),
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.t(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: _isDark ? null : Colors.white,
          gradient: _isDark
              ? const LinearGradient(
                  colors: masterGoldGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: SafeArea(
          child: Column(
            children: [
              SettingsHeader(onBack: () => Navigator.pop(context)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 22),
                  child: Column(
                    children: [
                      // 1) DARK MODE
                      ValueListenableBuilder<bool>(
                        valueListenable: AppSettings.darkModeVN,
                        builder: (_, v, __) => _SettingTile(
                          anim: _anim,
                          shimmerOn: _shimmerOn,
                          isDark: _isDark,
                          icon: Icons.dark_mode_rounded,
                          title: loc.darkMode.toUpperCase(),
                          fontFamily: _currentFont,
                          trailing: Switch(
                            value: v,
                            onChanged: (nv) => AppSettings.setDarkMode(nv),
                          ),
                          onTap: null,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2) SHIMMER
                      ValueListenableBuilder<bool>(
                        valueListenable: AppSettings.shimmerVN,
                        builder: (_, v, __) => _SettingTile(
                          anim: _anim,
                          shimmerOn: _shimmerOn,
                          isDark: _isDark,
                          icon: Icons.auto_awesome_rounded,
                          title: loc.shimmerAnimation.toUpperCase(),
                          fontFamily: _currentFont,
                          trailing: Switch(
                            value: v,
                            onChanged: (nv) => AppSettings.setShimmer(nv),
                          ),
                          onTap: null,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 3) GENERAL
                      _SettingTile(
                        anim: _anim,
                        shimmerOn: _shimmerOn,
                        isDark: _isDark,
                        icon: Icons.tune_rounded,
                        title: loc.general.toUpperCase(),
                        fontFamily: _currentFont,
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 18, color: Colors.black),
                        onTap: _openGeneral,
                      ),
                      const SizedBox(height: 12),

                      // 4) GO TO PRO (Test mode: all free)
                      _SettingTile(
                        anim: _anim,
                        shimmerOn: _shimmerOn,
                        isDark: _isDark,
                        icon: Icons.workspace_premium_rounded,
                        title: loc.goToPro.toUpperCase(),
                        fontFamily: _currentFont,
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 18, color: Colors.black),
                        onTap: _openGoToPro,
                      ),
                      const SizedBox(height: 12),

                      // 5) CONTACT
                      _SettingTile(
                        anim: _anim,
                        shimmerOn: _shimmerOn,
                        isDark: _isDark,
                        icon: Icons.contacts_rounded,
                        title: loc.contactUs.toUpperCase(),
                        fontFamily: _currentFont,
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 18, color: Colors.black),
                        onTap: _openContact,
                      ),
                      const SizedBox(height: 12),

                      // 6) ABOUT
                      _SettingTile(
                        anim: _anim,
                        shimmerOn: _shimmerOn,
                        isDark: _isDark,
                        icon: Icons.info_rounded,
                        title: loc.aboutApp.toUpperCase(),
                        fontFamily: _currentFont,
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 18, color: Colors.black),
                        onTap: _openAbout,
                      ),
                      const SizedBox(height: 12),

                      // 7) LOGOUT
                      _SettingTile(
                        anim: _anim,
                        shimmerOn: _shimmerOn,
                        isDark: _isDark,
                        icon: Icons.logout_rounded,
                        title: loc.logout.toUpperCase(),
                        fontFamily: _currentFont,
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 18, color: Colors.black),
                        onTap: _logout,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================= GO TO PRO PAGE =======================
// ✅ Test Mode: everything opens (FREE)

class GoToProPage extends StatefulWidget {
  const GoToProPage({super.key});

  @override
  State<GoToProPage> createState() => _GoToProPageState();
}

class _GoToProPageState extends State<GoToProPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  bool get _isDark => AppSettings.darkModeVN.value;
  bool get _shimmerOn => AppSettings.shimmerVN.value;
  String? get _currentFont => AppSettings.fontFamilyVN.value;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _syncAnimWithShimmer();
    AppSettings.shimmerVN.addListener(_syncAnimWithShimmer);
    AppSettings.darkModeVN.addListener(_rebuild);
    AppSettings.fontFamilyVN.addListener(_rebuild);
  }

  void _rebuild() {
    if (!mounted) return;
    setState(() {});
  }

  void _syncAnimWithShimmer() {
    if (!mounted) return;

    if (_shimmerOn) {
      if (!_anim.isAnimating) _anim.repeat();
    } else {
      if (_anim.isAnimating) _anim.stop();
      _anim.value = 0.0;
    }

    setState(() {});
  }

  @override
  void dispose() {
    AppSettings.shimmerVN.removeListener(_syncAnimWithShimmer);
    AppSettings.darkModeVN.removeListener(_rebuild);
    AppSettings.fontFamilyVN.removeListener(_rebuild);
    _anim.dispose();
    super.dispose();
  }

  Future<void> _pushWithLoader(Widget page) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.15),
      builder: (_) => const Center(
        child: SizedBox(
          width: 42,
          height: 42,
          child: CircularProgressIndicator(strokeWidth: 4),
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 220));

    if (!mounted) return;
    Navigator.pop(context);

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Future<void> _openFrames() async {
    await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePictureFramePage()),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openReceipt() async {
    await _pushWithLoader(const ReceiptPage());
  }

  Future<void> _openReceiptTemplates() async {
    // ✅ یہی اصل fix ہے: Receipt Templates والا بٹن اب کام کرے گا
    await _pushWithLoader(const ReceiptTemplatePage());
  }

  void _toastTest(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(fontFamily: _currentFont, color: Colors.black),
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.t(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: _isDark ? null : Colors.white,
          gradient: _isDark
              ? const LinearGradient(
                  colors: masterGoldGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: SafeArea(
          child: Column(
            children: [
              SettingsHeader(onBack: () => Navigator.pop(context)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      // ✅ (پرانے) Auto Backup
                      _SettingTile(
                        anim: _anim,
                        shimmerOn: _shimmerOn,
                        isDark: _isDark,
                        icon: Icons.backup_rounded,
                        title: loc.autoBackup.toUpperCase(),
                        fontFamily: _currentFont,
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 18, color: Colors.black),
                        onTap: () =>
                            _toastTest('${loc.autoBackup} (TEST MODE - FREE)'),
                      ),
                      const SizedBox(height: 12),

                      // ✅ Profile Picture Frame
                      _SettingTile(
                        anim: _anim,
                        shimmerOn: _shimmerOn,
                        isDark: _isDark,
                        icon: Icons.account_circle_rounded,
                        title: loc.profilePictureFrame.toUpperCase(),
                        fontFamily: _currentFont,
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 18, color: Colors.black),
                        onTap: _openFrames,
                      ),
                      const SizedBox(height: 12),

                      // ✅ Receipt (Purchased)
                      _SettingTile(
                        anim: _anim,
                        shimmerOn: _shimmerOn,
                        isDark: _isDark,
                        icon: Icons.receipt_long_rounded,
                        title: loc.receipt.toUpperCase(),
                        fontFamily: _currentFont,
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 18, color: Colors.black),
                        onTap: _openReceipt,
                      ),
                      const SizedBox(height: 12),

                      // ✅ Receipt Templates (Store)
                      _SettingTile(
                        anim: _anim,
                        shimmerOn: _shimmerOn,
                        isDark: _isDark,
                        icon: Icons.receipt_rounded,
                        title: loc.receiptTemplate.toUpperCase(),
                        fontFamily: _currentFont,
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 18, color: Colors.black),
                        onTap: _openReceiptTemplates,
                      ),
                      const SizedBox(height: 12),

                      // ✅ NEW 4 ITEMS (GoToPro)
                      _SettingTile(
                        anim: _anim,
                        shimmerOn: _shimmerOn,
                        isDark: _isDark,
                        icon: Icons.dashboard_customize_rounded,
                        title: 'UNLIMITED CUSTOM TEMPLATE',
                        fontFamily: _currentFont,
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 18, color: Colors.black),
                        onTap: () => _toastTest('UNLIMITED CUSTOM TEMPLATE (TEST MODE - FREE)'),
                      ),
                      const SizedBox(height: 12),

                      _SettingTile(
                        anim: _anim,
                        shimmerOn: _shimmerOn,
                        isDark: _isDark,
                        icon: Icons.document_scanner_rounded,
                        title: 'OCR SCANNER',
                        fontFamily: _currentFont,
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 18, color: Colors.black),
                        onTap: () => _toastTest('OCR SCANNER (TEST MODE - FREE)'),
                      ),
                      const SizedBox(height: 12),

                      _SettingTile(
                        anim: _anim,
                        shimmerOn: _shimmerOn,
                        isDark: _isDark,
                        icon: Icons.block_flipped,
                        title: 'REMOVE ADS',
                        fontFamily: _currentFont,
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 18, color: Colors.black),
                        onTap: () => _toastTest('REMOVE ADS (TEST MODE - FREE)'),
                      ),
                      const SizedBox(height: 12),

                      _SettingTile(
                        anim: _anim,
                        shimmerOn: _shimmerOn,
                        isDark: _isDark,
                        icon: Icons.shopping_cart_checkout_rounded,
                        title: 'BUY ALL',
                        fontFamily: _currentFont,
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 18, color: Colors.black),
                        onTap: () => _toastTest('BUY ALL (TEST MODE - FREE)'),
                      ),
                      const SizedBox(height: 12),

                      // ✅ Restore
                      _SettingTile(
                        anim: _anim,
                        shimmerOn: _shimmerOn,
                        isDark: _isDark,
                        icon: Icons.restore_rounded,
                        title: loc.restore.toUpperCase(),
                        fontFamily: _currentFont,
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 18, color: Colors.black),
                        onTap: () =>
                            _toastTest('${loc.restore} (TEST MODE - FREE)'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================= GENERAL SETTINGS PAGE =======================

class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  State<GeneralSettingsPage> createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  bool get _isDark => AppSettings.darkModeVN.value;
  bool get _shimmerOn => AppSettings.shimmerVN.value;
  String? get _currentFont => AppSettings.fontFamilyVN.value;

  bool _fontsExpanded = false;

  static const List<String> kAppFonts = <String>[
    'DEFAULT',
    'AASameer',
    'Aadil',
    'AlFars',
    'BlakaHollow',
    'BlakaInk',
    'CairoPlay',
    'Inter',
    'Katibeh',
    'Montserrat',
    'Nabla',
    'NotoSans',
    'NotoSerif',
    'Oi',
    'ReemKufiFun',
    'ReemKufiInk',
    'Roboto',
  ];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _syncAnimWithShimmer();
    AppSettings.shimmerVN.addListener(_syncAnimWithShimmer);
    AppSettings.darkModeVN.addListener(_rebuild);
    AppSettings.fontFamilyVN.addListener(_rebuild);
  }

  void _rebuild() {
    if (!mounted) return;
    setState(() {});
  }

  void _syncAnimWithShimmer() {
    if (!mounted) return;

    if (_shimmerOn) {
      if (!_anim.isAnimating) _anim.repeat();
    } else {
      if (_anim.isAnimating) _anim.stop();
      _anim.value = 0.0;
    }

    setState(() {});
  }

  @override
  void dispose() {
    AppSettings.shimmerVN.removeListener(_syncAnimWithShimmer);
    AppSettings.darkModeVN.removeListener(_rebuild);
    AppSettings.fontFamilyVN.removeListener(_rebuild);
    _anim.dispose();
    super.dispose();
  }

  void _openLanguage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LanguagePage()),
    );
  }

  Future<void> _selectFont(String family) async {
    if (family == 'DEFAULT') {
      await AppSettings.setFontFamily(null);
    } else {
      await AppSettings.setFontFamily(family);
    }
    if (!mounted) return;
    setState(() => _fontsExpanded = false);
  }

  String get _currentFontLabel {
    final f = AppSettings.fontFamilyVN.value;
    return f ?? AppLocalizations.t(context).defaultStr;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.t(context);
    final current = _currentFontLabel;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: _isDark ? null : Colors.white,
          gradient: _isDark
              ? const LinearGradient(
                  colors: masterGoldGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: SafeArea(
          child: Column(
            children: [
              SettingsHeader(onBack: () => Navigator.pop(context)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _SettingTile(
                        anim: _anim,
                        shimmerOn: _shimmerOn,
                        isDark: _isDark,
                        icon: Icons.backup_rounded,
                        title: loc.manualBackup.toUpperCase(),
                        fontFamily: _currentFont,
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 18, color: Colors.black),
                        onTap: () {},
                      ),
                      const SizedBox(height: 12),
                      _SettingTile(
                        anim: _anim,
                        shimmerOn: _shimmerOn,
                        isDark: _isDark,
                        icon: Icons.language_rounded,
                        title: loc.language.toUpperCase(),
                        fontFamily: _currentFont,
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 18, color: Colors.black),
                        onTap: _openLanguage,
                      ),
                      const SizedBox(height: 12),
                      _SettingTile(
                        anim: _anim,
                        shimmerOn: _shimmerOn,
                        isDark: _isDark,
                        icon: Icons.font_download_rounded,
                        title: loc.fonts.toUpperCase(),
                        fontFamily: _currentFont,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ShimmerInlineText(
                              anim: _anim,
                              shimmerOn: _shimmerOn,
                              text: current.toUpperCase(),
                              fontFamily: _currentFont,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _fontsExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 22,
                              color: Colors.black,
                            ),
                          ],
                        ),
                        onTap: () =>
                            setState(() => _fontsExpanded = !_fontsExpanded),
                      ),
                      if (_fontsExpanded) ...[
                        const SizedBox(height: 12),
                        ...kAppFonts.map((f) {
                          final selected =
                              (f == 'DEFAULT' &&
                                      AppSettings.fontFamilyVN.value == null) ||
                                  (AppSettings.fontFamilyVN.value == f);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _SettingTile(
                              anim: _anim,
                              shimmerOn: _shimmerOn,
                              isDark: _isDark,
                              icon: Icons.text_fields_rounded,
                              title: f == 'DEFAULT' ? loc.defaultStr : f,
                              fontFamily: f == 'DEFAULT' ? null : f,
                              trailing: Icon(
                                selected
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                size: 20,
                                color: Colors.black,
                              ),
                              onTap: () => _selectFont(f),
                            ),
                          );
                        }).toList(),
                      ],
                      const SizedBox(height: 12),
                      _SettingTile(
                        anim: _anim,
                        shimmerOn: _shimmerOn,
                        isDark: _isDark,
                        icon: Icons.restart_alt_rounded,
                        title: loc.resetSettings.toUpperCase(),
                        fontFamily: _currentFont,
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 18, color: Colors.black),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================= PLACEHOLDER PAGES =======================

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.t(context);
    final isDark = AppSettings.darkModeVN.value;
    final font = AppSettings.fontFamilyVN.value;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? null : Colors.white,
          gradient: isDark
              ? const LinearGradient(
                  colors: masterGoldGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: SafeArea(
          child: Column(
            children: [
              SettingsHeader(onBack: () => Navigator.pop(context)),
              Expanded(
                child: Center(
                  child: Text(
                    '${loc.contactUs}\n(${loc.comingSoon})',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: font,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.t(context);
    final isDark = AppSettings.darkModeVN.value;
    final font = AppSettings.fontFamilyVN.value;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? null : Colors.white,
          gradient: isDark
              ? const LinearGradient(
                  colors: masterGoldGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: SafeArea(
          child: Column(
            children: [
              SettingsHeader(onBack: () => Navigator.pop(context)),
              Expanded(
                child: Center(
                  child: Text(
                    '${loc.aboutApp}\n(${loc.comingSoon})',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: font,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================= SETTING TILE WITH SMOOTH SHIMMER =======================

class _SettingTile extends StatelessWidget {
  final AnimationController anim;
  final bool shimmerOn;
  final bool isDark;
  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;
  final String? fontFamily;

  const _SettingTile({
    required this.anim,
    required this.shimmerOn,
    required this.isDark,
    required this.icon,
    required this.title,
    required this.trailing,
    required this.onTap,
    this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        final t = shimmerOn ? anim.value : 0.0;

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
                color: isDark ? null : Colors.white,
                gradient: isDark
                    ? const LinearGradient(
                        colors: masterGoldGradient,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.30 : 0.18),
                    blurRadius: isDark ? 16 : 14,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(isDark ? 0.12 : 0.0),
                    blurRadius: isDark ? 10 : 0,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.black, size: 26),
                  const SizedBox(width: 12),
                  Expanded(child: _buildShimmerText(t)),
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

  Widget _buildShimmerText(double t) {
    final baseStyle = TextStyle(
      color: Colors.black,
      fontFamily: fontFamily,
      fontSize: 15.2,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.0,
    );

    if (!shimmerOn) {
      return Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }

    return Stack(
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: baseStyle,
        ),
        Positioned.fill(
          child: ClipRect(
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.85),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                  begin: Alignment(-1.5 + (t * 3), 0.0),
                  end: Alignment(-0.5 + (t * 3), 0.0),
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcIn,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: baseStyle.copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShimmerInlineText extends StatelessWidget {
  final AnimationController anim;
  final bool shimmerOn;
  final String text;
  final String? fontFamily;
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;

  const _ShimmerInlineText({
    required this.anim,
    required this.shimmerOn,
    required this.text,
    required this.fontFamily,
    required this.fontSize,
    required this.fontWeight,
    required this.letterSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final t = shimmerOn ? anim.value : 0.0;

        final baseStyle = TextStyle(
          color: Colors.black,
          fontFamily: fontFamily,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
        );

        if (!shimmerOn) {
          return Text(text, style: baseStyle, maxLines: 1);
        }

        return Stack(
          children: [
            Text(text, style: baseStyle, maxLines: 1),
            Positioned.fill(
              child: ClipRect(
                child: ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.85),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      begin: Alignment(-1.5 + (t * 3), 0.0),
                      end: Alignment(-0.5 + (t * 3), 0.0),
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    text,
                    style: baseStyle.copyWith(color: Colors.white),
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}