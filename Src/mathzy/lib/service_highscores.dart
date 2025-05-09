// lib/highscore_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const String _highScoresStorageKey = 'mathzy_high_scores_v1'; // Added version for future changes
const int _maxHighScores = 10;

class HighScoreEntry {
  final double timeTaken;
  final DateTime dateAchieved;

  HighScoreEntry({required this.timeTaken, required this.dateAchieved});

  Map<String, dynamic> toJson() => {
        'timeTaken': timeTaken,
        'dateAchieved': dateAchieved.toIso8601String(),
      };

  factory HighScoreEntry.fromJson(Map<String, dynamic> json) {
    return HighScoreEntry(
      timeTaken: (json['timeTaken'] as num).toDouble(), // Handle int or double from JSON
      dateAchieved: DateTime.parse(json['dateAchieved'] as String),
    );
  }
}

class HighScoreService {
  List<HighScoreEntry> _scores = [];
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    await _loadScores();
    _isInitialized = true;
  }

  Future<void> _loadScores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? scoresJson = prefs.getStringList(_highScoresStorageKey);
      if (scoresJson != null) {
        _scores = scoresJson
            .map((s) => HighScoreEntry.fromJson(jsonDecode(s) as Map<String, dynamic>))
            .toList();
        _scores.sort((a, b) => a.timeTaken.compareTo(b.timeTaken)); // Ensure sorted
      } else {
        _scores = [];
      }
    } catch (e) {
      // print("Error loading scores: $e"); // Optional: log error
      _scores = []; // Default to empty list on error
    }
  }

  Future<void> _saveScores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> scoresJson = _scores.map((s) => jsonEncode(s.toJson())).toList();
      await prefs.setStringList(_highScoresStorageKey, scoresJson);
    } catch (e) {
      // print("Error saving scores: $e"); // Optional: log error
    }
  }

  Future<bool> addScore(double timeTaken) async {
    if (!_isInitialized) await init(); // Ensure initialized

    final newEntry = HighScoreEntry(timeTaken: timeTaken, dateAchieved: DateTime.now());

    // Add the new score and re-sort
    _scores.add(newEntry);
    _scores.sort((a, b) => a.timeTaken.compareTo(b.timeTaken)); // Sort by time (ascending)

    bool madeItToList = true; // Assume it made it initially

    // If more than max scores, trim the list
    if (_scores.length > _maxHighScores) {
      // Check if the new entry is still in the list after trimming
      // (it would be if it's better than what was previously the Nth score)
      if (_scores.indexOf(newEntry) >= _maxHighScores) {
         madeItToList = false; // It was added but trimmed out
      }
      _scores = _scores.sublist(0, _maxHighScores);
    }
    
    await _saveScores();
    return madeItToList; // Return true if the score is now in the top list
  }

  List<HighScoreEntry> getTopScores() {
    // Ensure scores are loaded if accessed before init (though init should be called early)
    // if (!_isInitialized) {
    //   print("Warning: Accessing scores before HighScoreService is initialized.");
    //   // Potentially trigger a blocking load here, or ensure init is called in app startup
    // }
    return List<HighScoreEntry>.from(_scores); // Return a copy
  }

  // Optional: For testing or resetting scores
  Future<void> clearAllScores() async {
    _scores = [];
    await _saveScores();
    // print("All high scores cleared.");
  }
}