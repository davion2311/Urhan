// lib/ui_kit.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'app_settings.dart';

const List<Color> masterGoldGradient = [
  Color(0xFFBF953F),
  Color(0xFFFCF6BA),
  Color(0xFFD4AF37),
  Color(0xFFBF953F),
];

/// ✅ 3D Gold Icon (circle bg + border + shadow) — text shadows/backgrounds issue is NOT here
class GoldIcon3D extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const GoldIcon3D({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 30,
  });

  @override
  Widget build(BuildContext context) {
    final shimmerOn = AppSettings.shimmerVN.value;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.72),
          border: Border.all(
            color: const Color(0xFFD4AF37).withOpacity(0.95),
            width: 2.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: ShaderMask(
            shaderCallback: (rect) => LinearGradient(
              colors: shimmerOn
                  ? masterGoldGradient
                  : const [Color(0xFFD4AF37), Color(0xFFD4AF37)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(rect),
            blendMode: BlendMode.srcIn,
            child: Icon(icon, size: size, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// ✅ Header text — NO shadow / NO background behind text
class Header3DShineText extends StatelessWidget {
  final String text;
  final double t;
  final String? fontFamily;

  const Header3DShineText({
    super.key,
    required this.text,
    required this.t,
    this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    final shimmerOn = AppSettings.shimmerVN.value;

    final base = TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w900,
      letterSpacing: 2.2,
      fontFamily: fontFamily,
    );

    // ✅ shimmer OFF => plain clean text (no shadow)
    if (!shimmerOn) {
      return Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: base.copyWith(color: const Color(0xFF050505)),
      );
    }

    final shift = (t * 2.0) - 1.0;
    final begin = Alignment(-1.2 + shift, -1);
    final end = Alignment(1.2 + shift, 1);

    // ✅ shimmer ON => clean base + shine overlay (no shadow)
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: base.copyWith(color: const Color(0xFF0A0A0A)),
        ),
        ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            begin: begin,
            end: end,
            colors: [
              const Color(0xFF050505),
              const Color(0xFF050505).withOpacity(0.86),
              Colors.white.withOpacity(0.30),
              const Color(0xFF050505).withOpacity(0.92),
              const Color(0xFF050505),
            ],
            stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
          ).createShader(rect),
          blendMode: BlendMode.srcIn,
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: base.copyWith(color: const Color(0xFF050505)),
          ),
        ),
      ],
    );
  }
}

/// ✅ Gold shimmer text — NO shadow / NO background behind text
class GoldTextShimmer extends StatelessWidget {
  final String text;
  final double t;
  final double fontSize;
  final double letterSpacing;
  final FontWeight fontWeight;
  final TextAlign? align;
  final String? fontFamily;

  const GoldTextShimmer({
    super.key,
    required this.text,
    required this.t,
    this.fontSize = 16,
    this.letterSpacing = 1.6,
    this.fontWeight = FontWeight.w900,
    this.align,
    this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    final shimmerOn = AppSettings.shimmerVN.value;

    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      fontFamily: fontFamily,
    );

    // ✅ shimmer OFF => simple gold gradient text (no shadow)
    if (!shimmerOn) {
      return ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          colors: masterGoldGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
        blendMode: BlendMode.srcIn,
        child: Text(
          text,
          textAlign: align,
          style: style.copyWith(color: Colors.white),
        ),
      );
    }

    final shift = (t * 2.0) - 1.0;
    final begin = Alignment(-1.25 + shift, -1);
    final end = Alignment(1.25 + shift, 1);

    // ✅ shimmer ON => base gold + moving white highlight (no shadow)
    return Stack(
      children: [
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: masterGoldGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(rect),
          blendMode: BlendMode.srcIn,
          child: Text(
            text,
            textAlign: align,
            style: style.copyWith(color: Colors.white),
          ),
        ),
        ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            begin: begin,
            end: end,
            colors: [
              Colors.transparent,
              Colors.white.withOpacity(0.35),
              Colors.transparent,
            ],
            stops: const [0.35, 0.5, 0.65],
          ).createShader(rect),
          blendMode: BlendMode.srcATop,
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: masterGoldGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(rect),
            blendMode: BlendMode.srcIn,
            child: Text(
              text,
              textAlign: align,
              style: style.copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// ✅ Border shimmer painter (global ON/OFF)
class BorderShimmerPainter extends CustomPainter {
  final double t;
  final double radius;
  final double strokeWidth;

  BorderShimmerPainter({
    required this.t,
    this.radius = 28,
    this.strokeWidth = 3.4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = masterGoldGradient.first.withOpacity(0.85);
    canvas.drawPath(path, base);

    // ✅ shimmer OFF => only base border
    if (!AppSettings.shimmerVN.value) return;

    final ang = t * 2 * math.pi;
    final dx = math.cos(ang) * 0.9;
    final dy = math.sin(ang) * 0.9;

    final shader = LinearGradient(
      begin: Alignment(-1.2 + dx, -1.2 + dy),
      end: Alignment(1.2 + dx, 1.2 + dy),
      colors: [
        masterGoldGradient.first.withOpacity(0.08),
        masterGoldGradient[1].withOpacity(0.92),
        Colors.white.withOpacity(0.28),
        masterGoldGradient[2].withOpacity(0.22),
        masterGoldGradient.first.withOpacity(0.08),
      ],
      stops: const [0.0, 0.45, 0.55, 0.72, 1.0],
    ).createShader(rect);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = shader;

    canvas.drawPath(path, glow);
  }

  @override
  bool shouldRepaint(covariant BorderShimmerPainter old) =>
      old.t != t || old.strokeWidth != strokeWidth || old.radius != radius;
}

class GoldCapsuleButton extends StatelessWidget {
  final double t;
  final String text;
  final VoidCallback onTap;
  final double height;
  final String? fontFamily;

  const GoldCapsuleButton({
    super.key,
    required this.t,
    required this.text,
    required this.onTap,
    this.height = 56,
    this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: masterGoldGradient,
            stops: [0.0, 0.45, 0.72, 1.0],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: GoldTextShimmer(
          text: text,
          t: t,
          fontSize: 18,
          letterSpacing: 2.0,
          align: TextAlign.center,
          fontFamily: fontFamily,
        ),
      ),
    );
  }
}

class SimplePlaceholder extends StatelessWidget {
  final String title;
  const SimplePlaceholder({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ),
    );
  }
}