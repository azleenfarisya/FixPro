import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RatingDashboardPage extends StatelessWidget {
  final String userRole; // 'owner' or 'foreman'

  const RatingDashboardPage({
    super.key,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rating Dashboard'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: userRole == 'owner'
          ? _buildOwnerContent(context)
          : _buildForemanContent(),
    );
  }

  /// OWNER DASHBOARD
  Widget _buildOwnerContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.star_rate_rounded,
              color: Colors.amber,
              size: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              'Rate Foreman',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your feedback helps us improve service quality.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/foremanList');
              },
              icon: const Icon(Icons.rate_review),
              label: const Text('Rate Now'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// FOREMAN DASHBOARD
  Widget _buildForemanContent() {
    final String? foremanId = FirebaseAuth.instance.currentUser?.uid;

    if (foremanId == null) {
      return const Center(
        child: Text('You are not logged in.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ratings')
            .where('foremanId', isEqualTo: foremanId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'You have not received any ratings yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final ratings = snapshot.data!.docs;

          return ListView.builder(
            itemCount: ratings.length,
            itemBuilder: (context, index) {
              final data = ratings[index].data() as Map<String, dynamic>;
              final jobId = data['jobId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('working_schedules')
                    .doc(jobId)
                    .get(),
                builder: (context, scheduleSnapshot) {
                  String jobAssignment = "Loading job...";

                  if (scheduleSnapshot.connectionState == ConnectionState.done &&
                      scheduleSnapshot.hasData &&
                      scheduleSnapshot.data!.exists) {
                    final scheduleData =
                        scheduleSnapshot.data!.data() as Map<String, dynamic>?;
                    jobAssignment = scheduleData?['job_assignment'] ?? 'No job assignment';
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(jobAssignment),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Performance: ${data['performance']}"),
                          Text("Communication: ${data['communication']}"),
                          Text("Skills: ${data['skills']}"),
                          if (data['comment'] != null &&
                              data['comment'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text("Comment: ${data['comment']}"),
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