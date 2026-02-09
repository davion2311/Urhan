// lib/settings_header.dart
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import 'app_settings.dart';
import 'ui_kit.dart';
import 'profile_frames.dart';

class SettingsHeader extends StatefulWidget {
  final VoidCallback onBack;

  const SettingsHeader({
    super.key,
    required this.onBack,
  });

  @override
  State<SettingsHeader> createState() => _SettingsHeaderState();
}

class _SettingsHeaderState extends State<SettingsHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  String _name = "WAQAR TAILOR'S";
  String _phone = '';
  String _about = '';
  Uint8List? _profileBytes;

  // ✅ NEW keys
  static const _kNameV3 = 'settings_profile_name_v3';
  static const _kPhoneV3 = 'settings_profile_phone_v3';
  static const _kAboutV3 = 'settings_profile_about_v3';
  static const _kPhotoV3 = 'settings_profile_photo_b64_v3';

  // ✅ FALLBACK old keys (پرانا save بھی show ہوگا)
  static const _kNameOld = 'settings_profile_name';
  static const _kPhoneOld = 'settings_profile_phone';
  static const _kAboutOld = 'settings_profile_about';
  static const _kPhotoOld = 'settings_profile_photo_b64';

  // ✅ Frame keys (new + fallback)
  static const _kFrameV1 = 'settings_profile_frame_type_v1';
  static const _kFrameOld = 'settings_profile_frame_type';

  ProfileFrameType? _selectedFrame;

  final ImagePicker _picker = ImagePicker();
  bool get _shimmerOn => AppSettings.shimmerVN.value;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _syncAnimWithShimmer();
    AppSettings.shimmerVN.addListener(_syncAnimWithShimmer);

    _loadProfile();
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
    _anim.dispose();
    super.dispose();
  }

  ProfileFrameType? _tryParseFrame(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    for (final v in ProfileFrameType.values) {
      if (v.name == raw) return v;
    }
    return null;
  }

  String? _readFirstNonEmptyNullable(SharedPreferences prefs, List<String> keys) {
    for (final k in keys) {
      final v = prefs.getString(k);
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  String _readFirstNonEmpty(SharedPreferences prefs, List<String> keys) {
    return _readFirstNonEmptyNullable(prefs, keys) ?? '';
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final name = _readFirstNonEmptyNullable(prefs, [_kNameV3, _kNameOld]);
      final phone = _readFirstNonEmpty(prefs, [_kPhoneV3, _kPhoneOld]);
      final about = _readFirstNonEmpty(prefs, [_kAboutV3, _kAboutOld]);

      final b64 = _readFirstNonEmptyNullable(prefs, [_kPhotoV3, _kPhotoOld]);
      final frameRaw =
          _readFirstNonEmptyNullable(prefs, [_kFrameV1, _kFrameOld]);

      if (!mounted) return;
      setState(() {
        if (name != null && name.isNotEmpty) _name = name;
        _phone = phone;
        _about = about;
        _profileBytes = (b64 == null || b64.isEmpty) ? null : base64Decode(b64);
        _selectedFrame = _tryParseFrame(frameRaw);
      });
    } catch (_) {}
  }

  Future<void> _saveProfile({
    required String name,
    required String phone,
    required String about,
    required Uint8List? bytes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ Always save into NEW keys
      await prefs.setString(_kNameV3, name.trim());
      await prefs.setString(_kPhoneV3, phone.trim());
      await prefs.setString(_kAboutV3, about.trim());

      if (bytes == null) {
        await prefs.remove(_kPhotoV3);
      } else {
        await prefs.setString(_kPhotoV3, base64Encode(bytes));
      }
    } catch (_) {}
  }

  String _initials(String s) {
    final t = s.trim();
    if (t.isEmpty) return 'DD';
    final parts = t.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'DD';
    final first = parts.first;
    final last = parts.length >= 2 ? parts.last : '';
    final a = first.isNotEmpty ? first[0] : 'D';
    final b = last.isNotEmpty ? last[0] : (first.length >= 2 ? first[1] : 'D');
    return (a + b).toUpperCase();
  }

  Future<Uint8List?> _pickFromGalleryBytes() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      if (picked == null) return null;
      return await picked.readAsBytes();
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gallery error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  Future<void> _editProfile() async {
    final nameCtrl = TextEditingController(text: _name);
    final phoneCtrl = TextEditingController(text: _phone);
    final aboutCtrl = TextEditingController(text: _about);

    Uint8List? tempBytes = _profileBytes;

    final res = await showDialog<_ProfileResult>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              backgroundColor: Colors.black,
              surfaceTintColor: Colors.transparent,
              title: const Text(
                'EDIT PROFILE',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final pickedBytes = await _pickFromGalleryBytes();
                        if (pickedBytes == null) return;

                        if (!mounted) return;
                        final cropped = await Navigator.push<Uint8List?>(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                _CropSquarePage(bytes: pickedBytes, anim: _anim),
                          ),
                        );

                        if (cropped == null) return;
                        setLocal(() => tempBytes = cropped);
                      },
                      child: _ShimmerBorder(
                        t: _anim.value,
                        radius: 999,
                        strokeWidth: 3.2,
                        child: Container(
                          height: 96,
                          width: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black,
                            image: tempBytes == null
                                ? null
                                : DecorationImage(
                                    image: MemoryImage(tempBytes!),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          child: tempBytes == null
                              ? Center(
                                  child: ShaderMask(
                                    shaderCallback: (r) => const LinearGradient(
                                      colors: masterGoldGradient,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(r),
                                    blendMode: BlendMode.srcIn,
                                    child: const Text(
                                      'CHOOSE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.4,
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tap to choose photo',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _dialogField(
                      label: 'NAME',
                      controller: nameCtrl,
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 12),
                    _dialogField(
                      label: 'PHONE',
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _dialogField(
                      label: 'ABOUT',
                      controller: aboutCtrl,
                      keyboardType: TextInputType.text,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child:
                      const Text('CANCEL', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    final n = nameCtrl.text.trim();
                    final p = phoneCtrl.text.trim();
                    final a = aboutCtrl.text.trim();

                    if (n.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Name خالی نہیں ہو سکتا'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(
                      ctx,
                      _ProfileResult(name: n, phone: p, about: a, bytes: tempBytes),
                    );
                  },
                  child: const Text(
                    'SAVE',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || res == null) return;

    setState(() {
      _name = res.name;
      _phone = res.phone;
      _about = res.about;
      _profileBytes = res.bytes;
    });

    await _saveProfile(
      name: res.name,
      phone: res.phone,
      about: res.about,
      bytes: res.bytes,
    );

    await _loadProfile();
  }

  static Widget _dialogField({
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),
      cursorColor: const Color(0xFFD4AF37),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        filled: true,
        fillColor: const Color(0xFF0B0B0B),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _profileHeader();

  Widget _profileHeader() {
    const headerH = 150.0;

    return SizedBox(
      height: headerH,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.black, Color(0xFF0B0B0B), Colors.black],
                  stops: [0.0, 0.55, 1.0],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(70),
                  bottomRight: Radius.circular(70),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 22,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 10,
            right: 12,
            child: GestureDetector(
              onTap: widget.onBack,
              child: Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withOpacity(0.55),
                    width: 1.6,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 14,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                      colors: masterGoldGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(r),
                    blendMode: BlendMode.srcIn,
                    child: const Icon(Icons.arrow_forward,
                        size: 20, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Row(
              children: [
                _buildAvatarBlock(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _GoldTextLine(_name, t: _anim.value, size: 16.5, soft: false),
                      const SizedBox(height: 4),
                      _GoldTextLine(
                        _phone.isEmpty ? 'PHONE: —' : 'PHONE: $_phone',
                        t: _anim.value,
                        size: 12.7,
                        soft: true,
                      ),
                      const SizedBox(height: 4),
                      _GoldTextLine(
                        _about.isEmpty ? 'ABOUT: —' : 'ABOUT: $_about',
                        t: _anim.value,
                        size: 12.2,
                        soft: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                GestureDetector(
                  onTap: _editProfile,
                  child: CustomPaint(
                    painter: BorderShimmerPainter(
                      t: _shimmerOn ? _anim.value : 0.0,
                      radius: 999,
                      strokeWidth: 3.0,
                    ),
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.black,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 14,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          colors: masterGoldGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(rect),
                        blendMode: BlendMode.srcIn,
                        child: const Text(
                          'EDIT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.8,
                            fontSize: 12.5,
                          ),
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

  Widget _buildAvatarBlock() {
    const double avatarSize = 78;
    const double framePadding = 6;

    final avatar = Container(
      height: avatarSize,
      width: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black,
        image: _profileBytes == null
            ? null
            : DecorationImage(
                image: MemoryImage(_profileBytes!),
                fit: BoxFit.cover,
              ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: _profileBytes == null
          ? Center(
              child: _GoldTextLine(
                _initials(_name),
                t: _anim.value,
                size: 18,
                soft: false,
              ),
            )
          : null,
    );

    if (_selectedFrame != null) {
      return _ShimmerBorder(
        t: _anim.value,
        radius: 999,
        strokeWidth: 3.2,
        child: ProfileAvatarWithFrame(
          size: avatarSize,
          framePadding: framePadding,
          frameType: _selectedFrame!,
          animate: true,
          avatarChild: avatar,
        ),
      );
    }

    return _ShimmerBorder(
      t: _anim.value,
      radius: 999,
      strokeWidth: 3.2,
      child: avatar,
    );
  }
}

class _ProfileResult {
  final String name;
  final String phone;
  final String about;
  final Uint8List? bytes;

  _ProfileResult({
    required this.name,
    required this.phone,
    required this.about,
    required this.bytes,
  });
}

class _ShimmerBorder extends StatelessWidget {
  final double t;
  final double radius;
  final double strokeWidth;
  final Widget child;

  const _ShimmerBorder({
    required this.t,
    required this.radius,
    required this.strokeWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final shimmerOn = AppSettings.shimmerVN.value;
    return CustomPaint(
      painter: BorderShimmerPainter(
        t: shimmerOn ? t : 0.0,
        radius: radius,
        strokeWidth: strokeWidth,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}

class _GoldTextLine extends StatelessWidget {
  final String text;
  final double t;
  final double size;
  final bool soft;

  const _GoldTextLine(this.text, {required this.t, required this.size, required this.soft});

  @override
  Widget build(BuildContext context) {
    final shimmerOn = AppSettings.shimmerVN.value;

    final base = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.4,
        color: Colors.white,
      ),
    );

    final gold = ShaderMask(
      shaderCallback: (rect) => LinearGradient(
        colors: soft
            ? masterGoldGradient.map((c) => c.withOpacity(0.78)).toList()
            : masterGoldGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect),
      blendMode: BlendMode.srcIn,
      child: base,
    );

    if (!shimmerOn) return gold;

    return Stack(
      children: [
        gold,
        Positioned.fill(
          child: ClipRect(
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.35),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                  begin: Alignment(-1.5 + (t * 3), 0.0),
                  end: Alignment(-0.5 + (t * 3), 0.0),
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcATop,
              child: gold,
            ),
          ),
        ),
      ],
    );
  }
}

class _CropSquarePage extends StatefulWidget {
  final Uint8List bytes;
  final AnimationController anim;

  const _CropSquarePage({
    required this.bytes,
    required this.anim,
  });

  @override
  State<_CropSquarePage> createState() => _CropSquarePageState();
}

class _CropSquarePageState extends State<_CropSquarePage> {
  final TransformationController _tc = TransformationController();
  final GlobalKey _cropKey = GlobalKey();

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  Future<Uint8List?> _exportCropped() async {
    try {
      final boundary =
          _cropKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      return byteData.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    const double cropSize = 260;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'CROP PHOTO',
          style: TextStyle(
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFD4AF37)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final out = await _exportCropped();
              if (!mounted) return;
              Navigator.pop(context, out);
            },
            child: const Text(
              'DONE',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 18),
            AnimatedBuilder(
              animation: widget.anim,
              builder: (_, __) {
                return _ShimmerBorder(
                  t: widget.anim.value,
                  radius: 26,
                  strokeWidth: 3.2,
                  child: RepaintBoundary(
                    key: _cropKey,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: SizedBox(
                        width: cropSize,
                        height: cropSize,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(color: Colors.black),
                            InteractiveViewer(
                              transformationController: _tc,
                              minScale: 1.0,
                              maxScale: 6.0,
                              panEnabled: true,
                              scaleEnabled: true,
                              child: Image.memory(
                                widget.bytes,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            Text(
              'Pinch to zoom • Drag to move',
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}