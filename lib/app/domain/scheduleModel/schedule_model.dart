import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleModel {
  final String id;
  final String foremanName;
  final String date;
  final String startTime;
  final String endTime;
  final String? vehicleName;
  final String? vehicleColor;
  final String? plateNumber;
  final String? jobAssignment;
  final String status; // 'pending', 'in_progress', 'completed'
  final DateTime? completedAt;
  final String? notes;
  final List<String>? photoUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  ScheduleModel({
    required this.id,
    required this.foremanName,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.vehicleName,
    this.vehicleColor,
    this.plateNumber,
    this.jobAssignment,
    this.status = 'pending',
    this.completedAt,
    this.notes,
    this.photoUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert Firestore document to ScheduleModel
  factory ScheduleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScheduleModel(
      id: doc.id,
      foremanName: data['foreman_name'] ?? '',
      date: data['date'] ?? '',
      startTime: data['start_time'] ?? '',
      endTime: data['end_time'] ?? '',
      vehicleName: data['vehicle_name'],
      vehicleColor: data['vehicle_color'],
      plateNumber: data['plate_number'],
      jobAssignment: data['job_assignment'],
      status: data['status'] ?? 'pending',
      completedAt: data['completed_at'] != null
          ? (data['completed_at'] as Timestamp).toDate()
          : null,
      notes: data['notes'],
      photoUrls: data['photo_urls'] != null
          ? List<String>.from(data['photo_urls'])
          : null,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  // Convert ScheduleModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'foreman_name': foremanName,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'vehicle_name': vehicleName,
      'vehicle_color': vehicleColor,
      'plate_number': plateNumber,
      'job_assignment': jobAssignment,
      'status': status,
      'completed_at':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'notes': notes,
      'photo_urls': photoUrls,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a copy of ScheduleModel with updated fields
  ScheduleModel copyWith({
    String? id,
    String? foremanName,
    String? date,
    String? startTime,
    String? endTime,
    String? vehicleName,
    String? vehicleColor,
    String? plateNumber,
    String? jobAssignment,
    String? status,
    DateTime? completedAt,
    String? notes,
    List<String>? photoUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      foremanName: foremanName ?? this.foremanName,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      vehicleName: vehicleName ?? this.vehicleName,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      plateNumber: plateNumber ?? this.plateNumber,
      jobAssignment: jobAssignment ?? this.jobAssignment,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Add methods for:
  // - Status management
  // - Time calculations
  // - Data validation
  // - Serialization/deserialization
}
