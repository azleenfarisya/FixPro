class Rating {
  final String id;
  final String ownerId;
  final String foremanId;
  final String jobId;
  final int performance;
  final int communication;
  final int skills;
  final String comment;
  final DateTime createdAt;

  Rating({
    required this.id,
    required this.ownerId,
    required this.foremanId,
    required this.jobId,
    required this.performance,
    required this.communication,
    required this.skills,
    required this.comment,
    required this.createdAt,
  });

  // Convert Rating object to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'foremanId': foremanId,
      'jobId': jobId,
      'performance': performance,
      'communication': communication,
      'skills': skills,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create Rating object from Firebase snapshot
  factory Rating.fromMap(Map<String, dynamic> map, String documentId) {
    return Rating(
      id: documentId,
      ownerId: map['ownerId'] ?? '',
      foremanId: map['foremanId'] ?? '',
      jobId: map['jobId'] ?? '',
      performance: map['performance'] ?? 0,
      communication: map['communication'] ?? 0,
      skills: map['skills'] ?? 0,
      comment: map['comment'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}