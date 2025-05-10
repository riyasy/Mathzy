import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart'
    as mlkit;
import 'package:mathzy/constants.dart';

// --- SCRIBBLE PAINTER ---
class ScribblePainter extends CustomPainter {
  final List<Offset> points;
  ScribblePainter(this.points);
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black
          ..strokeWidth = 5.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.zero && points[i + 1] != Offset.zero) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ScribblePainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.points.length != points.length;
}
// --- END SCRIBBLE PAINTER ---

// --- INPUT CONTROLS ---

// --- Scribble Input Control ---
class ScribbleInputControl extends StatefulWidget {
  final bool isActive;
  final ValueChanged<String> onSubmit;

  const ScribbleInputControl({
    super.key,
    required this.isActive,
    required this.onSubmit,
  });

  @override
  State<ScribbleInputControl> createState() => _ScribbleInputControlState();
}

class _ScribbleInputControlState extends State<ScribbleInputControl> {
  final mlkit.DigitalInkRecognizer _recognizer = mlkit.DigitalInkRecognizer(
    languageCode: 'en',
  );
  final mlkit.DigitalInkRecognizerModelManager _modelManager =
      mlkit.DigitalInkRecognizerModelManager();
  bool _isScribbleModelReady = false;
  final List<Offset> _points = [];
  Timer? _autoSubmitTimer;
  bool _isProcessing = false;
  bool _hasUserStartedDrawingThisSession =
      false; // New state variable for the hint

  @override
  void initState() {
    super.initState();
    _checkAndDownloadScribbleModel();
  }

  @override
  void didUpdateWidget(ScribbleInputControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the control becomes inactive, clear points, cancel timer, and reset drawing session flag
    if (!widget.isActive && oldWidget.isActive) {
      _cancelAutoSubmitTimer();
      setState(() {
        _points.clear();
        _hasUserStartedDrawingThisSession = false; // Reset when inactive
      });
    }
    // If the control becomes active (and wasn't before), reset drawing session flag
    // This ensures the hint shows for each new question/activation.
    if (widget.isActive && !oldWidget.isActive) {
      setState(() {
        _hasUserStartedDrawingThisSession = false;
      });
    }
  }

