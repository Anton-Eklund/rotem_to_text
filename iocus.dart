// ignore_for_file: avoid_print

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:ui';

class Rotem {
  //Maximum rotation of image is ~45 deg.


  Rotem ({required RecognizedText recognizedText}) {
    //testMissing(recognizedText);
    _initAnalyses();
    _initVariables();
    _resolveRecognizedText(recognizedText);
    if(!_setMainReferencePoints()) {return;}
    _sortVariableOffsets();
    if(!_constructMissingVariableOffsets()) {return;}
    _allocateResults();
    _printResults();
    _identifyMissingResults ();
    // Vad sen?




    // Hantera null hos krävda värden, tex Intem och Heptem
 
  }

  // Temp for testing purposes
  void testMissing(RecognizedText recognizedText) {
    for(TextBlock block in recognizedText.blocks) {
      for(TextLine textLine in block.lines) {
        if(textLine.text.contains("68")) {
          print(textLine.text);
        }
      }
    }
  }

  // Definition of analyses in list of lists with (0) shorthand, (1) name, (2) regExpString, (3) outerPosition
  static const analysesDefinitions = [
      <dynamic>['fibtem','FIBTEM',r'^FIBTEM', OuterPositionsEnum.tl],
      <dynamic>['intem','INTEM',r'^INTEM',OuterPositionsEnum.bl],
      <dynamic>['extem','EXTEM',r'^EXTEM',OuterPositionsEnum.tr],
      <dynamic>['heptem','HEPTEM',r'^HEPTEM',OuterPositionsEnum.br]  
    ];
  
  // Init analyses and positions
  late final Map<String, Analysis> analysesByName;
  late final Map<OuterPositionsEnum,Analysis> analysesByPosition;
  void _initAnalyses () { 
    analysesByName = {};
    analysesByPosition = {};
    for (List<dynamic> analysisDefinition in analysesDefinitions) {
      final Analysis analysis = Analysis(name: analysisDefinition[1], regExpString: analysisDefinition[2], outerPositionsEnum: analysisDefinition[3]);
      analysesByName[analysisDefinition[0]] = analysis;
      analysesByPosition[analysisDefinition[3]] = analysis;
    }
  }

  // Definition of variables in list of lists with (0) shorthand, (1) name, (2) regExpString, (3) innerPosition
  static const variablesDefinitions = [
    <dynamic>['rt','Run time',r'^RT: ?\d{2}:\d{2}:\d{2}',0,'hh:mm:ss'],
    <dynamic>['ct','CT',r'CT',1,'s'],
    <dynamic>['a5','A5',r'A5',2,'mm'],
    <dynamic>['a10','A10',r'A10',3,'mm'],
    <dynamic>['a20','A20',r'A20',4,'mm'],
    <dynamic>['mcf','MCF',r'MCF',5,'mm'],
    <dynamic>['ml','ML',r'ML',6,'%'],
    <dynamic>['a30','A30',r'A30',7,'mm'],
  ];

  // Init variables according to variableDefinitions
  late final Map<int,Variable> _variablesByPosition;
  void _initVariables () {
    _variablesByPosition = {};
    for (List<dynamic> variableDefinition in variablesDefinitions) {
      final Variable variable = Variable(name: variableDefinition[1], regExpString: variableDefinition[2], position: variableDefinition[3]);
      _variablesByPosition[variableDefinition[3]] = variable;
    }
  }

  // RegExps to match all result lines
  List<RegExp> regExpForResults = [
    RegExp(r'^RT: ?(?<hours>\d{2}):(?<minutes>\d{2}):(?<seconds>\d{2})'),
    RegExp(r'^(?<int>\d{1,3}) ?(?<unit>s|(?:5(?: |$)))'), 
    RegExp(r'^(?<int>\d{1,3}) ?(?<unit>mm)'),
    RegExp(r'^(?<int>\d{1,3}) ?(?<unit>%)'),
  ];

