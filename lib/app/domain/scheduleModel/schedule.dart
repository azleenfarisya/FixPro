import 'package:cloud_firestore/cloud_firestore.dart';
import 'schedule_model.dart';

class Schedule {
  final CollectionReference _collection =
      FirebaseFirestore.instance.collection('working_schedules');

  // Get all schedules for a foreman
  Stream<List<ScheduleModel>> getSchedulesByForeman(String foremanName) {
    return _collection
        .where('foreman_name', isEqualTo: foremanName)
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ScheduleModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get schedules by date
  Future<List<ScheduleModel>> getSchedulesByDate(String date) async {
    final snapshot = await _collection.where('date', isEqualTo: date).get();

    return snapshot.docs
        .map((doc) => ScheduleModel.fromFirestore(doc))
        .toList();
  }

  // Create a new schedule
  Future<void> createSchedule(ScheduleModel schedule) async {
    await _collection.add(schedule.toFirestore());
  }

  // Update an existing schedule
  Future<void> updateSchedule(ScheduleModel schedule) async {
    await _collection.doc(schedule.id).update(schedule.toFirestore());
  }

  // Delete a schedule
  Future<void> deleteSchedule(String id) async {
    await _collection.doc(id).delete();
  }

  // Update job status
  Future<void> updateJobStatus(String id, String status) async {
    await _collection.doc(id).update({
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
      if (status == 'completed') 'completed_at': FieldValue.serverTimestamp(),
    });
  }

  // Add job details (vehicle and job assignment)
  Future<void> addJobDetails(
    String id, {
    required String vehicleName,
    required String vehicleColor,
    required String plateNumber,
    required String jobAssignment,
  }) async {
    await _collection.doc(id).update({
      'vehicle_name': vehicleName,
      'vehicle_color': vehicleColor,
      'plate_number': plateNumber,
      'job_assignment': jobAssignment,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
