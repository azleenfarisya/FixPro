import '../domain/ratingModel/rating_model.dart';
import '../services/rating_services.dart';

class RatingController {
  final RatingServices _services = RatingServices();

  Future<void> submitRating({
    required String jobId,
    required String foremanId,
    required String ownerId,
    required int performance,
    required int communication,
    required int skills,
    required String comment,
  }) async {
    final rating = RatingModel(
      id: '',
      jobId: jobId,
      foremanId: foremanId,
      ownerId: ownerId,
      performance: performance,
      communication: communication,
      skills: skills,
      comment: comment,
      timestamp: DateTime.now(),
    );

    await RatingServices.addRating(rating); 
  }

  Future<List<RatingModel>> fetchRatings(String foremanId) async {
    return RatingServices.getRatingsForForeman(foremanId);
  }
}