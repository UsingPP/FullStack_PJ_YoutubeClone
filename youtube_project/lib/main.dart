import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import "package:flutter/src/material/elevated_button.dart";
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // kIsWeb을 사용하기 위해 추가
import 'package:better_player/better_player.dart';



//kI0Uh2pOIw1AVr2SAeAVNz2XblZunr 예제용 비디오 아이디
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
      home: VideoWatchListPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("Video Upload Page#Test"),
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => VideoUploadPage()),
                );
              },
            ),
          ],

        )        
      ),
    );
  }
}




//비디오 업로드
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

    final uri = Uri.parse('http://localhost:8080/videoUpload/${_selectedFile!.name}'); // 서버의 주소와 포트

    setState(() {
      _uploadStatus = 'Uploading...';
    });

    try {
      final request = http.MultipartRequest('POST', uri);
      // 필드에 아이디, 비밀번호, 설명 추가
      request.fields.addAll({
        'video_id': '1Q2W3E4R',
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

//텍스트 업로드
class VideoViewPage extends StatefulWidget {
  @override 
  _VideoViewPageState createState() => _VideoViewPageState();
}
class _VideoViewPageState extends State<VideoViewPage> {  
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();



  Future<void> sendCommentToServer() async {
    HttpClientRequest httpRequest;
    HttpClientResponse httpResponse;
    var httpClient = HttpClient();
    var jsonContent = {
      "conmment_id" : _idController.text,
      "user_id" : _idController.text,
      "user_password" : _passwordController.text,
      "video_id" : "x1a55XF1",
      "contents" : _descriptionController.text
    };


    var jsonData = jsonEncode(jsonContent);

    try {
      var serverPath = "/commentUpload";
      httpRequest = await httpClient.post("10.0.2.2", 8080, serverPath)
        ..headers.contentType = ContentType("text", 'plain')
        ..write(jsonData);
      
      httpResponse = await httpRequest.close();
      if (httpResponse.statusCode == HttpStatus.ok) {
        print("Your Comment is in Server");
      }
      else {
        print("ERROR::${httpResponse.statusCode}");
      }
    } catch (error) {
      print("SendErrorOcur::$error");
      return;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
       title: Text("Video Page Client"),
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
            ElevatedButton(onPressed: sendCommentToServer, child: Text("Post Text")),
          ]
          )

        ),
      );
  }
}

//텍스트 업데이트
class CommentUpdatePage extends StatefulWidget {
  @override
  _CommentUpdateState createState() => _CommentUpdateState();
}
class _CommentUpdateState extends State<CommentUpdatePage> {
  final TextEditingController _commentEditingController = TextEditingController();
  final TextEditingController _idEditingController = TextEditingController();
  final TextEditingController _passwordEditingController = TextEditingController();

  Future<void> _updateCommentToServer() async {
    HttpClientRequest httpRequest;
    HttpClientResponse httpResponse;
    var httpClient = HttpClient();

    var data = {
      "comment_id" : "x1a55XF1B",
      "user_id" : _idEditingController.text,
      "user_password" : _passwordEditingController.text,
      "contents" : _commentEditingController.text
    };

    var jsonData = jsonEncode(data);
    try{
      var serverPath = "/commentUpdate";
      httpRequest = await httpClient.post("10.0.2.2", 8080, serverPath)
        ..headers.contentType = ContentType("text", 'plain')
        ..write(jsonData);
      httpResponse = await httpRequest.close();
      if (httpResponse.statusCode == HttpStatus.ok) {
        print("Your Comment is Changed");
      }
      else {
        debugPrint("::::ERROR::${httpResponse.statusCode}:::");
        debugPrint(await httpResponse.transform(utf8.decoder).join());
      }
    } catch (error) {
      debugPrint("SendErrorOcur::$error");
      return;
    }
  }


  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(
        title: Text('Video Upload Client'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _idEditingController,
              decoration: InputDecoration(labelText: 'Enter User ID'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordEditingController,
              decoration: InputDecoration(labelText: 'Enter Password'),
              obscureText: true,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _commentEditingController,
              decoration: InputDecoration(labelText: 'Enter Description'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateCommentToServer,
              child: Text('Exchange Comments'),
            ),
          ],
        ),
      ),);
  }
}

//텍스트 리드 :::::
class CommentReadPage extends StatefulWidget {
  final Map<String, dynamic> data;
  CommentReadPage({required this.data});
  @override
  _CommentReadState createState() => _CommentReadState();
}
class _CommentReadState extends State<CommentReadPage> {
  var _commentsData = [];
  var video_id = "";
  late String videoServerPath;
  BetterPlayerController? _betterPlayerController;

