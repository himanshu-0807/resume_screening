import 'package:flutter/material.dart';

class DetailsPage extends StatelessWidget {
  final Map<String, dynamic> resume;

  DetailsPage({required this.resume});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${resume['name']} Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${resume['name']}'),
            SizedBox(height: 8),
            Text('Email: ${resume['email']}'),
            SizedBox(height: 8),
            Text('Phone: ${resume['phone']}'),
            SizedBox(height: 8),
            Text('Matched Skills: ${resume['matched_skills'].join(", ")}'),
            SizedBox(height: 8),
            Text('Match Percentage: ${resume['match_percentage']}%'),
          ],
        ),
      ),
    );
  }
}
