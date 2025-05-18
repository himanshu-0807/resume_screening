import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

// Function to download resume from URL and save to temporary file
Future<String> downloadResumeFile(String url) async {
  try {
    // Get temporary directory
    final Directory tempDir = await getTemporaryDirectory();
    final String tempPath = tempDir.path;
    
    // Create a unique filename
    final String filename = 'resume_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final String filePath = '$tempPath/$filename';
    
    // Download file
    final http.Response response = await http.get(Uri.parse(url));
    
    // Write to file
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    
    return filePath;
  } catch (e) {
    print('Error downloading resume: $e');
    throw Exception('Failed to download resume');
  }
}

class ViewResumePage extends StatefulWidget {
  final String? storageUrl; // URL from Firebase Storage
  final Uint8List? resumeBytes; // Direct bytes if available
  final String? resumeName; // Name of the resume

  // Constructor with flexible parameters
  ViewResumePage({
    this.storageUrl,
    this.resumeBytes,
    this.resumeName,
  }) : assert(storageUrl != null || resumeBytes != null, 'Either storageUrl or resumeBytes must be provided');

  @override
  _ViewResumePageState createState() => _ViewResumePageState();
}

class _ViewResumePageState extends State<ViewResumePage> {
  late Future<String?> _resumeFilePath;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadResume();
  }

  Future<void> _loadResume() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.resumeBytes != null) {
        // If we have direct bytes, save them to a temporary file
        _resumeFilePath = _saveBytesToFile(widget.resumeBytes!);
      } else if (widget.storageUrl != null) {
        // If we have a storage URL, download the file
        _resumeFilePath = downloadResumeFile(widget.storageUrl!);
      } else {
        throw Exception('No resume data provided');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load resume: $e';
      });
      print('Error loading resume: $e');
    }
  }

  Future<String> _saveBytesToFile(Uint8List bytes) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = tempDir.path;
      final String filename = 'resume_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final String filePath = '$tempPath/$filename';
      
      final File file = File(filePath);
      await file.writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      print('Error saving bytes to file: $e');
      throw Exception('Failed to save resume data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.resumeName ?? 'View Resume'),
        backgroundColor: Colors.indigo,
        actions: [
          // Download button
          if (widget.storageUrl != null)
            IconButton(
              icon: Icon(Icons.download),
              onPressed: () {
                // Here you would implement download functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Downloading resume...')),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Error Loading Resume',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(_errorMessage!),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadResume,
                        child: Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : FutureBuilder<String?>(
                  future: _resumeFilePath,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (snapshot.hasData && snapshot.data != null) {
                      return PDFView(
                        filePath: snapshot.data!,
                        enableSwipe: true,
                        swipeHorizontal: true,
                        autoSpacing: false,
                        pageFling: false,
                        onError: (error) {
                          print('Error rendering PDF: $error');
                          setState(() {
                            _errorMessage = 'Could not render PDF: $error';
                          });
                        },
                        onPageError: (page, error) {
                          print('Error on page $page: $error');
                        },
                        onViewCreated: (PDFViewController controller) {
                          // PDF view created
                        },
                      );
                    } else {
                      return Center(child: Text('No resume data available'));
                    }
                  },
                ),
    );
  }
}
