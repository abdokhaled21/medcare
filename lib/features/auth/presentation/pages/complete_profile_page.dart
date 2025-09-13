import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medcare/core/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompleteProfilePage extends StatefulWidget {
  final String fullName;
  final String email;
  final String password;
  const CompleteProfilePage({super.key, required this.fullName, required this.email, required this.password});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

// Top-level smart single-line field
class _SmartOutlinedField extends StatefulWidget {
  final String label;
  final String? hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  const _SmartOutlinedField({
    super.key,
    required this.label,
    this.hint,
    required this.icon,
    required this.controller,
    required this.keyboardType,
    this.hasError = false,
    this.onChanged,
  });

  @override
  State<_SmartOutlinedField> createState() => _SmartOutlinedFieldState();
}

class _SmartOutlinedFieldState extends State<_SmartOutlinedField> {
  final FocusNode _fn = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _fn.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _fn.removeListener(_onChanged);
    widget.controller.removeListener(_onChanged);
    _fn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color base = Colors.black54;
    const Color active = AppColors.primary;
    const Color error = Colors.redAccent;
    final bool hasValue = widget.controller.text.isNotEmpty;
    final bool focused = _fn.hasFocus;

    final String? labelText = (focused || hasValue) ? widget.label : null;
    final String? hintText = (!focused && !hasValue)
        ? widget.label
        : (focused && !hasValue ? widget.hint : null);

    return TextField(
      focusNode: _fn,
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: TextStyle(color: widget.hasError ? error : (focused ? active : base), fontSize: 16),
        floatingLabelStyle: const TextStyle(color: active, fontWeight: FontWeight.w600),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        prefixIcon: Icon(widget.icon, color: widget.hasError ? error : AppColors.primary, size: 22),
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
      textInputAction: TextInputAction.next,
    );
  }
}

