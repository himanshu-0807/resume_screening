import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

// Function to download resume from URL and save to temporary file
Future<String> downloadResumeFile(String url) async {
  try {
    // Get temporary directory
    final Directory tempDir = await getTemporaryDirectory();
    final String tempPath = tempDir.path;

    // Create a unique filename
    final String filename =
        'resume_${DateTime.now().millisecondsSinceEpoch}.pdf';
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
  }) : assert(storageUrl != null || resumeBytes != null,
            'Either storageUrl or resumeBytes must be provided');

  @override
  _ViewResumePageState createState() => _ViewResumePageState();
}

class _ViewResumePageState extends State<ViewResumePage> {
  String? _filePath;
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasStoragePermission = false;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermission();
    _loadResume();
  }

  Future<void> _checkAndRequestPermission() async {
    try {
      if (!Platform.isAndroid) {
        // iOS doesn't require explicit storage permission for app directories
        setState(() {
          _hasStoragePermission = true;
        });
        return;
      }

      // For Android, check version to determine which permissions to request
      final deviceInfoPlugin = DeviceInfoPlugin();
      final androidInfo = await deviceInfoPlugin.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      // Android 13+ (API 33+) requires specific permission
      if (sdkInt >= 33) {
        final status = await Permission.photos.status;
        if (status.isGranted) {
          setState(() {
            _hasStoragePermission = true;
          });
          return;
        }

        final result = await Permission.photos.request();
        setState(() {
          _hasStoragePermission = result.isGranted;
        });
        if (!result.isGranted) {
          _handlePermissionDenied(result);
        }
      }
      // Android 10-12 (API 29-32)
      else if (sdkInt >= 29) {
        final status = await Permission.storage.status;
        if (status.isGranted) {
          setState(() {
            _hasStoragePermission = true;
          });
          return;
        }

        final result = await Permission.storage.request();
        setState(() {
          _hasStoragePermission = result.isGranted;
        });
        if (!result.isGranted) {
          _handlePermissionDenied(result);
        }
      }
      // Android 9 and below (API 28-)
      else {
        final status = await Permission.storage.status;
        if (status.isGranted) {
          setState(() {
            _hasStoragePermission = true;
          });
          return;
        }

        final result = await Permission.storage.request();
        setState(() {
          _hasStoragePermission = result.isGranted;
        });
        if (!result.isGranted) {
          _handlePermissionDenied(result);
        }
      }
    } catch (e) {
      print('Error checking permissions: $e');
      // Default to true for iOS and in case of errors to not block functionality
      setState(() {
        _hasStoragePermission = !Platform.isAndroid;
      });
    }
  }

  void _handlePermissionDenied(PermissionStatus status) {
    setState(() {
      _hasStoragePermission = false;
    });

    if (status.isPermanentlyDenied) {
      // Guide user to settings
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Storage permission is required to download the resume.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              openAppSettings();
            },
          ),
          duration: Duration(seconds: 10),
        ),
      );
    } else {
      // Regular denial
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Storage permission denied. Cannot download files.'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _loadResume() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _filePath = null;
    });

    try {
      String path;

      if (widget.resumeBytes != null) {
        // If we have direct bytes, save them to a temporary file
        path = await _saveBytesToFile(widget.resumeBytes!);
      } else if (widget.storageUrl != null) {
        // If we have a storage URL, download the file
        path = await downloadResumeFile(widget.storageUrl!);
      } else {
        throw Exception('No resume data provided');
      }

      if (!mounted) return;

      setState(() {
        _filePath = path;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

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
      final String filename =
          'resume_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final String filePath = '$tempPath/$filename';

      final File file = File(filePath);
      await file.writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      print('Error saving bytes to file: $e');
      throw Exception('Failed to save resume data');
    }
  }

  Future<void> _downloadResume() async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading resume...')),
    );

    if (!_hasStoragePermission) {
      await _checkAndRequestPermission();
      if (!_hasStoragePermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Storage permission required to download')),
        );
        return;
      }
    }

    try {
      // Determine the file name
      String fileName = widget.resumeName ??
          'resume_${DateTime.now().millisecondsSinceEpoch}.pdf';
      fileName = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
      fileName =
          fileName.replaceAll(RegExp(r'[^\w\s\.]'), '_'); // Sanitize file name

      // Get appropriate directory based on platform
      late String filePath;

      if (Platform.isAndroid) {
        try {
          // For Android 10+ (API 29+), we need to handle storage differently
          final deviceInfoPlugin = DeviceInfoPlugin();
          final androidInfo = await deviceInfoPlugin.androidInfo;

          if (androidInfo.version.sdkInt >= 29) {
            // For Android 10+ use the app's external directory
            final directory = await getExternalStorageDirectory();
            if (directory != null) {
              filePath = '${directory.path}/$fileName';
            } else {
              // Fallback to app-specific directory
              final appDir = await getApplicationDocumentsDirectory();
              filePath = '${appDir.path}/$fileName';
            }
          } else {
            // For older Android versions, use the Download directory
            final directory = Directory('/storage/emulated/0/Download');
            // Ensure directory exists
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
            filePath = '${directory.path}/$fileName';
          }
        } catch (e) {
          // Fallback to app-specific directory in case of any issues
          print('Error accessing Android storage: $e');
          final appDir = await getApplicationDocumentsDirectory();
          filePath = '${appDir.path}/$fileName';
        }
      } else if (Platform.isIOS) {
        // For iOS, save to app documents directory
        final directory = await getApplicationDocumentsDirectory();
        filePath = '${directory.path}/$fileName';
      } else {
        // For other platforms
        final directory = await getApplicationDocumentsDirectory();
        filePath = '${directory.path}/$fileName';
      }

      final file = File(filePath);

      // Create or overwrite the file
      if (widget.resumeBytes != null) {
        // Use direct bytes
        await file.writeAsBytes(widget.resumeBytes!);
      } else if (widget.storageUrl != null) {
        // Download from URL
        final response = await http.get(Uri.parse(widget.storageUrl!));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
        } else {
          throw Exception(
              'Failed to download: HTTP status ${response.statusCode}');
        }
      } else {
        throw Exception('No resume data available for download');
      }

      // Show success message with path
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resume saved to: $filePath'),
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      print('Error downloading resume: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
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
          if (widget.storageUrl != null || widget.resumeBytes != null)
            IconButton(
              icon: Icon(Icons.download),
              onPressed:
                  _downloadResume, // Allow clicking to trigger permission request if needed
              tooltip: 'Download Resume',
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
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
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
              : _filePath != null
                  ? PDFView(
                      filePath: _filePath!,
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
                    )
                  : Center(child: Text('No resume data available')),
    );
  }
}
