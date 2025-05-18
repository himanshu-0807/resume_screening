import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload a resume file to Firebase Storage
  Future<String> uploadResume(File file) async {
    try {
      // Get current user ID for organizing files
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create a unique filename using timestamp
      final fileName = path.basename(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'resumes/$userId/$timestamp-$fileName';

      // Upload file to Firebase Storage
      final uploadTask = _storage.ref().child(storagePath).putFile(file);
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading resume: $e');
      rethrow;
    }
  }

  // Get a resume file from Firebase Storage by URL
  Future<String> getResumeDownloadUrl(String storagePath) async {
    try {
      return await _storage.ref(storagePath).getDownloadURL();
    } catch (e) {
      print('Error getting resume download URL: $e');
      rethrow;
    }
  }

  // Delete a resume file from Firebase Storage
  Future<void> deleteResume(String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
    } catch (e) {
      print('Error deleting resume: $e');
      rethrow;
    }
  }
}
