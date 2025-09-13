import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:another_flushbar/flushbar.dart';
// removed: unused flushbar_route import
import 'package:medcare/core/theme/app_theme.dart';
import 'package:medcare/features/auth/presentation/pages/signup_page.dart';
import 'package:medcare/features/home/presentation/pages/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscure = true;
  bool _loading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _emailError = false;
  bool _passwordError = false;

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^\S+@\S+\.\S+$');
    return regex.hasMatch(email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _emailError = false;
      _passwordError = false;
    });

    if (email.isEmpty || password.isEmpty) {
      if (email.isEmpty) setState(() => _emailError = true);
      if (password.isEmpty) setState(() => _passwordError = true);
      Flushbar(
        message: 'Please enter email and password.',
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.redAccent,
        margin: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(12),
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() => _emailError = true);
      Flushbar(
        message: 'Please enter a valid email address.',
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.redAccent,
        margin: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(12),
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
      return;
    }

    setState(() => _loading = true);
    try {
      // Check Firestore if email exists
      final emailQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (emailQuery.docs.isEmpty) {
        setState(() => _emailError = true);
        Flushbar(
          message: 'This email is not registered. Please sign up.',
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.redAccent,
          margin: const EdgeInsets.all(12),
          borderRadius: BorderRadius.circular(12),
          flushbarPosition: FlushbarPosition.TOP,
        ).show(context);
        return;
      }

      final credentials = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);

      // Optional: ensure user document exists
      try {
        final uid = credentials.user?.uid;
        if (uid != null) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (!doc.exists) {
            // Create a minimal profile if needed
            await FirebaseFirestore.instance.collection('users').doc(uid).set({
              'email': email,
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        }
      } catch (_) {}

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String code = e.code.toLowerCase();
      String msg = 'Sign in failed. Please try again.';
      if (code == 'user-not-found') {
        msg = 'This email is not registered. Please sign up.';
        setState(() => _emailError = true);
      }
      // Newer SDKs may return 'invalid-credential' or 'invalid-login-credentials'
      else if (code == 'wrong-password' || code == 'invalid-credential' || code == 'invalid-login-credentials') {
        msg = 'Incorrect password. Please try again.';
        setState(() => _passwordError = true);
      }
      else if (code == 'invalid-email') msg = 'The email address is badly formatted.';
      else if (code == 'user-disabled') msg = 'This user has been disabled.';
      else if (code == 'too-many-requests') msg = 'Too many attempts. Try again later.';
      else if (code == 'network-request-failed') msg = 'Network error. Check your connection.';

      Flushbar(
        message: msg,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.redAccent,
        margin: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(12),
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
    } catch (_) {
      Flushbar(
        message: 'Unexpected error. Please try again.',
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.redAccent,
        margin: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(12),
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Container(
                height: MediaQuery.of(context).size.height,
                decoration: AppDecorations.gradientBackground,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 150),
                    // Top card with icon
                    Center(
                      child: Container(
                        width: 108,
                        height: 108,
                        decoration: AppDecorations.circleIconContainerStrong,
                        child: const Center(
                          child: Icon(
                            Icons.medication,
                            color: AppColors.purpleTop,
                            size: 56,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
              // Welcome text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Welcome Back', style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to continue',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(.90),
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Centered form card with shadow
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      // soft edge shadow hugging the border (stronger)
                      BoxShadow(
                        color: Colors.black.withOpacity(.14),
                        blurRadius: 18,
                        spreadRadius: 0,
                        offset: const Offset(0, 6),
                      ),
                      // deeper shadow for elevation (stronger)
                      BoxShadow(
                        color: Colors.black.withOpacity(.20),
                        blurRadius: 32,
                        spreadRadius: 2,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _LabeledField(
                        label: 'Email',
                        hint: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        controller: _emailController,
                        hasError: _emailError,
                        onChanged: (v) {
                          if (_emailError) setState(() => _emailError = false);
                        },
                      ),
                      const SizedBox(height: 20),
                      _PasswordField(
                        obscure: _obscure,
                        onToggle: () => setState(() => _obscure = !_obscure),
                        controller: _passwordController,
                        hasError: _passwordError,
                        onChanged: (v) {
                          if (_passwordError) setState(() => _passwordError = false);
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _signIn,
                          child: const Text('Sign In'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: RichText(
                  text: TextSpan(
                    text: "Don't have an account? ",
                    style: const TextStyle(color: Colors.white70),
                    children: [
                      TextSpan(
                        text: 'Sign Up',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SignUpPage(),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
            ),
            if (_loading) ...[
              ModalBarrier(dismissible: false, color: Colors.black.withOpacity(0.28)),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.20), blurRadius: 18, offset: Offset(0, 10), spreadRadius: -3),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.6, valueColor: AlwaysStoppedAnimation(AppColors.primary)),
                      ),
                      SizedBox(width: 12),
                      Text('Signing you in...', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatefulWidget {
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  const _LabeledField({
    required this.label,
    required this.hint,
    this.keyboardType,
    required this.controller,
    this.hasError = false,
    this.onChanged,
  });

  @override
  State<_LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<_LabeledField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool focused = _focusNode.hasFocus;
    const Color base = Colors.black54;
    const Color active = AppColors.primary;
    const Color error = Colors.redAccent;

    return TextField(
      focusNode: _focusNode,
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: TextStyle(color: widget.hasError ? error : (focused ? active : base), fontSize: 16),
        floatingLabelStyle: const TextStyle(color: active, fontWeight: FontWeight.w600),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        prefixIcon: Icon(Icons.email_outlined, color: widget.hasError ? error : (focused ? active : base), size: 22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.hasError ? error : base, width: 1.3),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: widget.hasError ? error : base, width: 1.3),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: widget.hasError ? error : active, width: 1.6),
        ),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  final bool obscure;
  final VoidCallback onToggle;
  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  const _PasswordField({required this.obscure, required this.onToggle, required this.controller, this.hasError = false, this.onChanged});

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool focused = _focusNode.hasFocus;
    const Color base = Colors.black54;
    const Color active = AppColors.primary;
    const Color error = Colors.redAccent;

    return TextField(
      focusNode: _focusNode,
      controller: widget.controller,
      obscureText: widget.obscure,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: 'Password',
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: TextStyle(color: widget.hasError ? error : (focused ? active : base), fontSize: 16),
        floatingLabelStyle: const TextStyle(color: active, fontWeight: FontWeight.w600),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        prefixIcon: Icon(Icons.lock_outline, color: widget.hasError ? error : (focused ? active : base), size: 22),
        suffixIcon: IconButton(
          icon: Icon(widget.obscure ? Icons.visibility_off : Icons.visibility, color: widget.hasError ? error : (focused ? active : base)),
          onPressed: widget.onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.hasError ? error : base, width: 1.3),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: widget.hasError ? error : base, width: 1.3),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: widget.hasError ? error : active, width: 1.6),
        ),
      ),
    );
  }
}
