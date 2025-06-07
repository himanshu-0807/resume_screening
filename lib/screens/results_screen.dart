import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resume_screening/screens/details_screen.dart';
import 'viewResumePage.dart'; // Import the ViewResumePage

class ResultsPage extends StatefulWidget {
  @override
  _ResultsPageState createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> rankedResumes =
        ModalRoute.of(context)!.settings.arguments as List<dynamic>;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Ranked Resumes',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
      ),
      body: Stack(
        children: [
          // Background gradient
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

          // Top wave decoration
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(screenSize.width, 220),
              painter: _WavePainter(Colors.white.withOpacity(0.15)),
            ),
          ),

          // Bottom wave decoration
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Transform(
              transform: Matrix4.rotationX(3.14),
              child: CustomPaint(
                size: Size(screenSize.width, 180),
                painter: _WavePainter(Colors.white.withOpacity(0.1)),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: rankedResumes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 60,
                              color: Colors.white.withOpacity(0.4),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No resumes found.',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Upload resumes to see results.',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: rankedResumes.length,
                        itemBuilder: (context, index) {
                          final resume = rankedResumes[index];
                          final name = resume['name'] ?? 'Unnamed Resume';
                          final matchedSkills = resume['matched_skills'] != null
                              ? (resume['matched_skills'] as List<dynamic>)
                                  .join(', ')
                              : 'None';
                          final matchPercentage = resume['match_percentage'] !=
                                  null
                              ? resume['match_percentage'].toStringAsFixed(2)
                              : '0.00';

                          return AnimatedOpacity(
                            opacity: 1.0,
                            duration: Duration(milliseconds: 300 + index * 100),
                            child: Container(
                              margin: EdgeInsets.symmetric(vertical: 12),
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.2)),
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
                                  // Header with rank and name
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade400
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.star,
                                          color: Colors.amber.shade700,
                                          size: 28,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          ' $name',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),

                                  // Matched Skills
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade400
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.green.shade700,
                                          size: 24,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Matched Skills',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white
                                                    .withOpacity(0.8),
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              matchedSkills,
                                              style: GoogleFonts.poppins(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.white,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),

                                  // Match Percentage
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade400
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.percent,
                                          color: Colors.blue.shade700,
                                          size: 24,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Match: $matchPercentage%',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 24),

                                  // Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ScaleTransition(
                                          scale: Tween<double>(
                                                  begin: 1.0, end: 0.95)
                                              .animate(
                                            CurvedAnimation(
                                              parent: _animationController,
                                              curve: Curves.easeInOut,
                                            ),
                                          ),
                                          child: ElevatedButton.icon(
                                            onPressed: resume['storage_url'] !=
                                                    null
                                                ? () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            ViewResumePage(
                                                          storageUrl: resume[
                                                              'storage_url'],
                                                          resumeName:
                                                              resume['name'] ??
                                                                  'Resume',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                : () {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Resume file not available',
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        backgroundColor:
                                                            Colors.red.shade700,
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        margin:
                                                            EdgeInsets.all(16),
                                                        elevation: 6,
                                                      ),
                                                    );
                                                  },
                                            icon: Icon(Icons.visibility,
                                                color: Colors.white, size: 24),
                                            label: Text(
                                              'View Resume',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.blue.shade600,
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              elevation: 8,
                                              shadowColor:
                                                  Colors.blue.withOpacity(0.4),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: ScaleTransition(
                                          scale: Tween<double>(
                                                  begin: 1.0, end: 0.95)
                                              .animate(
                                            CurvedAnimation(
                                              parent: _animationController,
                                              curve: Curves.easeInOut,
                                            ),
                                          ),
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      DetailsPage(
                                                          resume: resume),
                                                ),
                                              );
                                            },
                                            icon: Icon(Icons.info_outline,
                                                color: Colors.white, size: 24),
                                            label: Text(
                                              'Details',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.indigo.shade600,
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              elevation: 8,
                                              shadowColor: Colors.indigo
                                                  .withOpacity(0.4),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Wave painter for decorative background
class _WavePainter extends CustomPainter {
  final Color color;

  _WavePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    var path = Path();
    path.moveTo(0, size.height * 0.65);
    path.quadraticBezierTo(size.width * 0.3, size.height * 0.85,
        size.width * 0.5, size.height * 0.75);
    path.quadraticBezierTo(
        size.width * 0.7, size.height * 0.65, size.width, size.height * 0.85);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
