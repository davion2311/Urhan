import 'package:flutter/material.dart';

import 'ui_kit.dart';
import 'app_settings.dart';

enum _LoginMethod { phone, email }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  final _formKey = GlobalKey<FormState>();

  _LoginMethod _method = _LoginMethod.phone;

  final TextEditingController _idCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;

  bool get _shimmerOn => AppSettings.shimmerVN.value;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    _syncAnimWithShimmer();
    AppSettings.shimmerVN.addListener(_syncAnimWithShimmer);
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
    _idCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _goSignup() {
    Navigator.pushNamed(context, '/signup');
  }

  Future<void> _login() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  void _forgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Forgot Password (coming soon)'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppSettings.darkModeVN.value;
    final bg = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _topBar(isDark),
                  const SizedBox(height: 22),

                  Center(
                    child: isDark
                        ? GoldTextShimmer(
                            text: 'LOGIN',
                            t: _anim.value,
                            fontSize: 34,
                            letterSpacing: 3.0,
                          )
                        : const Text(
                            'LOGIN',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3.0,
                              color: Colors.black,
                            ),
                          ),
                  ),

                  const SizedBox(height: 22),

                  _loginCard(isDark),

                  const SizedBox(height: 22),

                  GestureDetector(
                    onTap: _goSignup,
                    child: Center(
                      child: isDark
                          ? GoldTextShimmer(
                              text: "DON'T HAVE AN ACCOUNT?  CREATE ACCOUNT",
                              t: _anim.value,
                              fontSize: 13.5,
                              letterSpacing: 1.2,
                            )
                          : const Text(
                              "DON'T HAVE AN ACCOUNT?  CREATE ACCOUNT",
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: Colors.black,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _topBar(bool isDark) {
    return Row(
      children: [
        GoldIcon3D(
          icon: Icons.arrow_back_ios_new_rounded,
          size: 20,
          onTap: () => Navigator.pop(context),
        ),
        const Spacer(),
        isDark
            ? GoldTextShimmer(
                text: 'DIGITAL DARZI',
                t: _anim.value,
                fontSize: 14,
                letterSpacing: 2.2,
              )
            : const Text(
                'DIGITAL DARZI',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                  color: Colors.black,
                ),
              ),
        const Spacer(),
        const SizedBox(width: 44),
      ],
    );
  }

  Widget _loginCard(bool isDark) {
    return CustomPaint(
      painter: BorderShimmerPainter(
        t: _shimmerOn ? _anim.value : 0.0,
        radius: 26,
        strokeWidth: 3.2,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _methodToggle(),
              const SizedBox(height: 12),
              _field(
                controller: _idCtrl,
                hint:
                    _method == _LoginMethod.phone ? 'PHONE NUMBER' : 'EMAIL',
                icon:
                    _method == _LoginMethod.phone ? Icons.phone : Icons.email,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _passCtrl,
                hint: 'PASSWORD',
                icon: Icons.lock,
                obscure: _obscure,
                suffix: GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: const Icon(Icons.visibility, color: Colors.black),
                ),
                validator: (v) =>
                    (v == null || v.length < 4) ? 'Invalid password' : null,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _forgotPassword,
                  child: const Text(
                    'FORGOT PASSWORD?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GoldCapsuleButton(
                t: _shimmerOn ? _anim.value : 0.0,
                text: _loading ? 'PLEASE WAIT...' : 'LOGIN',
                onTap: _login,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _methodToggle() {
    final isPhone = _method == _LoginMethod.phone;

    return Row(
      children: [
        Expanded(
          child: _toggleBtn('PHONE', isPhone, () {
            setState(() => _method = _LoginMethod.phone);
          }),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _toggleBtn('EMAIL', !isPhone, () {
            setState(() => _method = _LoginMethod.email);
          }),
        ),
      ],
    );
  }

  Widget _toggleBtn(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(colors: masterGoldGradient),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(colors: masterGoldGradient),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: obscure,
              validator: validator,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.black.withOpacity(0.7),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          if (suffix != null) suffix,
        ],
      ),
    );
  }
}