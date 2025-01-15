import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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

  Future<void> _pickImage() async {
    final pickedFile =
      await ImagePicker().pickImage(source: ImageSource.gallery);
    if(pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _processImage();
    }
  }

  Future<void> _processImage() async {
    final inputImage = InputImage.fromFilePath(_imageFile!.path);
    final textRecognizer = TextRecognizer();
    recognizedText = 
      await textRecognizer.processImage(inputImage);
    textRecognizer.close();
    _resolveRecognizedText();
  }

  /* 
  Hämta all info
  Bryt ned till rader
  Hitta punkter för rutnät (alla -TEM samt namn på mätningar), samt mätvärden (nummer samt s,mm,%)
  



   */

  void _resolveRecognizedText () {

    var results = <TextLine>[];
    var ct = <TextLine>[];
    var a5 = <TextLine>[];
    var a10 = <TextLine>[];
    var a20 = <TextLine>[];
    var mcf = <TextLine>[];
    var ml = <TextLine>[];
    var a30 = <TextLine>[];
    TextLine fibtem;
    TextLine intem;
    TextLine extem;
    TextLine heptem;

    RegExp regExpResults = RegExp(r'^\d{1,3} ?(?:[s%]|m{2}|(?:5(?: |$)))');
    RegExp regExpCT = RegExp(r'CT');
    RegExp regExpA5 = RegExp(r'A5');
    RegExp regExpA10 = RegExp(r'A10');
    RegExp regExpA20 = RegExp(r'A20');
    RegExp regExpMCF = RegExp(r'MCF');
    RegExp regExpML = RegExp(r'ML');
    RegExp regExpA30 = RegExp(r'A30');
    RegExp regExpFibtem = RegExp(r'^FIBTEM');
    RegExp regExpIntem = RegExp(r'^INTEM');
    RegExp regExpExtem = RegExp(r'^EXTEM');
    RegExp regExpHeptem = RegExp(r'^HEPTEM');

    int i = 0;
    for(TextBlock block in recognizedText.blocks) {
      //print('     Block ${i}');
      for(TextLine line in  block.lines) {
        //print('          Text: ${line.text}');

        if (regExpResults.hasMatch(line.text)){
          results.add(line);
        } else if (regExpCT.hasMatch(line.text)){
          ct.add(line);
        } else if (regExpA5.hasMatch(line.text)){
          a5.add(line);
        } else if (regExpA10.hasMatch(line.text)){
          a10.add(line);
        } else if (regExpA20.hasMatch(line.text)){
          a20.add(line);
        } else if (regExpMCF.hasMatch(line.text)){
          mcf.add(line);
        } else if (regExpML.hasMatch(line.text)){
          ml.add(line);
        } else if (regExpA30.hasMatch(line.text)){
          a30.add(line);
        } else if (regExpFibtem.hasMatch(line.text)){
          fibtem = line;
        } else if (regExpIntem.hasMatch(line.text)){
          intem = line;
        } else if (regExpExtem.hasMatch(line.text)){
          extem = line;
        } else if (regExpHeptem.hasMatch(line.text)){
          heptem = line;
        } 
        else {
          //print('Släng');
        }
      }
      //i++;
    }
//
/*     print('---------------------CT lines------------------------');
    for (TextLine line in listCT) {
      print('${line.text},${line.angle},${line.boundingBox.left},${line.boundingBox.right},${line.boundingBox.top},${line.boundingBox.bottom}');
    } */

/*     print(results);
    print(results.length); */













  }



















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
                    onPressed: _resolveRecognizedText,
                    child: Text('Print recognized text again'),
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

