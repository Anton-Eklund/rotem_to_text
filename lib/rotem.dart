import 'dart:ffi';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:ui';

class Rotem {
  //Maximum rotation of image is ~45 deg.


  Rotem ({required RecognizedText recognizedText}) {
    testMissing(recognizedText);
    _initAnalyses();
    _initVariables();
    _resolveRecognizedText(recognizedText);
    _allocateVariableOffset();
    _allocateResults();
    // Vad sen?




    // Hantera null hos krävda värden, tex Intem och Heptem
 
  }

  void testMissing(RecognizedText recognizedText) {
    for(TextBlock block in recognizedText.blocks) {
      for(TextLine textLine in block.lines) {
        if(textLine.text.contains("52")) {
          print(textLine.text);
        }
      }
    }
  }

   
  static const analysesDefinitions = [
    // List of Lists with (0) shorthand, (1) name, (2) regExpString, (3) outerPosition
      <dynamic>['fibtem','FIBTEM',r'^FIBTEM', OuterPositionsEnum.tl],
      <dynamic>['intem','INTEM',r'^INTEM',OuterPositionsEnum.bl],
      <dynamic>['extem','EXTEM',r'^EXTEM',OuterPositionsEnum.tr],
      <dynamic>['heptem','HEPTEM',r'^HEPTEM',OuterPositionsEnum.br]  
    ];
  
  late final Map<String, Analysis> analysesByName;
  late final Map<OuterPositionsEnum,Analysis> analysesByPosition;
  
  void _initAnalyses () {
    // Init analyses and positions
    analysesByName = {};
    analysesByPosition = {};
    for (List<dynamic> analysisDefinition in analysesDefinitions) {
      final Analysis analysis = Analysis(name: analysisDefinition[1], regExpString: analysisDefinition[2]);
      analysesByName[analysisDefinition[0]] = analysis;
      analysesByPosition[analysisDefinition[3]] = analysis;
    }
  }

  

  static const variablesDefinitions = [
    // List of Lists with (0) shorthand, (1) name, (2) regExpString, (3) innerPosition
    <dynamic>['analyses','Analyses',r'^(?:FIB)|(?:IN)|(?:EX)|(?:HEP)TEM',0,null],
    <dynamic>['rt','Run time',r'^RT: ?\d{2}:\d{2}:\d{2}',1,null],
    <dynamic>['ct','CT',r'CT',2,'s'],
    <dynamic>['a5','A5',r'A5',3,'mm'],
    <dynamic>['a10','A10',r'A10',4,'mm'],
    <dynamic>['a20','A20',r'A20',5,'mm'],
    <dynamic>['mcf','MCF',r'MCF',6,'mm'],
    <dynamic>['ml','ML',r'ML',7,'%'],
    <dynamic>['a30','A30',r'A30',8,'mm'],
  ];

  late final Map<String, Variable> _variablesByName;
  late final Map<int,Variable> _variablesByPosition;
  
  void _initVariables () {
    // Init variables
    _variablesByName = {};
    _variablesByPosition = {};
    for (List<dynamic> variableDefinition in variablesDefinitions) {
      final Variable variable = Variable(name: variableDefinition[1], regExpString: variableDefinition[2], variablePosition: variableDefinition[3]);
      _variablesByName[variableDefinition[0]] = variable;
      _variablesByPosition[variableDefinition[3]] = variable;
    }
  }

  
  
  late final List<Result> _unsortedResults;
  
  // RegExps to match all result lines
  List<RegExp> regExpForResults = [
    RegExp(r'^RT: ?(?<hours>\d{2}):(?<minutes>\d{2}):(?<seconds>\d{2})'),
    RegExp(r'^(?<int>\d{1,3}) ?(?:s|(?:5(?: |$)))'), 
    RegExp(r'^(?<int>\d{1,3}) ?mm'),
    RegExp(r'^(?<int>\d{1,3}) ?%'),
  ];
  

  // Resolve position of recognized text
  void _resolveRecognizedText (RecognizedText recognizedText) {
    _unsortedResults = <Result>[];
    // int i = 0;
    for(TextBlock block in recognizedText.blocks) {
      //print('Block ${i}');
      for(TextLine line in  block.lines) {
        // print('     Text: ${line.text}');
        bool matchFound = false;
        //Look for results match
        for(RegExp regExp in regExpForResults) {
          final match = regExp.firstMatch(line.text);
          // print('      Match: ${match.toString()}');
          if(match != null) {
            Result result = Result(regExpMatch: match, textLine: line);
            //print('          Match found in results with ${regExp.pattern}: ${result.result}');
            _unsortedResults.add(result);
            matchFound = true;
            break;
          }
          else {
            //print('          No match found in results with ${regExp.pattern}');
          }
        }
/*         if(matchFound) {
          break;
        } */
        //Else look for variable match
        for(Variable variable in _variablesByName.values) {
          if(variable.regExp.hasMatch(line.text)) {
            //print('          Match found in variables with ${variable.regExp.pattern}');
            variable._unsortedVariableTextLines.add(line);
            matchFound = true;
            break;
          }
        }
        if(matchFound) {
          break;
        }
        print('     Text: ${line.text}');
        // print('No match found => Trash');
      }
    }
    //i++;
  }


