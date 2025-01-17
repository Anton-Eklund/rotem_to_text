import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:rotem_to_text/rotem.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ROTEM to Text',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.
  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title = 'ROTEM to Text';

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  File? _imageFile;
  late RecognizedText recognizedText;
  late Rotem rotem;

  Future<void> _pickImage() async {
    final pickedFile =
      await ImagePicker().pickImage(source: ImageSource.gallery);
    if(pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _processImage() async {
    final inputImage = InputImage.fromFilePath(_imageFile!.path);
    final textRecognizer = TextRecognizer();
    recognizedText = 
      await textRecognizer.processImage(inputImage);
    textRecognizer.close();
  }

  Future<void> _resolveRotem() async {
    rotem = Rotem(recognizedText: recognizedText);
  }

  /* 
  Hämta all info
  Bryt ned till rader
  Hitta punkter för rutnät (alla -TEM samt namn på mätningar), samt mätvärden (nummer samt s,mm,%)
  



   */


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _imageFile == null
              ? Text('Select an image to analyze.')
              : Image.file(_imageFile!),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: Text('Pick image'),
                  ),
                  SizedBox(width: 20),              
                  ElevatedButton(
                    onPressed: _processImage,
                    child: Text('Process image'),
                  ),
                  SizedBox(width: 20),              
                  ElevatedButton(
                    onPressed: _resolveRotem,
                    child: Text('Resolve ROTEM'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}