  // Resolve type of recognized text (Result, Variable name or Analysis header) and allocate accordingly
  late final List<Result> _unsortedResults;
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
        for(Variable variable in _variablesByPosition.values) {
          if(variable.regExp.hasMatch(line.text)) {
            //print('          Match found in variables with ${variable.regExp.pattern}');
            variable._unsortedVariableTextLines.add(line);
            matchFound = true;
            break;
          }
        }
        for(Analysis analysis in analysesByPosition.values) {
          if(analysis.regExp.hasMatch(line.text)) {
            //print('          Match found in variables with ${variable.regExp.pattern}');
            analysis.analysisHeaderOffset = line.boundingBox.centerLeft;
            matchFound = true;
            break;
          }
        }
        if(!matchFound) {
          //print('     Text to trash: ${line.text} ');
        }
      }
    }
    //i++;
  }
  
  // Set reference offsets for sorting of offsets. Returns false if not possible to set reference.
  late Map<String,Offset> referenceOffsets;
  bool _setMainReferencePoints () {
    referenceOffsets = {};
    try  {
      if (analysesByPosition[OuterPositionsEnum.bl]!.analysisHeaderOffset == null ){
        throw Exception('Missing position of ${analysesByPosition[OuterPositionsEnum.bl]!.name} header, which is needed for analysis of ROTEM image');
      }
      if (analysesByPosition[OuterPositionsEnum.br]!.analysisHeaderOffset == null ){
        throw Exception('Missing position of ${analysesByPosition[OuterPositionsEnum.br]!.name} header, which is needed for analysis of ROTEM image');
      }
    }
    catch (e) {
      print(e);
      return false;
    }
    referenceOffsets['L'] = analysesByPosition[OuterPositionsEnum.bl]!.analysisHeaderOffset;
    referenceOffsets['R'] = analysesByPosition[OuterPositionsEnum.br]!.analysisHeaderOffset;
    referenceOffsets['C'] = (referenceOffsets['L']!+referenceOffsets['R']!)/2;
    return true;
  }

  void _sortVariableOffsets () {
    for(Variable variable in _variablesByPosition.values) {
      for (TextLine variableTextLine in variable._unsortedVariableTextLines) {
        if (variableTextLine.boundingBox.centerLeft.dx<referenceOffsets['C']!.dx) {
          if (variableTextLine.boundingBox.centerLeft.dy<referenceOffsets['L']!.dy) {
            analysesByPosition[OuterPositionsEnum.tl]!.variableHeaderOffsets[variable] = variableTextLine.boundingBox.centerLeft;
          }
          else {
            analysesByPosition[OuterPositionsEnum.bl]!.variableHeaderOffsets[variable] = variableTextLine.boundingBox.centerLeft;
          }
        }
        else {
          if (variableTextLine.boundingBox.top<referenceOffsets['R']!.dy) {
            analysesByPosition[OuterPositionsEnum.tr]!.variableHeaderOffsets[variable] = variableTextLine.boundingBox.centerLeft;
          }
          else {
            analysesByPosition[OuterPositionsEnum.br]!.variableHeaderOffsets[variable] = variableTextLine.boundingBox.centerLeft;
          }
        }
      }
    }
  }

  // Constructs new variableHeader offsets for missing recognition. Special case for position 0 (RT).
  bool _constructMissingVariableOffsets () {
    for(Analysis analysis in analysesByPosition.values) {
      if (analysis.variableHeaderOffsets.length==_variablesByPosition.length) {
        // print('Analysis ${analysis.name}: All positions found');
        continue;
      }
      else {
        // print('Analysis ${analysis.name}: Too few positions (${analysis.variableHeaderOffsets.length}/${_variablesByPosition.length}) found');
        List<Variable> toBeCreated = [];
        dynamic topPivot;
        dynamic bottomPivot;
        // Check for position 0 which Offset is irregular
        if (!analysis.variableHeaderOffsets.containsKey(_variablesByPosition[0])){ 
          toBeCreated.add(_variablesByPosition[0]!);
        }
        for (int position = 1; position<_variablesByPosition.length; position++) {
          final variable = _variablesByPosition[position]!;
          if (analysis.variableHeaderOffsets.containsKey(variable)){
            // Varaiable found. Set as top pivot if still null. Set as last pivot.
            if(topPivot == null) {
              topPivot = variable;
            }
            else {
              bottomPivot = variable;
            }  
          }
          else {
            toBeCreated.add(variable);
          }
        }
        if (bottomPivot == null) {
          
          try {
            analysis.active = false;
            throw Exception('Analysis ${analysis.name}: Not enough positions (${analysis.variableHeaderOffsets.length}/${_variablesByPosition.length}) to extrapolate on!');
          }
          catch (e) {
            print(e);
          }
          return false;
        }
        else {
          final int pivotDistance = bottomPivot.position-topPivot.position;
          for (Variable variable in toBeCreated) {
            final int topTargetDistance = variable.position-topPivot.position as int;
            double quotient = topTargetDistance/pivotDistance;
            if (variable.position==0) {
              quotient -= 0.4;
            }
            analysis.variableHeaderOffsets[variable] = Offset.lerp(analysis.variableHeaderOffsets[topPivot],analysis.variableHeaderOffsets[bottomPivot],quotient)!;      
          }
        }
      }
    }
    return true;
  }
  
  // Allocate results to their specific analysis
  late final Map<Analysis,List<Result>> resultsByAnalysis;
  void _allocateResults () {
    // Initiate resultsByAnalysis map and add lists for all analyses
    Map<Analysis,List<Result>> resultsByAnalysis = {};
    for(Analysis analysis in analysesByPosition.values) {
      resultsByAnalysis[analysis]=[];
    }

    // Allocate to analaysis by Offset
    for(Result unsortedResult in _unsortedResults) {
      if(unsortedResult.offset.dx<referenceOffsets['C']!.dx) {
        if(unsortedResult.offset.dy<referenceOffsets['L']!.dy) {
          resultsByAnalysis[analysesByPosition[OuterPositionsEnum.tl]]!.add(unsortedResult);
        }
        else {
          resultsByAnalysis[analysesByPosition[OuterPositionsEnum.bl]]!.add(unsortedResult);
        }   
      }
      else {
        if(unsortedResult.offset.dy<referenceOffsets['R']!.dy) {
          resultsByAnalysis[analysesByPosition[OuterPositionsEnum.tr]]!.add(unsortedResult);
        }
        else {
          resultsByAnalysis[analysesByPosition[OuterPositionsEnum.br]]!.add(unsortedResult);
        }  
      }
    }

    for(Analysis analysis in analysesByPosition.values) {
      //print(analysis.name);
      //print(resultsByAnalysis[analysis].toString());
      resultsByAnalysis[analysis]!.sort((a,b) => a.offset.dy.compareTo(b.offset.dy));
      //print(resultsByAnalysis[analysis].toString());
      if(resultsByAnalysis[analysis]!.length == analysis.variableHeaderOffsets.length) {
        for (MapEntry entry in _variablesByPosition.entries) {
          analysis.results[entry.value] = resultsByAnalysis[analysis]![entry.key];
        }
      }
      else {
        // Generate mesh.
        List<Offset> cutoffOffsets = [];
        Map<Variable,Offset> horizontalSwitchOffsets = analysesByPosition[analysis.outerPositionsEnum.horizontalSwitch()]!.variableHeaderOffsets;
        // The estimated distance from a header to the value, divided by the distance from the header to the header of the horizontally switched analysis.
        late final double distanceQuotient;
        if (analysis.outerPositionsEnum == OuterPositionsEnum.tl || analysis.outerPositionsEnum == OuterPositionsEnum.bl) {
          distanceQuotient = 0.2;
        }
        else{
          distanceQuotient = -0.2;
        }
        for (int i = 1; i< _variablesByPosition.length; i++) {
          Variable variableBefore = _variablesByPosition[i-1]!;
          Variable variableAfter = _variablesByPosition[i]!;
          Offset meanAnalysisSide = (analysis.variableHeaderOffsets[variableBefore]!+analysis.variableHeaderOffsets[variableAfter]!)/2;
          Offset meanSwitchedAnalysisSide = (horizontalSwitchOffsets[variableBefore]!+horizontalSwitchOffsets[variableAfter]!)/2;
          cutoffOffsets.add(Offset.lerp(meanAnalysisSide, meanSwitchedAnalysisSide, distanceQuotient)!);
        }
        // Add extra cutoff in end 
        cutoffOffsets.add(cutoffOffsets.last.translate(0, 100));

        int numberOfResultAllocated = 0;
        for(int k = 0; k<_variablesByPosition.length; k++) {
          if(numberOfResultAllocated==resultsByAnalysis[analysis]!.length) {
            //No more results to allocate
            break;
          }
          if(resultsByAnalysis[analysis]![numberOfResultAllocated].offset.dy<cutoffOffsets[k].dy) {
            analysis.results[_variablesByPosition[k]!] = resultsByAnalysis[analysis]![numberOfResultAllocated];
            numberOfResultAllocated++;
          }   
        }
      }
    }
  } 

  void _printResults() {
    for (Analysis analysis in analysesByPosition.values) {
      analysis.printAllResults();
    }
  }

  void _identifyMissingResults () {
    for(Analysis analysis in analysesByPosition.values) {
      if(analysis.results.length==analysis.variableHeaderOffsets.length) {
        // Results available for all analyses
        // print('${analysis.name}: No missing results');
        continue;
      }
      final dynamic runTime = analysis.results[_variablesByPosition[0]];

      if (runTime == null) {
        analysis.missingResults.add(_variablesByPosition[0]!);
        // Missing RT => Not possible to know if other results might be missing
      } 
      if (!analysis.results.containsKey(_variablesByPosition[1])) {
        analysis.missingResults.add(_variablesByPosition[1]!);
      }
      if (runTime != null && runTime.value>const Duration(minutes: 5) && !analysis.results.containsKey(_variablesByPosition[2])) {
        analysis.missingResults.add(_variablesByPosition[2]!);
      }
      if (runTime != null && runTime.value>const Duration(minutes: 10) && !analysis.results.containsKey(_variablesByPosition[3])) {
        analysis.missingResults.add(_variablesByPosition[3]!);
      }
      if (runTime != null && runTime.value>const Duration(minutes: 20) && !analysis.results.containsKey(_variablesByPosition[4])) {
        analysis.missingResults.add(_variablesByPosition[4]!);
      }
      if (!analysis.results.containsKey(_variablesByPosition[5])) {
        analysis.missingResults.add(_variablesByPosition[5]!);
      }
      if (!analysis.results.containsKey(_variablesByPosition[6])) {
        analysis.missingResults.add(_variablesByPosition[6]!);
      }
      if (runTime != null && runTime.value>const Duration(minutes: 30) && !analysis.results.containsKey(_variablesByPosition[7])) {
        analysis.missingResults.add(_variablesByPosition[7]!);
      }
      
      if(analysis.missingResults.isEmpty) {
        // Results available for all analyses
        // print('${analysis.name}: No missing results');
        continue;
      }
      else {
        try {
          String e = '${analysis.name} missing results for: ';
          for(Variable variable in analysis.missingResults) {
            e += '${variable.name}, ';
          }
          throw Exception(e);
        }
        catch (e) {
          print(e);
        }
      }
    }
  }





}

