import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String id;
  final String jobId;
  final String foremanId;
  final String ownerId;
  final int performance;
  final int communication;
  final int skills;
  final String comment;
  final DateTime timestamp;

  RatingModel({
    required this.id,
    required this.jobId,
    required this.foremanId,
    required this.ownerId,
    required this.performance,
    required this.communication,
    required this.skills,
    required this.comment,
    required this.timestamp,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json, String id) {
    return RatingModel(
      id: id,
      jobId: json['jobId'],
      foremanId: json['foremanId'],
      ownerId: json['ownerId'],
      performance: json['performance'],
      communication: json['communication'],
      skills: json['skills'],
      comment: json['comment'],
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jobId': jobId,
      'foremanId': foremanId,
      'ownerId': ownerId,
      'performance': performance,
      'communication': communication,
      'skills': skills,
      'comment': comment,
      'timestamp': timestamp,
    };
  }
}