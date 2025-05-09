// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:math';

// Helper class to hold parsed question details
class _ParsedQuestion {
  final String type; // e.g., "comparison", "addition_missing_middle"
  final List<String> parts;
  final int? x, y, z; // Store parsed numbers
  final String? op;
  final int unknownIndex; // e.g., 0 for "? + y", 2 for "x + ?"

  _ParsedQuestion(this.type, this.parts, this.x, this.y, this.z, this.op, this.unknownIndex);
}

class GameLogic {
  String generateQuestion() {
    // ... (your existing generateQuestion logic is fine) ...
    final random = Random();
    int x = random.nextInt(9) + 1;
    int y = random.nextInt(9) + 1;
    int op = random.nextInt(6);
    String question = '';
    switch (op) {
      case 0: question = '$x ? $y'; break;
      case 1: int z = x + (random.nextInt(9) + 1); question = '$x + ? = $z'; break;
      case 2: int z = y + (random.nextInt(9) + 1); question = '? + $y = $z'; break;
      case 3: int val = random.nextInt(x); int z = x - val; question = '$x - ? = $z'; break;
      case 4: int mult = random.nextInt(5) + 1; int z = x * mult; question = '$x × ? = $z'; break;
      case 5:
        List<int> divs = [];
        for (int i = 1; i <= x; i++) { if (x % i == 0) divs.add(i); }
        int d = divs.isEmpty ? 1 : divs[random.nextInt(divs.length)];
        int zVal = x ~/ d; // Renamed to avoid conflict with _ParsedQuestion.z
        question = '$x ÷ ? = $zVal';
        break;
    }
    return question;
  }

  // Private helper to parse the question string
  _ParsedQuestion? _parseQuestion(String questionStr) {
    if (questionStr.isEmpty) return null;
    final parts = questionStr.split(' ');
    if (parts.isEmpty) return null;

    try {
      if (parts.length == 3 && parts[1] == '?') { // "x ? y"
        return _ParsedQuestion("comparison", parts, int.parse(parts[0]), int.parse(parts[2]), null, parts[1], 1);
      } else if (parts.length == 5) { // "a op b = c" with one '?'
        int p4Val = int.parse(parts[4]); // Result
        String op = parts[1];
        int unknownIndex = -1;
        String type = "";

        if (parts[0] == '?') { // ? op y = z
          unknownIndex = 0;
          type = "${op}_missing_first";
          return _ParsedQuestion(type, parts, null, int.parse(parts[2]), p4Val, op, unknownIndex);
        } else if (parts[2] == '?') { // x op ? = z
          unknownIndex = 2;
           type = "${op}_missing_middle";
          return _ParsedQuestion(type, parts, int.parse(parts[0]), null, p4Val, op, unknownIndex);
        }
      }
    } catch (e) {
      // print("Error parsing question: $e");
      return null;
    }
    return null; // Should not happen if question formats are consistent
  }

  bool checkAnswer(String questionStr, String recognizedAnswer) {
    if (questionStr.isEmpty || recognizedAnswer.isEmpty || recognizedAnswer == '?') return false;

    final pQuestion = _parseQuestion(questionStr);
    if (pQuestion == null) return false;

    try {
      if (pQuestion.type == "comparison") {
        if (recognizedAnswer == '<' && pQuestion.x! < pQuestion.y!) return true;
        if (recognizedAnswer == '>' && pQuestion.x! > pQuestion.y!) return true;
        if (recognizedAnswer == '=' && pQuestion.x! == pQuestion.y!) return true;
      } else {
        int? userAnswerVal = int.tryParse(recognizedAnswer);
        if (userAnswerVal == null) return false;

        if (pQuestion.unknownIndex == 0) { // ? op y = z
          if (pQuestion.op == '+') return (userAnswerVal + pQuestion.y!) == pQuestion.z!;
          // Add other ops if ? can be first for them
        } else if (pQuestion.unknownIndex == 2) { // x op ? = z
          if (pQuestion.op == '+') return (pQuestion.x! + userAnswerVal) == pQuestion.z!;
          if (pQuestion.op == '-') return (pQuestion.x! - userAnswerVal) == pQuestion.z!;
          if (pQuestion.op == '×') return (pQuestion.x! * userAnswerVal) == pQuestion.z!;
          if (pQuestion.op == '÷') return (userAnswerVal != 0 && pQuestion.x! % userAnswerVal == 0 && pQuestion.x! ~/ userAnswerVal == pQuestion.z!);
        }
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  String calculateCorrectAnswer(String questionStr) {
    if (questionStr.isEmpty) return "";
    final pQuestion = _parseQuestion(questionStr);
    if (pQuestion == null) return "";

    try {
      if (pQuestion.type == "comparison") {
        if (pQuestion.x! < pQuestion.y!) return "<";
        if (pQuestion.x! > pQuestion.y!) return ">";
        if (pQuestion.x! == pQuestion.y!) return "=";
      } else {
         if (pQuestion.unknownIndex == 0) { // ? op y = z
          if (pQuestion.op == '+') return (pQuestion.z! - pQuestion.y!).toString();
          // Add other ops if needed
        } else if (pQuestion.unknownIndex == 2) { // x op ? = z
          if (pQuestion.op == '+') return (pQuestion.z! - pQuestion.x!).toString();
          if (pQuestion.op == '-') return (pQuestion.x! - pQuestion.z!).toString();
          if (pQuestion.op == '×') {
            if (pQuestion.x == 0) return pQuestion.z == 0 ? "any" : "none";
            if (pQuestion.z! % pQuestion.x! != 0) return "none";
            return (pQuestion.z! ~/ pQuestion.x!).toString();
          }
          if (pQuestion.op == '÷') {
            // Assuming generateQuestion ensures x != 0 for division questions.
            // And z (result of x / d) will also not be 0 if x != 0.
            if (pQuestion.z == 0) return "none"; // e.g. x / ? = 0 (Only if x=0, then ? is "any non-zero")
            if (pQuestion.x! % pQuestion.z! != 0) return "none"; // d = x / z must be integer
            return (pQuestion.x! ~/ pQuestion.z!).toString();
          }
        }
      }
    } catch (e) {
      return "";
    }
    return "";
  }
}