// provider/schedule_controller.dart
import 'package:fix_pro/app/domain/scheduleModel/schedule.dart';
import 'package:flutter/material.dart';
import '../domain/scheduleModel/schedule_model.dart';

class ScheduleController extends ChangeNotifier {
  final Schedule _schedule = Schedule();
  List<ScheduleModel> _schedules = [];
  List<ScheduleModel> get schedules => _schedules;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Get schedules for a specific foreman
  Stream<List<ScheduleModel>> getSchedulesByForeman(String foremanName) {
    return _schedule.getSchedulesByForeman(foremanName);
  }

  // Get schedules for a specific date
  Future<void> fetchSchedulesByDate(String date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _schedules = await _schedule.getSchedulesByDate(date);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new schedule
  Future<void> createSchedule(ScheduleModel schedule) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _schedule.createSchedule(schedule);
      await fetchSchedulesByDate(schedule.date);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update an existing schedule
  Future<void> updateSchedule(ScheduleModel schedule) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _schedule.updateSchedule(schedule);
      await fetchSchedulesByDate(schedule.date);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a schedule
  Future<void> deleteSchedule(String id, String date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _schedule.deleteSchedule(id);
      await fetchSchedulesByDate(date);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update job status
  Future<void> updateJobStatus(String id, String status, String date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _schedule.updateJobStatus(id, status);
      await fetchSchedulesByDate(date);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add job details
  Future<void> addJobDetails({
    required String id,
    required String date,
    required String vehicleName,
    required String vehicleColor,
    required String plateNumber,
    required String jobAssignment,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _schedule.addJobDetails(
        id,
        vehicleName: vehicleName,
        vehicleColor: vehicleColor,
        plateNumber: plateNumber,
        jobAssignment: jobAssignment,
      );
      await fetchSchedulesByDate(date);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
