import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:mime/mime.dart';
import 'package:mysql_client/mysql_client.dart';


String createRandomId() {
  const charactors = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();
  return List.generate(30, (index) => charactors[random.nextInt(charactors.length)]).join();
}


Future<Map<String,dynamic>> handleFileUpload(HttpRequest request, MySQLConnection conn) async {
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
    String? video_name = "unsigned";
    String video_id = "x1a55XF1";

    bool isExist = true;
    do {
      var result = await conn.execute("select * from video_table where video_id = :video_id", {"video_id" : video_id});
      if (result.numOfRows != 0) {
        print("\$ Same Video ID In Server::$video_id");
        video_id = createRandomId();
        print("\$ Exchange Video ID::$video_id");
        print("\$ Check Again If the same ID is in the DB...");
      }
      else {
        print("\$ ID is Completly Orthogonal::");
        isExist = false;
      }
    } while (isExist);

    String video_path = 'videoUpload/$video_id';

    for (final part in parts) {
      final contentDisposition = part.headers['content-disposition'];
      if (contentDisposition != null) {
        // 파일 처리 부분
        if (contentDisposition.contains('filename=')) {
          final filename = RegExp(r'filename="([^"]*)"').firstMatch(contentDisposition)?.group(1);
          if (filename != null) {
            video_path = "${video_path}/video.mp4";
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
      print(" & Received Video ID: $video_id");
      print(" & Received Video Name : $video_name");
      print(' & Received ID: $userId');
      print(' & Received Password: $userPassword');
      print(' & Received Description: $description');
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

void printHttpServerActivated(HttpServer server) {
  var ip = server.address.address;
  var port = server.port;
  print('\$ Server activated in ${ip}:${port}');
}

void printAndSendHttpResponse(var request, var content) async {
  request.response
    ..header.contentType = ContentType('text', 'plain', charset : "utf-8")
    ..statusCode = HttpStatus.ok
    ..write(content);
  await request.response.close();
}

void createContents(HttpRequest request, MySQLConnection conn) async {

  var content = await utf8.decoder.bind(request).join();
  var transaction = jsonDecode(content) as Map;

  print(transaction);
  // 동영상인지 댓글인지를 확인
  // 댓글의 경우 해당 동영상의 식별id와 작성한 댓글 내용이 나타날 것임
  
  // 댓글의 json
  // body :
  //{ comment_id = string
  //  User_id = string
  //  User_Password = string
  //  videoId : string
  //  commentContents : String
  //}

  var user_id = transaction['user_id'];
  var user_password = transaction['user_password'];
  var videoId = transaction["video_id"];
  var commentId = "${videoId}DEF";
  var commentContents = transaction["contents"];

  print("$user_id, $user_password, $commentId");

  // 데이터베이스에 해당 댓글을 유저 아이디와 비밀번호를 포함하여 등록
  try{
  await conn.execute("insert into comments_table values (:comment_id, :user_id, :user_password, :video_id, :contents)",
        {
          "comment_id" : commentId, 
          "user_id" : user_id, 
          "user_password" : user_password, 
          "video_id" : videoId, 
          "contents" : commentContents
    });
    request.response
      ..statusCode = HttpStatus.ok
      ..write(content);
    await request.response.close();
  } catch (error) {
    request.response
      ..statusCode = HttpStatus.notImplemented
      ..write(error);
    await request.response.close();
  }
  
}

void readVideo(HttpRequest request, MySQLConnection conn) async {
  var content = await utf8.decoder.bind(request).join();
  var transaction = jsonDecode(content) as Map;
  //json 파일로 오는 request를 변환함

  var reqFileID = transaction["video_id"];
  var sqlResult = await conn.execute("select video_url from video_table where video_id = :reqFileID", 
  {
    "reqFileID" : reqFileID
  });
  //SQL의 videoID를 기준으로 비디오 url을 가져옴

  if (sqlResult.numOfRows > 1) {
    request.response
      ..statusCode = HttpStatus.notFound
      ..write("Video Not Found");
    print("\$ 404 NOT FOUND::$reqFileID NOT FOUND");
    return;
  }

  String filePath = "/";
  for (final row in sqlResult.rows) {
    filePath = row.assoc()["video_url"]!;
  }
  // 파일의 이름 찾기 코드

  var videoFile = File(filePath);

  if (await videoFile.exists()) {
    final videoStream = videoFile.openRead();

    request.response.headers.contentType = ContentType('video', 'mp4');
    request.response.headers.set('Content-Disposition', 'inline; filename="${videoFile.uri.pathSegments.last}"');
    await videoStream.pipe(request.response);
  } else {
    request.response.statusCode= HttpStatus.notFound;
    request.response.write('VideoFile Not Found');
    request.response.close();
    }
}

void readContents(HttpRequest request, MySQLConnection conn) async {
  List<Map<dynamic, dynamic>> jsonList = [];

  var content = await utf8.decoder.bind(request).join();

  var transaction = jsonDecode(content) as Map;

  var videoId = transaction["video_id"];
  print("\$ Posted Information::$transaction");
  print("\$ Posted VideoID::$videoId");
  var result = await conn.execute("select user_id, contents from comments_table where video_id = :videoId",
    {"videoId" : videoId} 
  );
   //해당 비디오의 전체 유저들과 쓴 댓글을 전부 추출

  //비디오가 없는 경우
  if (result.isEmpty) {
    print("\$ ::NotVideoInDatabase::numOfResult ${result.numOfRows}");
    request.response
      ..statusCode = HttpStatus.noContent
      ..write("This Video dont't hvae Any Comments");
    await request.response.close();

    return;
  }


  for (final row in result.rows) {
    print("\$ Result List::${row.assoc()}");
    jsonList.add(row.assoc());
  }

  var jsonData = jsonEncode(jsonList);
  print("JsonData::$jsonList");
  request.response
    ..headers.contentType = ContentType('text', 'plain', charset: 'utf8')
    ..statusCode = HttpStatus.ok
    ..write(jsonData);
  await request.response.close();

   //흐름도
   //해당 비디오에 대한 정보가 오면 그 비디오에 맞는 댓글을 가져옴
}

void updateComment(HttpRequest request, MySQLConnection conn) async {
  var content = await utf8.decoder.bind(request).join();
  var transaction = jsonDecode(content) as Map;
  //파싱
  var user_id = transaction['user_id'];
  var user_password = transaction['user_password'];
  var commentId = transaction["commentId"];
  bool isRightUser = false;
  
  //아이디와 비밀번호 조회 후 해당 유저가 작성한 코멘트인지를 확인함
  var result = await conn.execute('select user_id, user_password from comments_table where comment_id = :commentId', { "commentId" : commentId});
  for (final row in result.rows) {
    if ((row.colAt(0) == user_id) && (row.colAt(1) == user_password)){
      isRightUser = true;
      break;
    }
  }
  
  if (isRightUser){
    try {
      var commentContents = transaction["contents"];
      await conn.execute("update comments_table SET contents = :commentContents where comment_id = :commentId", {"commentContents" : commentContents, "commentId" : commentId});
      result = await conn.execute("select * from comments_table where comment_id = :commentId", {"commentId" : commentId});
      
      for (final row in result.rows) 
      {
        print("\$ Updated Information::${row.assoc()}");
      }

      request.response
        ..statusCode = HttpStatus.ok
        ..write("Complete::Comment Update");
      await request.response.close();

    } catch (err) {
      request.response
        ..statusCode = HttpStatus.notImplemented
        ..write("notImplemented::Comment");
      await request.response.close();
    }
  } 
  else { // 비밀번호가 맞지 않은 경우 잘못된 유저라는 메세지를 보냄
    request.response
      ..statusCode = HttpStatus.notAcceptable
      ..write("Wrong User's Access");
      await request.response.close();
      return;
  }

}