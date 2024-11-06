import 'package:server/server.dart' as server;

// void main(List<String> arguments) {
//   print('Hello world: ${server.calculate()}!');
// }

import 'dart:io';
import 'dart:convert';
import 'handleFileUpload.dart';
import 'package:mysql_client/mysql_client.dart';

Future main() async {

  // Finally, close the connection
final conn = await MySQLConnection.createConnection(
  host: "127.0.0.1",
  port: 3306,
  userName: "root",
  password: "xswzaq1386@",
  databaseName: "youtube_db", // optional
);

await conn.connect();
print("SQL Connect");
conn.execute("show tables");

var result = await conn.execute("select comment_id, user_password from comments_table");

// print(result.numOfColumns);
// print(result.numOfRows);
// print(result.lastInsertID);
// print(result.affectedRows);

  // print query result
  for (final row in result.rows) {
    // print(row.colAt(0));
    // print(row.colByName("title"));

    // print all rows as Map<String, String>
    var rowcont = row.assoc();
    print(rowcont);
  }

  // close all connections
  await conn.close();

print(result.numOfColumns);
// actually connect to database
  var serverIp = InternetAddress.loopbackIPv4;
  var serverPort = 8080;

  var server = await HttpServer.bind(
    serverIp,
    serverPort,
  );

  printHttpServerActivated(server);

  await for (HttpRequest request in server ) {
    // 서버에 들어오는 경우는 댓글을 전송, 댓글을 발송
    //혹은 동영상을 전송, 동영상을 발송
    print("\$ Request in Server");
    try {
      print("${request.uri.path} and ${request.method}");
      switch (request.method) {
        case 'POST' : // 동영상이나 댓글을 업로드
          if (request.uri.path == '/videoUpload') {
            print('\$ Video Post request in Server');
            Future<Map<String,dynamic>> infomation = handleFileUpload(request);
            await infomation.then((info) {
              print(info);
              //conn.execute("INSERT INTO VIDEO_TABLE VALUE (:video_id, :video_name, :user_id, :user_password, :video_url, :description)", info);
            }
            ).catchError((error) {
              print("ExceptionError::$error");
            }); 
          } else if (request.uri.path == '/commentUpload'){
            print("111");
          }
          //createContents(request, conn);
        case 'GET' : // 동영상이나 댓글을 읽기
          readContents(request, conn);
        case 'PUT' : // 댓글 업데이트
          updateComment(request, conn);
        case 'DELETE' : // 댓글 영상 삭제
      }
    }
    catch (err) {
      print("\$ Exception in http request processing");
    }
  }
  
  
}

void printHttpServerActivated(HttpServer server) {
  var ip = server.address.address;
  var port = server.port;
  print('\$ Server activated in ${ip}:${port}');
}

void printAndSendHttpResponse(var request, var content) async {
  print("lHello World");
  request.response
    ..header.contentType = ContentType('text', 'plain', charset : "utf-8")
    ..statusCode = HttpStatus.ok
    ..write(content);
  await request.response.close();
}

//타입캐스팅 해야 할 듯

void createContents(HttpRequest request, MySQLConnection conn) async {

  var content = await utf8.decoder.bind(request).join();
  var transaction = jsonDecode(content) as Map;
  // 동영상인지 댓글인지를 확인
  // 댓글의 경우 해당 동영상의 식별id와 작성한 댓글 내용이 나타날 것임
  
  // 댓글의 json
  // body :
  //{ comment_id = int
  //  User_id = string
  //  User_Password = password
  //  videoId : int
  //  commentContents : String
  //}
  var _contentType = transaction["_contentType"];
  var user_id = transaction['user_id'];
  var user_password = transaction['user_password'];

  if (_contentType == 'COMMENT_STRING') {
    //댓글인 경우 해당
    var videoId = transaction["videoId"];
    var commentId = transaction["commentId"];
    var commentContents = transaction["commentContents"];

    // 데이터베이스에 해당 댓글을 유저 아이디와 비밀번호를 포함하여 등록
    await conn.execute("insert into comments_table values (:comment_id, :user_id, :user_password, :video_id, :comments_body)",
      {
        "comment_id" : commentId, 
        "user_id" : user_id, 
        "user_password" : user_password, 
        "video_id" : videoId, 
        "comments_body" : commentContents
      });
  }
  else if (_contentType == 'VIDEO_FILE') {
  }
  else {
    print("\$ ::WRONG TYPE COMMAND::");
  }

  printAndSendHttpResponse(request, content);
  
}

void updateComment(HttpRequest request, MySQLConnection conn) async {
  var content = await utf8.decoder.bind(request).join();
  var transaction = jsonDecode(content) as Map;
    //파싱
  var user_id = transaction['user_id'];
  var user_password = transaction['user_password'];
  var videoId = transaction["videoId"];
  var commentId = transaction["commentId"];
  bool isRightUser = false;
  
  var result = await conn.execute('select user_id, user_password from comments_table where comment_id = :commentId', { "commentId" : commentId});
  for (final row in result.rows) {
    var _result = row.assoc();
    if ((_result["user_id"] == user_id) && (_result["user_password"] == user_password)) {
      isRightUser = true;
    }
  }
  if (isRightUser){
    var commentContents = transaction["commentContents"];
    await conn.execute("update comments_table SET comment_body = :commentContents where comment_id = :commentId", {"commentContents" : commentContents, "commentId" : commentId});
  }

  printAndSendHttpResponse(request, content);
}

void readContents(HttpRequest request, MySQLConnection conn) async {
  var content = await utf8.decoder.bind(request).join();
  var transaction = jsonDecode(content) as Map;
  var videoId = transaction["videoId"];
  var video = await conn.execute("select video_url from video_table where video_id = :videoId",
    {"videoId" : videoId} 
    // 해당 비디오의 저장 url을 가져옴
    //어디에 저장해놓을 지에 대해서는 아직 미정
   );
}