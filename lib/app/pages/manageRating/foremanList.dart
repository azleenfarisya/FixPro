import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'addRating.dart';
import 'editRating.dart';

class ForemanListPage extends StatelessWidget {
  const ForemanListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Jobs - Rate Foreman'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('working_schedules')
            .where('status', isEqualTo: 'completed')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No completed jobs to rate."));
          }

          final jobs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final jobData = jobs[index].data() as Map<String, dynamic>;
              final jobId = jobs[index].id;
              final title = jobData['job_assignment'] ?? 'No Title';
              final foremanName = jobData['foreman_name'] ?? 'Unknown';
              final startTime = jobData['start_time'] ?? 'N/A';
              final endTime = jobData['end_time'] ?? 'N/A';
              final foremanId = jobData['foreman_id'] ?? 'unknown_foreman';
              final ownerId = jobData['owner_id'] ?? 'unknown_owner';

              // Placeholder image path; replace with Firestore URL if needed
              final image = 'assets/default_foreman.png';

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('ratings')
                    .where('jobId', isEqualTo: jobId)
                    .where('foremanId', isEqualTo: foremanId)
                    .get(),
                builder: (context, ratingSnapshot) {
                  bool hasRating = ratingSnapshot.hasData &&
                      ratingSnapshot.data!.docs.isNotEmpty;
                  final ratingDoc =
                      hasRating ? ratingSnapshot.data!.docs.first : null;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    color: Colors.blue.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Foreman: $foremanName'),
                          Text('Time: $startTime - $endTime'),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: hasRating
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AddRatingPage(
                                              foremanName: foremanName,
                                              jobTitle: title,
                                              foremanImageUrl: image,
                                              jobId: jobId,
                                              foremanId: foremanId,
                                              ownerId: ownerId,
                                            ),
                                          ),
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                ),
                                child: const Text('Rate'),
                              ),
                              const SizedBox(width: 10),
                              if (hasRating)
                                ElevatedButton(
                                  onPressed: () {
                                    final data = ratingDoc!.data()
                                        as Map<String, dynamic>;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditRatingPage(
                                          ratingId: ratingDoc.id,
                                          foremanName: foremanName,
                                          jobTitle: title,
                                          foremanImageUrl: image,
                                          jobId: jobId,
                                          foremanId: foremanId,
                                          initialPerformanceRating:
                                              data['performance'] ?? 0,
                                          initialCommunicationRating:
                                              data['communication'] ?? 0,
                                          initialSkillsRating:
                                              data['skills'] ?? 0,
                                          initialComment: data['comment'] ?? '',
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                  ),
                                  child: const Text('Edit'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}