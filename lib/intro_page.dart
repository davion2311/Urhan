import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import'package:shared_preferences/shared_preferences.dart';
import'package:video_player/video_player.dart';

class IntroPage extends StatefulWidget {
const IntroPage({Key? key}) : super(key: key);

@override
State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> with TickerProviderStateMixin {
static const String _videoPath = 'assets/intro.mp4';
static const String _kShopNameKey = 'shop_name';
static const String _kDefaultName = 'DIGITAL DARZI';

VideoPlayerController? _videoController;

Timer? _continueTimer;
bool _showContinue = false;

String _shopName = _kDefaultName;

late final AnimationController _animCtrl;
late final AnimationController _glitchCtrl;

@override
void initState() {
super.initState();

_animCtrl = AnimationController(  
  vsync: this,  
  duration: const Duration(milliseconds: 1500),  
)..repeat(reverse: true);  

_glitchCtrl = AnimationController(  
  vsync: this,  
  duration: const Duration(milliseconds: 3000),  
)..repeat();  

_loadShopName();  
_initVideo();  
_startContinueTimer();

}

void _startContinueTimer() {
_continueTimer?.cancel();
_continueTimer = Timer(const Duration(seconds: 4), () {
if (!mounted) return;
setState(() => _showContinue = true);
});
}

Future<void> _loadShopName() async {
final prefs = await SharedPreferences.getInstance();
final saved = prefs.getString(_kShopNameKey);
if (!mounted) return;
setState(() {
_shopName = (saved == null || saved.trim().isEmpty)
? _kDefaultName
: saved.trim().toUpperCase();
});
}

Future<void> _saveShopName(String name) async {
final prefs = await SharedPreferences.getInstance();
await prefs.setString(_kShopNameKey, name.trim().toUpperCase());
}

Future<void> _initVideo() async {
final controller = VideoPlayerController.asset(_videoPath);

try {  
  await controller.initialize();  
  controller  
    ..setLooping(true)  
    ..setVolume(0.0)  
    ..play();  

  if (!mounted) {  
    controller.dispose();  
    return;  
  }  

  setState(() => _videoController = controller);  
} catch (_) {  
  try {  
    controller.dispose();  
  } catch (_) {}  
  if (!mounted) return;  
  setState(() => _videoController = null);  
}

}

@override
void dispose() {
_continueTimer?.cancel();
_videoController?.dispose();
_animCtrl.dispose();
_glitchCtrl.dispose();
super.dispose();
}

void _goNext() {
if (!mounted) return;
Navigator.pushReplacementNamed(context, '/auth');
}

Future<void> _openEditNameDialog() async {
final controller = TextEditingController(text: _shopName);

final result = await showDialog<String>(  
  context: context,  
  barrierDismissible: true,  
  builder: (ctx) {  
    return Dialog(  
      backgroundColor: Colors.transparent,  
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),  
      child: ClipRRect(  
        borderRadius: BorderRadius.circular(22),  
        child: BackdropFilter(  
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),  
          child: Container(  
            padding: const EdgeInsets.all(16),  
            decoration: BoxDecoration(  
              color: Colors.black.withOpacity(0.35),  
              borderRadius: BorderRadius.circular(22),  
              border: Border.all(color: Colors.white.withOpacity(0.22)),  
            ),  
            child: Column(  
              mainAxisSize: MainAxisSize.min,  
              children: [  
                const SizedBox(height: 6),  
                AnimatedBuilder(  
                  animation: _animCtrl,  
                  builder: (_, __) => _Shimmer3DText(  
                    text: 'EDIT SHOP NAME',  
                    t: _animCtrl.value,  
                    fontSize: 15,  
                    letterSpacing: 2.2,  
                  ),  
                ),  
                const SizedBox(height: 14),  
                TextField(  
                  controller: controller,  
                  textCapitalization: TextCapitalization.characters,  
                  style: const TextStyle(  
                    color: Colors.white,  
                    fontSize: 16,  
                    fontWeight: FontWeight.w700,  
                    letterSpacing: 1.2,  
                  ),  
                  decoration: InputDecoration(  
                    hintText: 'ENTER NAME',  
                    hintStyle:  
                        TextStyle(color: Colors.white.withOpacity(0.55)),  
                    filled: true,  
                    fillColor: Colors.white.withOpacity(0.08),  
                    contentPadding: const EdgeInsets.symmetric(  
                        horizontal: 14, vertical: 14),  
                    border: OutlineInputBorder(  
                      borderRadius: BorderRadius.circular(14),  
                      borderSide: BorderSide(  
                          color: Colors.white.withOpacity(0.18)),  
                    ),  
                    enabledBorder: OutlineInputBorder(  
                      borderRadius: BorderRadius.circular(14),  
                      borderSide: BorderSide(  
                          color: Colors.white.withOpacity(0.18)),  
                    ),  
                    focusedBorder: OutlineInputBorder(  
                      borderRadius: BorderRadius.circular(14),  
                      borderSide: BorderSide(  
                          color: Colors.white.withOpacity(0.35)),  
                    ),  
                  ),  
                ),  
                const SizedBox(height: 14),  
                Row(  
                  children: [  
                    Expanded(  
                      child: _GlassMiniButton(  
                        label: 'CANCEL',  
                        onTap: () => Navigator.pop(ctx),  
                      ),  
                    ),  
                    const SizedBox(width: 10),  
                    Expanded(  
                      child: _GlassMiniButton(  
                        label: 'SAVE',  
                        onTap: () {  
                          final v = controller.text.trim();  
                          Navigator.pop(ctx,  
                              v.isEmpty ? _kDefaultName : v.toUpperCase());  
                        },  
                      ),  
                    ),  
                  ],  
                ),  
              ],  
            ),  
          ),  
        ),  
      ),  
    );  
  },  
);  

if (result != null && mounted) {  
  setState(() => _shopName = result);  
  await _saveShopName(result);  
}

}

