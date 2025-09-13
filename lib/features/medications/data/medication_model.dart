import 'package:cloud_firestore/cloud_firestore.dart';

class Medication {
  final String id;
  final String userId;
  final String name;
  final String dosage; // e.g., 100mg
  final String frequency; // e.g., Once daily
  final String timeCategory; // Morning | Evening | As Needed
  final List<String> days; // Mon..Sun
  final String? notes;
  final Timestamp createdAt;
  final Timestamp? endAt; // optional end date

  Medication({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.timeCategory,
    required this.days,
    required this.createdAt,
    this.endAt,
    this.notes,
  });

  factory Medication.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Medication(
      id: doc.id,
      userId: (data['userId'] ?? '') as String,
      name: (data['name'] ?? '') as String,
      dosage: (data['dosage'] ?? '') as String,
      frequency: (data['frequency'] ?? '') as String,
      timeCategory: (data['timeCategory'] ?? 'Morning') as String,
      days: (List<String>.from(data['days'] ?? const [])),
      notes: (data['notes'] as String?),
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()),
      endAt: data['endAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'timeCategory': timeCategory,
        'days': days,
        'notes': notes,
        'createdAt': createdAt,
        'endAt': endAt,
      };
}
