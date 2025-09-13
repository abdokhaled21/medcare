import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medcare/core/theme/app_theme.dart';
import 'package:medcare/features/medications/data/medication_model.dart';
import 'package:medcare/features/medications/data/medication_service.dart';
import 'package:medcare/features/medications/presentation/pages/edit_medication_page.dart';

class MedicationDetailsPage extends StatefulWidget {
  const MedicationDetailsPage({super.key, required this.med});

  final Medication med;

  @override
  State<MedicationDetailsPage> createState() => _MedicationDetailsPageState();
}

class _MedicationDetailsPageState extends State<MedicationDetailsPage> {
  // Shared notifier to perform instant (optimistic) UI updates across widgets
  final ValueNotifier<bool?> _takenOverride = ValueNotifier<bool?>(null);
  late Medication _med;

  @override
  void dispose() {
    _takenOverride.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _med = widget.med;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final topH = h * 0.25; // match HomePage top gradient height
          return Stack(
            children: [
              // Background gradient like Home (outside SafeArea)
              Container(
                height: topH,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF909FF2), Colors.white],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),

              // Foreground content
              SafeArea(
                child: Column(
              children: [
                // Header content (no decoration)
                Container(
                  height: 92,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      _headerActionBtn(
                        context,
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Medication Details',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: .2,
                          ),
                        ),
                      ),
                      _headerActionBtn(context, icon: Icons.edit, onTap: () async {
                        final updated = await Navigator.of(context).push<Medication>(
                          MaterialPageRoute(builder: (_) => EditMedicationPage(med: _med)),
                        );
                        if (updated != null && mounted) {
                          setState(() => _med = updated);
                        }
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 0),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: _TopSummaryCard(med: _med, uid: uid, takenOverride: _takenOverride),
                      ),
                      const SizedBox(height: 16),
                      // Details section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _SectionCard(
                          title: 'Details',
                          child: Column(
                            children: [
                              _kv('Frequency', _med.frequency),
                              const SizedBox(height: 12),
                              _kv('Time', _med.timeCategory),
                              const SizedBox(height: 12),
                              _kv(
                                'Start Date',
                                '${_med.createdAt.toDate().day}/${_med.createdAt.toDate().month}/${_med.createdAt.toDate().year}',
                              ),
                              if (_med.endAt != null) ...[
                                const SizedBox(height: 12),
                                _kv(
                                  'End Date',
                                  '${_med.endAt!.toDate().day}/${_med.endAt!.toDate().month}/${_med.endAt!.toDate().year}',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _SectionCard(
                          title: 'Schedule',
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 12,
                            children: [
                              for (final d in _med.days)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE9EDFF),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(d, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_med.notes != null && _med.notes!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _SectionCard(
                            title: 'Notes',
                            child: Text(
                              _med.notes!,
                              style: const TextStyle(color: AppColors.textDark),
                            ),
                          ),
                        ),
                      const SizedBox(height: 18),
                      if (uid != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _TakenActionBar(uid: uid, med: _med, takenOverride: _takenOverride),
                        ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _DeleteButton(med: _med),
                      ),
                    ],
                  ),
                ),
                ],
              ),
            ),
            ],
          );
        },
      ),
      ),
    );
  }

  // Key-Value row helper for the Details section
  Widget _kv(String k, String v) {
    return Row(
      children: [
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            k,
            style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w600),
          ),
        ),
        Text(v, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
      ],
    );
  }

  // Removed unused helpers (_formatDate)

  static Widget _headerActionBtn(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
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
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _TopSummaryCard extends StatelessWidget {
  const _TopSummaryCard({required this.med, required this.uid, required this.takenOverride});
  final Medication med;
  final String? uid;
  final ValueNotifier<bool?> takenOverride;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool?>(
      valueListenable: takenOverride,
      builder: (context, forced, _) {
        return StreamBuilder<bool>(
          stream: uid == null
              ? const Stream<bool>.empty()
              : MedicationService.instance.watchTakenForDate(userId: uid!, medicationId: med.id),
          builder: (context, snap) {
            final taken = forced ?? (snap.data ?? false);
            final bg = taken ? const Color(0xFFE9F8EE) : const Color(0xFFFFF2E0);
            final fg = taken ? const Color(0xFF34C759) : const Color(0xFFED9B1E);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
              constraints: const BoxConstraints(minHeight: 240),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: taken ? Border.all(color: const Color(0xFF34C759), width: 2) : null,
                boxShadow: const [
                  BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.06), blurRadius: 18, offset: Offset(0, 8)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9E1FF),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.06), blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: const Icon(Icons.medication_liquid, color: AppColors.primary, size: 36),
                  ),
                  const SizedBox(height: 18),
                  Text(med.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
                  const SizedBox(height: 10),
                  Text(
                    med.dosage,
                    style: TextStyle(color: AppColors.primary.withOpacity(0.8), fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.04), blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Text(
                      taken ? 'Taken Today' : 'Pending',
                      style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// Removed _StatusBanner in favor of the chip inside the top card

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.06), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black87)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TakenActionBar extends StatefulWidget {
  const _TakenActionBar({required this.uid, required this.med, required this.takenOverride});
  final String uid;
  final Medication med;
  final ValueNotifier<bool?> takenOverride;

  @override
  State<_TakenActionBar> createState() => _TakenActionBarState();
}

class _TakenActionBarState extends State<_TakenActionBar> {
  bool _busy = false;

  String _todayAbbr() {
    const map = {
      DateTime.monday: 'Mon',
      DateTime.tuesday: 'Tue',
      DateTime.wednesday: 'Wed',
      DateTime.thursday: 'Thu',
      DateTime.friday: 'Fri',
      DateTime.saturday: 'Sat',
      DateTime.sunday: 'Sun',
    };
    return map[DateTime.now().weekday]!;
  }

  // Find the next scheduled date starting from tomorrow if today isn't scheduled
  DateTime _nextScheduledDate() {
    final today = DateTime.now();
    final daysSet = widget.med.days.toSet();
    if (daysSet.isEmpty) return today;
    for (int add = 1; add <= 7; add++) {
      final d = today.add(Duration(days: add));
      final abbr = _abbrFor(d);
      if (daysSet.contains(abbr)) return d;
    }
    return today.add(const Duration(days: 1));
  }

  String _abbrFor(DateTime d) {
    const map = {
      DateTime.monday: 'Mon',
      DateTime.tuesday: 'Tue',
      DateTime.wednesday: 'Wed',
      DateTime.thursday: 'Thu',
      DateTime.friday: 'Fri',
      DateTime.saturday: 'Sat',
      DateTime.sunday: 'Sun',
    };
    return map[d.weekday]!;
  }

  String _formatDateDMY(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool?>(
      valueListenable: widget.takenOverride,
      builder: (context, forced, _) {
        return StreamBuilder<bool>(
          stream: MedicationService.instance
              .watchTakenForDate(userId: widget.uid, medicationId: widget.med.id),
          builder: (context, snap) {
            final taken = forced ?? (snap.data ?? false);
            final isTodayScheduled = widget.med.days.contains(_todayAbbr());
            final nextDate = isTodayScheduled ? null : _nextScheduledDate();
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTodayScheduled
                      ? (taken ? const Color(0xFFFFA000) : const Color(0xFF34C759))
                      : const Color(0xFFF3F4F6),
                  foregroundColor: isTodayScheduled ? Colors.white : AppColors.textLight,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _busy || !isTodayScheduled
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        // Optimistic UI: flip immediately
                        widget.takenOverride.value = !taken;
                        await MedicationService.instance.setTakenToday(
                          userId: widget.uid,
                          medicationId: widget.med.id,
                          taken: !taken,
                        );
                        final msg = !taken ? 'Medication marked as taken' : 'Marked as not taken';
                        if (mounted) {
                          // success = true -> green (taken), false -> yellow (not taken)
                          _showTopFlushbar(context, msg, success: !taken);
                        }
                        // Let stream take control again
                        widget.takenOverride.value = null;
                        if (mounted) setState(() => _busy = false);
                      },
                child: Text(
                  isTodayScheduled
                      ? (taken ? 'Mark as Not Taken' : 'Mark as Taken')
                      : 'Next: ${_abbrFor(nextDate!)} ${_formatDateDMY(nextDate)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isTodayScheduled ? Colors.white : AppColors.textLight,
                  ),
                ),
              ),
            ),
          ],
        );
          },
        );
      },
    );
  }
}

