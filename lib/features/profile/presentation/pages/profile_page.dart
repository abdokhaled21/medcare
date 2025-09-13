import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medcare/core/routes/app_router.dart';
import 'package:medcare/core/theme/app_theme.dart';
import 'package:medcare/features/home/presentation/pages/home_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Stack(
        children: [
          // Header gradient
          SizedBox(
            height: 200,
            width: double.infinity,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF909FF2), Colors.white],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Title Row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      const Text(
                        'My Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: AppDecorations.roundedIconContainer(),
                        child: IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                          onPressed: () {},
                          tooltip: 'Edit Profile',
                        ),
                      )
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: uid == null
                      ? const Center(child: Text('Please sign in'))
                      : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                          builder: (context, snap) {
                            if (snap.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final data = snap.data?.data() ?? const <String, dynamic>{};
                            final name = (data['fullName'] ?? FirebaseAuth.instance.currentUser?.displayName ?? 'User').toString();
                            final email = (data['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '').toString();
                            final photoUrl = data['photoUrl'] as String?;

                            final phone = (data['phone'] ?? '').toString();
                            final age = (data['age']?.toString() ?? '');
                            final gender = (data['gender'] ?? '').toString();
                            final height = (data['height_cm']?.toString() ?? ''); // cm
                            final weight = (data['weight_kg']?.toString() ?? ''); // kg
                            final blood = (data['blood_type'] ?? '').toString();

                            final med = (data['medical'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
                            final allergies = (med['allergies'] ?? '').toString();
                            final conditions = (med['conditions'] ?? '').toString();
                            final doctor = (med['doctor_name'] ?? '').toString();
                            final doctorPhone = (med['doctor_phone'] ?? '').toString();

                            final emergencyName = (data['emergency_name'] ?? '').toString();
                            final emergencyPhone = (data['emergency_phone'] ?? '').toString();

                            return SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              child: Column(
                                children: [
                                  _TopCard(name: name, email: email, photoUrl: photoUrl),
                                  const SizedBox(height: 14),
                                  _InfoCard(
                                    title: 'Personal Information',
                                    rows: [
                                      _InfoRow(label: 'Phone', value: phone.isEmpty ? '-' : phone),
                                      _InfoRow(label: 'Age', value: age.isEmpty ? '-' : '$age years'),
                                      _InfoRow(label: 'Gender', value: gender.isEmpty ? '-' : gender),
                                      _InfoRow(label: 'Height', value: height.isEmpty ? '-' : '$height cm'),
                                      _InfoRow(label: 'Weight', value: weight.isEmpty ? '-' : '$weight kg'),
                                      _InfoRow(label: 'Blood Type', value: blood.isEmpty ? '-' : blood),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  _InfoCard(
                                    title: 'Medical Information',
                                    rows: [
                                      _InfoRow(label: 'Allergies', value: allergies.isEmpty ? '-' : allergies, emphasize: true),
                                      _InfoRow(label: 'Conditions', value: conditions.isEmpty ? '-' : conditions, emphasize: true),
                                      _InfoRow(label: 'Doctor', value: doctor.isEmpty ? '-' : doctor),
                                      _InfoRow(label: 'Doctor Phone', value: doctorPhone.isEmpty ? '-' : doctorPhone),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  _InfoCard(
                                    title: 'Emergency Contact',
                                    rows: [
                                      _InfoRow(label: 'Name', value: emergencyName.isEmpty ? '-' : emergencyName),
                                      _InfoRow(label: 'Phone', value: emergencyPhone.isEmpty ? '-' : emergencyPhone),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
        ),
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
              currentIndex: 1,
              onTap: (i) {
                if (i == 0) {
                  Navigator.of(context).pushReplacement(PageRouteBuilder(
                    settings: const RouteSettings(name: AppRoutes.home),
                    transitionDuration: const Duration(milliseconds: 300),
                    pageBuilder: (_, animation, __) => const HomePage(),
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

class _TopCard extends StatelessWidget {
  final String name;
  final String email;
  final String? photoUrl;
  const _TopCard({required this.name, required this.email, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.08), blurRadius: 18, offset: Offset(0, 10), spreadRadius: -3),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.12),
              borderRadius: BorderRadius.circular(38),
            ),
            clipBehavior: Clip.antiAlias,
            child: photoUrl == null || photoUrl!.isEmpty
                ? const Icon(Icons.person, color: AppColors.primary, size: 38)
                : Image.network(photoUrl!, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;
  const _InfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.08), blurRadius: 18, offset: Offset(0, 10), spreadRadius: -3),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;
  const _InfoRow({required this.label, required this.value, this.emphasize = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textLight, fontSize: 14),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 14,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
                color: emphasize ? Colors.black87 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
