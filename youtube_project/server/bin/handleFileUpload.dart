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

    print("\$ Start handling Video File");
    // MimeMultipartTransformer로 multipart 데이터를 처리합니다.
    final transformer = MimeMultipartTransformer(boundary);
    final parts = await transformer.bind(request).toList();

    String? userId;
    String? userPassword;
    String? description;
    String? video_id;
    String? video_name;
    String video_path = 'uploads/';

    for (final part in parts) {
      final contentDisposition = part.headers['content-disposition'];
      if (contentDisposition != null) {
        // 파일 처리 부분
        if (contentDisposition.contains('filename=')) {
          final filename = RegExp(r'filename="([^"]*)"').firstMatch(contentDisposition)?.group(1);
          if (filename != null) {
            video_path = video_path + filename;
            final file = File(video_path);
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
          if (contentDisposition.contains('name="user_id"')) {
            userId = await part.transform(utf8.decoder).join();
          } else if (contentDisposition.contains('name="user_password"')) {
            userPassword = await part.transform(utf8.decoder).join();
          } else if (contentDisposition.contains('name="description"')) {
            description = await part.transform(utf8.decoder).join();
          } else if (contentDisposition.contains('name="video_id"')) {
            video_id = await part.transform(utf8.decoder).join();
          } else if (contentDisposition.contains('name="video_name"')) {
            video_name = await part.transform(utf8.decoder).join();
          }
        }
      }
    }

    print("\$ Save Video in $video_path");

    // id, password, description 처리
    // description의 경우 작성되지 않은 경우 [내용 없음]이라고 자동으로 채워서 서버에 전송되도록 프론트엔드를 구성
    if (userId != null && userPassword != null && description != null) {
      print("Received Video ID: $video_id");
      print("Received Video Name : $video_name");
      print('Received ID: $userId');
      print('Received Password: $userPassword');
      print('Received Description: $description');
      information = { "video_id" : video_id, 
                      "video_name" : video_name,
                      "user_id" : userId,
                      "user_password" : userPassword,
                      "video_url" : video_path,
                      "description" : description};
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
