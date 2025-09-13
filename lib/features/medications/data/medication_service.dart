import 'package:cloud_firestore/cloud_firestore.dart';
import 'medication_model.dart';

class MedicationService {
  MedicationService._();
  static final instance = MedicationService._();

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('medications');
  CollectionReference<Map<String, dynamic>> get _intakesCol => _db.collection('medication_intakes');

  Stream<List<Medication>> watchUserMedications(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Medication.fromDoc(d)).toList());
  }

  Future<String> addMedication(Medication med) async {
    final doc = await _col.add(med.toMap());
    return doc.id;
  }

  Future<void> deleteMedication(String id) async {
    await _col.doc(id).delete();
  }

  Future<void> updateMedication(Medication med) async {
    await _col.doc(med.id).update(med.toMap());
  }

  // ---------- Daily intake status ----------
  /// Returns a stream that emits whether the medication is marked as taken for [date] (defaults to today, local time).
  Stream<bool> watchTakenForDate({
    required String userId,
    required String medicationId,
    DateTime? date,
  }) {
    final d = date ?? DateTime.now();
    final key = _dateKey(d);
    final docId = _intakeDocId(userId, medicationId, key);
    return _intakesCol.doc(docId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return false;
      return (data['taken'] as bool?) ?? false;
    });
  }

  /// Sets today's intake status for the given medication. If [taken] is false, the document is deleted to keep storage clean.
  Future<void> setTakenToday({
    required String userId,
    required String medicationId,
    required bool taken,
    DateTime? now,
  }) async {
    final d = now ?? DateTime.now();
    final key = _dateKey(d);
    final docId = _intakeDocId(userId, medicationId, key);
    final docRef = _intakesCol.doc(docId);
    if (taken) {
      await docRef.set({
        'userId': userId,
        'medicationId': medicationId,
        'date': key,
        'taken': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      // delete if exists; ignore if missing
      await docRef.delete().catchError((_) {});
    }
  }

  String _dateKey(DateTime d) {
    // yyyy-MM-dd in local time
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _intakeDocId(String userId, String medId, String dateKey) => '${userId}_${medId}_$dateKey'.replaceAll('__', '_');
}
