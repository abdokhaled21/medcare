import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:another_flushbar/flushbar.dart';
// removed: unused flushbar_route import
import 'package:medcare/features/auth/presentation/pages/login_page.dart';
import 'package:medcare/core/theme/app_theme.dart';
import 'package:medcare/core/routes/app_router.dart';
import 'package:medcare/features/medications/data/medication_service.dart';
import 'package:medcare/features/medications/data/medication_model.dart';
import 'package:medcare/features/profile/presentation/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loading = false;
  Stream<List<Medication>>? _medsStream; // cache to avoid rebuild-induced waiting state
  List<Medication> _lastMeds = const <Medication>[]; // keep last value to avoid spinner flash

  Future<void> _confirmAndLogout() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.28),
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          title: Row(
            children: const [
              CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFE8F0FE),
                child: Icon(Icons.logout, color: AppColors.primary, size: 18),
              ),
              SizedBox(width: 10),
              Text('Sign out', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          content: const Text(
            'Are you sure you want to sign out?\nYou will need to sign in again to continue.',
            style: TextStyle(height: 1.3),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.primary, width: 1.2),
                        foregroundColor: AppColors.primary,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        padding: EdgeInsets.zero,
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _signOut();
    }
  }

  Future<void> _signOut() async {
    setState(() => _loading = true);
    try {
      // Clear any app-side caches here if added in future (e.g., providers, local storage)
      await FirebaseAuth.instance.signOut();
      // Keep the overlay visible for 3 seconds to match requested UX
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      Flushbar(
        message: 'Failed to sign out. Please try again.',
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.redAccent,
        margin: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(12),
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
    }
  }

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _medsStream = MedicationService.instance.watchUserMedications(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final authName = FirebaseAuth.instance.currentUser?.displayName;
    final name = (args != null && args['name'] is String && (args['name'] as String).isNotEmpty)
        ? args['name'] as String
        : (authName ?? 'User');

    final user = FirebaseAuth.instance.currentUser;
    // Ensure stream is initialized once when user becomes available (e.g., hot restart)
    if (user != null && _medsStream == null) {
      _medsStream = MedicationService.instance.watchUserMedications(user.uid);
    }
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
          final topH = h * 0.25; // 25% of screen height per request
          return Stack(
            children: [
              // Subtle purple -> white gradient that blends (no hard edge)
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
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting over the blended header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, $name!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(color: const Color(0xFF909FF2)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Today's Medications",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(color: const Color(0xFF909FF2)),
                                ),
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: _loading ? null : _confirmAndLogout,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFEFEFF4), width: 1),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.10),
                                      blurRadius: 16,
                                      offset: Offset(0, 6),
                                    ),
                                    BoxShadow(
                                      color: Color.fromRGBO(144, 159, 242, 0.25),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.logout_rounded,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                        ],
                      ),
                    ),
                    // Content directly on white background
                    Expanded(
                      child: user == null
                          ? const Center(child: Text('Please sign in'))
                          : StreamBuilder<List<Medication>>(
                              stream: _medsStream,
                              initialData: _lastMeds,
                              builder: (context, snap) {
                                // Use cached data to avoid flicker while dialog is on top
                                final meds = snap.data ?? _lastMeds;
                                // Update cache (no setState to avoid rebuild loop)
                                _lastMeds = meds;
                                if (snap.connectionState == ConnectionState.waiting && meds.isEmpty) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final groups = <String, List<Medication>>{};
                                for (final m in meds) {
                                  groups.putIfAbsent(m.timeCategory, () => <Medication>[]).add(m);
                                }

                                final order = ['Morning', 'Evening', 'As Needed'];
                                final sections = order.where((o) => groups.containsKey(o)).toList();

                                if (sections.isEmpty) {
                                  return const Center(child: Text('No medications yet. Tap + to add.'));
                                }

                                return ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                                  itemCount: sections.length,
                                  itemBuilder: (context, idx) {
                                    final key = sections[idx];
                                    final list = groups[key]!;
                                    return _Section(
                                      title: key,
                                      count: list.length,
                                      icon: key == 'Morning'
                                          ? Icons.wb_sunny
                                          : key == 'Evening'
                                              ? Icons.nights_stay
                                              : Icons.medical_services,
                                      children: [
                                        for (final m in list) _MedicationCard(m: m),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Signing you out...',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ]);
        },
      ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addMedication),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFEFEFF4), width: 1),
              boxShadow: const [
                // Soft ambient shadow
                BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.10), blurRadius: 24, offset: Offset(0, 8), spreadRadius: 0),
                // Subtle outer glow to emphasize border
                BoxShadow(color: Color.fromRGBO(144, 159, 242, 0.20), blurRadius: 12, offset: Offset(0, 2), spreadRadius: 1),
              ],
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textLight,
              showUnselectedLabels: false,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
              ],
              currentIndex: 0,
              onTap: (i) {
                if (i == 1) {
                  Navigator.of(context).push(PageRouteBuilder(
                    settings: const RouteSettings(name: AppRoutes.profile),
                    transitionDuration: const Duration(milliseconds: 300),
                    pageBuilder: (_, animation, __) => const ProfilePage(),
                    transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
                  ));
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final List<Widget> children;
  const _Section({required this.title, required this.count, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('$count ${count == 1 ? 'medication' : 'medications'}', style: const TextStyle(color: AppColors.textLight)),
              ],
            ),
          ),
          for (final c in children) Padding(padding: const EdgeInsets.only(bottom: 12), child: c),
        ],
      ),
    );
  }
}

