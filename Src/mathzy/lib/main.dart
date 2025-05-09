// main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mathzy/constants.dart';
import 'package:mathzy/game_logic.dart';
import 'package:mathzy/screen_highscore.dart';
import 'package:mathzy/service_preferences.dart';
import 'package:mathzy/control_scribble_pad.dart';
import 'package:mathzy/control_voice_input.dart';
import 'package:mathzy/service_highscores.dart';
import 'package:mathzy/screen_welcome.dart';
// For kPlaceholderAvatars/kAvatarAssetPaths and kAppCountries
import 'package:mathzy/control_player_profile_bar.dart'; // Import the new widget

// ... (keep constants and main() function as is) ...
const int kTargetCorrectAnswers = 10;
const Duration kStopwatchTickDuration = Duration(milliseconds: 50);
const String kInitialInstructionText = "Press Start to Play!";

final PreferencesService _preferencesService = PreferencesService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await _preferencesService.resetFirstRun(); // For testing
  bool showWelcomeScreen = await _preferencesService.isFirstRun();
  runApp(MathScribbleGameApp(showWelcomeScreen: showWelcomeScreen));
}

enum InputMode { scribble, voice }

class MathScribbleGameApp extends StatelessWidget {
  final bool showWelcomeScreen;
  const MathScribbleGameApp({super.key, required this.showWelcomeScreen});

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
      home: showWelcomeScreen ? const WelcomeScreen() : const MathScribbleGame(),
    );
  }
}


class MathScribbleGame extends StatefulWidget {
  const MathScribbleGame({super.key});
  @override
  State<MathScribbleGame> createState() => _MathScribbleGameState();
}

class _MathScribbleGameState extends State<MathScribbleGame> {
  final GameLogic _gameLogic = GameLogic();
  final HighScoreService _highScoreService = HighScoreService();

  // Profile Data State
  String? _userName;
  int? _avatarIndex;
  String? _countryCode;
  bool _profileDataLoaded = false; // To prevent flicker on load

  // Assume consistent use of placeholders from WelcomeScreen setting
  final bool _useIconPlaceholdersForAvatarInProfile = true; // Match WelcomeScreen

