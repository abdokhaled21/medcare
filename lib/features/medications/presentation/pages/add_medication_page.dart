import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medcare/core/theme/app_theme.dart';
import 'package:medcare/features/medications/data/medication_model.dart';
import 'package:medcare/features/medications/data/medication_service.dart';

class AddMedicationPage extends StatefulWidget {
  const AddMedicationPage({super.key});

  @override
  State<AddMedicationPage> createState() => _AddMedicationPageState();
}

class _AddMedicationPageState extends State<AddMedicationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _frequencies = const ['Once daily', 'Twice daily', 'As needed'];
  final _timeCats = const ['Morning', 'Evening', 'As Needed'];

  String _frequency = 'Once daily';
  String _timeCategory = 'Morning';
  final Set<String> _days = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'};

  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be signed in')));
      return;
    }

    setState(() => _saving = true);

    try {
      final med = Medication(
        id: '',
        userId: user.uid,
        name: _nameCtrl.text.trim(),
        dosage: _dosageCtrl.text.trim(),
        frequency: _frequency,
        timeCategory: _timeCategory,
        days: _days.toList()..sort((a,b)=>_weekIndex(a).compareTo(_weekIndex(b))),
        createdAt: Timestamp.now(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      await MedicationService.instance.addMedication(med);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int _weekIndex(String d) {
    const map = {
      'Mon': 1,
      'Tue': 2,
      'Wed': 3,
      'Thu': 4,
      'Fri': 5,
      'Sat': 6,
      'Sun': 7,
    };
    return map[d] ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Stack(
          children: [
            // Full-screen gradient background (covers status bar too)
            Positioned.fill(child: Container(decoration: AppDecorations.gradientBackground)),

            // Foreground content respecting safe areas
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _saving ? null : () => Navigator.of(context).maybePop(),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.22),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(.26), width: 1),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 10, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Add Medication', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // White rounded container that holds the scrollable form
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 24, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Add New Medication', style: Theme.of(context).textTheme.headlineMedium),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _nameCtrl,
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.medication_outlined, color: Color(0xFF909FF2)),
                                    hintText: 'Medication Name',
                                  ),
                                  validator: (v) => (v==null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _dosageCtrl,
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.scale_outlined, color: Color(0xFF909FF2)),
                                    hintText: 'Dosage (e.g., 100mg)',
                                  ),
                                  validator: (v) => (v==null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                                const SizedBox(height: 12),
                                _LabeledDropdownField(
                                  icon: Icons.schedule_outlined,
                                  label: 'Frequency',
                                  value: _frequency,
                                  items: _frequencies,
                                  onChanged: (v) => setState(() => _frequency = v!),
                                ),
                                const SizedBox(height: 12),
                                _LabeledDropdownField(
                                  icon: Icons.access_time,
                                  label: 'Time Category',
                                  value: _timeCategory,
                                  items: _timeCats,
                                  onChanged: (v) => setState(() => _timeCategory = v!),
                                ),
                                const SizedBox(height: 16),
                                Text('Days of Week', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    for (final d in const ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'])
                                      ChoiceChip(
                                        label: Text(d),
                                        selected: _days.contains(d),
                                        onSelected: (sel) => setState(() { if (sel) { _days.add(d); } else { _days.remove(d); } }),
                                        selectedColor: const Color(0xFF909FF2),
                                        showCheckmark: false,
                                        labelStyle: TextStyle(color: _days.contains(d) ? Colors.white : AppColors.textDark, fontWeight: FontWeight.w600),
                                        backgroundColor: const Color(0xFFF2F2F7),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Text('Additional Notes', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _notesCtrl,
                                  minLines: 3,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    labelText: 'Notes (Optional)',
                                    prefixIcon: Icon(Icons.insert_drive_file_rounded, color: Color(0xFF909FF2)),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _saving ? null : _save,
                                    child: _saving
                                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation(Colors.white)))
                                        : const Text('Add Medication'),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledDropdownField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _LabeledDropdownField({
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      isFocused: false,
      isEmpty: false,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        prefixIcon: Icon(icon, color: const Color(0xFF909FF2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: AppColors.textDark,
              ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: [for (final i in items) DropdownMenuItem(value: i, child: Text(i))],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