// Animated shadow button with press bounce
class _BounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final List<BoxShadow>? shadow;
  final Border? border;
  final double borderRadius;
  final int tapDelayMs;

  const _BounceButton({
    required this.child,
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
    this.shadow,
    this.border,
    this.borderRadius = 14,
    this.tapDelayMs = 0,
  });

  @override
  State<_BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<_BounceButton> {
  bool _pressed = false;

  void _setPressed(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(widget.borderRadius);
    final child = Center(child: widget.child);
    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      scale: _pressed ? 0.94 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: br,
          boxShadow: widget.shadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: br,
          child: Ink(
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: br,
              border: widget.border,
            ),
            child: InkWell(
              borderRadius: br,
              splashColor: widget.foregroundColor.withOpacity(0.12),
              highlightColor: widget.foregroundColor.withOpacity(0.06),
              splashFactory: InkRipple.splashFactory,
              onHighlightChanged: (v) => _setPressed(v),
              onTap: () async {
                if (widget.tapDelayMs > 0) {
                  await Future.delayed(Duration(milliseconds: widget.tapDelayMs));
                }
                widget.onTap();
              },
              child: IconTheme(
                data: IconThemeData(color: widget.foregroundColor),
                child: DefaultTextStyle(
                  style: TextStyle(color: widget.foregroundColor, fontSize: 16),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Notification preference item tile
class _PrefItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrefItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E7EE)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.20)),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withOpacity(.35),
          ),
        ],
      ),
    );
  }
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  File? _avatar;
  String? _gender; // selected by user
  String? _blood;  // selected by user
  int _step = 0; // 0: personal info, 1: medical info
  bool _loading = false; // controls full-screen loading overlay

  // Medical step controllers
  final TextEditingController _allergiesCtrl = TextEditingController();
  final TextEditingController _conditionsCtrl = TextEditingController();
  final TextEditingController _doctorNameCtrl = TextEditingController();
  final TextEditingController _doctorPhoneCtrl = TextEditingController();

  // Personal step controllers
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _ageCtrl = TextEditingController();
  final TextEditingController _heightCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _emergencyNameCtrl = TextEditingController();
  final TextEditingController _emergencyPhoneCtrl = TextEditingController();

  // Step 2: Notification preferences
  bool _notifMedication = true;
  bool _notifDailyCheck = true;
  bool _notifRefill = true;

  final _picker = ImagePicker();

  // Error flags for per-field red borders
  bool _errPhone = false;
  bool _errAge = false;
  bool _errGender = false;
  bool _errHeight = false;
  bool _errWeight = false;
  bool _errBlood = false;
  bool _errEmergencyName = false;
  bool _errEmergencyPhone = false;
  bool _errAllergies = false;
  bool _errConditions = false;
  bool _errDoctorName = false;
  bool _errDoctorPhone = false;

  Future<void> _pickAvatar() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) {
      setState(() => _avatar = File(img.path));
    }
  }

  @override
  void dispose() {
    _allergiesCtrl.dispose();
    _conditionsCtrl.dispose();
    _doctorNameCtrl.dispose();
    _doctorPhoneCtrl.dispose();
    _phoneCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  bool _validateStep0() {
    final phone = _phoneCtrl.text.trim();
    final age = _ageCtrl.text.trim();
    final height = _heightCtrl.text.trim();
    final weight = _weightCtrl.text.trim();
    final eName = _emergencyNameCtrl.text.trim();
    final ePhone = _emergencyPhoneCtrl.text.trim();
    final phoneReg = RegExp(r'^[+\d][\d\-\s]{6,}$');
    setState(() {
      _errPhone = false;
      _errAge = false;
      _errGender = false;
      _errHeight = false;
      _errWeight = false;
      _errBlood = false;
      _errEmergencyName = false;
      _errEmergencyPhone = false;
    });
    if (phone.isEmpty || !phoneReg.hasMatch(phone)) {
      setState(() => _errPhone = true);
      _showMsg('Please enter a valid phone number');
      return false;
    }
    if (_gender == null) {
      setState(() => _errGender = true);
      _showMsg('Please select gender');
      return false;
    }
    if (_blood == null) {
      setState(() => _errBlood = true);
      _showMsg('Please select blood type');
      return false;
    }
    if (age.isEmpty) {
      setState(() => _errAge = true);
      _showMsg('Please enter your age');
      return false;
    }
    if (height.isEmpty) {
      setState(() => _errHeight = true);
      _showMsg('Please enter your height');
      return false;
    }
    if (weight.isEmpty) {
      setState(() => _errWeight = true);
      _showMsg('Please enter your weight');
      return false;
    }
    if (eName.isEmpty) {
      setState(() => _errEmergencyName = true);
      _showMsg('Please enter emergency contact name');
      return false;
    }
    if (ePhone.isEmpty) {
      setState(() => _errEmergencyPhone = true);
      _showMsg('Please enter emergency contact phone');
      return false;
    }
    return true;
  }

  bool _validateStep1() {
    setState(() {
      _errAllergies = false;
      _errConditions = false;
      _errDoctorName = false;
      _errDoctorPhone = false;
    });
    if (_allergiesCtrl.text.trim().isEmpty) {
      setState(() => _errAllergies = true);
      _showMsg('Please enter allergies');
      return false;
    }
    if (_conditionsCtrl.text.trim().isEmpty) {
      setState(() => _errConditions = true);
      _showMsg('Please enter medical conditions');
      return false;
    }
    if (_doctorNameCtrl.text.trim().isEmpty) {
      setState(() => _errDoctorName = true);
      _showMsg('Please enter doctor name');
      return false;
    }
    if (_doctorPhoneCtrl.text.trim().isEmpty) {
      setState(() => _errDoctorPhone = true);
      _showMsg('Please enter doctor phone');
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

  Future<void> _completeSetup() async {
    setState(() => _loading = true);
    try {
      // Create user in Firebase Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );
      final uid = cred.user!.uid;

      // Build user profile map
      final profile = {
        'uid': uid,
        'fullName': widget.fullName,
        'email': widget.email,
        'phone': _phoneCtrl.text.trim(),
        'age': int.tryParse(_ageCtrl.text.trim()) ?? 0,
        'gender': _gender,
        'height_cm': double.tryParse(_heightCtrl.text.trim()) ?? 0,
        'weight_kg': double.tryParse(_weightCtrl.text.trim()) ?? 0,
        'blood_type': _blood,
        'emergency_name': _emergencyNameCtrl.text.trim(),
        'emergency_phone': _emergencyPhoneCtrl.text.trim(),
        'medical': {
          'allergies': _allergiesCtrl.text.trim(),
          'conditions': _conditionsCtrl.text.trim(),
          'doctor_name': _doctorNameCtrl.text.trim(),
          'doctor_phone': _doctorPhoneCtrl.text.trim(),
        },
        'preferences': {
          'notif_medication': _notifMedication,
          'notif_daily_check': _notifDailyCheck,
          'notif_refill': _notifRefill,
        },
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('users').doc(uid).set(profile, SetOptions(merge: true));
      // Update display name in Auth profile
      await cred.user!.updateDisplayName(widget.fullName);

      if (!mounted) return;
      _showMsg('Registration successful');
      // Navigate to Home and clear back stack
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false, arguments: {'name': widget.fullName});
    } on FirebaseAuthException catch (e) {
      _showMsg(e.message ?? 'Authentication failed');
    } catch (e) {
      _showMsg('Something went wrong');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --- Step 0: Personal Information card ---
  Widget _buildPersonalCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF2FF),
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _avatar == null
                              ? const Icon(Icons.person, size: 64, color: AppColors.purpleTop)
                              : Image.file(_avatar!, fit: BoxFit.cover),
                        ),
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap to change avatar', style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _LabeledField(
              label: 'Phone Number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              controller: _phoneCtrl,
              hasError: _errPhone,
              onChanged: (_) => setState(() => _errPhone = false),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _LabeledField(
                    label: 'Age',
                    icon: Icons.cake,
                    keyboardType: TextInputType.number,
                    controller: _ageCtrl,
                    hasError: _errAge,
                    onChanged: (_) => setState(() => _errAge = false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DropdownField(
                    label: 'Gender',
                    value: _gender,
                    items: const ['Male', 'Female'],
                    onChanged: (v) => setState(() { _gender = v; _errGender = false; }),
                    icon: Icons.person_outlined,
                    hasError: _errGender,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _LabeledField(
                    label: 'Height (cm)',
                    icon: Icons.straighten,
                    keyboardType: TextInputType.number,
                    controller: _heightCtrl,
                    hasError: _errHeight,
                    onChanged: (_) => setState(() => _errHeight = false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LabeledField(
                    label: 'Weight (kg)',
                    icon: Icons.monitor_weight,
                    keyboardType: TextInputType.number,
                    controller: _weightCtrl,
                    hasError: _errWeight,
                    onChanged: (_) => setState(() => _errWeight = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _DropdownField(
              label: 'Blood Type',
              value: _blood,
              items: const ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'],
              onChanged: (v) => setState(() { _blood = v; _errBlood = false; }),
              icon: Icons.bloodtype,
              hasError: _errBlood,
            ),
            const SizedBox(height: 18),
            const Text('Emergency Contact', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Contact Name',
              icon: Icons.person_pin_circle_sharp,
              keyboardType: TextInputType.name,
              controller: _emergencyNameCtrl,
              hasError: _errEmergencyName,
              onChanged: (_) => setState(() => _errEmergencyName = false),
            ),
            const SizedBox(height: 14),
            _LabeledField(
              label: 'Contact Phone',
              icon: Icons.phone_in_talk,
              keyboardType: TextInputType.phone,
              controller: _emergencyPhoneCtrl,
              hasError: _errEmergencyPhone,
              onChanged: (_) => setState(() => _errEmergencyPhone = false),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 1: Medical Information card ---
  Widget _buildMedicalCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Medical Information',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 16),
            _SmartOutlinedMultiline(
              label: 'Known Allergies',
              hint: 'List any known allergies (e.g., penicillin, peanuts)',
              icon: Icons.warning_amber_outlined,
              controller: _allergiesCtrl,
              hasError: _errAllergies,
              onChanged: (_) => setState(() => _errAllergies = false),
            ),
            const SizedBox(height: 16),
            _SmartOutlinedMultiline(
              label: 'Medical Conditions',
              hint: 'List any ongoing medical conditions',
              icon: Icons.medical_services,
              controller: _conditionsCtrl,
              hasError: _errConditions,
              onChanged: (_) => setState(() => _errConditions = false),
            ),
            const SizedBox(height: 18),
            const Text('Primary Doctor', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _SmartOutlinedField(
              label: 'Doctor Name',
              icon: Icons.add_box,
              controller: _doctorNameCtrl,
              keyboardType: TextInputType.name,
              hasError: _errDoctorName,
              onChanged: (_) => setState(() => _errDoctorName = false),
            ),
            const SizedBox(height: 14),
            _SmartOutlinedField(
              label: 'Doctor Phone',
              icon: Icons.phone,
              controller: _doctorPhoneCtrl,
              keyboardType: TextInputType.phone,
              hasError: _errDoctorPhone,
              onChanged: (_) => setState(() => _errDoctorPhone = false),
            ),
            const SizedBox(height: 18),
            _healthTipCard(),
          ],
        ),
      ),
    );
  }

  Widget _healthTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.25),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Icon(Icons.health_and_safety, color: AppColors.primary, size: 32),
          SizedBox(height: 10),
          Text('Health Tip', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text(
            'Providing accurate medical information helps us give you better medication reminders and health insights.',
            style: TextStyle(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- Step 2: Notification Preferences ---
  Widget _buildNotificationsCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Notification Preferences',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 14),

            // Pref items container-like grouping
            _PrefItem(
              icon: Icons.notifications_active,
              title: 'Medication Reminders',
              subtitle: "Get notified when it's time to take your medication",
              value: _notifMedication,
              onChanged: (v) => setState(() => _notifMedication = v),
            ),
            const SizedBox(height: 12),
            _PrefItem(
              icon: Icons.schedule_outlined,
              title: 'Daily Health Check',
              subtitle: 'Receive daily prompts to log your health status',
              value: _notifDailyCheck,
              onChanged: (v) => setState(() => _notifDailyCheck = v),
            ),
            const SizedBox(height: 12),
            _PrefItem(
              icon: Icons.medical_information,
              title: 'Medication Refill Alerts',
              subtitle: "Get reminded when you're running low on medication",
              value: _notifRefill,
              onChanged: (v) => setState(() => _notifRefill = v),
            ),

            const SizedBox(height: 16),

            // Success gradient card
            Container(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF5A71E4), Color(0xFF6B4399)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(.10), blurRadius: 16, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle_outline, color: Colors.white, size: 44),
                  SizedBox(height: 10),
                  Text("You're All Set!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                  SizedBox(height: 6),
                  Text(
                    'Your profile is complete. Start managing your medications with personalized reminders and health tracking.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_step > 0) {
          setState(() => _step = _step - 1);
          return false; // consume back to go to step 1 instead of popping route
        }
        return true;
      },
      child: Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Container(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    decoration: AppDecorations.gradientBackground,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 70),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              Text(
                                'Complete Your Profile',
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 26),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Help us personalize your medication experience',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withOpacity(.72),
                                      fontSize: 13,
                                    ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 18),
                              // simple progress bars
                              Row(
                                children: [
                                  Expanded(child: _progressBar(active: _step >= 0)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _progressBar(active: _step >= 1)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _progressBar(active: _step >= 2)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // White card with internal scroll
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            height: 540,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(.14), blurRadius: 18, offset: const Offset(0, 6)),
                                BoxShadow(color: Colors.black.withOpacity(.20), blurRadius: 32, spreadRadius: 2, offset: const Offset(0, 14)),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 280),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeIn,
                                child: _step == 0
                                    ? KeyedSubtree(key: const ValueKey('step0'), child: _buildPersonalCard())
                                    : _step == 1
                                        ? KeyedSubtree(key: const ValueKey('step1'), child: _buildMedicalCard())
                                        : KeyedSubtree(key: const ValueKey('step2'), child: _buildNotificationsCard()),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              const spacer = 16.0;
                              final total = constraints.maxWidth;
                              final targetPrev = _step > 0 ? (total - spacer) / 2 : 0.0;
                              final targetNext = _step > 0 ? (total - spacer) / 2 : total;
                              return SizedBox(
                                height: 54,
                                child: Row(
                                  children: [
                                    // Previous grows from 0 to half width
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 260),
                                      curve: Curves.easeInOut,
                                      width: targetPrev,
                                      child: targetPrev == 0
                                          ? const SizedBox.shrink()
                                          : _BounceButton(
                                              backgroundColor: Colors.white.withOpacity(0.06),
                                              foregroundColor: Colors.white,
                                              border: Border.all(color: Colors.white, width: 1.5),
                                              shadow: null, // no shadow for Previous
                                              borderRadius: 14,
                                              onTap: () => setState(() => _step = _step - 1),
                                              child: const Text('Previous', style: TextStyle(fontWeight: FontWeight.w600)),
                                            ),
                                    ),
                                    // Animated spacer between buttons
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 260),
                                      curve: Curves.easeInOut,
                                      width: _step > 0 ? spacer : 0,
                                    ),
                                    // Next shrinks from left and remains pinned to the right edge
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 260),
                                          curve: Curves.easeInOut,
                                          width: targetNext,
                                          child: _BounceButton(
                                            backgroundColor: Colors.white,
                                            foregroundColor: AppColors.primary,
                                            shadow: const [
                                              BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.20), blurRadius: 18, offset: Offset(0, 10), spreadRadius: -3),
                                            ],
                                            borderRadius: 14,
                                            tapDelayMs: 120,
                                            onTap: () {
                                              if (_loading) return;
                                              if (_step == 0) {
                                                if (_validateStep0()) setState(() => _step = 1);
                                              } else if (_step == 1) {
                                                if (_validateStep1()) setState(() => _step = 2);
                                              } else {
                                                setState(() => _loading = true);
                                                _completeSetup();
                                              }
                                            },
                                            child: Text(_step < 2 ? 'Next' : 'Complete Setup', style: const TextStyle(fontWeight: FontWeight.w700)),
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
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (_loading) ...[
              // Blocks interactions with a transparent dark filter
              ModalBarrier(dismissible: false, color: Colors.black.withOpacity(0.28)),
              // Centered loading card
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
                      Text('Creating your account...', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ));
  }

  Widget _progressBar({bool active = false}) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withOpacity(.35),
        borderRadius: BorderRadius.circular(4),
        // Overlay an icon to force constant purple without affecting padding
      ),
    );
  }
}
// Top-level smart multiline field: label sits next to icon before focus, floats on focus/when has text
class _SmartOutlinedMultiline extends StatefulWidget {
  final String label;
  final String? hint;
  final IconData icon;
  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  const _SmartOutlinedMultiline({super.key, required this.label, this.hint, required this.icon, required this.controller, this.hasError = false, this.onChanged});