class Analysis {

  Analysis({required this.name, required String regExpString, required this.outerPositionsEnum}) {
    regExp = RegExp(regExpString);// Run method
  }
  bool active = true;

  final String name;
  final OuterPositionsEnum outerPositionsEnum;
  late final RegExp regExp;

  dynamic analysisHeaderOffset;
  final Map<Variable,Offset> variableHeaderOffsets = {};

  final Map<Variable,Result> results = {};
  final List<Variable> missingResults = [];

  void printAllResults() {
    print(name);
    for(MapEntry entry in results.entries) {
      print('   ${entry.key.name}: ${entry.value.toString()}');
    } 
    print('');
  }
}

class Variable {

  final String name;
  late final RegExp regExp;
  final int position;

  final List <TextLine> _unsortedVariableTextLines = <TextLine>[];

  Variable({required this.name, required String regExpString, required this.position}) {
    regExp = RegExp(regExpString);// Run method
  }

  void addTextLine (TextLine textLine) {
    // Add variableTextLine to unsorted list
    _unsortedVariableTextLines.add(textLine);
  }
  
}

enum OuterPositionsEnum {
  tl('Top left'),
  bl('Bottom left'),
  tr('Top right'),
  br('Bottom right');

  final String value;
  const OuterPositionsEnum(this.value);

  OuterPositionsEnum horizontalSwitch() {
    switch (this) {
      case tl:
        return OuterPositionsEnum.tr;
      case bl:
        return OuterPositionsEnum.br;
      case tr:
        return OuterPositionsEnum.tl;
      case br:
        return OuterPositionsEnum.bl;
      default:
        return throw Error();    
    }
  }
}

class Result {
  late final dynamic value;
  late final String unit;
  late final Offset offset;
  Result({required RegExpMatch regExpMatch, required TextLine textLine}) {
    offset = textLine.boundingBox.centerLeft;
    switch( regExpMatch.groupCount) {
      case 2:
        value = int.tryParse(regExpMatch.namedGroup('int')!);
        unit = regExpMatch.namedGroup('unit')!;
      case 3:
        value = Duration(
          hours: int.parse(regExpMatch.namedGroup('hours')!),
          minutes: int.parse(regExpMatch.namedGroup('minutes')!), 
          seconds: int.parse(regExpMatch.namedGroup('seconds')!));
          unit = "hh:mm:ss";  
    }
    
  }

  @override
  String toString() {
    // TODO: implement toString
    return '$value $unit';
  }
}