  // 댓글 관련 팝업 생성
  AlertDialog userLogInAndSendChangeMessagePopup(BuildContext context, int offset, {String commentId = "NULL"}) {
    // offset이 0인 경우 => 수정모드. 댓글을 수정하기 위해서 작동함
    // offset이 1인 경우 => 삭제 모드. 댓글을 삭제하는 메세지를 서버로 전송함
    // offset이 2인 경우 => 댓글 작성
    TextEditingController userIdTextController = TextEditingController();
    TextEditingController userPasswordTextController = TextEditingController();
    TextEditingController userCommentTextController = TextEditingController();
                  print( commentId);

    return AlertDialog(
      content: SizedBox(
        height: offset == 1 ? 150 : 370,
          child: Column(
          children: [
            Text( offset == 0 ? "댓글 수정" :
              (offset == 1 ? "댓글 삭제" : "댓글 작성"),
              style: TextStyle( fontSize: 14),
            ),
            SizedBox(height: 10,),
            TextField(
              controller: userIdTextController,
              decoration: InputDecoration(labelText: "아이디"),
            ),
            TextField(
              controller: userPasswordTextController,
              decoration: InputDecoration(labelText: "패스워드"),
            ),
            SizedBox(height: 5,),
            if (offset == 0 || offset == 2)
              TextField(
                controller: userCommentTextController,
                decoration: InputDecoration(
                  labelText: offset == 0 ? "수정 내용" : "댓글 작성",
                  border: OutlineInputBorder(), // 테두리 추가
                  alignLabelWithHint: true, // 여러 줄 텍스트에 레이블 정렬
                ),
                maxLines: 20, // 텍스트 필드를 5줄 높이로
                minLines: 7, // 최소 3줄 높이로 보이도록 설정
                keyboardType: TextInputType.multiline,
              ),
          ],
      )
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text("취소"),
        ),
        TextButton(
          onPressed: () {
            if (offset == 0) {
              setState(() {
                _updateCommentToServer(commentId, userIdTextController.text, userPasswordTextController.text, userCommentTextController.text);
              });
            }
            // 서버로 메시지 전송 로직
            Navigator.of(context).pop();
          },
          child: Text("확인"),
        ),
      ],
    );
  }


  Future<void> _updateCommentToServer(String comment_id, String user_id, String user_password, String comments) async {
    HttpClientRequest httpRequest;
    HttpClientResponse httpResponse;
    var httpClient = HttpClient();

    var data = {
      "comment_id" : comment_id,
      "user_id" : user_id,
      "user_password" : user_password,
      "contents" : comments
    };

    print(data);

    var jsonData = jsonEncode(data);
    try{
      var serverPath = "/commentUpdate";
      httpRequest = await httpClient.post("10.0.2.2", 8080, serverPath)
        ..headers.contentType = ContentType("text", 'plain')
        ..write(jsonData);
      httpResponse = await httpRequest.close();
      if (httpResponse.statusCode == HttpStatus.ok) {
        print("Your Comment is Changed");
      }
      else {
        debugPrint("::::ERROR::${httpResponse.statusCode}:::");
        debugPrint(await httpResponse.transform(utf8.decoder).join());
      }
    } catch (error) {
      debugPrint("SendErrorOcur::$error");
      return;
    }
  }

  //댓글을 가져오기
  Future<void> DownloadCommentFile(String video_id) async {
    var httpClient = HttpClient();
    HttpClientRequest httpRequest;
    HttpClientResponse httpResponse;
    Map jsonContent = {
      'video_id': video_id,
    };

    var content = jsonEncode(jsonContent);

    try {

      debugPrint("Cl::MakeRequest");
      var serverPath = "/commentRead";

      httpRequest = await httpClient.post("10.0.2.2", 8080, serverPath)
        ..headers.contentType = ContentType('text', 'plain', charset: 'utf8')
        ..headers.contentLength = content.length
        ..write(content);

      debugPrint(httpRequest.uri.path);
      httpResponse = await httpRequest.close();

      debugPrint("httpResponse Arrived");
      var httpResponseContent = await utf8.decoder.bind(httpResponse).join();
      debugPrint("HttpResponseContent::$httpResponseContent");
      
      setState(() {
      _commentsData = (jsonDecode(httpResponseContent) as List);
      });

    }
    catch (error) {
      print("Error::$error");
      return;
    }
  }

  @override
  void initState() {
    super.initState();
    video_id = widget.data["VIDEO_ID"];
    videoServerPath = "";//"http://10.0.2.2:8080/videoRead/${video_id}/output.m3u8";
    debugPrint("init:::${videoServerPath}");



    final BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      videoServerPath,
      // bufferingConfiguration: BetterPlayerBufferingConfiguration(
      //   minBufferMs: 25000, // 최소 버퍼 크기 (밀리초 단위)
      //   maxBufferMs: 6553600, // 최대 버퍼 크기 (밀리초 단위)
      //   bufferForPlaybackMs: 25000, // 재생을 시작하기 전에 필요한 버퍼 크기
      //   bufferForPlaybackAfterRebufferMs: 60000, // 재버퍼링 후 재생을 시작하기 전에 필요한 버퍼 크기
      // ) 아니 뭐가 문제야 이거
    );

    _betterPlayerController = BetterPlayerController(
        const BetterPlayerConfiguration(
          aspectRatio: 16 / 9,
          autoPlay: true,
          looping: false,
          controlsConfiguration: BetterPlayerControlsConfiguration(
            enablePlayPause: true,
            enableFullscreen: true,
          ),
        ),
        betterPlayerDataSource: dataSource,
      );

    DownloadCommentFile(video_id);

  }
  @override
  void dispose() {
    _betterPlayerController?.dispose();
    super.dispose();
  }  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
          children: [
          _betterPlayerController != null
              ? Container(
                  color: Colors.black, // 예시로 배경색 지정
                  child: BetterPlayer(controller: _betterPlayerController!),
                )
              : Container(
                width: 300,
                color : Colors.black,
                child: CircularProgressIndicator()
              ), // 초기화 중일 때 로딩 표시
          Container(
            alignment: Alignment.centerLeft,
            padding : EdgeInsets.all(8.0),
            child: 
              Column( 
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.data["VIDEO_NAME"],
                    style : TextStyle( fontSize: 21),
                  ),
                  Text(
                    widget.data["USER_ID"],
                    style : TextStyle( 
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                ],
              ),
          ),
          //여기부터는 댓글 뷰
          //댓글 입력 기능 => 버튼 누르면 팝업이 떠서 댓글 작성 가능
          Container(),
          Expanded(
            child : ListView.builder(
              itemCount: _commentsData.length,
              itemBuilder: (context, index) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 추가된 Container
                    Container(
                      width: 50,
                      height: 50,
                      margin: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.blue, // 배경색
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _commentsData[index]["user_id"][0], // 유저 ID의 첫 글자 표시
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 1),
                    Container(
                      height: 50,
                      margin: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            // color: Colors.black,
                            child : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children : [
                                Container(//이름
                                  child : Text(
                                    "${_commentsData[index]["user_id"]}",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),            
                                ),
                                SizedBox(width : 12),
                                GestureDetector(
                                  onTap: () {
                                    showDialog(context: context, builder: (context) {
                                      return userLogInAndSendChangeMessagePopup(context, 0, commentId: _commentsData[index]["comment_id"]);
                                    }
                                    );
                                    print("수정");
                                  },
                                  child : Container( // 수정
                                    child : 
                                      Text("수정",
                                      style: TextStyle(fontSize: 9),)
                                  ),
                                ),
                                SizedBox(width : 5), 
                                GestureDetector(
                                  onTap: () {
                                    showDialog(context: context, builder: (context) { return userLogInAndSendChangeMessagePopup(context, 1, commentId: _commentsData[index]["comment_id"]);});
                                    print("삭제");
                                  },
                                  child : Container( // 수정
                                    child : 
                                      Text("삭제",
                                      style: TextStyle(fontSize: 9),)
                                  ),
                                ),
                              ]
                            )
                          ),
                          Text(_commentsData[index]["contents"]),
                        ],
                      ),
                    )
                  ],
                );
              },
            ),
          ),
        ],
      )
    );
  }

}


