import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart' as mlkit;
import 'package:confetti/confetti.dart';

// --- DURATION CONSTANTS ---
const Duration kModelReadyDisplayDuration = Duration(milliseconds: 1000);
const Duration kModelDownloadedDisplayDuration = Duration(seconds: 1);
const Duration kFeedbackOverlayDisplayDuration = Duration(milliseconds: 500);
const Duration kMainFeedbackClearDelay = Duration(milliseconds: 1000);
const Duration kAutoSubmitDelay = Duration(milliseconds: 700);
const Duration kConfettiDuration = Duration(milliseconds: 500);
// --- END DURATION CONSTANTS ---

void main() => runApp(MathScribbleGameApp());

class MathScribbleGameApp extends StatelessWidget {
  const MathScribbleGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mathzy',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          titleTextStyle: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      home: MathScribbleGame(),
    );
  }
}

class MathScribbleGame extends StatefulWidget {
  const MathScribbleGame({super.key});

  @override
  State<MathScribbleGame> createState() => _MathScribbleGameState();
}

class _MathScribbleGameState extends State<MathScribbleGame> {
  final mlkit.DigitalInkRecognizer recognizer =
      mlkit.DigitalInkRecognizer(languageCode: 'en');
  List<Offset> points = [];
  String question = '';
  String feedbackText = '';
  int score = 0;
  int timeLeft = 60;
  Timer? gameTimer;
  bool _isModelDownloaded = false;
  bool _isGameActive = false;

  bool _showFeedbackOverlay = false;
  bool _isAnswerCorrectForOverlay = false;
  String _correctAnswerForDisplay = "";
  late ConfettiController _confettiController;

