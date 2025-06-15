import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'addRating.dart';
import 'editRating.dart';

class ForemanListPage extends StatelessWidget {
  const ForemanListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> foremanJobs = [
      {
        'title': 'Oil Change - Yamaha FZ',
        'foreman': 'Robert Fox',
        'time': '10.00am - 12.00 pm',
        'image': 'assets/robert_fox.png',
        'jobId': 'job_001',
        'foremanId': 'foreman_001',
        'ownerId': 'owner_001',
      },
      {
        'title': 'Tire Replacement - Axia Perodua',
        'foreman': 'Wade Warren',
        'time': '2.00pm - 4.00pm',
        'image': 'assets/wade_warren.png',
        'jobId': 'job_002',
        'foremanId': 'foreman_002',
        'ownerId': 'owner_002',
      },
      {
        'title': 'Oil Change - Honda Civic',
        'foreman': 'Marvin Shaw',
        'time': '10.00am - 12.00 pm',
        'image': 'assets/marvin_shaw.png',
        'jobId': 'job_003',
        'foremanId': 'foreman_003',
        'ownerId': 'owner_003',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Foreman List'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: foremanJobs.length,
        itemBuilder: (context, index) {
          final job = foremanJobs[index];

          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('ratings')
                .where('jobId', isEqualTo: job['jobId'])
                .where('foremanId', isEqualTo: job['foremanId'])
                .get(),
            builder: (context, snapshot) {
              bool hasRating = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
              final ratingDoc = hasRating ? snapshot.data!.docs.first : null;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.blue.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job['title']!,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Foreman : ${job['foreman']}'),
                      Text('Time : ${job['time']}'),
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
                                        builder: (context) => AddRatingPage(
                                          foremanName: job['foreman']!,
                                          jobTitle: job['title']!,
                                          foremanImageUrl: job['image']!,
                                          jobId: job['jobId']!,
                                          foremanId: job['foremanId']!,
                                          ownerId: job['ownerId']!,
                                        ),
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: const Text('Rate'),
                          ),
                          const SizedBox(width: 10),
                          if (hasRating)
                            ElevatedButton(
                              onPressed: () {
                                final data =
                                    ratingDoc!.data() as Map<String, dynamic>;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditRatingPage(
                                      ratingId: ratingDoc.id,
                                      foremanName: job['foreman']!,
                                      jobTitle: job['title']!,
                                      foremanImageUrl: job['image']!,
                                      jobId: job['jobId']!,
                                      foremanId: job['foremanId']!,
                                      initialPerformanceRating:
                                          data['performance'] ?? 0,
                                      initialCommunicationRating:
                                          data['communication'] ?? 0,
                                      initialSkillsRating: data['skills'] ?? 0,
                                      initialComment: data['comment'] ?? '',
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
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
      ),
    );
  }
}