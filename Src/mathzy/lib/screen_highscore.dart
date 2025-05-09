// lib/high_score_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'service_highscores.dart';

class HighScoreScreen extends StatelessWidget {
  final HighScoreService highScoreService;

  const HighScoreScreen({super.key, required this.highScoreService});

  @override
  Widget build(BuildContext context) {
    // Call init here to ensure scores are loaded if this screen is accessed directly
    // or if the service wasn't initialized early enough.
    // FutureBuilder will handle the loading state.
    final Future<void> initFuture = highScoreService.init();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top 10 High Scores'),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: IconThemeData(color: Theme.of(context).appBarTheme.titleTextStyle?.color ?? Colors.black),
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
      ),
      body: FutureBuilder<void>(
        future: initFuture, // Wait for service initialization
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // print("Error initializing HighScoreService for screen: ${snapshot.error}");
            return Center(child: Text('Error loading scores: ${snapshot.error}. Please try again.'));
          }

          // After init, get the scores
          final scores = highScoreService.getTopScores();

          if (scores.isEmpty) {
            return const Center(child: Text('No high scores yet. Go play!'));
          }

          return LayoutBuilder( // Use LayoutBuilder for responsive table
            builder: (context, constraints) {
              return SingleChildScrollView( // For vertical scrolling
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center( // Center the table if it's narrower than the screen
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth > 500 ? 500 : constraints.maxWidth * 0.95), // Ensure a min width or take most of screen
                      child: DataTable(
                        columnSpacing: 16.0,
                        headingRowColor: MaterialStateProperty.all(Colors.blueGrey.shade100),
                        columns: const [
                          DataColumn(label: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Time (s)', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                          DataColumn(label: Text('Date Achieved', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: scores.asMap().entries.map((entry) {
                          int rank = entry.key + 1;
                          HighScoreEntry scoreData = entry.value;
                          return DataRow(
                            cells: [
                              DataCell(Text('$rank.')),
                              DataCell(Text(scoreData.timeTaken.toStringAsFixed(2))),
                              DataCell(Text(DateFormat('MMM d, yyyy HH:mm').format(scoreData.dateAchieved))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              );
            }
          );
        },
      ),
    );
  }
}