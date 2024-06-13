import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
//import 'package:flutter_camera_ml_vision/flutter_camera_ml_vision.dart';

//my wifi address 192.168.35.165

late List<CameraDescription> _cameras;
XFile? takedPhoto;
String uri = 'http://192.168.35.165:5001';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const CameraPage(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
    );
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _cameraController;

  @override
  void initState() {
    super.initState();
    _cameraController = CameraController(_cameras[0], ResolutionPreset.max);
    _cameraController.initialize().then((_) {
      if (!mounted) {
        debugPrint('!!! can not mount camera');
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      debugPrint('!!! err : $e');
    });
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('take photo')),
      body: Center(
        child: _cameraController.value.isInitialized
            ? CameraPreview(_cameraController)
            : const Text('not initialized'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          takedPhoto = await _cameraController.takePicture();
          Navigator.push(context, MaterialPageRoute(
            builder: (context) {
              return ResultPage();
            },
          ));
        },
        child: const Icon(Icons.camera),
      ),
      //bottomNavigationBar: BottomNavigationBar(items: []),
    );
  }
}

class ResultPage extends StatelessWidget {
  const ResultPage({super.key});

  Future<Uint8List?> upload() async {
    //set url and header
    Uri url = Uri.parse(uri);
    var header = {'Content-Type': 'application/json'};

    //set image data to body as base64
    if (takedPhoto == null) {
      debugPrint('!!! taken photo null');
      return null;
    }
    Uint8List imageBytes = await takedPhoto!.readAsBytes();
    String base64Image = base64Encode(imageBytes);
    var body = jsonEncode({"image": base64Image});

    try {
      http.Response response = await http.post(
        url,
        headers: header,
        body: body,
      );
      debugPrint('!!! Response status: ${response.statusCode}');
      debugPrint('!!! Response body: ${response.body}');

      final data = jsonDecode(response.body);
      if (data['result_image'] == null) {
        debugPrint('!!! result image null');
        return null;
      }
      return base64Decode(data['result_image']);
    } catch (e) {
      debugPrint('!!! err $e');
    }
    return null;
  }

  Future<Uint8List?> checkPhoto() async {
    return await takedPhoto?.readAsBytes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('depth estimation')),
      body: Center(
        child: FutureBuilder(
          //future: checkPhoto(),
          future: upload(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError || snapshot.data == null) {
              return const Text('err');
            }
            Uint8List image = snapshot.data!;
            return Image.memory(image);
          },
        ),
      ),
    );
  }
}