@override
Widget build(BuildContext context) {
final mq = MediaQuery.of(context);

return Scaffold(  
  body: Stack(  
    fit: StackFit.expand,  
    children: [  
      // Video (no crop)  
      if (_videoController != null && _videoController!.value.isInitialized)  
        Container(  
          color: Colors.black,  
          alignment: Alignment.center,  
          child: FittedBox(  
            fit: BoxFit.contain,  
            child: SizedBox(  
              width: _videoController!.value.size.width,  
              height: _videoController!.value.size.height,  
              child: VideoPlayer(_videoController!),  
            ),  
          ),  
        )  
      else  
        Container(color: Colors.black),  

      // Overlay  
      Container(  
        decoration: BoxDecoration(  
          gradient: LinearGradient(  
            begin: Alignment.topCenter,  
            end: Alignment.bottomCenter,  
            colors: [  
              Colors.black.withOpacity(0.45),  
              Colors.black.withOpacity(0.10),  
              Colors.black.withOpacity(0.55),  
            ],  
          ),  
        ),  
      ),  

      // TOP GOLD CAPSULE - height=120, text with glitch  
      SafeArea(  
        child: Padding(  
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),  
          child: Align(  
            alignment: Alignment.topCenter,  
            child: _GoldCapsuleShell(  
              height: 120,  
              horizontalPadding: 14,  
              child: ConstrainedBox(  
                constraints: const BoxConstraints(  
                  minWidth: 260,  
                  maxWidth: 360,  
                ),  
                child: Row(  
                  children: [  
                    const SizedBox(width: 8),  

                    Expanded(  
                      child: Center(  
                        child: AnimatedBuilder(  
                          animation: _glitchCtrl,  
                          builder: (_, __) {  
                            return FittedBox(  
                              fit: BoxFit.scaleDown,  
                              child: _GlitchText(  
                                text: _shopName,  
                                t: _glitchCtrl.value,  
                                fontSize: 100,  
                                letterSpacing: 1.8,  
                              ),  
                            );  
                          },  
                        ),  
                      ),  
                    ),  

                    const SizedBox(width: 8),  

                    _GoldEditButton(onTap: _openEditNameDialog),  

                    const SizedBox(width: 10),  
                  ],  
                ),  
              ),  
            ),  
          ),  
        ),  
      ),  

      // Bottom: SKIP + CONTINUE (with glitch on CONTINUE)  
      Positioned(  
        left: 18,  
        right: 18,  
        bottom: mq.padding.bottom + 22,  
        child: Row(  
          mainAxisAlignment: MainAxisAlignment.spaceBetween,  
          children: [  
            GestureDetector(  
              onTap: _goNext,  
              child: Text(  
                'SKIP',  
                style: TextStyle(  
                  color: Colors.white.withOpacity(0.92),  
                  fontSize: 14,  
                  fontWeight: FontWeight.w800,  
                  letterSpacing: 2.4,  
                  shadows: [  
                    Shadow(  
                      blurRadius: 14,  
                      color: Colors.black.withOpacity(0.65),  
                      offset: const Offset(0, 6),  
                    ),  
                  ],  
                ),  
              ),  
            ),  
            AnimatedOpacity(  
              opacity: _showContinue ? 1 : 0,  
              duration: const Duration(milliseconds: 250),  
              child: IgnorePointer(  
                ignoring: !_showContinue,  
                child: _GoldCapsuleButton(  
                  onTap: _goNext,  
                  child: AnimatedBuilder(  
                    animation: _glitchCtrl,  
                    builder: (_, __) => _GlitchText(  
                      text: 'CONTINUE',  
                      t: _glitchCtrl.value,  
                      fontSize: 18,  
                      letterSpacing: 2.6,  
                    ),  
                  ),  
                ),  
              ),  
            ),  
          ],  
        ),  
      ),  
    ],  
  ),  
);

}
}

