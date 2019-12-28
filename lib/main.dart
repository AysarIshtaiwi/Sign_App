import 'package:flutter/material.dart';
import 'package:sign_app/screens/chat_screen.dart';
import 'package:sign_app/screens/search.dart';
import 'package:sign_app/screens/Home.dart';
import 'package:camera/camera.dart';



List<CameraDescription> cameras;

Future<Null> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    //logError(e.code, e.description);
  }
  runApp(MaterialApp(

    initialRoute: Home.id,
    routes: {
      Home.id: (context) => Home(),
      ChatScreen.id: (context) => ChatScreen(),
      Search.id: (context) => Search(),
    },
    home: Home(),
  ),
  );
}
