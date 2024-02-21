import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

double textSize = 20;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

RenderRepaintBoundary? findNearestRepaintBoundary(RenderObject? render) {
  RenderObject? renderObject = render;
  while (renderObject != null) {
    if (renderObject is RenderRepaintBoundary) {
      return renderObject;
    }
    renderObject = renderObject.parent;
  }
  return null;
}

Future<Uint8List?> getLocalImage(GlobalKey? globalKey) async {
  if (globalKey == null) return null;
  var currCtx = globalKey.currentContext;
  if (currCtx == null) return null;
  var rendered = currCtx.findRenderObject();
  if (rendered is RenderRepaintBoundary) {
    ui.Image image = rendered.toImageSync();
    ByteData? byteData = await (image.toByteData(format: ui.ImageByteFormat.png));
    if (byteData != null) {
      return byteData.buffer.asUint8List();
    }
  }
  var autre = findNearestRepaintBoundary(rendered);
  if (autre is RenderRepaintBoundary) {
    ui.Image image = await autre.toImage();
    ByteData? byteData = await (image.toByteData(format: ui.ImageByteFormat.png));
    if (byteData != null) {
      return byteData.buffer.asUint8List();
    }
  }
  return null;
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String firstButtonText = 'Take photo';
  String secondButtonText = 'Record video';

  String albumName = 'Media';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: Column(
            children: <Widget>[
              Flexible(
                flex: 1,
                child: Container(
                  child: SizedBox.expand(
                    child: TextButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.blue),
                      ),
                      onPressed: _takePhoto,
                      child: Text(firstButtonText, style: TextStyle(fontSize: textSize, color: Colors.white)),
                    ),
                  ),
                ),
              ),
              ScreenshotWidget(),
              Flexible(
                child: Container(
                    child: SizedBox.expand(
                  child: TextButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.white),
                    ),
                    onPressed: _recordVideo,
                    child: Text(secondButtonText, style: TextStyle(fontSize: textSize, color: Colors.blueGrey)),
                  ),
                )),
                flex: 1,
              )
            ],
          ),
        ),
      ),
    ));
  }

  Future<void> _takePhoto() async {
    var recordedImage = await ImagePicker().pickImage(source: ImageSource.camera);
    if (recordedImage == null) return;
    setState(() {
      firstButtonText = 'saving in progress...';
    });
    var success = await GallerySaver.saveImage(recordedImage.path, albumName: albumName);
    setState(() {
      firstButtonText = (success ?? false) ? 'Error!!' : 'image saved!';
    });
  }

  Future<void> _recordVideo() async {
    var recordedVideo = await ImagePicker().pickVideo(source: ImageSource.camera);
    if (recordedVideo == null) return;
    setState(() {
      secondButtonText = 'saving in progress...';
    });
    bool? success = await GallerySaver.saveVideo(recordedVideo.path, albumName: albumName);
    setState(() {
      secondButtonText = (success ?? false) ? 'Error!!' : 'video saved!';
    });
  }

  // ignore: unused_element
  Future<void> _saveNetworkVideo() async {
    String path = 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4';
    bool? success = await GallerySaver.saveVideo(path, albumName: albumName);
    setState(() {
      print((success ?? false) ? 'Error!!' : 'Video is saved');
    });
  }

  // ignore: unused_element
  Future<void> _saveNetworkImage() async {
    String path = 'https://image.shutterstock.com/image-photo/montreal-canada-july-11-2019-600w-1450023539.jpg';
    bool? success = await GallerySaver.saveImage(path, albumName: albumName);
    setState(() {
      print((success ?? false) ? 'Error!!' : 'Image is saved');
    });
  }
}

class ScreenshotWidget extends StatefulWidget {
  @override
  _ScreenshotWidgetState createState() => _ScreenshotWidgetState();
}

class _ScreenshotWidgetState extends State<ScreenshotWidget> {
  final GlobalKey _globalKey = GlobalKey();
  String screenshotButtonText = 'Save screenshot';

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 1,
      child: RepaintBoundary(
        key: _globalKey,
        child: Container(
          child: SizedBox.expand(
            child: TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.pink),
              ),
              onPressed: _saveScreenshot,
              child: Text(screenshotButtonText, style: TextStyle(fontSize: textSize, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveScreenshot() async {
    setState(() {
      screenshotButtonText = 'saving in progress...';
    });
    try {
      final Uint8List? pngBytes = await getLocalImage(_globalKey);

      //create file
      final String dir = (await getApplicationDocumentsDirectory()).path;
      final String fullPath = '$dir/${DateTime.now().millisecond}.png';
      File capturedFile = File(fullPath);
      if (pngBytes == null) return;
      await capturedFile.writeAsBytes(pngBytes);
      print(capturedFile.path);

      var result = await GallerySaver.saveImage(capturedFile.path);
      if (result == null || !result) return;
      setState(() {
        screenshotButtonText = 'screenshot saved!';
      });
    } catch (e) {
      print(e);
    }
  }
}
