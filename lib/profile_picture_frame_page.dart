// lib/profile_picture_frame_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';
import 'ui_kit.dart';
import 'settings_header.dart';
import 'profile_frames.dart';

class ProfilePictureFramePage extends StatefulWidget {
  const ProfilePictureFramePage({super.key});

  @override
  State<ProfilePictureFramePage> createState() => _ProfilePictureFramePageState();
}

class _ProfilePictureFramePageState extends State<ProfilePictureFramePage> {
  // ✅ new + fallback
  static const _kSelectedFrameV1 = 'settings_profile_frame_type_v1';
  static const _kSelectedFrameOld = 'settings_profile_frame_type';

  ProfileFrameType? _selected;

  bool get _isDark => AppSettings.darkModeVN.value;
  String? get _font => AppSettings.fontFamilyVN.value;

  @override
  void initState() {
    super.initState();
    _loadSelected();
  }

  ProfileFrameType? _tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    for (final v in ProfileFrameType.values) {
      if (v.name == raw) return v;
    }
    return null;
  }

  Future<void> _loadSelected() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ try v1 then old
      final raw = prefs.getString(_kSelectedFrameV1) ??
          prefs.getString(_kSelectedFrameOld);

      if (!mounted) return;
      setState(() => _selected = _tryParse(raw));
    } catch (_) {}
  }

  Future<void> _apply(ProfileFrameType type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSelectedFrameV1, type.name); // ✅ always save to v1
    } catch (_) {}

    if (!mounted) return;
    Navigator.pop(context, 1); // settings_page.dart awaiting int
  }

  Future<void> _removeFrame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kSelectedFrameV1);
      await prefs.remove(_kSelectedFrameOld);
    } catch (_) {}

    if (!mounted) return;
    Navigator.pop(context, 1);
  }

  String _label(ProfileFrameType t) {
    switch (t) {
      case ProfileFrameType.royalGoldOrbit:
        return 'ROYAL GOLD ORBIT';
      case ProfileFrameType.diamondShine:
        return 'DIAMOND SHINE';
      case ProfileFrameType.flameCrown:
        return 'FLAME CROWN';
      case ProfileFrameType.neonPulse:
        return 'NEON PULSE';
      case ProfileFrameType.sparkleRing:
        return 'SPARKLE RING';
      case ProfileFrameType.haloSweep:
        return 'HALO SWEEP';
      case ProfileFrameType.crystalWaves:
        return 'CRYSTAL WAVES';
      case ProfileFrameType.premiumDotsRun:
        return 'DOTS RUN';
      case ProfileFrameType.auroraLoop:
        return 'AURORA LOOP';
      case ProfileFrameType.luxuryShimmerBand:
        return 'LUXURY BAND';
    }
  }

  @override
  Widget build(BuildContext context) {
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'PROFILE PICTURE FRAME',
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: _font,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),

                      _TopPreview(
                        fontFamily: _font,
                        selected: _selected,
                        onRemove: _removeFrame,
                      ),

                      const SizedBox(height: 12),

                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.only(bottom: 6),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.92,
                          ),
                          itemCount: ProfileFrameType.values.length,
                          itemBuilder: (context, i) {
                            final t = ProfileFrameType.values[i];
                            final selected = (_selected == t);

                            return _FrameCard(
                              title: _label(t),
                              fontFamily: _font,
                              selected: selected,
                              frameType: t,
                              onTap: () => _apply(t),
                            );
                          },
                        ),
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

class _TopPreview extends StatelessWidget {
  final String? fontFamily;
  final ProfileFrameType? selected;
  final VoidCallback onRemove;

  const _TopPreview({
    required this.fontFamily,
    required this.selected,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final has = selected != null;

    return Container(
      height: 110,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: masterGoldGradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ✅ If no frame => show plain avatar (no fake frame)
          if (!has)
            Container(
              height: 72,
              width: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
              ),
              alignment: Alignment.center,
              child: Text(
                'W',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: fontFamily,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            )
          else
            ProfileAvatarWithFrame(
              size: 72,
              framePadding: 10,
              frameType: selected!,
              animate: true,
              avatarChild: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
                alignment: Alignment.center,
                child: Text(
                  'W',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: fontFamily,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ),
            ),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              has ? 'PREVIEW (SELECTED)' : 'PREVIEW (NO FRAME)',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black,
                fontFamily: fontFamily,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(width: 10),

          if (has)
            GestureDetector(
              onTap: onRemove,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.black,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: masterGoldGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(r),
                  blendMode: BlendMode.srcIn,
                  child: const Text(
                    'REMOVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11.5,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FrameCard extends StatelessWidget {
  final String title;
  final String? fontFamily;
  final bool selected;
  final ProfileFrameType frameType;
  final VoidCallback onTap;

  const _FrameCard({
    required this.title,
    required this.fontFamily,
    required this.selected,
    required this.frameType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: masterGoldGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.10),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
          border: Border.all(
            color: selected ? Colors.black : Colors.black.withOpacity(0.25),
            width: selected ? 2.2 : 1.2,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 4),

            ProfileAvatarWithFrame(
              size: 66,
              framePadding: 10,
              frameType: frameType,
              animate: false, // grid smooth رہے
              avatarChild: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
                alignment: Alignment.center,
                child: Text(
                  'W',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: fontFamily,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: fontFamily,
                    fontWeight: FontWeight.w900,
                    fontSize: 11.8,
                    letterSpacing: 0.8,
                    height: 1.15,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_ios_rounded,
                size: selected ? 20 : 16,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}