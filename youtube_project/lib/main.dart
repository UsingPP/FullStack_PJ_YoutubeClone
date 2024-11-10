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
      home: MainPage(),
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
            ElevatedButton(
              child: const Text("Text Upload Page#Test"),
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => VideoViewPage()),
                );
              },
            ),
            ElevatedButton(
              child: const Text("Comment View Page#Test"),
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => CommentReadPage()),
                );
              },
            ),
            ElevatedButton(
              child: const Text("Comment Update Page#Test"),
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => CommentUpdatePage()),
                );
              },
            ),
            ElevatedButton(
              child: const Text("Watch Video"),
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => VideoWatch()),
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

class VideoWatch extends StatefulWidget {
  @override
  _VideoWatchState createState() => _VideoWatchState();
}

class _VideoWatchState extends State<VideoWatch> {
  final video_id = 'kI0Uh2pOIw1AVr2SAeAVNz2XblZunr';
  late String serverPath;
  late BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    super.initState();
    debugPrint("init");
    serverPath = "http://10.0.2.2:8080/videoRead/${video_id}/output.m3u8";
    debugPrint(serverPath);
    final BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      serverPath,);

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
  }

  @override
  void dispose() {
    _betterPlayerController.dispose();
    super.dispose();
  }  
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("HLS Player"),
      ),
      body: Center(
        child: BetterPlayer(
          controller: _betterPlayerController,
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

//텍스트 리드
class CommentReadPage extends StatefulWidget {
  @override 
  _CommentReadState createState() => _CommentReadState();
}
class _CommentReadState extends State<CommentReadPage> {
  var _commentsData = [];

  //동영상이랑 댓글을 보내기
  Future<void> DownloadCommentFile() async {
    var httpClient = HttpClient();
    HttpClientRequest httpRequest;
    HttpClientResponse httpResponse;
    Map jsonContent = {
      'video_id': 'x1a55XF1',
    };

    var content = await jsonEncode(jsonContent);

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
    DownloadCommentFile();
    print(_commentsData.toString());
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body : 
        ListView.builder(
          itemCount: _commentsData.length,
          itemBuilder: (context, index) {
            return Row(
              children : [
                Text("${_commentsData[index]["user_id"]} : "),
                Text(_commentsData[index]["contents"])
                 ]
            );
          },
      )
    );
  }

}