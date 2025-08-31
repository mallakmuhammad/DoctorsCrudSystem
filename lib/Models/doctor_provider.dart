import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_model.dart';

class DoctorProvider with ChangeNotifier {
final _collection = FirebaseFirestore.instance
    .collection('doctors')
    .doc('ecUkoQVD6UcIJgpJ0ehf') 
    .collection('doctors');
  List<Doctor> _doctors = [];

  List<Doctor> get doctors => _doctors;

Future<void> fetchDoctors() async {
  try {
    final snapshot = await _collection.get();
    print('Total docs: ${snapshot.docs.length}');
    _doctors = snapshot.docs.map((doc) {
      final doctor = Doctor.fromJson(doc.data(), doc.id);
      print('Fetched: ${doctor.name}');
      return doctor;
    }).toList();
    notifyListeners();
  } catch (e) {
    print('Error fetching doctors: $e');
  }
}

  Future<void> addDoctor(Doctor doctor) async {
    await _collection.add(doctor.toJson());
    await fetchDoctors();
  }

  Future<void> updateDoctor(Doctor doctor) async {
    await _collection.doc(doctor.id).update(doctor.toJson());
    await fetchDoctors();
  }

  Future<void> deleteDoctor(String id) async {
    await _collection.doc(id).delete();
    await fetchDoctors();
  }
}
