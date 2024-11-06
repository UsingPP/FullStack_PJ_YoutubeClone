import 'dart:io';
import 'dart:convert';
import 'package:mime/mime.dart';

Future<Map<String,dynamic>> handleFileUpload(HttpRequest request) async {
  Map<String,dynamic> information = {};
  try {
    final contentType = request.headers.contentType;
    if (contentType == null || contentType.mimeType != 'multipart/form-data') {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write('Invalid content type')
        ..close();
      return information;
    }

    final boundary = contentType.parameters['boundary'];
    if (boundary == null) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write('Missing boundary in content type')
        ..close();
      return information;
    }

    // MimeMultipartTransformer로 multipart 데이터를 처리합니다.
    final transformer = MimeMultipartTransformer(boundary);
    final parts = await transformer.bind(request).toList();

    String? id;
    String? password;
    String? description;

    for (final part in parts) {
      final contentDisposition = part.headers['content-disposition'];
      if (contentDisposition != null) {
        // 파일 처리 부분
        if (contentDisposition.contains('filename=')) {
          final filename = RegExp(r'filename="([^"]*)"').firstMatch(contentDisposition)?.group(1);
          if (filename != null) {
            final file = File('uploads/$filename');
            await file.create(recursive: true);
            await part.pipe(file.openWrite());
            
            request.response
              ..headers.add(HttpHeaders.accessControlAllowOriginHeader, "*")
              ..statusCode = HttpStatus.ok
              ..write('File uploaded successfully: $filename');
            await request.response.close();
          }
        }
        // 텍스트 필드 처리 부분
        
        if (contentDisposition != null) {
          if (contentDisposition.contains('name="id"')) {
            id = await part.transform(utf8.decoder).join();
          } else if (contentDisposition.contains('name="password"')) {
            password = await part.transform(utf8.decoder).join();
          } else if (contentDisposition.contains('name="description"')) {
            description = await part.transform(utf8.decoder).join();
          }
        }
      }
    }

    // id, password, description 처리
    if (id != null && password != null && description != null) {
      print('Received ID: $id');
      print('Received Password: $password');
      print('Received Description: $description');
      information = { "id" : id, "pw" : password, "description" : description};
    } else {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write('Missing form fields')
        ..close();
      
    }
    print(information);
    return information;
  } catch (e) {
    print('Error during file upload: $e');
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write('Internal Server Error')
      ..close();
    return information;
  }
}