void _showTopFlushbar(BuildContext context, String message, {bool success = true}) {
  Flushbar(
    message: message,
    duration: const Duration(seconds: 2),
    flushbarPosition: FlushbarPosition.TOP,
    backgroundColor: success ? const Color(0xFF34C759) : const Color(0xFFED9B1E),
    margin: const EdgeInsets.all(12),
    borderRadius: BorderRadius.circular(12),
    icon: Icon(success ? Icons.check_circle_rounded : Icons.info_rounded, color: Colors.white),
    leftBarIndicatorColor: Colors.white.withOpacity(.6),
    isDismissible: true,
    animationDuration: const Duration(milliseconds: 300),
  ).show(context);
}

Future<bool?> _confirmDelete(BuildContext context) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withOpacity(.45),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, anim1, anim2) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (ctx, anim, _, __) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return Opacity(
        opacity: curved.value,
        child: Transform.scale(
          scale: Tween<double>(begin: .96, end: 1).evaluate(curved),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(ctx).size.width * .86,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.10), blurRadius: 28, offset: Offset(0, 12)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0x1AEB5757),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEB5757), size: 32),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Delete Medication',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Are you sure you want to delete this medication? This action cannot be undone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textLight, height: 1.35),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEB5757),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              shadowColor: const Color.fromRGBO(235, 87, 87, 0.35),
                              elevation: 2,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _DeleteButton extends StatefulWidget {
  const _DeleteButton({required this.med});
  final Medication med;

  @override
  State<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<_DeleteButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: const Color(0xFFEB5757),
          side: const BorderSide(color: Color(0xFFEB5757)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _busy
            ? null
            : () async {
                final ok = await _confirmDelete(context);
                if (ok != true) return;
                setState(() => _busy = true);
                await MedicationService.instance.deleteMedication(widget.med.id);
                if (mounted) {
                  setState(() => _busy = false);
                  Navigator.of(context).pop();
                }
              },
        child: const Text('Delete Medication', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
