import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/ratingModel/rating_model.dart';

class RatingServices {
  static final CollectionReference _ratingCollection =
      FirebaseFirestore.instance.collection('ratings');

  static Future<void> addRating(RatingModel rating) async {
    await _ratingCollection.add(rating.toJson());
  }

  static Future<List<RatingModel>> getRatingsForForeman(String foremanId) async {
    final snapshot = await _ratingCollection
        .where('foremanId', isEqualTo: foremanId)
        .get();

    return snapshot.docs
        .map((doc) => RatingModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  static Future<void> updateRating(RatingModel rating) async {
  await FirebaseFirestore.instance
      .collection('ratings')
      .doc(rating.id)
      .update(rating.toJson());
}

}