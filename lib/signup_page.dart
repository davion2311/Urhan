// lib/signup_page.dart
// ✅ UI Updated EXACTLY as you described
// ✅ NO Theme Manager (removed totally)
// ✅ Signup -> goes back to Login (/auth)
// ✅ Uses ui_kit.dart + app_settings.dart

import 'dart:ui';
import 'package:flutter/material.dart';

import 'ui_kit.dart';
import 'app_settings.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _pass2Ctrl = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;

  bool get _isDark => AppSettings.darkModeVN.value;

  Color get _bg => Theme.of(context).scaffoldBackgroundColor;

  Color get _pillBg => _isDark ? const Color(0xFF0A0A0A) : Colors.white;
  Color get _pillInner => _isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04);

  Color get _stroke => const Color(0xFFD4AF37);

  Color get _textPrimary => _isDark ? Colors.white : Colors.black;
  Color get _hint => _isDark ? Colors.white.withOpacity(0.55) : Colors.black.withOpacity(0.55);

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    _userCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  void _goLogin() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/auth');
  }

  Future<void> _signup() async {
    if (_loading) return;

    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      // ✅ Here you can add real signup later.
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account Created ✅  اب Login کریں'),
          backgroundColor: Colors.green,
        ),
      );

      // ✅ As you asked: signup -> back to login
      Navigator.pushReplacementNamed(context, '/auth');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signup failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 18, 16, mq.padding.bottom + 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _topBar(),
                      const SizedBox(height: 18),

                      Center(
                        child: GoldTextShimmer(
                          text: 'SIGN UP',
                          t: _anim.value,
                          fontSize: 34,
                          letterSpacing: 3.0,
                          fontWeight: _FontWeightFix.w900,
                          align: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 18),

                      _capsuleSection(),

                      const SizedBox(height: 18),

                      _bottomLink(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        GoldIcon3D(
          icon: Icons.arrow_back_ios_new_rounded,
          size: 20,
          onTap: _goLogin,
        ),
        const Spacer(),
        Opacity(
          opacity: 0.9,
          child: GoldTextShimmer(
            text: 'DIGITAL DARZI',
            t: _anim.value,
            fontSize: 14,
            letterSpacing: 2.2,
            align: TextAlign.center,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 44),
      ],
    );
  }

  Widget _capsuleSection() {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return CustomPaint(
          painter: BorderShimmerPainter(
            t: _anim.value,
            radius: 26,
            strokeWidth: 3.2,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            decoration: BoxDecoration(
              color: _pillBg,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isDark ? 0.65 : 0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // ✅ Username
                  _capsuleField(
                    controller: _userCtrl,
                    hint: 'USERNAME',
                    icon: Icons.person,
                    keyboardType: TextInputType.name,
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return 'Username لازمی ہے';
                      if (s.length < 3) return 'کم ازکم 3 حرف';
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // ✅ Email
                  _capsuleField(
                    controller: _emailCtrl,
                    hint: 'EMAIL',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return 'Email لازمی ہے';
                      if (!s.contains('@')) return 'صحیح ای میل لکھیں';
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // ✅ Password
                  _capsuleField(
                    controller: _passCtrl,
                    hint: 'PASSWORD',
                    icon: Icons.lock,
                    keyboardType: TextInputType.visiblePassword,
                    obscure: _obscure1,
                    suffix: GestureDetector(
                      onTap: () => setState(() => _obscure1 = !_obscure1),
                      child: Icon(
                        _obscure1 ? Icons.visibility : Icons.visibility_off,
                        size: 20,
                        color: _stroke.withOpacity(0.95),
                      ),
                    ),
                    validator: (v) {
                      final s = (v ?? '');
                      if (s.trim().isEmpty) return 'Password لازمی ہے';
                      if (s.length < 4) return 'کم ازکم 4 حرف';
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // ✅ Confirm Password
                  _capsuleField(
                    controller: _pass2Ctrl,
                    hint: 'CONFIRM PASSWORD',
                    icon: Icons.verified_user_rounded,
                    keyboardType: TextInputType.visiblePassword,
                    obscure: _obscure2,
                    suffix: GestureDetector(
                      onTap: () => setState(() => _obscure2 = !_obscure2),
                      child: Icon(
                        _obscure2 ? Icons.visibility : Icons.visibility_off,
                        size: 20,
                        color: _stroke.withOpacity(0.95),
                      ),
                    ),
                    validator: (v) {
                      final s = (v ?? '');
                      if (s.trim().isEmpty) return 'Confirm لازمی ہے';
                      if (s != _passCtrl.text) return 'Passwords match نہیں کر رہے';
                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  // ✅ Signup button
                  IgnorePointer(
                    ignoring: _loading,
                    child: Opacity(
                      opacity: _loading ? 0.7 : 1.0,
                      child: GoldCapsuleButton(
                        t: _anim.value,
                        text: _loading ? 'PLEASE WAIT...' : 'SIGN UP',
                        onTap: _signup,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _capsuleField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _pillInner,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _stroke.withOpacity(_isDark ? 0.35 : 0.30),
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  colors: masterGoldGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(r),
                blendMode: BlendMode.srcIn,
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  obscureText: obscure,
                  validator: validator,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                  cursorColor: _stroke,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: _hint,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 8),
                suffix,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomLink() {
    return GestureDetector(
      onTap: _goLogin,
      child: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          colors: masterGoldGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
        blendMode: BlendMode.srcIn,
        child: const Text(
          'Already have an account?  LOGIN',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// tiny helper to keep fontWeight stable in some compilers
class _FontWeightFix {
  static const FontWeight w900 = FontWeight.w900;
}