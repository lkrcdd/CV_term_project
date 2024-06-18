import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'dart:math' as math;
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
  int _bottomIndex = 0;

  void tapBottom(int index) {
    setState(() => _bottomIndex = index);
  }

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
          if (_bottomIndex == 0) {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return DepthPage();
              },
            ));
          } else if (_bottomIndex == 1) {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return DetectionPage();
              },
            ));
          } else if (_bottomIndex == 2) {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return TextPage();
              },
            ));
          } else {
            return;
          }
        },
        child: const Icon(Icons.camera),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_enhance),
            label: 'depth estimation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'object detection',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.text_fields),
            label: 'recognize text',
          ),
        ],
        currentIndex: _bottomIndex,
        selectedItemColor: Colors.blue,
        onTap: tapBottom,
      ),
    );
  }
}

class DepthPage extends StatelessWidget {
  const DepthPage({super.key});

  Future<Uint8List?> estimate() async {
    //set url and header
    Uri url = Uri.parse('$uri/depth');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('depth estimation')),
      body: Center(
        child: FutureBuilder(
          future: estimate(),
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

class DetectionPage extends StatelessWidget {
  const DetectionPage({super.key});

  Future<Uint8List?> detect() async {
    //set url and header
    Uri url = Uri.parse('$uri/detection');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('object detection')),
      body: Center(
        child: FutureBuilder(
          future: detect(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError || snapshot.data == null) {
              return const Text('err');
            }
            Uint8List image = snapshot.data!;
            return Transform.rotate(
              angle: 90 * (math.pi / 180),
              child: Image.memory(image),
            );
          },
        ),
      ),
    );
  }
}

class TextPage extends StatelessWidget {
  const TextPage({super.key});

  Future<String?> recognize() async {
    //set url and header
    Uri url = Uri.parse('$uri/text');
    var header = {'Content-Type': 'application/json'};

    //set image data to body as base64
    if (takedPhoto == null) {
      debugPrint('!!! taken photo null');
      return null;
    }
    Uint8List imageBytes = await takedPhoto!.readAsBytes();
    String base64Image = base64Encode(imageBytes);
    var body = jsonEncode({"image": base64Image});

    // final ByteData bytes =
    //     await rootBundle.load('assets/images/test_london.jpg');
    // final List<int> list = bytes.buffer.asUint8List();
    // final String base64Image = base64Encode(list);
    // var body = jsonEncode({"image": base64Image});

    try {
      http.Response response = await http.post(
        url,
        headers: header,
        body: body,
      );
      debugPrint('!!! Response status: ${response.statusCode}');
      debugPrint('!!! Response body: ${response.body}');

      final data = jsonDecode(response.body);
      if (data['result_text'] == null) {
        debugPrint('!!! result text null');
        return null;
      }
      return data['result_text'];
    } catch (e) {
      debugPrint('!!! err $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('recognize text')),
      body: Center(
        child: FutureBuilder(
          future: recognize(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError || snapshot.data == null) {
              return const Text('err');
            }
            String text = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.file(File(takedPhoto!.path)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(text),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