//사실상 현재 메인 페이지
class VideoWatchListPage extends StatefulWidget {
 @override 
  _VideoWatchListState createState() => _VideoWatchListState();
}
class _VideoWatchListState extends State<VideoWatchListPage> {
  List<dynamic> videoData = [];
  int videoLength = 0;

  Future<void> GetVideoFromServer() async {
    var httpClient = HttpClient();
    HttpClientRequest httpRequest;
    HttpClientResponse httpResponse;

    try {
      debugPrint("Video Request");
      var serverPath = "/GetVideoList";
      httpRequest = await httpClient.post("10.0.2.2", 8080, serverPath)
        ..headers.contentType = ContentType('application', 'json', charset: 'utf-8');
      httpResponse = await httpRequest.close();
      //이미지 주소, 동영상 제목, 동영상 코드, 작성자가 올 것

      StringBuffer stringHandler = StringBuffer();
      await for (var chunk in httpResponse) {
        String chunkStr = utf8.decode(chunk);
        stringHandler.write(chunkStr);
      }
      try {
        String fullData = stringHandler.toString();
        setState(() {
          videoData = jsonDecode(fullData) as List; // JSON 디코딩
          print(videoData.length);
        },);
      } catch (error) {
        print('Error processing data: $error');
      }
      //videoData[0] => 첫번째 값 { "A" : ~~}
      print(videoData[0]);
      print(videoData[0]["USER_ID"]);
    }
    catch(error) {
      print("Error::$error");
      return;
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      await GetVideoFromServer();
    });
  }
  
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: videoData.length,  // 리스트의 개수만큼 아이템 생성
        itemBuilder: (context, index) {
          return GestureDetector( // 해당 컨테이너를 누르면 영상 동작
            onTap: () {
              print("::::::::::::::::::::::::::::::${videoData[index]}");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CommentReadPage(data: videoData[index])),
              );
            },
            child: Container(
              margin: EdgeInsets.all(8.0),
              color: Colors.black,  // 각 아이템마다 색상을 다르게 설정
              height: 300,  // 컨테이너 높이 설정
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.all(2.0),
                    color: Colors.black12,
                    height: 240,
                  ),
                  SizedBox(height:5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        margin: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.blue, // 배경색
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            videoData[index]["USER_ID"][0], // 유저 ID의 첫 글자 표시
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            videoData[index]["VIDEO_NAME"],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            videoData[index]["USER_ID"],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