// ------------------ GOLD CAPSULE ------------------

class _GoldCapsuleShell extends StatelessWidget {
final double height;
final double horizontalPadding;
final Widget child;

const _GoldCapsuleShell({
required this.height,
required this.horizontalPadding,
required this.child,
});

@override
Widget build(BuildContext context) {
return Container(
height: height,
padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(999),
gradient: const LinearGradient(
begin: Alignment.centerLeft,
end: Alignment.centerRight,
colors: [
Color(0xFFC8A349),
Color(0xFFFFE7A6),
Color(0xFFC8A349),
],
stops: [0.0, 0.52, 1.0],
),
boxShadow: const [
BoxShadow(
color: Color(0x99000000),
blurRadius: 16,
offset: Offset(0, 10),
),
],
),
alignment: Alignment.center,
child: child,
);
}
}

class _GoldCapsuleButton extends StatelessWidget {
final VoidCallback onTap;
final Widget child;

const _GoldCapsuleButton({required this.onTap, required this.child});

@override
Widget build(BuildContext context) {
return GestureDetector(
onTap: onTap,
child: Container(
height: 54,
padding: const EdgeInsets.symmetric(horizontal: 34),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(999),
gradient: const LinearGradient(
begin: Alignment.centerLeft,
end: Alignment.centerRight,
colors: [
Color(0xFFC8A349),
Color(0xFFFFE7A6),
Color(0xFFC8A349),
],
stops: [0.0, 0.52, 1.0],
),
boxShadow: const [
BoxShadow(
color: Color(0x99000000),
blurRadius: 16,
offset: Offset(0, 10),
),
],
),
alignment: Alignment.center,
child: Center(child: child),
),
);
}
}

class _GoldEditButton extends StatelessWidget {
final VoidCallback onTap;
const _GoldEditButton({required this.onTap});

@override
Widget build(BuildContext context) {
return GestureDetector(
onTap: onTap,
child: Container(
width: 32,
height: 32,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: Colors.black.withOpacity(0.10),
border: Border.all(color: Colors.black.withOpacity(0.18)),
),
child: const Icon(
Icons.edit,
size: 16,
color: Color(0xFF0B0B0B),
),
),
);
}
}

// ------------------ GLITCH TEXT (ENHANCED) ------------------