  @override
  void dispose() {
    _recognizer.close();
    _autoSubmitTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAndDownloadScribbleModel() async {
    try {
      bool downloaded = await _modelManager.isModelDownloaded('en');
      if (!downloaded && mounted) {
        print("Scribble model needs download...");
        await _modelManager.downloadModel('en', isWifiRequired: false);
        downloaded = true;
        print("Scribble model downloaded.");
      } else if (downloaded) {
        print("Scribble model already available.");
      }
      if (mounted) setState(() => _isScribbleModelReady = downloaded);
    } catch (e) {
      print("Error checking/downloading scribble model: $e");
      if (mounted) {
        setState(() => _isScribbleModelReady = false);
      }
    }
  }

  void _cancelAutoSubmitTimer() {
    _autoSubmitTimer?.cancel();
  }

  void _startAutoSubmitTimer() {
    _cancelAutoSubmitTimer();
    _autoSubmitTimer = Timer(kAutoSubmitScribbleDelay, _submitScribble);
  }

  void _handlePanStart(DragStartDetails details) {
    if (!widget.isActive || !_isScribbleModelReady || _isProcessing) return;
    _cancelAutoSubmitTimer();
    setState(() {
      _points.add(details.localPosition);
      _hasUserStartedDrawingThisSession = true; // User has started drawing
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!widget.isActive || !_isScribbleModelReady || _isProcessing) return;
    _cancelAutoSubmitTimer();
    // Ensure _hasUserStartedDrawingThisSession is true if somehow missed in onPanStart
    if (!_hasUserStartedDrawingThisSession) {
      _hasUserStartedDrawingThisSession = true;
    }
    setState(() {
      _points.add(details.localPosition);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!widget.isActive || !_isScribbleModelReady || _isProcessing) return;
    if (_points.isNotEmpty && _points.last != Offset.zero) {
      setState(() {
        _points.add(Offset.zero);
      });
    }
    bool hasActualDrawing = _points.any((p) => p != Offset.zero);
    if (hasActualDrawing) {
      _startAutoSubmitTimer();
    }
  }

  String _processScribbleCandidates(
    List<mlkit.RecognitionCandidate> candidates,
  ) {
    // ... (your existing processing logic remains the same)
    final pat = RegExp(r'^[0-9<=>]+$');
    final map = {
      'Z': '2',
      'z': '2',
      'S': '5',
      's': '5',
      'O': '0',
      'o': '0',
      'L': '1',
      'l': '1',
      'I': '1',
      'i': '1',
      'B': '8',
      'b': '8',
      'G': '9',
      'g': '9',
      'q': '9',
    };
    String best = "";
    double bestScr = -1.0;
    if (candidates.isEmpty) return "?";
    for (var c in candidates) {
      String orig = c.text;
      String proc = "";
      if (orig.length == 1) {
        proc = map[orig] ?? orig;
      } else {
        StringBuffer sb = StringBuffer();
        for (int i = 0; i < orig.length; i++) {
          sb.write(map[orig[i]] ?? orig[i]);
        }
        proc = sb.toString();
      }
      if (pat.hasMatch(proc)) {
        double curScr = c.score ?? 0.0; // Handle null score
        if (curScr > bestScr) {
          bestScr = curScr;
          best = proc;
        } else if (best.isEmpty && curScr == bestScr) {
          best = proc;
        }
      }
    }
    if (best.isEmpty &&
        candidates.isNotEmpty &&
        pat.hasMatch(candidates.first.text)) {
      best = candidates.first.text;
    }
    return best.isEmpty ? '?' : best;
  }

  Future<void> _submitScribble() async {
    if (_points.isEmpty ||
        !_isScribbleModelReady ||
        _isProcessing ||
        !widget.isActive) {
      return;
    }
    bool hasActualDrawing = _points.any((p) => p != Offset.zero);
    if (!hasActualDrawing) {
      _points.clear();
      if (mounted)
        setState(() {}); // Ensure UI updates if points were just cleared
      return;
    }

    setState(() => _isProcessing = true);
    _cancelAutoSubmitTimer();

    final ink = mlkit.Ink();
    var stroke = mlkit.Stroke();
    final pointsCopy = List<Offset>.from(_points);
    if (mounted) {
      setState(() {
        _points.clear();
        // _hasUserStartedDrawingThisSession will be reset in didUpdateWidget
        // when isActive changes, or when a new question effectively starts.
        // Or, if you want the hint to reappear for the *next* stroke of the *same* question
        // after a submission, you'd reset it here too.
        // For now, it resets when the question/active state changes.
      });
    }

    for (var p in pointsCopy) {
      if (p != Offset.zero) {
        stroke.points.add(
          mlkit.StrokePoint(
            x: p.dx,
            y: p.dy,
            t: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } else {
        if (stroke.points.isNotEmpty) {
          ink.strokes.add(stroke);
          stroke = mlkit.Stroke();
        }
      }
    }
    if (stroke.points.isNotEmpty) {
      ink.strokes.add(stroke);
    }

    if (ink.strokes.isEmpty) {
      if (mounted) setState(() => _isProcessing = false);
      return;
    }

    try {
      final candidates = await _recognizer.recognize(ink);
      String recognizedAndProcessed = _processScribbleCandidates(
        candidates.isNotEmpty ? candidates : [],
      );
      widget.onSubmit(recognizedAndProcessed);
    } catch (e) {
      print("Error during scribble recognition: $e");
      widget.onSubmit("?");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = widget.isActive ? Colors.white : Colors.grey[300]!;
    Widget? overlayChild;

    if (!_isScribbleModelReady) {
      overlayChild = Center(
        child: Text(
          "Loading drawing model...",
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    } else if (_isProcessing) {
      overlayChild = Center(child: CircularProgressIndicator());
    } else if (!widget.isActive) {
      overlayChild = Center(
        child: Text(
          "Scribble disabled",
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    } else if (widget.isActive && !_hasUserStartedDrawingThisSession) {
      // New condition for hint
      overlayChild = Center(
        child: Text(
          "Draw the answer here",
          style: TextStyle(
            fontSize: 18,
            color: Colors.blueGrey.shade400,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          behavior: HitTestBehavior.opaque,
          child: CustomPaint(
            foregroundPainter: ScribblePainter(_points),
            child: Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  top: BorderSide(color: Colors.blueGrey.shade300, width: 1),
                ),
              ),
              child: overlayChild, // Show hint or other overlays
            ),
          ),
        );
      },
    );
  }
}