  String question = kInitialInstructionText;
  int _correctAnswersCount = 0;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _uiUpdateTimer;
  double _displayedElapsedTime = 0.0;
  bool _isGameActive = false;
  String feedbackText = '';
  String _correctAnswerForDisplay = "";
  InputMode _currentInputMode = InputMode.scribble;
  bool _listenTrigger = false;
  String _completedQuestionText = "";
  bool _wasLastAnswerCorrect = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData(); // Load profile data
    _highScoreService.init().then((_) {
      if (mounted) setState(() {});
    });
    _initializeToPreGameState();
  }

  Future<void> _loadProfileData() async {
    _userName = await _preferencesService.getUserName();
    _avatarIndex = await _preferencesService.getAvatarIndex();
    _countryCode = await _preferencesService.getCountryCode();
    if (mounted) {
      setState(() {
        _profileDataLoaded = true;
      });
    }
  }

  // Call this method when returning from the WelcomeScreen after editing
  Future<void> _refreshProfileData() async {
    await _loadProfileData(); // Reloads data from preferences
  }

  void _initializeToPreGameState() {
    // ... (rest of the method remains the same)
    if (!mounted) return;
    _stopwatch.stop();
    _stopwatch.reset();
    _uiUpdateTimer?.cancel();

    setState(() {
      _isGameActive = false;
      question = kInitialInstructionText;
      _correctAnswersCount = 0;
      _displayedElapsedTime = 0.0;
      feedbackText = '';
      _correctAnswerForDisplay = '';
      _completedQuestionText = '';
      _wasLastAnswerCorrect = false;
      _listenTrigger = false;
    });
  }

  void _toggleInputMode() {
    // ... (remains the same)
    setState(() {
      if (_currentInputMode == InputMode.scribble) {
        _currentInputMode = InputMode.voice;
        if (_isGameActive) _listenTrigger = !_listenTrigger;
      } else {
        _currentInputMode = InputMode.scribble;
      }
      if (!_isGameActive) {
        feedbackText = "";
        _correctAnswerForDisplay = "";
      }
    });
  }

  void _startGame() {
    // ... (remains the same)
     if (!mounted) return;
    setState(() {
      _isGameActive = true;
      _correctAnswersCount = 0;
      _displayedElapsedTime = 0.0;
      feedbackText = '';
      _correctAnswerForDisplay = '';
      _completedQuestionText = '';
      _wasLastAnswerCorrect = false;
      _listenTrigger = false;
    });

    _stopwatch.reset();
    _stopwatch.start();

    _uiUpdateTimer?.cancel();
    _uiUpdateTimer = Timer.periodic(kStopwatchTickDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_stopwatch.isRunning) {
        setState(() {
          _displayedElapsedTime = _stopwatch.elapsedMilliseconds / 1000.0;
        });
      } else {
        setState(() {
          _displayedElapsedTime = _stopwatch.elapsedMilliseconds / 1000.0;
        });
        timer.cancel();
      }
    });
    _generateAndSetQuestion();
  }

  void _resetGame() {
    _initializeToPreGameState();
  }

  void _generateAndSetQuestion() {
    // ... (remains the same)
    if (!_isGameActive || !mounted) return;
    final newQuestion = _gameLogic.generateQuestion();
    setState(() {
      question = newQuestion;
      feedbackText = '';
      _correctAnswerForDisplay = '';
      _completedQuestionText = '';
      _wasLastAnswerCorrect = false;
      if (_currentInputMode == InputMode.voice) {
        _listenTrigger = !_listenTrigger;
      }
    });
  }

  Future<void> _handleSubmission(String answer) async {
    // ... (remains the same, including the high score saving part)
    if (!mounted || !_isGameActive) return;

    if (answer.isEmpty || answer == '?') {
      setState(() {
        feedbackText = "Input unclear";
        _completedQuestionText = "";
        _correctAnswerForDisplay = "";
      });
      Future.delayed(kMainFeedbackClearDelay, () {
        if (mounted) setState(() => feedbackText = '');
      });
      if (_currentInputMode == InputMode.voice && _isGameActive) {
        setState(() => _listenTrigger = !_listenTrigger);
      }
      return;
    }

    bool isCorrect = _gameLogic.checkAnswer(question, answer);
    _wasLastAnswerCorrect = isCorrect;
    _completedQuestionText = question.replaceFirst('?', answer);
    _correctAnswerForDisplay = "";

    if (!isCorrect) {
      _correctAnswerForDisplay = _gameLogic.calculateCorrectAnswer(question);
    }

    int currentCorrectAnswers = _correctAnswersCount;
    if (isCorrect) {
      currentCorrectAnswers++;
    }

    setState(() {
      feedbackText = "";
      if (isCorrect) {
        _correctAnswersCount = currentCorrectAnswers;
      }
    });

    if (isCorrect && currentCorrectAnswers >= kTargetCorrectAnswers) {
      _stopwatch.stop();
      _uiUpdateTimer?.cancel();
      
      final finalTime = _stopwatch.elapsedMilliseconds / 1000.0;
      setState(() {
        _isGameActive = false;
        _displayedElapsedTime = finalTime;
      });

      await _highScoreService.addScore(finalTime);

      Future.delayed(kFeedbackOverlayDisplayDuration, () {
        if (mounted) {
          setState(() {
            _completedQuestionText = "";
            _correctAnswerForDisplay = "";
          });
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: Text('Challenge Complete!'),
              content: Text(
                  'You answered $kTargetCorrectAnswers questions correctly in ${finalTime.toStringAsFixed(2)} seconds!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _resetGame();
                  },
                  child: Text('Play Again'),
                ),
              ],
            ),
          );
        }
      });
    } else if (_isGameActive) {
      Future.delayed(kFeedbackOverlayDisplayDuration, () {
        if (mounted && _isGameActive) {
          _generateAndSetQuestion();
        }
      });
    }
    
    if (feedbackText.isNotEmpty || (!isCorrect && _correctAnswerForDisplay.isNotEmpty)) {
        Future.delayed(kMainFeedbackClearDelay, () {
            if (mounted) {
                 setState(() {
                    if (feedbackText.isNotEmpty) feedbackText = '';
                 });
            }
        });
    }
  }

  void _navigateToHighScores() {
    // ... (remains the same)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HighScoreScreen(highScoreService: _highScoreService),
      ),
    );
  }

  void _navigateToEditProfile() async {
    // Navigate to WelcomeScreen for editing.
    // The WelcomeScreen will handle saving changes.
    // When it pops, we refresh the profile data here.
    final result = await Navigator.push<bool>( // Expecting a bool if changes were made
      context,
      MaterialPageRoute(
        builder: (context) => WelcomeScreen(isEditingProfile: true), // Pass a flag
      ),
    );

    // if (result == true) { // Or simply refresh regardless
      _refreshProfileData();
    // }
  }


  @override
  void dispose() {
    // ... (remains the same)
    _stopwatch.stop();
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String timeToDisplay = (_isGameActive || _stopwatch.elapsedMilliseconds > 0 || _correctAnswersCount >= kTargetCorrectAnswers)
        ? _displayedElapsedTime.toStringAsFixed(2)
        : "0.00";

    return Scaffold(
      appBar: PreferredSize( // Use PreferredSize to customize AppBar height
        preferredSize: Size.fromHeight(kToolbarHeight + (_profileDataLoaded ? 50.0 : 0)), // Adjust height for profile bar
        child: AppBar(
          title: Text('Mathzy'),
          flexibleSpace: _profileDataLoaded ? Column( // Add profile bar below title
            mainAxisAlignment: MainAxisAlignment.end, // Align to bottom of AppBar space
            children: [
               // This empty container helps push the PlayerProfileBar to the bottom
               // of the AppBar's flexibleSpace if title is centered or has specific alignment needs.
               // For a simple top-aligned title, direct placement works too.
              // Spacer(), // Use Spacer if title is not taking full width
              PlayerProfileBar(
                userName: _userName,
                avatarIndex: _avatarIndex,
                countryCode: _countryCode,
                onEditProfile: _navigateToEditProfile,
                useIconPlaceholdersForAvatar: _useIconPlaceholdersForAvatarInProfile,
              ),
            ],
          ) : null,
          actions: [
            IconButton(
              icon: Icon(Icons.leaderboard),
              tooltip: 'High Scores',
              onPressed: _navigateToHighScores,
            ),
            IconButton(
              icon: Icon(
                _currentInputMode == InputMode.scribble ? Icons.mic : Icons.edit,
              ),
              tooltip: _currentInputMode == InputMode.scribble
                  ? 'Switch to Voice Input'
                  : 'Switch to Scribble Input',
              onPressed: _toggleInputMode,
            ),
          ],
        ),
      ),
      body: Stack(
        // ... (rest of the body Column remains the same) ...
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle_outline, color: Colors.blueAccent, size: 28),
                                  SizedBox(width: 4),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (Widget child, Animation<double> animation) =>
                                        ScaleTransition(scale: animation, child: child),
                                    child: Text(
                                      '$_correctAnswersCount / $kTargetCorrectAnswers',
                                      key: ValueKey<int>(_correctAnswersCount),
                                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                  ),
                                ],
                              ),
                              Flexible(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(Icons.timer_outlined, color: Theme.of(context).textTheme.bodyLarge?.color, size: 28),
                                    SizedBox(width: 4),
                                    Text(
                                      '$timeToDisplay s',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        if (_completedQuestionText.isNotEmpty && _isGameActive)
                          Text(
                            _completedQuestionText,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: _wasLastAnswerCorrect ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                            textAlign: TextAlign.center,
                          )
                        else
                          Text(
                            question,
                            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        SizedBox(height: 10),
                        Container(
                          height: 50,
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (feedbackText.isNotEmpty)
                                  Flexible(
                                    child: Text(
                                      feedbackText,
                                      style: TextStyle(fontSize: 18, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, maxLines: 1,
                                    ),
                                  ),
                                if (feedbackText.isEmpty &&
                                    _completedQuestionText.isNotEmpty &&
                                    !_wasLastAnswerCorrect &&
                                    _correctAnswerForDisplay.isNotEmpty)
                                  Flexible(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 2.0),
                                      child: Text(
                                        "Correct answer: $_correctAnswerForDisplay",
                                        style: TextStyle(fontSize: 16, color: Colors.orange[700], fontWeight: FontWeight.w500),
                                        textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, maxLines: 1,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _isGameActive ? _resetGame : _startGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isGameActive ? Colors.redAccent : Colors.green,
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          child: Text(_isGameActive ? "Reset Game" : "Start Game", style: TextStyle(color: Colors.white)),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 6,
                child: _currentInputMode == InputMode.scribble
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
        ],
      ),
    );
  }
}