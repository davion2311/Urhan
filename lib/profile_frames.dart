// lib/profile_frames.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';
import 'ui_kit.dart';

enum ProfileFrameType {
  royalGoldOrbit,
  diamondShine,
  flameCrown,
  neonPulse,
  sparkleRing,
  haloSweep,
  crystalWaves,
  premiumDotsRun,
  auroraLoop,
  luxuryShimmerBand,
}

/// ✅ Frame Selection Page
/// - Shows GRID previews (not just names)
/// - Tap a preview => saves + shows selected tick
/// - Back => Header will show selected frame automatically (reads same pref key)
class ProfilePictureFramePage extends StatefulWidget {
  const ProfilePictureFramePage({super.key});

  @override
  State<ProfilePictureFramePage> createState() => _ProfilePictureFramePageState();
}

class _ProfilePictureFramePageState extends State<ProfilePictureFramePage>
    with SingleTickerProviderStateMixin {
  static const String _kSelectedFrame = 'settings_profile_frame_type_v1';

  late final AnimationController _anim;

  ProfileFrameType? _selected;

  bool get _isDark => AppSettings.darkModeVN.value;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _loadSelected();
    AppSettings.darkModeVN.addListener(_rebuild);
    AppSettings.shimmerVN.addListener(_rebuild);
  }

  void _rebuild() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    AppSettings.darkModeVN.removeListener(_rebuild);
    AppSettings.shimmerVN.removeListener(_rebuild);
    _anim.dispose();
    super.dispose();
  }

  Future<void> _loadSelected() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kSelectedFrame);
      if (!mounted) return;

      setState(() {
        _selected = (raw == null || raw.isEmpty) ? null : _tryParseFrame(raw);
      });
    } catch (_) {}
  }

  ProfileFrameType? _tryParseFrame(String raw) {
    for (final v in ProfileFrameType.values) {
      if (v.name == raw) return v;
    }
    return null;
  }

  Future<void> _setSelected(ProfileFrameType? t) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (t == null) {
        await prefs.remove(_kSelectedFrame);
      } else {
        await prefs.setString(_kSelectedFrame, t.name);
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _selected = t);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          t == null ? 'Frame Removed ✅' : 'Frame Applied ✅',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  String _label(ProfileFrameType t) {
    // Simple readable labels (آپ چاہیں تو localization میں add کروا لینا)
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
        return 'PREMIUM DOTS RUN';
      case ProfileFrameType.auroraLoop:
        return 'AURORA LOOP';
      case ProfileFrameType.luxuryShimmerBand:
        return 'LUXURY SHIMMER BAND';
    }
  }

  Widget _pageBg({required Widget child}) {
    // Keeping consistent with your settings rules:
    // Dark => masterGoldGradient background, Light => white
    return Container(
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
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _pageBg(
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(
                onBack: () => Navigator.pop(context),
                t: _anim.value,
              ),
              const SizedBox(height: 10),

              // ✅ Preview grid
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                  child: Column(
                    children: [
                      _SectionTitle(t: _anim.value, text: 'CHOOSE YOUR FRAME'),
                      const SizedBox(height: 12),

                      // ✅ "None" / remove frame tile
                      _FrameTile(
                        isDark: _isDark,
                        t: _anim.value,
                        title: 'NONE (NO FRAME)',
                        selected: _selected == null,
                        onTap: () => _setSelected(null),
                        preview: _PreviewAvatarOnly(
                          isDark: _isDark,
                          t: _anim.value,
                        ),
                      ),

                      const SizedBox(height: 12),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ProfileFrameType.values.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.05,
                        ),
                        itemBuilder: (_, i) {
                          final type = ProfileFrameType.values[i];
                          final isSel = _selected == type;

                          return _FrameTile(
                            isDark: _isDark,
                            t: _anim.value,
                            title: _label(type),
                            selected: isSel,
                            onTap: () => _setSelected(type),
                            preview: ProfileAvatarWithFrame(
                              size: 78,
                              framePadding: 8,
                              frameType: type,
                              animate: true,
                              avatarChild: _DemoAvatar(
                                isDark: _isDark,
                                t: _anim.value,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 18),
                      Text(
                        'Tap any preview to apply.\nFrames are saved automatically.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.75),
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
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

/// ✅ Top bar matching your premium look
class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final double t;

  const _TopBar({
    required this.onBack,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        children: [
          // left spacer
          const SizedBox(width: 44),

          Expanded(
            child: Center(
              child: Header3DShineText(
                text: 'FRAMES',
                t: t,
              ),
            ),
          ),

          // back on right (as your app style)
          GoldIcon3D(
            icon: Icons.arrow_forward,
            onTap: onBack,
            size: 26,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final double t;
  final String text;

  const _SectionTitle({required this.t, required this.text});

  @override
  Widget build(BuildContext context) {
    return GoldTextShimmer(
      text: text,
      t: t,
      fontSize: 14.2,
      letterSpacing: 1.8,
      fontWeight: FontWeight.w900,
      align: TextAlign.center,
    );
  }
}

/// ✅ One preview tile (3D button style + shimmer border)
class _FrameTile extends StatelessWidget {
  final bool isDark;
  final double t;
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final Widget preview;

  const _FrameTile({
    required this.isDark,
    required this.t,
    required this.title,
    required this.selected,
    required this.onTap,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final shimmerOn = AppSettings.shimmerVN.value;
    final tt = shimmerOn ? t : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: BorderShimmerPainter(
          t: tt,
          radius: 22,
          strokeWidth: 3.0,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),

            // Dark => gold button, Light => white button
            color: isDark ? null : Colors.white,
            gradient: isDark
                ? const LinearGradient(
                    colors: masterGoldGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.16),
                blurRadius: isDark ? 18 : 14,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(isDark ? 0.10 : 0.0),
                blurRadius: isDark ? 10 : 0,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 20,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Center(child: preview),
              const Spacer(),
              _TileTitle(
                t: tt,
                title: title,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileTitle extends StatelessWidget {
  final double t;
  final String title;

  const _TileTitle({required this.t, required this.title});

  @override
  Widget build(BuildContext context) {
    // Text always black + shimmer highlight (like your settings buttons)
    final shimmerOn = AppSettings.shimmerVN.value;

    final baseStyle = const TextStyle(
      color: Colors.black,
      fontSize: 11.6,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.0,
    );

    final base = Text(
      title,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: baseStyle,
    );

    if (!shimmerOn) return base;

    return Stack(
      children: [
        base,
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
                textAlign: TextAlign.center,
                maxLines: 2,
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

/// ✅ Demo avatar shown inside previews
class _DemoAvatar extends StatelessWidget {
  final bool isDark;
  final double t;

  const _DemoAvatar({
    required this.isDark,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.92),
            Colors.black.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'DD',
          style: TextStyle(
            color: Colors.white.withOpacity(0.15),
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
      ),
    );
  }
}

/// ✅ Preview for "None" option
class _PreviewAvatarOnly extends StatelessWidget {
  final bool isDark;
  final double t;

  const _PreviewAvatarOnly({
    required this.isDark,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 94,
      height: 94,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.86),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'NO\nFRAME',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.20),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

/// ✅ Main widget: avatar + animated premium frame overlay
class ProfileAvatarWithFrame extends StatefulWidget {
  final double size;
  final Widget avatarChild;
  final ProfileFrameType frameType;
  final bool animate;
  final double framePadding;

  /// optional: adds shadow to avatar child container
  final bool avatarShadow;

  const ProfileAvatarWithFrame({
    super.key,
    required this.size,
    required this.avatarChild,
    required this.frameType,
    this.animate = true,
    this.framePadding = 6,
    this.avatarShadow = false,
  });

  @override
  State<ProfileAvatarWithFrame> createState() => _ProfileAvatarWithFrameState();
}

class _ProfileAvatarWithFrameState extends State<ProfileAvatarWithFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: _durationFor(widget.frameType),
    );
    if (widget.animate) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant ProfileAvatarWithFrame oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.frameType != widget.frameType) {
      _c.duration = _durationFor(widget.frameType);
      if (widget.animate) {
        _c
          ..stop()
          ..value = 0
          ..repeat();
      }
    }

    if (oldWidget.animate != widget.animate) {
      if (widget.animate) {
        if (!_c.isAnimating) _c.repeat();
      } else {
        _c.stop();
      }
    }
  }

  Duration _durationFor(ProfileFrameType t) {
    switch (t) {
      case ProfileFrameType.royalGoldOrbit:
        return const Duration(milliseconds: 3200);
      case ProfileFrameType.diamondShine:
        return const Duration(milliseconds: 2800);
      case ProfileFrameType.flameCrown:
        return const Duration(milliseconds: 2600);
      case ProfileFrameType.neonPulse:
        return const Duration(milliseconds: 2400);
      case ProfileFrameType.sparkleRing:
        return const Duration(milliseconds: 3000);
      case ProfileFrameType.haloSweep:
        return const Duration(milliseconds: 3400);
      case ProfileFrameType.crystalWaves:
        return const Duration(milliseconds: 3100);
      case ProfileFrameType.premiumDotsRun:
        return const Duration(milliseconds: 2200);
      case ProfileFrameType.auroraLoop:
        return const Duration(milliseconds: 3600);
      case ProfileFrameType.luxuryShimmerBand:
        return const Duration(milliseconds: 2800);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outer = widget.size + (widget.framePadding * 2);

    return SizedBox(
      width: outer,
      height: outer,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(outer),
                painter: _ProfileFramePainter(
                  t: t,
                  type: widget.frameType,
                ),
              ),
              ClipOval(
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: widget.avatarShadow
                        ? const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 14,
                              offset: Offset(0, 8),
                            )
                          ]
                        : null,
                  ),
                  child: widget.avatarChild,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ✅ Painter dispatcher for styles
class _ProfileFramePainter extends CustomPainter {
  final double t;
  final ProfileFrameType type;

  _ProfileFramePainter({required this.t, required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (math.min(size.width, size.height) / 2);

    final ringW = r * 0.14;
    final innerR = r - ringW * 0.75;

    switch (type) {
      case ProfileFrameType.royalGoldOrbit:
        _royalGoldOrbit(canvas, c, innerR, ringW, t);
        break;
      case ProfileFrameType.diamondShine:
        _diamondShine(canvas, c, innerR, ringW, t);
        break;
      case ProfileFrameType.flameCrown:
        _flameCrown(canvas, c, innerR, ringW, t);
        break;
      case ProfileFrameType.neonPulse:
        _neonPulse(canvas, c, innerR, ringW, t);
        break;
      case ProfileFrameType.sparkleRing:
        _sparkleRing(canvas, c, innerR, ringW, t);
        break;
      case ProfileFrameType.haloSweep:
        _haloSweep(canvas, c, innerR, ringW, t);
        break;
      case ProfileFrameType.crystalWaves:
        _crystalWaves(canvas, c, innerR, ringW, t);
        break;
      case ProfileFrameType.premiumDotsRun:
        _premiumDotsRun(canvas, c, innerR, ringW, t);
        break;
      case ProfileFrameType.auroraLoop:
        _auroraLoop(canvas, c, innerR, ringW, t);
        break;
      case ProfileFrameType.luxuryShimmerBand:
        _luxuryShimmerBand(canvas, c, innerR, ringW, t);
        break;
    }
  }

  void _drawBaseGoldRing(Canvas canvas, Offset c, double innerR, double ringW) {
    final rect = Rect.fromCircle(center: c, radius: innerR + ringW * 0.55);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringW
      ..shader = LinearGradient(
        colors: masterGoldGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringW * 1.35
      ..color = Colors.white.withOpacity(0.10);

    canvas.drawCircle(c, innerR + ringW * 0.45, glow);
    canvas.drawCircle(c, innerR + ringW * 0.45, p);
  }

  void _drawSweepHighlight(
    Canvas canvas,
    Offset c,
    double radius,
    double ringW,
    double start,
    double sweep,
  ) {
    final rect = Rect.fromCircle(center: c, radius: radius);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = ringW
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.85),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(start),
      ).createShader(rect);

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: radius),
      0,
      sweep,
      false,
      p,
    );
  }

  void _royalGoldOrbit(Canvas canvas, Offset c, double innerR, double ringW, double t) {
    _drawBaseGoldRing(canvas, c, innerR, ringW);

    final orbitR = innerR + ringW * 0.45;
    const count = 3;
    for (int i = 0; i < count; i++) {
      final ang = (t * math.pi * 2) + (i * (math.pi * 2 / count));
      final p = Offset(c.dx + math.cos(ang) * orbitR, c.dy + math.sin(ang) * orbitR);

      final gem = Paint()
        ..color = Colors.white.withOpacity(0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(p, ringW * 0.26, gem);
      canvas.drawCircle(p, ringW * 0.18, Paint()..color = Colors.white.withOpacity(0.85));
    }

    _drawSweepHighlight(
      canvas,
      c,
      innerR + ringW * 0.45,
      ringW * 0.55,
      (t * math.pi * 2),
      math.pi * 0.75,
    );
  }

  void _diamondShine(Canvas canvas, Offset c, double innerR, double ringW, double t) {
    _drawBaseGoldRing(canvas, c, innerR, ringW);

    final rr = innerR + ringW * 0.45;
    final rect = Rect.fromCircle(center: c, radius: rr);

    const spikes = 10;
    for (int i = 0; i < spikes; i++) {
      final ang = (i * (math.pi * 2 / spikes)) + (t * 0.6);
      final p1 = Offset(
        c.dx + math.cos(ang) * (rr - ringW * 0.10),
        c.dy + math.sin(ang) * (rr - ringW * 0.10),
      );
      final p2 = Offset(
        c.dx + math.cos(ang) * (rr + ringW * 0.55),
        c.dy + math.sin(ang) * (rr + ringW * 0.55),
      );

      final line = Paint()
        ..strokeWidth = ringW * 0.10
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(0.12);

      canvas.drawLine(p1, p2, line);
    }

    final sweepAng = (t * math.pi * 2);
    final sweepPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringW * 0.65
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.95),
          Colors.white.withOpacity(0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.7, 1.0],
        transform: GradientRotation(sweepAng),
      ).createShader(rect);

    canvas.drawArc(rect, 0, math.pi * 2, false, sweepPaint);
  }

  void _flameCrown(Canvas canvas, Offset c, double innerR, double ringW, double t) {
    _drawBaseGoldRing(canvas, c, innerR, ringW);

    final top = Offset(c.dx, c.dy - (innerR + ringW * 0.95));
    const flames = 7;
    for (int i = 0; i < flames; i++) {
      final x = (i - (flames - 1) / 2) * ringW * 0.55;
      final wave = math.sin((t * math.pi * 2) + i) * ringW * 0.18;
      final h = ringW * (1.10 + 0.35 * math.sin((t * math.pi * 2) + i * 0.6));

      final p = Path()
        ..moveTo(top.dx + x, top.dy + ringW * 0.55)
        ..quadraticBezierTo(top.dx + x + ringW * 0.20, top.dy - h + wave, top.dx + x, top.dy - h)
        ..quadraticBezierTo(top.dx + x - ringW * 0.20, top.dy - h + wave, top.dx + x, top.dy + ringW * 0.55)
        ..close();

      final flamePaint = Paint()
        ..color = Colors.white.withOpacity(0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawPath(p, flamePaint);
      canvas.drawPath(p, Paint()..color = Colors.white.withOpacity(0.16));
    }

    _drawSweepHighlight(
      canvas,
      c,
      innerR + ringW * 0.45,
      ringW * 0.45,
      (t * math.pi * 2),
      math.pi * 0.55,
    );
  }

  void _neonPulse(Canvas canvas, Offset c, double innerR, double ringW, double t) {
    _drawBaseGoldRing(canvas, c, innerR, ringW);

    final rr = innerR + ringW * 0.45;
    final pulse = (0.65 + 0.35 * math.sin(t * math.pi * 2));
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringW * (1.6 * pulse)
      ..color = Colors.white.withOpacity(0.10 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    canvas.drawCircle(c, rr, glow);
    _drawSweepHighlight(canvas, c, rr, ringW * 0.55, t * math.pi * 2, math.pi * 0.40);
  }

  void _sparkleRing(Canvas canvas, Offset c, double innerR, double ringW, double t) {
    _drawBaseGoldRing(canvas, c, innerR, ringW);

    final rr = innerR + ringW * 0.45;
    const sparkCount = 14;
    for (int i = 0; i < sparkCount; i++) {
      final ang = (i * (math.pi * 2 / sparkCount)) + (t * math.pi * 2);
      final p = Offset(c.dx + math.cos(ang) * rr, c.dy + math.sin(ang) * rr);
      final s = (0.6 + 0.4 * math.sin((t * math.pi * 2) + i)) * ringW * 0.20;

      final paint = Paint()
        ..color = Colors.white.withOpacity(0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(p, s, paint);
      canvas.drawCircle(p, s * 0.55, Paint()..color = Colors.white.withOpacity(0.22));
    }
  }

  void _haloSweep(Canvas canvas, Offset c, double innerR, double ringW, double t) {
    _drawBaseGoldRing(canvas, c, innerR, ringW);

    final rr = innerR + ringW * 0.45;
    final rect = Rect.fromCircle(center: c, radius: rr);

    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringW * 0.85
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.22),
          Colors.white.withOpacity(0.65),
          Colors.white.withOpacity(0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.55, 0.75, 1.0],
        transform: GradientRotation(t * math.pi * 2),
      ).createShader(rect);

    canvas.drawArc(rect, 0, math.pi * 2, false, p);
  }

  void _crystalWaves(Canvas canvas, Offset c, double innerR, double ringW, double t) {
    _drawBaseGoldRing(canvas, c, innerR, ringW);

    final rr = innerR + ringW * 0.45;
    const waveCount = 3;

    for (int k = 0; k < waveCount; k++) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringW * 0.30
        ..color = Colors.white.withOpacity(0.10 + k * 0.04);

      final rrr = rr + (k * ringW * 0.35);
      final wobble = math.sin((t * math.pi * 2) + k) * ringW * 0.14;
      canvas.drawCircle(c, rrr + wobble, p);
    }

    _drawSweepHighlight(canvas, c, rr, ringW * 0.40, t * math.pi * 2, math.pi * 0.55);
  }

  void _premiumDotsRun(Canvas canvas, Offset c, double innerR, double ringW, double t) {
    _drawBaseGoldRing(canvas, c, innerR, ringW);

    final rr = innerR + ringW * 0.45;
    const dots = 18;
    for (int i = 0; i < dots; i++) {
      final phase = i / dots;
      final ang = (phase * math.pi * 2) + (t * math.pi * 2);
      final p = Offset(c.dx + math.cos(ang) * rr, c.dy + math.sin(ang) * rr);

      final alpha = (0.15 + 0.55 * (1 - ((phase - t).abs() % 1.0))).clamp(0.10, 0.70);
      final dot = Paint()
        ..color = Colors.white.withOpacity(alpha.toDouble())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

      canvas.drawCircle(p, ringW * 0.16, dot);
    }
  }

  void _auroraLoop(Canvas canvas, Offset c, double innerR, double ringW, double t) {
    _drawBaseGoldRing(canvas, c, innerR, ringW);

    final rr = innerR + ringW * 0.45;
    final rect = Rect.fromCircle(center: c, radius: rr);

    final p1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringW * 0.70
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.25),
          Colors.white.withOpacity(0.55),
          Colors.white.withOpacity(0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.55, 0.75, 1.0],
        transform: GradientRotation(t * math.pi * 2),
      ).createShader(rect);

    final p2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringW * 0.40
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.16),
          Colors.white.withOpacity(0.40),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 0.75, 1.0],
        transform: GradientRotation((t * math.pi * 2) + 1.4),
      ).createShader(rect);

    canvas.drawArc(rect, 0, math.pi * 2, false, p1);
    canvas.drawArc(rect, 0, math.pi * 2, false, p2);
  }

  void _luxuryShimmerBand(Canvas canvas, Offset c, double innerR, double ringW, double t) {
    _drawBaseGoldRing(canvas, c, innerR, ringW);

    final rr = innerR + ringW * 0.45;
    final rect = Rect.fromCircle(center: c, radius: rr);

    final band = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringW * 0.95
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.08),
          Colors.white.withOpacity(0.85),
          Colors.white.withOpacity(0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.52, 0.70, 1.0],
        transform: GradientRotation(t * math.pi * 2),
      ).createShader(rect);

    canvas.drawArc(rect, 0, math.pi * 2, false, band);
  }

  @override
  bool shouldRepaint(covariant _ProfileFramePainter old) {
    return old.t != t || old.type != type;
  }
}