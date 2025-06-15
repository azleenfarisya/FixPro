import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/ratingModel/rating_model.dart';
import '../../services/rating_services.dart';

class AddRatingPage extends StatefulWidget {
  final String jobId;
  final String foremanId;
  final String ownerId;
  final String foremanName;
  final String jobTitle;
  final String foremanImageUrl;

  const AddRatingPage({
    super.key,
    required this.jobId,
    required this.foremanId,
    required this.ownerId,
    required this.foremanName,
    required this.jobTitle,
    required this.foremanImageUrl,
  });

  @override
  State<AddRatingPage> createState() => _AddRatingPageState();
}

class _AddRatingPageState extends State<AddRatingPage> {
  int performanceRating = 0;
  int communicationRating = 0;
  int skillsRating = 0;
  final TextEditingController commentController = TextEditingController();
  bool isLoading = false;

  Widget buildRatingRow(String label, int rating, Function(int) onRated) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            flex: 3,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => onRated(index + 1),
                  child: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 22,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> handleSubmit() async {
    if (performanceRating == 0 || communicationRating == 0 || skillsRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please rate all categories.")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final rating = RatingModel(
        id: '', // Firebase will auto-generate
        jobId: widget.jobId,
        foremanId: widget.foremanId,
        ownerId: widget.ownerId,
        performance: performanceRating,
        communication: communicationRating,
        skills: skillsRating,
        comment: commentController.text,
        timestamp: DateTime.now(),
      );

      await RatingServices.addRating(rating);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Rating submitted successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error submitting rating: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit rating.")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Foreman'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: const Color(0xFF73BDE3),
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'Rate Foreman',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage(widget.foremanImageUrl),
              ),
              const SizedBox(height: 10),
              Text(
                widget.foremanName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.jobTitle,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFB3DDF2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    buildRatingRow('Performance', performanceRating,
                        (value) => setState(() => performanceRating = value)),
                    buildRatingRow('Communication', communicationRating,
                        (value) => setState(() => communicationRating = value)),
                    buildRatingRow('Skills', skillsRating,
                        (value) => setState(() => skillsRating = value)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: commentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Comment',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}