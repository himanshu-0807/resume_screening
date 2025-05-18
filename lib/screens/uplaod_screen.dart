// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:lottie/lottie.dart';

// class UploadPage extends StatefulWidget {
//   @override
//   _UploadPageState createState() => _UploadPageState();
// }

// class _UploadPageState extends State<UploadPage> {
//   List<File>? selectedFiles;
//   TextEditingController skillsController = TextEditingController();

//   Future<void> pickFiles() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['pdf', 'docx'],
//       allowMultiple: true,
//     );

//     if (result != null) {
//       setState(() {
//         selectedFiles = result.paths.map((path) => File(path!)).toList();
//       });
//     }
//   }

//   Future<void> uploadFiles() async {
//     if (selectedFiles == null || selectedFiles!.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please select at least one resume file.')),
//       );
//       return;
//     }

//     if (skillsController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please enter required skills.')),
//       );
//       return;
//     }

//     String url = Platform.isAndroid
//         ? 'http://192.168.2.9:5000/upload'
//         : 'http://127.0.0.1:5000/upload';

//     var request = http.MultipartRequest('POST', Uri.parse(url));
//     for (File file in selectedFiles!) {
//       request.files
//           .add(await http.MultipartFile.fromPath('resumes', file.path));
//     }

//     request.fields['skills'] = skillsController.text.trim();

//     try {
//       var response = await request.send();
//       if (response.statusCode == 200) {
//         var responseData = await http.Response.fromStream(response);
//         var data = jsonDecode(responseData.body);
//         Navigator.pushNamed(context, '/results',
//             arguments: data['ranked_resumes']);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error uploading resumes!')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to connect to server!')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Upload Resumes',
//             style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//         centerTitle: true,
//         backgroundColor: Colors.indigo,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             Lottie.asset(
//               'assets/animations/upload.json',
//               height: 180,
//               width: 180,
//             ),
//             SizedBox(height: 12),
//             TextField(
//               controller: skillsController,
//               decoration: InputDecoration(
//                 labelText: 'Enter required skills (comma-separated)',
//                 border:
//                     OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
//                 prefixIcon: Icon(Icons.code, color: Colors.indigoAccent),
//               ),
//             ),
//             SizedBox(height: 16),
//             ElevatedButton.icon(
//               onPressed: pickFiles,
//               icon: Icon(Icons.file_upload, color: Colors.white),
//               label: Text('Pick Resumes'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.indigoAccent,
//                 padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//               ),
//             ),
//             SizedBox(height: 16),
//             if (selectedFiles != null && selectedFiles!.isNotEmpty)
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: selectedFiles!.length,
//                   itemBuilder: (context, index) {
//                     return ListTile(
//                       leading: Icon(Icons.description, color: Colors.indigo),
//                       title: Text(
//                         selectedFiles![index].path.split('/').last,
//                         style: TextStyle(color: Colors.indigoAccent),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             if (selectedFiles == null || selectedFiles!.isEmpty)
//               Text(
//                 'No files selected yet.',
//                 style: TextStyle(color: Colors.grey, fontSize: 16),
//               ),
//             Spacer(),
//             ElevatedButton.icon(
//               onPressed: uploadFiles,
//               icon: Icon(Icons.cloud_upload, color: Colors.white),
//               label: Text('Upload Resumes'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
