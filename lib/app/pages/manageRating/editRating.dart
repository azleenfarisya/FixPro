import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/ratingModel/rating_model.dart';
import '../../services/rating_services.dart';

class EditRatingPage extends StatefulWidget {
  final String ratingId;
  final String foremanName;
  final String jobTitle;
  final String foremanImageUrl;
  final int initialPerformanceRating;
  final int initialCommunicationRating;
  final int initialSkillsRating;
  final String initialComment;
  final String foremanId;
  final String jobId;

  const EditRatingPage({
    super.key,
    required this.ratingId,
    required this.foremanName,
    required this.jobTitle,
    required this.foremanImageUrl,
    required this.initialPerformanceRating,
    required this.initialCommunicationRating,
    required this.initialSkillsRating,
    required this.initialComment,
    required this.foremanId,
    required this.jobId,
  });

  @override
  State<EditRatingPage> createState() => _EditRatingPageState();
}

class _EditRatingPageState extends State<EditRatingPage> {
  late int performanceRating;
  late int communicationRating;
  late int skillsRating;
  late TextEditingController commentController;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    performanceRating = widget.initialPerformanceRating;
    communicationRating = widget.initialCommunicationRating;
    skillsRating = widget.initialSkillsRating;
    commentController = TextEditingController(text: widget.initialComment);
  }

  Widget buildRatingRow(String label, int rating, Function(int) onRated) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
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

  Future<void> saveChanges() async {
    setState(() => isSaving = true);

    final updatedRating = RatingModel(
      id: widget.ratingId,
      foremanId: widget.foremanId,
      jobId: widget.jobId,
      ownerId: "currentOwnerId",
      timestamp: DateTime.now(),
      performance: performanceRating,
      communication: communicationRating,
      skills: skillsRating,
      comment: commentController.text.trim(),
    );

    try {
      await RatingServices.updateRating(updatedRating);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Rating'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: const Color(0xFF73BDE3),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'Edit Rating',
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
                  onPressed: isSaving ? null : saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Changes',
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