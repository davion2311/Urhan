// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_settings.dart';
import 'app_localizations.dart';

import 'intro_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'dashboard_page.dart';
import 'by_default_page.dart';
import 'history_page.dart';
import 'settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _darkTheme(String? fontFamily) {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      textTheme: base.textTheme.apply(fontFamily: fontFamily),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: fontFamily),
    );
  }

  ThemeData _lightTheme(String? fontFamily) {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: base.textTheme.apply(fontFamily: fontFamily),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: fontFamily),
    );
  }

  // ✅ RTL/LTR کا سسٹم مکمل ختم کر دیا
  // ✅ اب ہمیشہ LTR ہوگا
  Locale _localeFromCode(String code) {
    final v = code.trim();
    if (v.isEmpty) return const Locale('ur');

    if (v.contains('_')) {
      final parts = v.split('_');
      final lang = parts.isNotEmpty ? parts[0] : 'ur';
      final country = parts.length > 1 ? parts[1] : null;
      return Locale(lang, country);
    }

    if (v.contains('-')) {
      final parts = v.split('-');
      final lang = parts.isNotEmpty ? parts[0] : 'ur';
      final country = parts.length > 1 ? parts[1] : null;
      return Locale(lang, country);
    }

    return Locale(v);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.darkModeVN,
      builder: (context, isDark, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: AppSettings.fontFamilyVN,
          builder: (context, fontFamily, __) {
            return ValueListenableBuilder<String?>(
              valueListenable: AppSettings.languageCodeVN,
              builder: (context, langCode, ___) {
                // ✅ RTL/LTR کا سسٹم مکمل ختم
                // ✅ اب ہمیشہ LTR (بائیں سے دائیں)
                final textDirection = TextDirection.ltr;
                
                final locale = _localeFromCode(langCode ?? 'ur');

                return MaterialApp(
                  title: 'Digital Darzi',
                  debugShowCheckedModeBanner: false,

                  theme:
                      isDark ? _darkTheme(fontFamily) : _lightTheme(fontFamily),

                  // ✅ تمام 35 لینگویج سپورٹ
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],

                  // ✅ اب ہمیشہ LTR (بائیں سے دائیں)
                  // ✅ RTL/LTR کا سسٹم مکمل ختم
                  builder: (context, child) {
                    return Directionality(
                      textDirection: textDirection, // ہمیشہ LTR
                      child: child ?? const SizedBox.shrink(),
                    );
                  },

                  initialRoute: '/',
                  routes: {
                    '/': (context) => const IntroPage(),
                    '/auth': (context) => const LoginPage(),
                    '/signup': (context) => const SignupPage(),
                    '/dashboard': (context) => const DashboardPage(),
                    '/by_default': (context) => const ByDefaultPage(),
                    '/history': (context) => const HistoryPage(),
                    '/settings': (context) => const SettingsPage(),
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}