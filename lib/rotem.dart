import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:ui';

class Rotem {

  Rotem ({required RecognizedText recognizedText}) {
    _resolveRecognizedText(recognizedText);
    for(Variable variable in _variables.values) {
      variable._sortPosition();
    } 
    // Vad sen?


  }

  // Constructor with RecognizedText
  // Method _resolveRecognizedText
  
  final Map<String, Analysis> analyses = {
    'fibtem':Analysis(name: 'FIBTEM'),
    'intem':Analysis(name: 'INTEM'),
    'extem':Analysis(name: 'EXTEM'),
    'heptem':Analysis(name: 'HEPTEM')
  };

  final Map<String, Variable> _variables = {
    'analyses':Variable(name: 'Analyses', regExpString: r'^(?:FIB)|(?:IN)|(?:EX)|(?:HEP)TEM'),
    'ct':Variable(name: 'CT', regExpString: r'CT'),
    'a5':Variable(name: 'A5', regExpString: r'A5'),
    'a10':Variable(name: 'A10', regExpString: r'A10'),
    'a20':Variable(name: 'A20', regExpString: r'A20'),
    'mcf':Variable(name: 'MCF', regExpString: r'MCF'),
    'ml':Variable(name: 'ML', regExpString: r'ML'),
    'a30':Variable(name: 'A30', regExpString: r'A30')
  };

  final _unsortedResultsTextLines = <TextLine>[];
  RegExp regExpResults = RegExp(r'^\d{1,3} ?(?:[s%]|m{2}|(?:5(?: |$)))');  

  void _resolveRecognizedText (RecognizedText recognizedText) {

    // int i = 0;
    for(TextBlock block in recognizedText.blocks) {
      //print('Block ${i}');
      for(TextLine line in  block.lines) {
        //print('     Text: ${line.text}');
        //Look for results match
        if(regExpResults.hasMatch(line.text)) {
          _unsortedResultsTextLines.add(line);
        }
        else {
          //Else look for variable match
          for(Variable variable in _variables.values) {
            if(variable.regExp.hasMatch(line.text)) {
              variable._unsortedVariableTextLines.add(line);
              break;
            }
          }
          //print('          Släng');
        }
      }
      //i++;
    }
  }

}

class Analysis {

  Analysis({required this.name});

  late final int position;

  late final String name;
  late final double rt;
  late final int ct;
  late final int a5;
  late final int a10;
  late final int a20;
  late final int mcf;
  late final int ml;
  late final int a30;

  late final List <TextLine> unsortedResults;
}

class Variable {

  final String name;
  late final Offset _meanOffset;
  final List <TextLine> _unsortedVariableTextLines = <TextLine>[];
  late final RegExp regExp;

  late final Offset tl;
  late final Offset tr;
  late final Offset bl;
  late final Offset br;

  Variable({required this.name, required String regExpString}) {
    regExp = RegExp(regExpString);// Run method
  }

  void addTextLine (TextLine textLine) {
    _unsortedVariableTextLines.add(textLine);
  }
  
  void _sortPosition () {
    if(_unsortedVariableTextLines.length!=4) {
      throw Error();
    }
    Offset sumOffset = Offset(0,0);
    for (TextLine variableTextLine in _unsortedVariableTextLines) {
      sumOffset += variableTextLine.boundingBox.centerLeft;
    }
    _meanOffset = sumOffset/4;

    for (TextLine variable in _unsortedVariableTextLines) {
      if (variable.boundingBox.centerLeft.dx<_meanOffset.dx) {
        if (variable.boundingBox.centerLeft.dy<_meanOffset.dy) {
          tl = variable.boundingBox.centerLeft;
        }
        else {
          tr = variable.boundingBox.centerLeft;
        }
      }
      else {
        if (variable.boundingBox.top<_meanOffset.dy) {
          bl = variable.boundingBox.centerLeft;
        }
        else {
          br = variable.boundingBox.centerLeft;
        }
      }
    }
  }
}