  @override
  State<_SmartOutlinedMultiline> createState() => _SmartOutlinedMultilineState();
}

class _SmartOutlinedMultilineState extends State<_SmartOutlinedMultiline> {
  final FocusNode _fn = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _fn.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _fn.removeListener(_onChanged);
    widget.controller.removeListener(_onChanged);
    _fn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color base = Colors.black54;
    const Color active = AppColors.primary;
    const Color error = Colors.redAccent;
    final bool hasValue = widget.controller.text.isNotEmpty;
    final bool focused = _fn.hasFocus;

    // Use labelText always, and control floating behavior to keep it inline before focus.
    final String labelText = widget.label;
    final FloatingLabelBehavior floatBehavior = (focused || hasValue)
        ? FloatingLabelBehavior.auto
        : FloatingLabelBehavior.never;
    final String? hintText = (focused && !hasValue) ? widget.hint : null;
    final bool alignLabel = (focused || hasValue); // keep label inline (center) when not focused/empty

    return TextField(
      focusNode: _fn,
      controller: widget.controller,
      maxLines: 3,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        alignLabelWithHint: alignLabel,
        floatingLabelBehavior: floatBehavior,
        labelStyle: TextStyle(color: widget.hasError ? error : (focused ? active : base), fontSize: 16),
        floatingLabelStyle: const TextStyle(color: active, fontWeight: FontWeight.w600),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        prefixIcon: Icon(widget.icon, color: widget.hasError ? error : AppColors.primary, size: 22),
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
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
    );
  }
}