  Timer? _autoSubmitTimer;


  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: kConfettiDuration);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAndDownloadModel();
      }
    });
  }

  void _cancelAutoSubmitTimer() {
    _autoSubmitTimer?.cancel();
  }

  void _startAutoSubmitTimer() {
    _cancelAutoSubmitTimer();
    _autoSubmitTimer = Timer(kAutoSubmitDelay, () {
      bool hasActualDrawing = points.any((p) => p != Offset.zero);
      if (hasActualDrawing && _isGameActive && _isModelDownloaded) {
        onSubmit();
      }
    });
  }

  Future<void> _checkAndDownloadModel() async {
    if (!mounted) return;
    final modelManager = mlkit.DigitalInkRecognizerModelManager();
    setState(() { feedbackText = 'Initializing model...'; _isGameActive = false;});
    try {
      final isModelAvailable = await modelManager.isModelDownloaded('en');
      if (!mounted) return;
      if (isModelAvailable) {
        setState(() { _isModelDownloaded = true; feedbackText = 'Model ready!'; });
        Future.delayed(kModelReadyDisplayDuration, () {
          if (mounted) { setState(() { if (_isModelDownloaded) feedbackText = ''; }); startGame(); }
        });
      } else {
        setState(() { feedbackText = 'Downloading language model (en)...'; });
        await modelManager.downloadModel('en', isWifiRequired: false);
        if (!mounted) return;
        setState(() { _isModelDownloaded = true; feedbackText = 'Model downloaded!'; });
        Future.delayed(kModelDownloadedDisplayDuration, () {
          if (mounted) { setState(() { if (_isModelDownloaded) feedbackText = ''; }); startGame(); }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _isModelDownloaded = false; feedbackText = 'Error with model. Check connection/restart.'; _isGameActive = false; });
    }
  }

  void startGame() {
    if (!mounted) return;
    _cancelAutoSubmitTimer();
    if (!_isModelDownloaded) {
      setState(() { question = "Waiting for model..."; _isGameActive = false; });
      return;
    }
    generateQuestion();
    setState(() {
      _isGameActive = true; timeLeft = 60; score = 0;
      feedbackText = ''; _correctAnswerForDisplay = ''; _showFeedbackOverlay = false;
    });

    gameTimer?.cancel();
    gameTimer = Timer.periodic(Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          t.cancel(); _isGameActive = false;
          if (mounted) {
            _cancelAutoSubmitTimer();
            showDialog(
                context: context, barrierDismissible: false,
                builder: (_) => AlertDialog(
                      title: Text('Game Over!'), content: Text('Your Score: $score'),
                      actions: [ TextButton(onPressed: () { Navigator.pop(context); resetGame(); }, child: Text('Restart')) ],
                    ));
          }
        }
      });
    });
  }

  void resetGame() {
    if (!mounted) return;
    gameTimer?.cancel();
    _cancelAutoSubmitTimer();
    setState(() {
      timeLeft = 60; points.clear(); feedbackText = ''; question = '';
      _isGameActive = false; _showFeedbackOverlay = false; _correctAnswerForDisplay = '';
    });
    if (_isModelDownloaded) { startGame(); } else { _checkAndDownloadModel(); }
  }

  void generateQuestion() {
    final random = Random(); int x = random.nextInt(9) + 1; int y = random.nextInt(9) + 1;
    int op = random.nextInt(6);
    switch (op) {
      case 0: question = '$x ? $y'; break;
      case 1: int z = x + (random.nextInt(9) + 1); question = '$x + ? = $z'; break;
      case 2: int z = y + (random.nextInt(9) + 1); question = '? + $y = $z'; break;
      case 3: int val = random.nextInt(x); int z = x - val; question = '$x - ? = $z'; break;
      case 4: int mult = random.nextInt(5) + 1; int z = x * mult; question = '$x × ? = $z'; break;
      case 5: List<int> divs = []; for (int i=1;i<=x;i++){if(x%i==0)divs.add(i);} int d = divs.isEmpty?1:divs[random.nextInt(divs.length)]; int z = x ~/ d; question = '$x ÷ ? = $z'; break;
    }
  }

  String processCandidates(List<mlkit.RecognitionCandidate> candidates) {
    final pat = RegExp(r'^[0-9<=>]+$');
    final map = {'Z':'2','z':'2','S':'5','s':'5','O':'0','o':'0','L':'1','l':'1','I':'1','i':'1','B':'8','b':'8','G':'9','g':'9','q':'9',};
    String best = ""; double bestScr = -1.0;
    for (var c in candidates) {
      String orig = c.text; String proc = "";
      if (orig.length == 1) { proc = map[orig] ?? orig; }
      else { StringBuffer sb = StringBuffer(); for (int i=0;i<orig.length;i++){sb.write(map[orig[i]]??orig[i]);} proc = sb.toString(); }
      if (pat.hasMatch(proc)) {
        double curScr = c.score;
        if (curScr > bestScr) { bestScr = curScr; best = proc; }
        else if (best.isEmpty && curScr == bestScr) { best = proc; }
      }
    }
    if (best.isEmpty && candidates.isNotEmpty) { if(pat.hasMatch(candidates.first.text)){ best = candidates.first.text;}}
    return best.isEmpty ? '?' : best;
  }

  String calculateCorrectAnswer() {
    final parts = question.split(' '); if (parts.isEmpty) return "";
    try {
      if (parts.length == 3 && parts[1] == '?') {
        int x = int.parse(parts[0]); int y = int.parse(parts[2]);
        if (x < y) return "<"; if (x > y) return ">"; if (x == y) return "=";
      } else if (parts.length == 5) {
        if (parts[0] == '?') {
          int y = int.parse(parts[2]); String op = parts[1]; int z = int.parse(parts[4]);
          if (op == '+') return (z - y).toString();
        } else if (parts[2] == '?') {
          int x = int.parse(parts[0]); String op = parts[1]; int z = int.parse(parts[4]);
          if (op == '+') return (z - x).toString(); if (op == '-') return (x - z).toString();
          if (op == '×') { if (x == 0) return z == 0 ? "any" : "none"; return (z ~/ x).toString(); }
          if (op == '÷') { if (z == 0) return "none if x!=0"; return (x ~/ z).toString(); }
        }
      }
    } catch (e) { return ""; } return "";
  }

  Future<void> onSubmit() async {
    _cancelAutoSubmitTimer();
    if (points.isEmpty || !_isModelDownloaded || !_isGameActive) return;
    bool hasActualDrawing = points.any((p) => p != Offset.zero);
    if (!hasActualDrawing) { return; }

    final ink = mlkit.Ink(); var stroke = mlkit.Stroke();
    for (var p in points) {
      if (p != Offset.zero) { stroke.points.add(mlkit.StrokePoint(x: p.dx, y: p.dy, t: DateTime.now().millisecondsSinceEpoch)); }
      else { if (stroke.points.isNotEmpty) { ink.strokes.add(stroke); stroke = mlkit.Stroke(); }}
    }
    if (stroke.points.isNotEmpty) { ink.strokes.add(stroke); }
    if (ink.strokes.isEmpty) {
      if (mounted) setState(() { feedbackText = 'Draw something to submit.'; });
      Future.delayed(Duration(milliseconds: 1200), () { if (mounted) setState(() => feedbackText = ''); });
      return;
    }

    final candidates = await recognizer.recognize(ink);
    String recognizedAndProcessed = processCandidates(candidates.isNotEmpty ? candidates : []);
    if (!mounted) return;
    bool isCorrect = checkAnswer(recognizedAndProcessed);
    _isAnswerCorrectForOverlay = isCorrect; _correctAnswerForDisplay = "";
    if (isCorrect) { _confettiController.play(); } else { _correctAnswerForDisplay = calculateCorrectAnswer(); }

    setState(() {
      _showFeedbackOverlay = true; feedbackText = recognizedAndProcessed;
      if (isCorrect) { score++; }
      points.clear();
      if (_isGameActive) { generateQuestion(); }
    });

    Future.delayed(kFeedbackOverlayDisplayDuration, () {
      if (mounted) setState(() { _showFeedbackOverlay = false; });
    });
    Future.delayed(kMainFeedbackClearDelay, () {
      if (mounted) setState(() { feedbackText = ''; _correctAnswerForDisplay = ''; });
    });
  }

  bool checkAnswer(String recognized) {
    final parts = question.split(' '); String cleaned = recognized;
    try {
      if (parts.length == 3 && parts[1] == '?') {
        int x = int.parse(parts[0]); int y = int.parse(parts[2]);
        if (cleaned == '<' && x < y) return true; if (cleaned == '>' && x > y) return true; if (cleaned == '=' && x == y) return true;
      } else if (parts.length == 5) {
        int? val = int.tryParse(cleaned); if (val == null) return false;
        if (parts[0] == '?') {
          int y = int.parse(parts[2]); String op = parts[1]; int z = int.parse(parts[4]);
          if (op == '+') return (val + y) == z;
        } else if (parts[2] == '?') {
          int x = int.parse(parts[0]); String op = parts[1]; int z = int.parse(parts[4]);
          if (op == '+') return (x + val) == z; if (op == '-') return (x - val) == z;
          if (op == '×') return (x * val) == z;
          if (op == '÷') return (val != 0 && x % val == 0 && x ~/ val == z);
        }
      }
    } catch (e) { return false; } return false;
  }

  void _handlePanStart(DragStartDetails details) {
    _cancelAutoSubmitTimer();
    if (!_isGameActive && points.isEmpty && !_isModelDownloaded) return;
    if (!_isGameActive && _isModelDownloaded && points.isEmpty) return;
    setState(() { points.add(details.localPosition); });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _cancelAutoSubmitTimer();
    if (!_isGameActive && points.isEmpty && !_isModelDownloaded) return;
    if (!_isGameActive && _isModelDownloaded && points.isEmpty) return;
    setState(() { points.add(details.localPosition); });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (points.isNotEmpty && points.last != Offset.zero) {
      points.add(Offset.zero);
    }
    bool hasActualDrawing = points.any((p) => p != Offset.zero);
    if (hasActualDrawing && _isGameActive && _isModelDownloaded) {
      _startAutoSubmitTimer();
    }
  }

  @override
  void dispose() {
    recognizer.close();
    gameTimer?.cancel();
    _autoSubmitTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Math Scribble Game')),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                 child: Padding(
                   padding: const EdgeInsets.all(8.0),
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Padding(
                         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                         child: Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             Row(children: [
                                 Icon(Icons.monetization_on, color: Colors.amber, size: 28),
                                 SizedBox(width: 4),
                                 AnimatedSwitcher( duration: const Duration(milliseconds: 300),
                                   transitionBuilder: (Widget child, Animation<double> animation) => ScaleTransition(scale: animation, child: child),
                                   child: Text('$score', key: ValueKey<int>(score), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                                 ), ], ),
                             Row(children: [
                                 Icon(Icons.timer_outlined, color: Theme.of(context).textTheme.bodyLarge?.color, size: 28),
                                 SizedBox(width: 4),
                                 Text('$timeLeft s', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: timeLeft < 10 ? Colors.redAccent : Theme.of(context).textTheme.bodyLarge?.color)),
                             ],),
                           ],),),
                       SizedBox(height: 10),
                       if (_isGameActive || question.isNotEmpty)
                         Text(question, style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                       SizedBox(height: 10),
                       Container( height: 50, alignment: Alignment.center,
                         child: (_showFeedbackOverlay || feedbackText.isEmpty) ? SizedBox.shrink()
                             : Padding( padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                 child: Column( mainAxisSize: MainAxisSize.min, children: [
                                     Text("You wrote: $feedbackText", style: TextStyle(fontSize: 18, color: Colors.blueGrey, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                                     if (_correctAnswerForDisplay.isNotEmpty)
                                       Flexible(child: Padding( padding: const EdgeInsets.only(top: 4.0), child: Text("Correct: $_correctAnswerForDisplay", style: TextStyle(fontSize: 16, color: Colors.orange[700], fontWeight: FontWeight.w500)))),
                                   ],),),),
                     ],),),),),
              Expanded(
                flex: 6,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    WidgetsBinding.instance.addPostFrameCallback((_) { if(mounted) { }});
                    return GestureDetector(
                      onPanStart: _handlePanStart,
                      onPanUpdate: _handlePanUpdate,
                      onPanEnd: _handlePanEnd,
                      behavior: HitTestBehavior.opaque,
                      child: CustomPaint(
                        foregroundPainter: ScribblePainter(points),
                        child: Container(
                          width: constraints.maxWidth, height: constraints.maxHeight,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(top: BorderSide(color: Colors.blueGrey.shade300, width: 1)),
                          ),
                        ),),);},),),
            ],),
          if (_showFeedbackOverlay)
            AnimatedOpacity(
              opacity: _showFeedbackOverlay ? 1.0 : 0.0,
              duration: Duration(milliseconds: 300),
              child: Container(
                color: _isAnswerCorrectForOverlay
                    ? Colors.green.withValues(alpha:0.7)
                    : Colors.red.withValues(alpha:0.7),
                child: Center(
                  child: Padding( // Added padding around the content
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isAnswerCorrectForOverlay
                              ? Icons.check_circle_outline
                              : Icons.cancel_outlined,
                          color: Colors.white,
                          size: 100,
                        ),
                        SizedBox(height: 20),
                        Text(
                          _isAnswerCorrectForOverlay ? "CORRECT!" : "INCORRECT",
                          style: TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        if (!_isAnswerCorrectForOverlay &&
                            _correctAnswerForDisplay.isNotEmpty)
                          Flexible( // Make this text flexible
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                "Answer was: $_correctAnswerForDisplay",
                                style: TextStyle(
                                    fontSize: 20, color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Align( alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController, blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false, colors: const [ Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple ],
              gravity: 0.3, emissionFrequency: 0.05, numberOfParticles: 15,
            ),),
        ],),);
  }
}

class ScribblePainter extends CustomPainter {
  final List<Offset> points;
  ScribblePainter(this.points);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint() ..color = Colors.black ..strokeWidth = 5.0 ..strokeCap = StrokeCap.round ..strokeJoin = StrokeJoin.round;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.zero && points[i + 1] != Offset.zero) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant ScribblePainter oldDelegate) => oldDelegate.points != points || oldDelegate.points.length != points.length;
}