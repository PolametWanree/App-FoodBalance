import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      _controller = CameraController(
        cameras![0], 
        ResolutionPreset.high,
      );

      _initializeControllerFuture = _controller?.initialize();
      setState(() {});
    } else {
      print('No cameras available');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera page'),
      ),
      body: _controller == null
          ? Center(child: CircularProgressIndicator())
          : FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Center(
                    child: SizedBox(
                      width: 300, // กำหนดความกว้างของกล้อง
                      height: 400, // กำหนดความสูงของกล้อง
                      child: CameraPreview(_controller!),
                    ),
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
                
              },
            ),
    );
  }
}
