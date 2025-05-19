import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:resume_screening/services/auth_service.dart';
import 'package:resume_screening/services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Custom wave painter for decorative background
class WavePainter extends CustomPainter {
  final Color color;

  WavePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    var path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.9,
        size.width * 0.5, size.height * 0.8);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.7, size.width, size.height * 0.9);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class UploadPage extends StatefulWidget {
  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage>
    with SingleTickerProviderStateMixin {
  List<File>? selectedFiles;
  TextEditingController skillsController = TextEditingController();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
    _getUserName();
  }

  @override
  void dispose() {
    _animationController.dispose();
    skillsController.dispose();
    super.dispose();
  }

  void _getUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.displayName ?? 'User';
      });
    }
  }

  Future<void> pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        selectedFiles = result.paths.map((path) => File(path!)).toList();
      });
    }
  }

  Future<void> uploadFiles() async {
    if (selectedFiles == null || selectedFiles!.isEmpty) {
      _showErrorSnackBar('Please select at least one resume file.');
      return;
    }

    if (skillsController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter required skills.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String url = Platform.isAndroid
        ? 'http://192.168.184.133:5000/upload'
        : 'http://127.0.0.1:5000/upload';

    var request = http.MultipartRequest('POST', Uri.parse(url));

    // List to store Firebase Storage URLs
    List<String> storageUrls = [];
    List<Map<String, dynamic>> fileMetadata = [];

    // Upload each file to Firebase Storage first
    try {
      for (int i = 0; i < selectedFiles!.length; i++) {
        File file = selectedFiles![i];
        // Upload to Firebase Storage
        String downloadUrl = await _storageService.uploadResume(file);
        storageUrls.add(downloadUrl);

        // Create metadata for the file
        String fileName = file.path.split('/').last;
        fileMetadata.add({
          'name': fileName,
          'url': downloadUrl,
          'type': fileName.split('.').last.toLowerCase(),
          // 'uploadedAt': FieldValue.serverTimestamp(),
        });

        // Add file to HTTP request for analysis
        request.files
            .add(await http.MultipartFile.fromPath('resumes', file.path));
      }

      // Save file metadata to Firestore
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('uploads')
            .add({
          'files': fileMetadata,
          'skills': skillsController.text.trim(),
          'uploadedAt': FieldValue.serverTimestamp(),
        });
      }

      // Add skills to the request
      request.fields['skills'] = skillsController.text.trim();

      // Send request to analysis server
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await http.Response.fromStream(response);
        var data = jsonDecode(responseData.body);

        // Add storage URLs to the results
        List<dynamic> rankedResumes = data['ranked_resumes'];
        for (int i = 0;
            i < rankedResumes.length && i < storageUrls.length;
            i++) {
          rankedResumes[i]['storage_url'] = storageUrls[i];
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          Navigator.pushNamed(context, '/results', arguments: rankedResumes);
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showErrorSnackBar('Error analyzing resumes!');
        }
      }
    } catch (e) {
      print('Error during upload: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to upload or analyze resumes!');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
      ),
    );
  }

  void _signOut() async {
    await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Resume Screening',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
            tooltip: 'Profile',
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.indigo.shade800,
                  Colors.indigo.shade600,
                  Colors.indigo.shade400,
                  Colors.indigo.shade200,
                ],
              ),
            ),
          ),

          // Top wave decoration
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(screenSize.width, 200),
              painter: WavePainter(Colors.white.withOpacity(0.1)),
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome message
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.indigo.shade100,
                                radius: 25,
                                child: Icon(
                                  Icons.person,
                                  size: 30,
                                  color: Colors.indigo,
                                ),
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome,',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    _userName ?? 'User',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Upload resumes and find the best candidates matching your requirements.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Animation
                    Center(
                      child: Container(
                        height: 160,
                        width: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Lottie.asset(
                            'assets/animations/upload.json',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Skills input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: skillsController,
                        decoration: InputDecoration(
                          labelText: 'Required Skills',
                          hintText: 'e.g. Python, Machine Learning, SQL',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          prefixIcon: Icon(Icons.code, color: Colors.indigo),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // File selection button
                    ElevatedButton.icon(
                      onPressed: pickFiles,
                      icon:
                          Icon(Icons.file_upload_outlined, color: Colors.white),
                      label: Text(
                        'Select Resumes',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                    ),

                    SizedBox(height: 16),

                    // Selected files list
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: selectedFiles != null &&
                                selectedFiles!.isNotEmpty
                            ? ListView.separated(
                                padding: EdgeInsets.all(16),
                                itemCount: selectedFiles!.length,
                                separatorBuilder: (context, index) => Divider(),
                                itemBuilder: (context, index) {
                                  final fileName = selectedFiles![index]
                                      .path
                                      .split('/')
                                      .last;
                                  final fileExtension =
                                      fileName.split('.').last.toLowerCase();

                                  return ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 8),
                                    leading: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: fileExtension == 'pdf'
                                            ? Colors.red.shade100
                                            : Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        fileExtension == 'pdf'
                                            ? Icons.picture_as_pdf
                                            : Icons.article,
                                        color: fileExtension == 'pdf'
                                            ? Colors.red.shade700
                                            : Colors.blue.shade700,
                                      ),
                                    ),
                                    title: Text(
                                      fileName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon:
                                          Icon(Icons.close, color: Colors.grey),
                                      onPressed: () {
                                        setState(() {
                                          selectedFiles!.removeAt(index);
                                          if (selectedFiles!.isEmpty) {
                                            selectedFiles = null;
                                          }
                                        });
                                      },
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.upload_file,
                                      size: 60,
                                      color: Colors.grey.shade400,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No files selected',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Select PDF or DOCX files',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Upload button
                    SizedBox(
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : uploadFiles,
                        icon: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.cloud_upload, color: Colors.white),
                        label: Text(
                          _isLoading ? 'Uploading...' : 'Upload and Analyze',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.green.shade300,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.indigo),
                      SizedBox(height: 20),
                      Text(
                        'Processing Resumes...',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
