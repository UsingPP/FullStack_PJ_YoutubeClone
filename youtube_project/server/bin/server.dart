import 'package:server/server.dart' as server;

// void main(List<String> arguments) {
//   print('Hello world: ${server.calculate()}!');
// }

import 'dart:io';
import 'dart:convert';
import 'serverHandler.dart';
import 'package:http/http.dart' as http; 
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
print("\$ SQL Connect");

// var result = await conn.execute("select * from video_table");

// print(result.numOfColumns);
// print(result.numOfRows);
// print(result.lastInsertID);
// print(result.affectedRows);

// List<Map<dynamic, dynamic>> myList = [];
//   //print query result
// for (final row in result.rows) {
//   print(row.colAt(1));

//   //print all rows as Map<String, String>
//   myList.add(row.assoc());
//   print(myList);
//   }


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
          if (request.uri.path == '/videoUpload') 
          {
            print('\$ Video Post request in Server');
            Future<Map<String,dynamic>> infomation = handleFileUpload(request);
            await infomation.then((info) 
            {
              print(info);
              //conn.execute("INSERT INTO VIDEO_TABLE VALUE (:video_id, :video_name, :user_id, :user_password, :video_url, :description)", info);
            }
            ).catchError((error) {
              print("ExceptionError::$error");
            }); 
          } 
          else if (request.uri.path == '/commentUpload')
          {
            createContents(request, conn);
          }
          //createContents(request, conn);
          break;

        case 'GET' : // 동영상이나 댓글을 읽기
          if (request.uri.path == '/videoRead')
          {
            readVideo(request, conn);
          } 
          else if (request.uri.path == '/CommentRead') 
          {
            readContents(request, conn);
          }
          break;

        case 'PUT' : // 댓글 업데이트
          updateComment(request, conn);
          break;

        case 'DELETE' : // 댓글 영상 삭제
          break;
      }
    }
    catch (err) {
      print("\$ Exception in http request processing");
    }
  }
  //서버 종료 시 conn 연결 해제
  await conn.close();
  print("\$ SQL Disconnect");
}