class _GlitchText extends StatelessWidget {
final String text;
final double t;
final double fontSize;
final double letterSpacing;

const _GlitchText({
required this.text,
required this.t,
required this.fontSize,
required this.letterSpacing,
});

@override
Widget build(BuildContext context) {
final random = math.Random(t.hashCode);
final shouldGlitch = t % 0.2 < 0.12;

final baseStyle = TextStyle(  
  fontSize: fontSize,  
  fontWeight: FontWeight.w900,  
  letterSpacing: letterSpacing,  
  color: const Color(0xFF0B0B0B),  
  height: 1.0,  
);  

if (!shouldGlitch) {  
  return Text(  
    text,  
    maxLines: 1,  
    overflow: TextOverflow.visible,  
    style: baseStyle.copyWith(  
      shadows: [  
        Shadow(  
          blurRadius: 20,  
          color: Colors.white.withOpacity(0.3),  
          offset: const Offset(0, 0),  
        ),  
        Shadow(  
          blurRadius: 18,  
          color: Color(0xFFFFE7A6).withOpacity(0.35),  
          offset: const Offset(0, 0),  
        ),  
        const Shadow(  
          blurRadius: 12,  
          color: Colors.black54,  
          offset: Offset(0, 6),  
        ),  
      ],  
    ),  
  );  
}  

final offsetX = (random.nextDouble() - 0.5) * 8;  
final offsetY = (random.nextDouble() - 0.5) * 4;  

return Stack(  
  children: [  
    // Red channel (left)  
    Transform.translate(  
      offset: Offset(offsetX - 5, offsetY),  
      child: Text(  
        text,  
        maxLines: 1,  
        overflow: TextOverflow.visible,  
        style: baseStyle.copyWith(  
          color: Colors.red.withOpacity(1.0),  
        ),  
      ),  
    ),  
    // Cyan channel (right)  
    Transform.translate(  
      offset: Offset(offsetX + 5, offsetY),  
      child: Text(  
        text,  
        maxLines: 1,  
        overflow: TextOverflow.visible,  
        style: baseStyle.copyWith(  
          color: Colors.cyan.withOpacity(1.0),  
        ),  
      ),  
    ),  
    // Green channel (slight offset)  
    Transform.translate(  
      offset: Offset(offsetX, offsetY + 2),  
      child: Text(  
        text,  
        maxLines: 1,  
        overflow: TextOverflow.visible,  
        style: baseStyle.copyWith(  
          color: Colors.green.withOpacity(0.6),  
        ),  
      ),  
    ),  
    // Main text  
    Transform.translate(  
      offset: Offset(offsetX, offsetY),  
      child: Text(  
        text,  
        maxLines: 1,  
        overflow: TextOverflow.visible,  
        style: baseStyle.copyWith(  
          shadows: [  
            Shadow(  
              blurRadius: 30,  
              color: Colors.white.withOpacity(0.7),  
              offset: const Offset(0, 0),  
            ),  
            const Shadow(  
              blurRadius: 15,  
              color: Colors.black87,  
              offset: Offset(0, 6),  
            ),  
          ],  
        ),  
      ),  
    ),  
  ],  
);

}
}

// ------------------ OTHER TEXT WIDGETS ------------------

class _Shimmer3DText extends StatelessWidget {
final String text;
final double t;
final double fontSize;
final double letterSpacing;

const _Shimmer3DText({
required this.text,
required this.t,
required this.fontSize,
required this.letterSpacing,
});

@override
Widget build(BuildContext context) {
final base = TextStyle(
fontSize: fontSize,
letterSpacing: letterSpacing,
fontWeight: FontWeight.w900,
);

final shift = (t * 2.0) - 1.0;  
final begin = Alignment(-1.2 + shift, -1);  
final end = Alignment(1.2 + shift, 1);  

return Stack(  
  children: [  
    Text(  
      text,  
      style: base.copyWith(  
        color: Colors.black.withOpacity(0.60),  
        shadows: const [  
          Shadow(offset: Offset(0, 2), blurRadius: 2),  
          Shadow(offset: Offset(0, 7), blurRadius: 14),  
        ],  
      ),  
    ),  
    ShaderMask(  
      shaderCallback: (rect) {  
        return LinearGradient(  
          begin: begin,  
          end: end,  
          colors: const [  
            Colors.white,  
            Color(0xFFB9F2FF),  
            Colors.white,  
          ],  
          stops: const [0.0, 0.5, 1.0],  
        ).createShader(rect);  
      },  
      blendMode: BlendMode.srcIn,  
      child: Text(  
        text,  
        style: base.copyWith(  
          color: Colors.white,  
          shadows: [  
            Shadow(  
              blurRadius: 16,  
              color: Colors.white.withOpacity(0.22),  
              offset: const Offset(0, 0),  
            ),  
          ],  
        ),  
      ),  
    ),  
  ],  
);

}
}

class _GlassMiniButton extends StatelessWidget {
final String label;
final VoidCallback onTap;
const _GlassMiniButton({required this.label, required this.onTap});

@override
Widget build(BuildContext context) {
return GestureDetector(
onTap: onTap,
child: ClipRRect(
borderRadius: BorderRadius.circular(14),
child: BackdropFilter(
filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
child: Container(
padding: const EdgeInsets.symmetric(vertical: 12),
alignment: Alignment.center,
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.10),
borderRadius: BorderRadius.circular(14),
border: Border.all(color: Colors.white.withOpacity(0.22)),
),
child: Text(
label,
style: TextStyle(
color: Colors.white.withOpacity(0.95),
fontSize: 12,
fontWeight: FontWeight.w900,
letterSpacing: 2.0,
),
),
),
),
),
);
}
}