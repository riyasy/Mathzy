import 'dart:async';
import 'package:flutter/material.dart';
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
    _speech.cancel(); // Ensure all resources are released
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
            // Consider setting _isSpeechAvailable to false too,
            // as an error might mean the service is unusable.
            // For now, we reflect the error primarily through _isListening.
            // If initialize() itself failed, _isSpeechAvailable would be false from its result.
            // This onError is for subsequent errors.
             _isSpeechAvailable = false; // If a persistent error occurs, speech might not be available
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

        if (recognized.isNotEmpty) { // Process on final result
          print("VoiceInputControl Recognized (final): '$recognized'");
          String processed = _processVoiceInput(_currentVoiceText);
          if (processed != "?" && processed.isNotEmpty) {
            print("VoiceInputControl Submitting: '$processed'");
            widget.onSubmit(processed);
            // Optionally clear current text after submission, or let it be overwritten by next recognition
            setState(() => _currentVoiceText = "");
          }
        } else if (recognized.isNotEmpty) {
           print("VoiceInputControl Recognized (interim): '$recognized'");
        }
      },
    );
  }

  Future<void> _stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
      print("VoiceInputControl stopped listening.");
    }
    // onStatus callback will update _isListening state
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'Speech Available: $_isSpeechAvailable',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isSpeechAvailable ? Colors.green : Colors.red),
            ),
            SizedBox(height: 10),
            Text(
              'Is Listening: $_isListening',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isListening ? Colors.blue : Colors.orange),
            ),
            SizedBox(height: 10),
            Text(
              'Current Voice Text: "${_currentVoiceText.isEmpty ? "---" : _currentVoiceText}"',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 20),
            // Contextual status message
            if (!_isSpeechAvailable)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  "Voice input is currently unavailable. Please check microphone permissions or network connection.",
                  style: TextStyle(fontSize: 16, color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              )
            else if (_isListening)
              Text(
                _currentVoiceText.isNotEmpty ? 'Processing: "$_currentVoiceText"' : "Listening...",
                style: TextStyle(fontSize: 16, color: Colors.blue, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  widget.isActive
                      ? "Voice input active. Waiting for trigger to listen."
                      : "Voice input is idle.",
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

