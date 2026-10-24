import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../widgets/cookie_art.dart';

const _dark = Color(0xFF2B1A12); // chocolate
const _cream = Color(0xFFFFF8F1); // sheet background
const _field = Color(0xFFF6EBDD); // input background
const _caramel = Color(0xFFC98A44); // accent
const _brown = Color(0xFF6B3E26); // secondary text

/// One screen for both Sign in and Sign up.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _loginKey = GlobalKey<FormState>();
  final _signupKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  final _auth = AuthService();
  late final AnimationController _float;

  bool _signUp = false;
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

  static final _usernameRule = RegExp(r'^[A-Za-z0-9_]{3,20}$');

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _setMode(bool signUp) {
    if (_loading || signUp == _signUp) return;
    setState(() => _signUp = signUp);
  }

  Future<void> _login() async {
    if (!_loginKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.signIn(email: _email.text.trim(), password: _password.text);
      // AuthGate listens to auth changes and opens the shop automatically.
    } on AuthException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgot() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _snack('Enter your email first.');
      return;
    }
    try {
      await _auth.resetPassword(email);
      _snack('Password reset email sent.');
    } on AuthException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _register() async {
    if (!_signupKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final username = _username.text.trim();

      // Is the username still free?
      final available = await Supabase.instance.client
          .rpc('username_available', params: {'name': username});
      if (available != true) {
        _snack('That username is already taken. Try another one.');
        return;
      }

      final res = await _auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        fullName: _name.text.trim(),
        username: username,
      );
      if (!mounted) return;

      if (res.session == null) {
        // Email confirmation is enabled in Supabase.
        _snack('Check your email to confirm your account, then sign in.');
        setState(() => _signUp = false);
      }
      // Otherwise a session exists and AuthGate opens the shop.
    } on AuthException catch (e) {
      _snack(e.message);
    } on PostgrestException catch (e) {
      _snack('Could not check the username: ${e.message}');
    } catch (_) {
      _snack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _dec(String hint, IconData icon, {Widget? suffix}) {
    OutlineInputBorder border(Color color, [double width = 0]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: width == 0
              ? BorderSide.none
              : BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: _brown),
      suffixIcon: suffix,
      filled: true,
      fillColor: _field,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: border(_field),
      enabledBorder: border(_field),
      focusedBorder: border(_caramel, 1.6),
      errorBorder: border(Colors.red.shade300, 1.2),
      focusedErrorBorder: border(Colors.red.shade400, 1.6),
    );
  }

  Widget _eye(bool obscured, VoidCallback onTap) {
    return IconButton(
      icon: Icon(obscured ? Icons.visibility : Icons.visibility_off, size: 20),
      color: _brown,
      onPressed: onTap,
    );
  }

  Widget _primaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: _loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _caramel,
          foregroundColor: _dark,
          disabledBackgroundColor: _caramel.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: _dark),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
      ),
    );
  }

  Widget _heading(String title, String subtitle) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _dark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: _brown),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _loginForm() {
    return Form(
      key: _loginKey,
      child: Column(
        children: [
          _heading('Welcome back', 'Sign in to order your favorite cookies.'),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: _dec('Email address', Icons.mail_outline),
            validator: (v) => (v == null || !v.contains('@'))
                ? 'Enter a valid email'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _password,
            obscureText: _obscure,
            decoration: _dec(
              'Password',
              Icons.lock_outline,
              suffix: _eye(_obscure, () => setState(() => _obscure = !_obscure)),
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? 'At least 6 characters' : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _forgot,
              style: TextButton.styleFrom(foregroundColor: _brown),
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 4),
          _primaryButton('Sign in', _login),
        ],
      ),
    );
  }

  Widget _signupForm() {
    return Form(
      key: _signupKey,
      child: Column(
        children: [
          _heading('Create your account', 'Join us and get your cookies fresh.'),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: _dec('Full name', Icons.person_outline),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _username,
            autocorrect: false,
            decoration: _dec('Username', Icons.alternate_email),
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.isEmpty) return 'Choose a username';
              if (!_usernameRule.hasMatch(value)) {
                return '3-20 letters, numbers or underscore only';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: _dec('Email address', Icons.mail_outline),
            validator: (v) => (v == null || !v.contains('@'))
                ? 'Enter a valid email'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _password,
            obscureText: _obscure,
            decoration: _dec(
              'Password',
              Icons.lock_outline,
              suffix: _eye(_obscure, () => setState(() => _obscure = !_obscure)),
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? 'At least 6 characters' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirm,
            obscureText: _obscureConfirm,
            decoration: _dec(
              'Confirm password',
              Icons.lock_outline,
              suffix: _eye(
                _obscureConfirm,
                () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) =>
                v != _password.text ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 20),
          _primaryButton('Create account', _register),
        ],
      ),
    );
  }

  Widget _buildSheet(bool keyboardOpen) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Transform.translate(
        offset: Offset(0, (1 - v) * 120),
        child: Opacity(opacity: v, child: child),
      ),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: keyboardOpen,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              children: [
                _ModeToggle(signUp: _signUp, onChanged: _setMode),
                const SizedBox(height: 24),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _signUp ? _signupForm() : _loginForm(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: _dark,
      body: Column(
        children: [
          if (!keyboardOpen)
            Expanded(flex: 4, child: _Hero(animation: _float)),
          Expanded(
            flex: keyboardOpen ? 1 : 7,
            child: _buildSheet(keyboardOpen),
          ),
        ],
      ),
    );
  }
}

/// Dark top area with a floating cookie.
class _Hero extends StatelessWidget {
  const _Hero({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, c) {
          final size = (c.maxHeight - 76).clamp(90.0, 210.0).toDouble();
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: size,
                  height: size,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // soft glow behind the cookie
                      Positioned(
                        left: -size * 0.3,
                        right: -size * 0.3,
                        top: -size * 0.3,
                        bottom: -size * 0.3,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [Color(0x55C98A44), Color(0x00C98A44)],
                            ),
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          final t = Curves.easeInOut.transform(animation.value) - 0.5;
                          return Transform.translate(
                            offset: Offset(0, t * 14),
                            child: Transform.rotate(angle: t * 0.1, child: child),
                          );
                        },
                        child: CookieArt(size: size),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'COOKIE STORE',
                  style: TextStyle(
                    color: Color(0xFFFFF3E0),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'FRESHLY BAKED · EVERY DAY',
                  style: TextStyle(
                    color: _caramel,
                    fontSize: 10,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The "Sign in | Sign up" pill with a sliding highlight.
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.signUp, required this.onChanged});

  final bool signUp;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _field,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: signUp ? Alignment.centerRight : Alignment.centerLeft,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: _caramel,
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _Segment(
                  label: 'Sign in',
                  selected: !signUp,
                  onTap: () => onChanged(false),
                ),
              ),
              Expanded(
                child: _Segment(
                  label: 'Sign up',
                  selected: signUp,
                  onTap: () => onChanged(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: selected ? _dark : _brown,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}