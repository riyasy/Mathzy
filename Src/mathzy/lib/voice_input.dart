import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mathzy/constants.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// --- Voice Input Control ---
class VoiceInputControl extends StatefulWidget {
  final bool isActive;
  final bool listenTrigger;
  final ValueChanged<String> onSubmit;

  const VoiceInputControl({
    super.key,
    required this.isActive,
    required this.listenTrigger,
    required this.onSubmit,
  });

  @override
  State<VoiceInputControl> createState() => _VoiceInputControlState();
}

class _VoiceInputControlState extends State<VoiceInputControl> {
  final stt.SpeechToText _speech = stt.SpeechToText(); // Keep instance local
  bool _isSpeechAvailable = false;
  bool _isListening = false;
  String _currentVoiceText = "";
  String _lastSubmittedText = "";

  @override
  void initState() {
    super.initState();
    _initializeSpeechRecognizer();
  }

  @override
  void didUpdateWidget(VoiceInputControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.listenTrigger != oldWidget.listenTrigger &&
        widget.listenTrigger &&
        widget.isActive &&
        _isSpeechAvailable &&
        !_isListening) {
      _startListening();
    }
    if (widget.isActive != oldWidget.isActive && !widget.isActive) {
      _stopListening();
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _initializeSpeechRecognizer() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (mounted) {
          bool listeningNow = status == stt.SpeechToText.listeningStatus;
          if (_isListening != listeningNow) {
            setState(() => _isListening = listeningNow);
          }
        }
      },
      onError: (errorNotification) {
        print('VoiceInputControl Error: $errorNotification');
        if (mounted) {
          setState(() {
            _isListening = false;
            _isSpeechAvailable = false;
          });
        }
      },
    );
    if (mounted) {
      setState(() => _isSpeechAvailable = available);
      print("VoiceInputControl Speech Available: $_isSpeechAvailable");
      if (_isSpeechAvailable &&
          widget.isActive &&
          widget.listenTrigger &&
          !_isListening) {
        _startListening();
      }
    }
  }

  String _processVoiceInput(String rawVoiceText) {
    String p = rawVoiceText.toLowerCase().trim();
    p = p.replaceAll("zero", "0");
    p = p.replaceAll("one", "1");
    p = p.replaceAll("two", "2");
    p = p.replaceAll("to", "2");
    p = p.replaceAll("too", "2");
    p = p.replaceAll("three", "3");
    p = p.replaceAll("four", "4");
    p = p.replaceAll("for", "4");
    p = p.replaceAll("five", "5");
    p = p.replaceAll("six", "6");
    p = p.replaceAll("seven", "7");
    p = p.replaceAll("eight", "8");
    p = p.replaceAll("ate", "8");
    p = p.replaceAll("nine", "9");
    p = p.replaceAll("less than", "<");
    p = p.replaceAll("lesser than", "<");
    p = p.replaceAll("greater than", ">");
    p = p.replaceAll("equal to", "=");
    p = p.replaceAll("equals", "=");
    p = p.replaceAll("is", "=");
    p = p.replaceAll(RegExp(r'\s+'), '');
    p = p.replaceAll(RegExp(r'[^0-9<=>]'), '');
    return p.isEmpty ? "?" : p;
  }

  Future<void> _startListening() async {
    if (!_isSpeechAvailable || _isListening || !widget.isActive) return;
    print("VoiceInputControl starting listening...");
    if (mounted) setState(() => _currentVoiceText = "");

    _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        String recognized = result.recognizedWords;
        if (mounted) setState(() => _currentVoiceText = recognized);

        if (result.finalResult && recognized.isNotEmpty) {
          print("VoiceInputControl Final Result: '$recognized'");
          if (mounted &&
              _currentVoiceText != _lastSubmittedText &&
              widget.isActive) {
            String processed = _processVoiceInput(_currentVoiceText);
            if (processed != "?" && processed.isNotEmpty) {
              print("VoiceInputControl Submitting: '$processed'");
              _lastSubmittedText = _currentVoiceText;
              widget.onSubmit(processed);
            } else {
              print(
                "VoiceInputControl Processed to empty or '?', not submitting.",
              );
              // Reset _lastSubmittedText if processing failed?
              _lastSubmittedText =
                  ""; // Allow retry with potentially same raw input
            }
          }
        }
      },
      listenFor: kListenForDuration,
      pauseFor: kPauseForDuration,
      localeId: 'en_US',
      partialResults: true,
      cancelOnError: true,
      onDevice: true,
    );
  }

  Future<void> _stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
      print("VoiceInputControl stopped listening.");
    }
    // onStatus will update _isListening state
  }

  @override
  Widget build(BuildContext context) {
    return ListeningBlobIndicator(
      isListening: _isListening,
      isSpeechAvailable: _isSpeechAvailable,
      currentText: _currentVoiceText,
    );
  }
}

// --- Listening Blob Indicator Widget ---
class ListeningBlobIndicator extends StatefulWidget {
  final bool isListening;
  final bool isSpeechAvailable;
  final String currentText;
  const ListeningBlobIndicator({
    super.key,
    required this.isListening,
    required this.isSpeechAvailable,
    required this.currentText,
  });
  @override
  State<ListeningBlobIndicator> createState() => _ListeningBlobIndicatorState();
}

class _ListeningBlobIndicatorState extends State<ListeningBlobIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: kListeningBlobAnimationDuration,
    );
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticInOut),
    );
    if (widget.isListening) _animationController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(ListeningBlobIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening != oldWidget.isListening) {
      if (widget.isListening) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child:
            !widget.isSpeechAvailable
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /* Error message */
                    Icon(Icons.mic_off, size: 80, color: Colors.grey[400]),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        "Voice input unavailable.",
                        style: TextStyle(fontSize: 16, color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.isListening)
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha:0.8),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha:0.4),
                                blurRadius: 25,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.graphic_eq,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      )
                    else
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          /* Idle message */
                          Icon(
                            Icons.mic_none,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            child: Text(
                              "Voice input mode.\nListening starts automatically.",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        widget.isListening
                            ? (widget.currentText.isNotEmpty
                                ? '"${widget.currentText}"'
                                : "Listening...")
                            : "",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blueGrey,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

// --- Pulsing Dot Indicator Widget (for top bar) ---
class ListeningDotIndicator extends StatefulWidget {
  final bool isListening;
  const ListeningDotIndicator({super.key, required this.isListening});
  @override
  State<ListeningDotIndicator> createState() => _ListeningDotIndicatorState();
}

class _ListeningDotIndicatorState extends State<ListeningDotIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  @override
  void initState() {
    /* ... as before ... */
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: kPulsingDotAnimationDuration,
    );
    _opacityAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    if (widget.isListening) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.3;
    }
  }

  @override
  void didUpdateWidget(ListeningDotIndicator oldWidget) {
    /* ... as before ... */
    super.didUpdateWidget(oldWidget);
    if (widget.isListening != oldWidget.isListening) {
      if (widget.isListening) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.animateTo(0.3, duration: Duration(milliseconds: 100));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Icon(Icons.circle, size: 12, color: Colors.redAccent),
    );
  }
}
