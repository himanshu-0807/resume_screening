import 'package:flutter/material.dart';
import 'viewResumePage.dart'; // Import the ViewResumePage

class ResultsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Retrieve ranked resumes passed via navigation arguments
    final List<dynamic> rankedResumes =
        ModalRoute.of(context)!.settings.arguments as List<dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ranked Resumes',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        elevation: 5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: rankedResumes.isEmpty
            ? Center(
                child: Text(
                  'No resumes found.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: rankedResumes.length,
                itemBuilder: (context, index) {
                  final resume = rankedResumes[index];
                  final name = resume['name'] ?? 'Unnamed Resume';
                  final matchedSkills = resume['matched_skills'] != null
                      ? (resume['matched_skills'] as List<dynamic>).join(', ')
                      : 'None';
                  final matchPercentage = resume['match_percentage'] != null
                      ? resume['match_percentage'].toStringAsFixed(2)
                      : '0.00';

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 6,
                    margin: EdgeInsets.symmetric(vertical: 10),
                    shadowColor: Colors.grey.withOpacity(0.4),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${index + 1}. $name',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.star, color: Colors.amber, size: 24),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Matched Skills: $matchedSkills',
                                  style: TextStyle(fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.percent,
                                  color: Colors.indigoAccent, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Match Percentage: $matchPercentage%',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blueGrey[700],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Check if we have a storage URL
                                if (resume.containsKey('storage_url') && resume['storage_url'] != null) {
                                  // Use the Firebase Storage URL to view the resume
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ViewResumePage(
                                        storageUrl: resume['storage_url'],
                                        resumeName: resume['name'] ?? 'Resume',
                                      ),
                                    ),
                                  );
                                } else {
                                  // Show error if no URL is available
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Resume file not available')),
                                  );
                                }
                              },
                              icon: Icon(Icons.arrow_forward),
                              label: Text(
                                'View Resume',
                                style: TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigoAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
