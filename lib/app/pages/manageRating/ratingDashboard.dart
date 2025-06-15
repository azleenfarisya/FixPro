import 'package:flutter/material.dart';

class RatingDashboardPage extends StatelessWidget {
  final String? ownerId; // Make it optional

  const RatingDashboardPage({super.key, this.ownerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: const Text('Rating Dashboard'),
      centerTitle: true,
      automaticallyImplyLeading: false,
    ),
      body: Padding(
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
                  textStyle:
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}