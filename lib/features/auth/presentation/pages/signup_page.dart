import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medcare/core/theme/app_theme.dart';
import 'package:medcare/features/auth/presentation/pages/complete_profile_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _agree = false;
  bool _errName = false;
  bool _errEmail = false;
  bool _errPass = false;
  bool _errConfirm = false;
  bool _loading = false;
  String _loadingText = '';

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    final emailReg = RegExp(r'^[\w\.-]+@[\w\.-]+\.[A-Za-z]{2,}$');
    final passReg = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*(?:[0-9]|[٠-٩]))(?=.*[!@#\$%^&*()_+\-=\[\]{};:\\|,.<>\/?]).{6,}$',
    );

    setState(() {
      _errName = false;
      _errEmail = false;
      _errPass = false;
      _errConfirm = false;
    });
    if (name.isEmpty) {
      setState(() => _errName = true);
      _showMsg('Please enter your full name');
      return false;
    }
    if (!emailReg.hasMatch(email)) {
      setState(() => _errEmail = true);
      _showMsg('Please enter a valid email');
      return false;
    }
    if (!passReg.hasMatch(pass)) {
      setState(() => _errPass = true);
      _showMsg('Password must be 6+ chars with upper, lower, number and special');
      return false;
    }
    if (pass != confirm) {
      setState(() => _errConfirm = true);
      _showMsg('Passwords do not match');
      return false;
    }
    if (!_agree) {
      _showMsg('Please accept Terms & Conditions');
      return false;
    }
    return true;
  }

  void _showMsg(String msg) {
    Flushbar(
      message: msg,
      backgroundColor: Colors.redAccent,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(12),
      flushbarPosition: FlushbarPosition.TOP,
      icon: const Icon(Icons.error_outline, color: Colors.white),
    ).show(context);
  }

  // In-page overlay is rendered in build() when _loading is true.

  Future<void> _onSignUpPressed() async {
    if (_loading) return;
    if (!_validate()) return;
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    setState(() {
      _loadingText = 'Checking email...';
      _loading = true;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        if (mounted) {
          setState(() => _loading = false);
          setState(() => _errEmail = true);
          _showMsg('This email is already registered. Please log in.');
        }
        return;
      }
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CompleteProfilePage(fullName: name, email: email, password: pass),
        ),
      );
    } catch (_) {
      setState(() => _loading = false);
      _showMsg('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        // ensure not stuck
        if (_loading) setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
                decoration: AppDecorations.gradientBackground,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 100),
                    Center(
                      child: Container(
                        width: 118,
                        height: 118,
                        decoration: AppDecorations.circleIconContainerStrong,
                        child: const Center(
                          child: Icon(
                            Icons.person_add,
                            color: AppColors.purpleTop,
                            size: 60,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Create Account', style: Theme.of(context).textTheme.headlineLarge),
                          const SizedBox(height: 6),
                          Text(
                            'Join us to manage your health',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(.90),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.14),
                              blurRadius: 18,
                              spreadRadius: 0,
                              offset: const Offset(0, 6),
                            ),
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
                              label: 'Full Name',
                              hint: 'Full Name',
                              keyboardType: TextInputType.name,
                              controller: _nameCtrl,
                              hasError: _errName,
                              onChanged: (_) => setState(() => _errName = false),
                            ),
                            const SizedBox(height: 16),
                            _LabeledField(
                              label: 'Email',
                              hint: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              controller: _emailCtrl,
                              hasError: _errEmail,
                              onChanged: (_) => setState(() => _errEmail = false),
                            ),
                            const SizedBox(height: 16),
                            _PasswordField(
                              label: 'Password',
                              obscure: _obscure1,
                              controller: _passCtrl,
                              onToggle: () => setState(() => _obscure1 = !_obscure1),
                              hasError: _errPass,
                              onChanged: (_) => setState(() => _errPass = false),
                            ),
                            const SizedBox(height: 16),
                            _PasswordField(
                              label: 'Confirm Password',
                              obscure: _obscure2,
                              controller: _confirmCtrl,
                              onToggle: () => setState(() => _obscure2 = !_obscure2),
                              hasError: _errConfirm,
                              onChanged: (_) => setState(() => _errConfirm = false),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Checkbox(
                                  value: _agree,
                                  onChanged: (v) => setState(() => _agree = v ?? false),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  side: const BorderSide(color: Colors.black54, width: 1.3),
                                  activeColor: AppColors.primary,
                                  checkColor: Colors.white,
                                ),
                                Expanded(
                                  child: Text(
                                    'I agree to the Terms of Service and Privacy Policy',
                                    style: const TextStyle(color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _onSignUpPressed,
                                child: const Text('Sign Up'),
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
                          text: 'Already have an account? ',
                          style: const TextStyle(color: Colors.white70),
                          children: [
                            TextSpan(
                              text: 'Sign In',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => Navigator.of(context).pop(),
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
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        _loadingText.isEmpty ? 'Loading...' : _loadingText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LabeledField extends StatefulWidget {
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  const _LabeledField({required this.label, required this.hint, this.keyboardType, this.controller, this.hasError = false, this.onChanged});

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
        prefixIcon: Icon(Icons.person_outline, color: widget.hasError ? error : (focused ? active : base), size: 22),
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
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final TextEditingController? controller;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  const _PasswordField({required this.label, required this.obscure, required this.onToggle, this.controller, this.hasError = false, this.onChanged});

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
        labelText: widget.label,
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
