import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // kIsWeb을 사용하기 위해 추가

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Upload Client',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: VideoUploadPage(),
    );
  }
}

class VideoUploadPage extends StatefulWidget {
  @override
  _VideoUploadPageState createState() => _VideoUploadPageState();
}

class _VideoUploadPageState extends State<VideoUploadPage> {
  PlatformFile? _selectedFile;
  String _uploadStatus = 'No file selected';
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // 파일 선택 함수
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null && result.files.single != null) {
      setState(() {
        _selectedFile = result.files.single;
        _uploadStatus = 'File selected: ${_selectedFile!.name}';
      });
    }
  }

  // 파일 업로드 함수
  Future<void> _uploadFile() async {
    if (_selectedFile == null) {
      setState(() {
        _uploadStatus = 'No file selected';
      });
      return;
    }

    final uri = Uri.parse('http://localhost:8080/videoUpload'); // 서버의 주소와 포트

    setState(() {
      _uploadStatus = 'Uploading...';
    });

    try {
      final request = http.MultipartRequest('POST', uri);
      // 필드에 아이디, 비밀번호, 설명 추가
      request.fields.addAll({
        'video_id': '1234',
        'user_id': _idController.text,
        'user_password': _passwordController.text,
        'description': _descriptionController.text,
      });
      // 파일 추가 (웹과 모바일 환경에 따라 다르게 처리)
      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          _selectedFile!.bytes!,
          filename: _selectedFile!.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          _selectedFile!.path!,
          filename: _selectedFile!.name,
        ));
      }

      // 파일 업로드 전송
      final response = await request.send();

      if (response.statusCode == 200) {
        setState(() {
          _uploadStatus = 'Upload successful';
        });
      } else {
        setState(() {
          _uploadStatus = 'Upload failed with status: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _uploadStatus = 'Error occurred: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Upload Client'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _idController,
              decoration: InputDecoration(labelText: 'Enter User ID'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Enter Password'),
              obscureText: true,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Enter Description'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickFile,
              child: Text('Select Video File'),
            ),
            SizedBox(height: 20),
            Text(_uploadStatus),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadFile,
              child: Text('Upload File'),
            ),
          ],
        ),
      ),
    );
  }
}
