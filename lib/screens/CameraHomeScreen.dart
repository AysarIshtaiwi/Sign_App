import 'dart:async';
import 'dart:io';
import 'package:sign_app/components/progress.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

import 'package:path/path.dart';
import 'package:async/async.dart';
import 'dart:convert';

class CameraHomeScreen extends StatefulWidget {
  List<CameraDescription> cameras;
  CameraHomeScreen(this.cameras);

  @override
  State<StatefulWidget> createState() {
    return _CameraHomeScreenState();
  }
}

class _CameraHomeScreenState extends State<CameraHomeScreen> {
  String imagePath;
  int _recordedCounter = 0;
  bool _startRecording = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  CameraController controller;

  final String _assetVideoRecorder = 'images/ic_video_shutter.png';
  final String _assetStopVideoRecorder = 'images/ic_stop_video.png';

  String videoPath;
  VideoPlayerController videoController;
  VoidCallback videoPlayerListener;
  Future<String> message;
  bool translationDone=false;
  final FlutterTts flutterTts = new FlutterTts();


  @override
  void initState() {
    try {
      onCameraSelected(widget.cameras[0]);
    } catch (e) {
      print(e.toString());
    }
    super.initState();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cameras.isEmpty) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all(16.0),
        child: Text(
          'No Camera Found!',
          style: TextStyle(
            fontSize: 16.0,
            color: Colors.white,
          ),
        ),
      );
    }

    if (!controller.value.isInitialized) {
      return Container();
    }

    return AspectRatio(
      key: _scaffoldKey,
      aspectRatio: controller.value.aspectRatio,
      child: Container(
        child: Stack(
          children: <Widget>[

            Container(
                margin: EdgeInsets.only(bottom: 100.0),
                child: CameraPreview(controller)),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                height: 100.0,
                padding: EdgeInsets.all(20.0),
                color: Colors.black,
                child: Stack(
                  //mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.center,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.all(Radius.circular(50.0)),
                          onTap: () {
                            !_startRecording
                                ? onVideoRecordButtonPressed()
                                : onStopButtonPressed();
                            setState(() {
                              _startRecording = !_startRecording;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(4.0),
                            child: Image.asset(
                              !_startRecording
                                  ? _assetVideoRecorder
                                  : _assetStopVideoRecorder,
                              width: 72.0,
                              height: 72.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    //TODO togle camera button
//                    !_startRecording ? _getToggleCamera() : new Container(),
                    //TODO Show recorded videos
//                    _recordedCounter != 0
//                        ? getRecordedVideos(_recordedCounter)
//                        : new Container(),
                    //TODO Go to next Page
                    _recordedCounter != -0
                        ? translateButton()
                        : new Container(),
                    FutureBuilder(
                      future: message,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return new Container();
                        } else if (snapshot.hasError) {
                          print(
                              "no data ********************************************************");
                          return new Container();
                        } else if (message!=null) {

                          return new Container();
                        }
                        return Container();
                      },
                    ),
                  ],
                ),
              ),
            ),
            FutureBuilder(
              future: message,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return circularProgress();
                } else if (snapshot.hasError) {
                  print(
                      "no data ********************************************************");
                  return circularProgress();
                } else if (message!=null) {

                  return new Container();
                }
                return Container();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget nextPageButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(right: 45.0),
        child: FloatingActionButton(
          heroTag: "btn1",
          onPressed: () {
            setState(() {
              nextPage(context);
            });
          },
          child: Icon(
            Icons.navigate_next,
            size: 50.0,
            color: Colors.white,
          ),
          backgroundColor: Colors.red,
        ),
      ),
    );
  }

  Widget translateButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(left: 45.0),
        child: FloatingActionButton(
          heroTag: "btn2",
          onPressed: () {
            setState(() {
              setCameraResult();
              message = message;
            });
          },
          child: Icon(
            Icons.translate,
            size: 40.0,
            color: Colors.white,
          ),
          backgroundColor: Colors.red,
        ),
      ),
    );
  }
  nextPage(BuildContext context){
    Navigator.pop(this.context);

//    print("cameraaaaaaaaaa" +widget.id);
//
//      Navigator.push(
//        context,
//        MaterialPageRoute(
//          builder: (context) => Contact(),
//        ),
//      );

  }

  Future speak(String str)async{
    await flutterTts.speak(str);

  }

  Widget getRecordedVideos(int counter) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        height: 400.0,
        width: 200.0,
//        child: Image.asset('assets/images/ic_flutter_devs_logo.png'),
        child: Row(
          children: <Widget>[
            getContainer(),
          ],
        ),
      ),
    );
  }

  Widget getContainer() {
    var item = Container(
      height: 50.0,
      width: 30,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
    );

    return item;
  }

  void onCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) await controller.dispose();
    controller = CameraController(cameraDescription, ResolutionPreset.high);

    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        showSnackBar('Camera Error: ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showException(e);
    }

    if (mounted) setState(() {});
  }

  String timestamp() => new DateTime.now().millisecondsSinceEpoch.toString();

  void setCameraResult() {
    File video = new File(videoPath);
    message = upload(video);
  }

  void onVideoRecordButtonPressed() {
    print('onVideoRecordButtonPressed()');
    startVideoRecording().then((String filePath) {
      if (mounted) setState(() {});
      if (filePath != null) showSnackBar('Saving video to $filePath');
    });
  }

  void onStopButtonPressed() {
    stopVideoRecording().then((_) {
      if (mounted)
        setState(() {
          _recordedCounter++;
          print(_recordedCounter);
        });
      showSnackBar('Video recorded to: $videoPath');
    });
  }

  Future<String> startVideoRecording() async {
    if (!controller.value.isInitialized) {
      showSnackBar('Error: select a camera first.');
      return null;
    }

    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Videos';
    await new Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.mp4';

    if (controller.value.isRecordingVideo) {
      return null;
    }

    try {
      videoPath = filePath;
      await controller.startVideoRecording(filePath);
    } on CameraException catch (e) {
      _showException(e);
      return null;
    }
    return filePath;
  }

  Future<void> stopVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.stopVideoRecording();
    } on CameraException catch (e) {
      _showException(e);
      return null;
    }

//    setCameraResult();
  }

  void _showException(CameraException e) {
    logError(e.code, e.description);
    showSnackBar('Error: ${e.code}\n${e.description}');
  }

  void showSnackBar(String message) {
    print(message);
  }

  void logError(String code, String message) =>
      print('Error: $code\nMessage: $message');

  Future<String> upload(File imageFile) async {

    print("translation strted");
    // open a bytestream
    var stream =
    new http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
    // get file length
    var length = await imageFile.length();

    // string to uri
    var uri = Uri.parse("https://sign-ml-api.herokuapp.com/predict/classifier");

    // create multipart request
    var request = new http.MultipartRequest("POST", uri);

    // multipart that takes file
    var multipartFile = new http.MultipartFile('file', stream, length,
        filename: basename(imageFile.path));

    // add file to multipart
    request.files.add(multipartFile);

    // send
    var response = await request.send();
    print(response.statusCode);

    // listen for response
    response.stream.transform(utf8.decoder).listen((value) {
      if (response.statusCode == 200) {
        String data = value;
        var decodedData = jsonDecode(data);
        String message = decodedData['readable_predictions'];
        print(message);
        speak(message);
      } else
        print(response.statusCode);
    });
  }
}
