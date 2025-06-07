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
import 'package:google_fonts/google_fonts.dart';

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
    path.moveTo(0, size.height * 0.65);
    path.quadraticBezierTo(size.width * 0.3, size.height * 0.85, size.width * 0.5, size.height * 0.75);
    path.quadraticBezierTo(size.width * 0.7, size.height * 0.65, size.width, size.height * 0.85);
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

class _UploadPageState extends State<UploadPage> with SingleTickerProviderStateMixin {
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
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
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

    String url = Platform.isAndroid ? 'http://192.168.75.133:5000/upload' : 'http://127.0.0.1:5000/upload';

    var request = http.MultipartRequest('POST', Uri.parse(url));

    List<String> storageUrls = [];
    List<Map<String, dynamic>> fileMetadata = [];

    try {
      for (int i = 0; i < selectedFiles!.length; i++) {
        File file = selectedFiles![i];
        String downloadUrl = await _storageService.uploadResume(file);
        storageUrls.add(downloadUrl);

        String fileName = file.path.split('/').last;
        fileMetadata.add({
          'name': fileName,
          'url': downloadUrl,
          'type': fileName.split('.').last.toLowerCase(),
        });

        request.files.add(await http.MultipartFile.fromPath('resumes', file.path));
      }

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).collection('uploads').add({
          'files': fileMetadata,
          'skills': skillsController.text.trim(),
          'uploadedAt': FieldValue.serverTimestamp(),
        });
      }

      request.fields['skills'] = skillsController.text.trim();

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await http.Response.fromStream(response);
        var data = jsonDecode(responseData.body);

        List<dynamic> rankedResumes = data['ranked_resumes'];
        for (int i = 0; i < rankedResumes.length && i < storageUrls.length; i++) {
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
        content: Text(
          message,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.white),
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        elevation: 6,
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
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: Colors.white, size: 28),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            tooltip: 'Profile',
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white, size: 28),
            onPressed: _signOut,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient with glassmorphic effect
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.indigo.shade900,
                  Colors.blue.shade700,
                  Colors.blue.shade500,
                  Colors.cyan.shade300,
                ],
                stops: [0.0, 0.4, 0.7, 1.0],
              ),
            ),
          ),

          // Wave decoration with softer opacity
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(screenSize.width, 220),
              painter: WavePainter(Colors.white.withOpacity(0.15)),
            ),
          ),

          // Bottom wave for symmetry
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Transform(
              transform: Matrix4.rotationX(3.14),
              child: CustomPaint(
                size: Size(screenSize.width, 180),
                painter: WavePainter(Colors.white.withOpacity(0.1)),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Welcome card with glassmorphic effect
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.white.withOpacity(0.3),
                                  radius: 30,
                                  child: Icon(
                                    Icons.person_outline,
                                    size: 36,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome,',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                    Text(
                                      _userName ?? 'User',
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Upload resumes to find top candidates tailored to your needs.',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Animation with neumorphic container
                      Center(
                        child: Container(
                          height: 180,
                          width: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade200,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                offset: Offset(8, 8),
                                blurRadius: 20,
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.7),
                                offset: Offset(-8, -8),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Lottie.asset(
                              'assets/animations/upload.json',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 24),

                      // Skills input with glassmorphic effect
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: skillsController,
                          style: GoogleFonts.poppins(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Required Skills',
                            hintText: 'e.g. Python, Machine Learning, SQL',
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.5),
                            ),
                            prefixIcon: Icon(Icons.code, color: Colors.white.withOpacity(0.8)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          ),
                        ),
                      ),

                      SizedBox(height: 24),

                      // File selection button with animated press effect
                      GestureDetector(
                        onTapDown: (_) => _animationController.reverse(),
                        onTapUp: (_) => _animationController.forward(),
                        onTapCancel: () => _animationController.forward(),
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 1.0, end: 0.95).animate(
                            CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: pickFiles,
                            icon: Icon(Icons.file_upload_outlined, color: Colors.white, size: 28),
                            label: Text(
                              'Select Resumes',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 8,
                              shadowColor: Colors.indigo.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 24),

                      // Selected files list with animated list items
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: selectedFiles != null && selectedFiles!.isNotEmpty
                            ? ListView.separated(
                                padding: EdgeInsets.all(16),
                                itemCount: selectedFiles!.length,
                                separatorBuilder: (context, index) => Divider(
                                  color: Colors.white.withOpacity(0.2),
                                  height: 8,
                                ),
                                itemBuilder: (context, index) {
                                  final fileName = selectedFiles![index].path.split('/').last;
                                  final fileExtension = fileName.split('.').last.toLowerCase();

                                  return AnimatedOpacity(
                                    opacity: 1.0,
                                    duration: Duration(milliseconds: 300),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                      leading: Container(
                                        padding: EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: fileExtension == 'pdf'
                                              ? Colors.red.shade400.withOpacity(0.2)
                                              : Colors.blue.shade400.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          fileExtension == 'pdf' ? Icons.picture_as_pdf : Icons.article,
                                          color: fileExtension == 'pdf' ? Colors.red.shade700 : Colors.blue.shade700,
                                          size: 28,
                                        ),
                                      ),
                                      title: Text(
                                        fileName,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(Icons.close, color: Colors.white.withOpacity(0.7)),
                                        onPressed: () {
                                          setState(() {
                                            selectedFiles!.removeAt(index);
                                            if (selectedFiles!.isEmpty) {
                                              selectedFiles = null;
                                            }
                                          });
                                        },
                                      ),
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
                                      color: Colors.white.withOpacity(0.4),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No files selected',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Select PDF or DOCX files',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),

                      SizedBox(height: 24),

                      // Upload button with animated press effect
                      GestureDetector(
                        onTapDown: (_) => _animationController.reverse(),
                        onTapUp: (_) => _animationController.forward(),
                        onTapCancel: () => _animationController.forward(),
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 1.0, end: 0.95).animate(
                            CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : uploadFiles,
                            icon: _isLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Icon(Icons.cloud_upload, color: Colors.white, size: 28),
                            label: Text(
                              _isLoading ? 'Uploading...' : 'Upload and Analyze',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.green.shade300,
                              padding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 8,
                              shadowColor: Colors.green.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay with glassmorphic effect
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Processing Resumes...',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
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