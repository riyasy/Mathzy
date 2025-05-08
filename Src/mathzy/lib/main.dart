import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:mathzy/constants.dart';
import 'package:mathzy/game_logic.dart';
import 'package:mathzy/scribble_pad.dart';
import 'package:mathzy/voice_input.dart';

void main() => runApp(MathScribbleGameApp());

// Moved enum here for better top-level visibility if needed elsewhere later
enum InputMode { scribble, voice }

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



// --- GAME SCREEN WIDGET AND STATE ---
class MathScribbleGame extends StatefulWidget {
  const MathScribbleGame({super.key});
  @override
  State<MathScribbleGame> createState() => _MathScribbleGameState();
}

class _MathScribbleGameState extends State<MathScribbleGame> {
  final GameLogic _gameLogic = GameLogic();

  String question = '';
  int score = 0;
  int timeLeft = 60;
  Timer? gameTimer;
  bool _isGameActive = false;

  String feedbackText = '';
  bool _showFeedbackOverlay = false;
  bool _isAnswerCorrectForOverlay = false;
  String _correctAnswerForDisplay = "";
  late ConfettiController _confettiController;

  InputMode _currentInputMode = InputMode.scribble;
  bool _listenTrigger = false; // Used ONLY to signal VoiceInputControl

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: kConfettiDuration);
    // Child widgets handle their own init (model download, speech init)
    startGame();
  }

  void _toggleInputMode() {
    setState(() {
      if (_currentInputMode == InputMode.scribble) {
        _currentInputMode = InputMode.voice;
        if (_isGameActive) _listenTrigger = !_listenTrigger; // Trigger voice
      } else {
        _currentInputMode = InputMode.scribble;
        // Voice stopping is handled by VoiceInputControl's didUpdateWidget or dispose
      }
      feedbackText = "";
      _correctAnswerForDisplay = ""; // Clear feedback
    });
  }

  void startGame() {
    if (!mounted) return;
    setState(() {
      _isGameActive = true;
      timeLeft = 60;
      score = 0;
      feedbackText = '';
      _correctAnswerForDisplay = '';
      _showFeedbackOverlay = false;
      _listenTrigger = false; // Reset trigger explicitly
    });
    _generateAndSetQuestion();

    gameTimer?.cancel();
    gameTimer = Timer.periodic(Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          t.cancel();
          _isGameActive = false;
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder:
                  (_) => AlertDialog(
                    title: Text('Game Over!'),
                    content: Text('Your Score: $score'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          resetGame();
                        },
                        child: Text('Restart'),
                      ),
                    ],
                  ),
            );
          }
        }
      });
    });
  }

  void resetGame() {
    if (!mounted) return;
    gameTimer?.cancel();
    setState(() {
      _isGameActive = false;
      timeLeft = 60;
      score = 0;
      question = '';
      feedbackText = '';
      _correctAnswerForDisplay = '';
      _showFeedbackOverlay = false;
      _listenTrigger = false;
    });
    startGame();
  }

  void _generateAndSetQuestion() {
    final newQuestion = _gameLogic.generateQuestion();
    setState(() {
      question = newQuestion;
      feedbackText = '';
      _correctAnswerForDisplay = '';
      if (_currentInputMode == InputMode.voice) {
        _listenTrigger = !_listenTrigger; // Toggle trigger for voice control
      }
    });
  }

  void _handleSubmission(String answer) {
    if (!mounted || !_isGameActive) return;
    if (answer.isEmpty || answer == '?') {
      setState(() {
        feedbackText = "Input unclear";
      });
      Future.delayed(kMainFeedbackClearDelay, () {
        if (mounted) setState(() => feedbackText = '');
      });
      if (_currentInputMode == InputMode.voice) {
        setState(() => _listenTrigger = !_listenTrigger); // Retry listen
      }
      return;
    }

    bool isCorrect = _gameLogic.checkAnswer(question, answer);
    _isAnswerCorrectForOverlay = isCorrect;
    _correctAnswerForDisplay = "";
    if (isCorrect) {
      _confettiController.play();
    } else {
      _correctAnswerForDisplay = _gameLogic.calculateCorrectAnswer(question);
    }

    setState(() {
      _showFeedbackOverlay = true;
      feedbackText = "Submitted: $answer"; // Simplified feedback text
      if (isCorrect) {
        score++;
      }
      if (_isGameActive) {
        _generateAndSetQuestion();
      }
    });

    Future.delayed(kFeedbackOverlayDisplayDuration, () {
      if (mounted) {
        setState(() {
          _showFeedbackOverlay = false;
        });
      }
    });
    Future.delayed(kMainFeedbackClearDelay, () {
      if (mounted) {
        setState(() {
          feedbackText = '';
          _correctAnswerForDisplay = '';
        });
      }
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _confettiController.dispose();
    // Child widgets handle their own disposals
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mathzy'),
        actions: [
          IconButton(
            icon: Icon(
              _currentInputMode == InputMode.scribble ? Icons.mic : Icons.edit,
            ),
            tooltip:
                _currentInputMode == InputMode.scribble
                    ? 'Switch to Voice Input'
                    : 'Switch to Scribble Input',
            onPressed: _toggleInputMode,
          ),
        ],
      ),
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
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.monetization_on,
                                    color: Colors.amber,
                                    size: 28,
                                  ),
                                  SizedBox(width: 4),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder:
                                        (
                                          Widget child,
                                          Animation<double> animation,
                                        ) => ScaleTransition(
                                          scale: animation,
                                          child: child,
                                        ),
                                    child: Text(
                                      '$score',
                                      key: ValueKey<int>(score),
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Flexible(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Dot indicator removed, rely on blob below
                                    Icon(
                                      Icons.timer_outlined,
                                      color:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color,
                                      size: 28,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '$timeLeft s',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            timeLeft < 10
                                                ? Colors.redAccent
                                                : Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        if (_isGameActive || question.isNotEmpty)
                          Text(
                            question,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        SizedBox(height: 10),
                        Container(
                          height: 50,
                          alignment: Alignment.center,
                          child:
                              (_showFeedbackOverlay || feedbackText.isEmpty)
                                  ? SizedBox.shrink()
                                  : Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            feedbackText,
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.blueGrey,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        if (_correctAnswerForDisplay.isNotEmpty)
                                          Flexible(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                top: 2.0,
                                              ),
                                              child: Text(
                                                "Correct: $_correctAnswerForDisplay",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.orange[700],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                textAlign: TextAlign.center,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 6,
                child:
                    _currentInputMode == InputMode.scribble
                        ? ScribbleInputControl(
                          isActive: _isGameActive,
                          onSubmit: _handleSubmission,
                        )
                        : VoiceInputControl(
                          isActive: _isGameActive,
                          listenTrigger: _listenTrigger,
                          onSubmit: _handleSubmission,
                        ),
              ),
            ],
          ),
          if (_showFeedbackOverlay)
            AnimatedOpacity(
              opacity: _showFeedbackOverlay ? 1.0 : 0.0,
              duration: Duration(milliseconds: 300),
              child: Container(
                color:
                    _isAnswerCorrectForOverlay
                        ? Colors.green.withValues(alpha:0.7)
                        : Colors.red.withValues(alpha:0.7),
                child: Center(
                  child: Padding(
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
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (!_isAnswerCorrectForOverlay &&
                            _correctAnswerForDisplay.isNotEmpty)
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                "Answer was: $_correctAnswerForDisplay",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white70,
                                ),
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
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
              gravity: 0.3,
              emissionFrequency: 0.05,
              numberOfParticles: 10,
            ),
          ),
        ],
      ),
    );
  }
}