class _MedicationCard extends StatefulWidget {
  final Medication m;
  const _MedicationCard({required this.m});

  @override
  State<_MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<_MedicationCard> {
  // Firestore-backed; UI reads from stream, with optimistic local override.
  bool? _localChecked; // keep for potential UI override if needed later
  bool _saving = false;
  
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

  DateTime _nextScheduledDate(List<String> days) {
    final today = DateTime.now();
    if (days.isEmpty) return today;
    for (int add = 0; add < 7; add++) {
      final d = today.add(Duration(days: add));
      if (days.contains(_abbrFor(d))) return d;
    }
    return today;
  }

  String _formatDMY(DateTime d) => '${d.day}/${d.month}/${d.year}';
  
  @override
  Widget build(BuildContext context) {
    final m = widget.m;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<bool>(
      stream: userId == null
          ? const Stream<bool>.empty()
          : MedicationService.instance.watchTakenForDate(
              userId: userId,
              medicationId: m.id,
            ),
      builder: (context, snap) {
        final checked = _localChecked ?? (snap.data ?? false);
        final days = m.days;
        final isTodayScheduled = days.contains(_todayAbbr());
        final nextDate = _nextScheduledDate(days);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.medicationDetails, arguments: m),
            child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: checked ? Border.all(color: const Color(0xFF34C759), width: 2) : null,
            boxShadow: const [
              BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.06), blurRadius: 18, offset: Offset(0, 8)),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(0xFFD9E1FF),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.06), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.medication, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.name,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        m.dosage,
                        style: TextStyle(
                          color: AppColors.primary.withOpacity(0.8),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.frequency,
                      style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: checked,
                  onChanged: userId == null || _saving
                      ? null
                      : (v) async {
                          if (!isTodayScheduled) {
                            Flushbar(
                              message: 'Not scheduled for today. Next reminder: ${_abbrFor(nextDate)} ${_formatDMY(nextDate)}',
                              duration: const Duration(seconds: 3),
                              flushbarPosition: FlushbarPosition.TOP,
                              backgroundColor: const Color(0xFFED9B1E),
                              margin: const EdgeInsets.all(12),
                              borderRadius: BorderRadius.circular(12),
                              icon: const Icon(Icons.info_rounded, color: Colors.white),
                            ).show(context);
                            return;
                          }
                          final newVal = v ?? false;
                          setState(() => _saving = true);
                          await MedicationService.instance.setTakenToday(
                            userId: userId,
                            medicationId: m.id,
                            taken: newVal,
                          );
                          if (mounted) setState(() => _saving = false);
                        },
                  activeColor: const Color(0xFF34C759),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
}
