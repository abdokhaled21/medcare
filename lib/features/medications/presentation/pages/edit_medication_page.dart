import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medcare/core/theme/app_theme.dart';
import 'package:medcare/features/medications/data/medication_model.dart';
import 'package:medcare/features/medications/data/medication_service.dart';

class EditMedicationPage extends StatefulWidget {
  const EditMedicationPage({super.key, required this.med});

  final Medication med;

  @override
  State<EditMedicationPage> createState() => _EditMedicationPageState();
}

class _EditMedicationPageState extends State<EditMedicationPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _dosageCtrl;
  late final TextEditingController _notesCtrl;

  final _frequencies = const ['Once daily', 'Twice daily', 'As needed'];
  final _timeCats = const ['Morning', 'Evening', 'As Needed'];

  late String _frequency;
  late String _timeCategory;
  late Set<String> _days;
  late DateTime _startDate; // maps to createdAt
  DateTime? _endDate;

  bool _saving = false;
  bool _allowPopOnce = false; // bypass WillPopScope once after confirming discard

  // Initial values to detect changes (for Discard button enabling)
  late String _initName;
  late String _initDosage;
  late String _initNotes;
  late String _initFrequency;
  late String _initTimeCategory;
  late Set<String> _initDays;
  late DateTime _initStartDate;
  DateTime? _initEndDate;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.med.name);
    _dosageCtrl = TextEditingController(text: widget.med.dosage);
    _notesCtrl = TextEditingController(text: widget.med.notes ?? '');
    _frequency = widget.med.frequency;
    _timeCategory = widget.med.timeCategory;
    _days = widget.med.days.toSet();
    _startDate = widget.med.createdAt.toDate();
    _endDate = widget.med.endAt?.toDate();

    // Snapshot initial state
    _initName = _nameCtrl.text;
    _initDosage = _dosageCtrl.text;
    _initNotes = _notesCtrl.text;
    _initFrequency = _frequency;
    _initTimeCategory = _timeCategory;
    _initDays = {..._days};
    _initStartDate = _startDate;
    _initEndDate = _endDate;

    // Rebuild on text changes to update dirty state
    _nameCtrl.addListener(_onAnyChange);
    _dosageCtrl.addListener(_onAnyChange);
    _notesCtrl.addListener(_onAnyChange);
  }

  Future<bool> _showUnsavedDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              const Text('Unsaved Changes', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          content: const Text(
            'You have unsaved changes. Are you sure you want to discard them?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Continue Editing'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<bool> _confirmDiscardIfDirty() async {
    if (_allowPopOnce) return true;
    if (!_isDirty() || _saving) return true;
    final ok = await _showUnsavedDialog();
    if (ok) {
      // allow next pop without re-triggering the dialog
      setState(() => _allowPopOnce = true);
      return true;
    }
    return false;
  }

  Future<void> _pickEndDate() async {
    final initial = _endDate ?? _startDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select end date',
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onAnyChange() {
    if (mounted) setState(() {});
  }

  bool _isDirty() {
    final eqDays = _initDays.length == _days.length && _initDays.containsAll(_days);
    return _nameCtrl.text.trim() != _initName.trim() ||
        _dosageCtrl.text.trim() != _initDosage.trim() ||
        _notesCtrl.text.trim() != _initNotes.trim() ||
        _frequency != _initFrequency ||
        _timeCategory != _initTimeCategory ||
        !eqDays ||
        !_isSameDay(_startDate, _initStartDate) ||
        !_compareNullableDates(_endDate, _initEndDate);
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  bool _compareNullableDates(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return _isSameDay(a, b);
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select start date',
    );
    if (picked != null) setState(() => _startDate = picked);
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
        id: widget.med.id,
        userId: widget.med.userId, // keep original owner
        name: _nameCtrl.text.trim(),
        dosage: _dosageCtrl.text.trim(),
        frequency: _frequency,
        timeCategory: _timeCategory,
        days: _days.toList()..sort((a,b)=>_weekIndex(a).compareTo(_weekIndex(b))),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        createdAt: Timestamp.fromDate(_startDate),
        endAt: _endDate == null ? null : Timestamp.fromDate(_endDate!),
      );
      await MedicationService.instance.updateMedication(med);
      if (!mounted) return;
      Navigator.of(context).pop<Medication>(med);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
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

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final dirty = _isDirty();
    return WillPopScope(
      onWillPop: _confirmDiscardIfDirty,
      child: Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Stack(
          children: [
            Positioned.fill(child: Container(decoration: AppDecorations.gradientBackground)),
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
                            onTap: _saving
                                ? null
                                : () async {
                                    if (!_isDirty()) {
                                      Navigator.of(context).maybePop();
                                      return;
                                    }
                                    final ok = await _showUnsavedDialog();
                                    if (ok && mounted) {
                                      setState(() => _allowPopOnce = true);
                                      Navigator.of(context).maybePop();
                                    }
                                  },
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
                          const Text('Edit Medication', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.25),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Text('Edit Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Form container
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
                                // Title above the form
                                Row(
                                  children: [
                                    const Icon(Icons.edit, size: 18, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text('Edit Medication Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                // Center icon below the title with translucent background and purple border
                                Center(
                                  child: Container(
                                    width: 74,
                                    height: 74,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(.10),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: AppColors.primary.withOpacity(.35), width: 1.6),
                                    ),
                                    child: const Icon(Icons.medication_liquid, color: AppColors.primary, size: 36),
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // Basic Information
                                Text(
                                  'Basic Information',
                                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                        color: AppColors.textDark,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _nameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Medication Name',
                                    prefixIcon: Icon(Icons.medication_outlined, color: Color(0xFF909FF2)),
                                  ),
                                  validator: (v) => (v==null || v.trim().isEmpty) ? 'Required' : null,
                                  onChanged: (_) => _onAnyChange(),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _dosageCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Dosage (e.g., 100mg)',
                                    prefixIcon: Icon(Icons.scale_outlined, color: Color(0xFF909FF2)),
                                  ),
                                  validator: (v) => (v==null || v.trim().isEmpty) ? 'Required' : null,
                                  onChanged: (_) => _onAnyChange(),
                                ),

                                const SizedBox(height: 18),
                                Text(
                                  'Schedule Settings',
                                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                        color: AppColors.textDark,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                _LabeledDropdownField(
                                  icon: Icons.schedule_outlined,
                                  label: 'Frequency',
                                  value: _frequency,
                                  items: _frequencies,
                                  onChanged: (v) => setState(() { _frequency = v!; }),
                                ),
                                const SizedBox(height: 14),
                                _LabeledDropdownField(
                                  icon: Icons.access_time,
                                  label: 'Time Category',
                                  value: _timeCategory,
                                  items: _timeCats,
                                  onChanged: (v) => setState(() { _timeCategory = v!; }),
                                ),

                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Text('Days of Week', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w700)),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () => setState(() { _days = {'Mon','Tue','Wed','Thu','Fri','Sat','Sun'}; }),
                                      child: const Text('Select All'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
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
                                Text('Duration', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: _pickStartDate,
                                        child: InputDecorator(
                                          isFocused: false,
                                          isEmpty: false,
                                          decoration: const InputDecoration(
                                            labelText: 'Start Date',
                                            floatingLabelBehavior: FloatingLabelBehavior.always,
                                            prefixIcon: Icon(Icons.event, color: Color(0xFF909FF2)),
                                          ),
                                          child: Text(_formatDate(_startDate)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Stack(
                                        alignment: Alignment.centerRight,
                                        children: [
                                          GestureDetector(
                                            onTap: _pickEndDate,
                                            child: InputDecorator(
                                              isFocused: false,
                                              isEmpty: false,
                                              decoration: const InputDecoration(
                                                labelText: 'End Date',
                                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                                prefixIcon: Icon(Icons.event_busy, color: Color(0xFF909FF2)),
                                              ),
                                              child: Text(
                                                _endDate == null ? 'Optional' : _formatDate(_endDate!),
                                                maxLines: 1,
                                                softWrap: false,
                                                overflow: TextOverflow.visible,
                                              ),
                                            ),
                                          ),
                                          if (_endDate != null)
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: Padding(
                                                padding: const EdgeInsets.only(right: 2),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    customBorder: const CircleBorder(),
                                                    onTap: () => setState(() => _endDate = null),
                                                    child: const SizedBox(
                                                      width: 28,
                                                      height: 28,
                                                      child: Center(child: Icon(Icons.close_rounded, size: 16)),
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
                                  onChanged: (_) => _onAnyChange(),
                                ),

                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _saving ? null : _save,
                                    child: _saving
                                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation(Colors.white)))
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.save_rounded),
                                            SizedBox(width: 8),
                                            Text('Save Changes'),
                                          ],
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(52),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ).copyWith(
                                      side: MaterialStateProperty.resolveWith((states) {
                                        if (states.contains(MaterialState.disabled)) {
                                          return const BorderSide(color: Color(0xFFE5E7EB), width: 1);
                                        }
                                        return const BorderSide(color: Color(0xFFE0E0E0), width: 1);
                                      }),
                                      foregroundColor: MaterialStateProperty.resolveWith((states) {
                                        final base = const Color(0xFF6B7280);
                                        return states.contains(MaterialState.disabled) ? base.withOpacity(.45) : base;
                                      }),
                                    ),
                                    onPressed: _saving || !dirty ? null : () => Navigator.of(context).maybePop(),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.cancel_outlined),
                                        SizedBox(width: 8),
                                        Text('Discard Changes', style: TextStyle(fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ),
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