  void _allocateVariableOffset () {
    for (Variable variable in _variablesByName.values) {
      variable._sortInnerPosition();
    }
  }


  void _allocateResults () {
    // Allocate results to their specific analysis and variable
    final double _dxAnalysisMiddle = (_variablesByPosition[0]!.outerPositions[OuterPositionsEnum.br]!.dx + _variablesByPosition[0]!.outerPositions[OuterPositionsEnum.bl]!.dx)/2;
    Map<OuterPositionsEnum,List<Result>> resultsSortedByAnalysis = {
      OuterPositionsEnum.tl:<Result>[],
      OuterPositionsEnum.bl:<Result>[],
      OuterPositionsEnum.tr:<Result>[],
      OuterPositionsEnum.br:<Result>[]
    };
    for(Result unsortedResult in _unsortedResults) {
      if(unsortedResult.offset.dx<_dxAnalysisMiddle) {
        if(unsortedResult.offset.dy<_variablesByPosition[0]!.outerPositions[OuterPositionsEnum.bl]!.dy) {
          resultsSortedByAnalysis[OuterPositionsEnum.tl]!.add(unsortedResult);
        }
        else {
          resultsSortedByAnalysis[OuterPositionsEnum.bl]!.add(unsortedResult);
        }   
      }
      else {
        if(unsortedResult.offset.dy<_variablesByPosition[0]!.outerPositions[OuterPositionsEnum.br]!.dy) {
          resultsSortedByAnalysis[OuterPositionsEnum.tr]!.add(unsortedResult);
        }
        else {
          resultsSortedByAnalysis[OuterPositionsEnum.br]!.add(unsortedResult);
        }  
      }
    }
    print('Results allocated to each analysis but not to the specific variable');
  } 





}

class Analysis {

  Analysis({required this.name, required String regExpString}) {
    regExp = RegExp(regExpString);// Run method
  }

  late final RegExp regExp;

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
  final int _variablePosition;
  final List <TextLine> _unsortedVariableTextLines = <TextLine>[];
  late final RegExp regExp;

  final Map<OuterPositionsEnum,Offset> outerPositions = {};

  Variable({required this.name, required String regExpString, required int variablePosition}) : _variablePosition = variablePosition {
    regExp = RegExp(regExpString);// Run method
  }

  void addTextLine (TextLine textLine) {
    _unsortedVariableTextLines.add(textLine);
  }
  
  void _sortInnerPosition () {
    if(_unsortedVariableTextLines.length!=4) {
      print('Too few positions (${_unsortedVariableTextLines.length}) found for variable $name');
      //throw Error();
    }
    Offset sumOffset = Offset(0,0);
    for (TextLine variableTextLine in _unsortedVariableTextLines) {
      sumOffset += variableTextLine.boundingBox.centerLeft;
    }
    final Offset meanOffset = sumOffset/4;

    for (TextLine variable in _unsortedVariableTextLines) {
      if (variable.boundingBox.centerLeft.dx<meanOffset.dx) {
        if (variable.boundingBox.centerLeft.dy<meanOffset.dy) {
          outerPositions[OuterPositionsEnum.tl] = variable.boundingBox.centerLeft;
        }
        else {
          outerPositions[OuterPositionsEnum.bl] = variable.boundingBox.centerLeft;
        }
      }
      else {
        if (variable.boundingBox.top<meanOffset.dy) {
          outerPositions[OuterPositionsEnum.tr] = variable.boundingBox.centerLeft;
        }
        else {
          outerPositions[OuterPositionsEnum.br] = variable.boundingBox.centerLeft;
        }
      }
    }
  }
}

enum OuterPositionsEnum {
  tl('Top left'),
  bl('Bottom left'),
  tr('Top right'),
  br('Bottom right');

  final String value;
  const OuterPositionsEnum(this.value);
}

class Result {
    late final dynamic result;
    late final Offset offset;
    Result({required RegExpMatch regExpMatch, required TextLine textLine}) {
      switch( regExpMatch.groupCount) {
        case 1:
          result = int.tryParse(regExpMatch.namedGroup('int')!);
        case 3:
          result = Duration(
            hours: int.parse(regExpMatch.namedGroup('hours')!),
            minutes: int.parse(regExpMatch.namedGroup('minutes')!), 
            seconds: int.parse(regExpMatch.namedGroup('seconds')!)
          );
      }
      offset = textLine.boundingBox.centerLeft;
    }
}