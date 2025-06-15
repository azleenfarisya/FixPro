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
    try {
      final snapshot = await _collection.where('date', isEqualTo: date).get();
      return snapshot.docs
          .map((doc) => ScheduleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch schedules: $e');
    }
  }

  // Create a new schedule
  Future<void> createSchedule(ScheduleModel schedule) async {
    try {
      // Check for existing schedule
      final existingSchedules = await getSchedulesByDate(schedule.date);
      if (existingSchedules.any((s) => s.foremanName == schedule.foremanName)) {
        throw Exception(
            'Schedule already exists for this foreman on this date');
      }

      await _collection.add(schedule.toFirestore());
    } catch (e) {
      throw Exception('Failed to create schedule: $e');
    }
  }

  // Update an existing schedule
  Future<void> updateSchedule(ScheduleModel schedule) async {
    try {
      if (schedule.id == null) {
        throw Exception('Schedule ID is required for update');
      }

      final docRef = _collection.doc(schedule.id);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('Schedule not found');
      }

      await docRef.update(schedule.toFirestore());
    } catch (e) {
      throw Exception('Failed to update schedule: $e');
    }
  }

  // Delete a schedule
  Future<void> deleteSchedule(String id) async {
    try {
      final docRef = _collection.doc(id);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('Schedule not found');
      }

      await docRef.delete();
    } catch (e) {
      throw Exception('Failed to delete schedule: $e');
    }
  }

  // Update job status
  Future<void> updateJobStatus(String id, String status) async {
    try {
      final docRef = _collection.doc(id);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('Schedule not found');
      }

      final validStatuses = [
        'available',
        'assigned',
        'in_progress',
        'completed',
        'cancelled'
      ];
      if (!validStatuses.contains(status)) {
        throw Exception('Invalid status: $status');
      }

      await docRef.update({
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
        if (status == 'completed') 'completed_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update job status: $e');
    }
  }

  // Add job details
  Future<void> addJobDetails(
    String id, {
    required String vehicleName,
    required String vehicleColor,
    required String plateNumber,
    required String jobAssignment,
  }) async {
    try {
      final docRef = _collection.doc(id);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('Schedule not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['status'] != 'available') {
        throw Exception('Cannot add job details to a non-available schedule');
      }

      await docRef.update({
        'vehicle_name': vehicleName,
        'vehicle_color': vehicleColor,
        'plate_number': plateNumber,
        'job_assignment': jobAssignment,
        'status': 'assigned',
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add job details: $e');
    }
  }

  // Get schedules by date range
  Future<List<ScheduleModel>> getSchedulesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      final snapshot = await _collection
          .where('date', isGreaterThanOrEqualTo: startDateStr)
          .where('date', isLessThanOrEqualTo: endDateStr)
          .get();

      return snapshot.docs
          .map((doc) => ScheduleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch schedules by date range: $e');
    }
  }

  // Get schedules by status
  Future<List<ScheduleModel>> getSchedulesByStatus(String status) async {
    try {
      final snapshot = await _collection
          .where('status', isEqualTo: status)
          .orderBy('date')
          .get();

      return snapshot.docs
          .map((doc) => ScheduleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch schedules by status: $e');
    }
  }
}