// Restore helper field widgets used in personal card
class _LabeledField extends StatefulWidget {
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  const _LabeledField({required this.label, required this.icon, this.keyboardType, this.controller, this.hasError = false, this.onChanged});

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
        prefixIcon: Icon(widget.icon, color: widget.hasError ? error : AppColors.primary, size: 22),
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

class _DropdownField extends StatefulWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  final IconData icon;
  final bool hasError;
  const _DropdownField({required this.label, required this.items, this.value, this.onChanged, required this.icon, this.hasError = false});

  @override
  State<_DropdownField> createState() => _DropdownFieldState();
}

class _DropdownFieldState extends State<_DropdownField> {
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
    return Focus(
      focusNode: _focusNode,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelStyle: TextStyle(color: widget.hasError ? error : (focused ? active : base), fontSize: 16),
          floatingLabelStyle: const TextStyle(color: active, fontWeight: FontWeight.w600),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          prefixIcon: Icon(widget.icon, color: widget.hasError ? error : AppColors.primary, size: 22),
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
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: widget.value,
            icon: const Icon(Icons.expand_more, color: AppColors.primary),
            isExpanded: true,
            onChanged: widget.onChanged,
            hint: Text(
              widget.label,
              style: const TextStyle(color: Colors.black45),
              overflow: TextOverflow.ellipsis,
            ),
            dropdownColor: Colors.white,
            items: widget.items
                .map((e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(e, style: const TextStyle(color: Colors.black87)),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

