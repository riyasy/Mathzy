// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:math';

// --- GAME LOGIC ---
class GameLogic {
  String generateQuestion() {
    final random = Random();
    int x = random.nextInt(9) + 1;
    int y = random.nextInt(9) + 1;
    int op = random.nextInt(6);
    String question = '';
    switch (op) {
      /* ... cases ... */
      case 0:
        question = '$x ? $y';
        break;
      case 1:
        int z = x + (random.nextInt(9) + 1);
        question = '$x + ? = $z';
        break;
      case 2:
        int z = y + (random.nextInt(9) + 1);
        question = '? + $y = $z';
        break;
      case 3:
        int val = random.nextInt(x);
        int z = x - val;
        question = '$x - ? = $z';
        break;
      case 4:
        int mult = random.nextInt(5) + 1;
        int z = x * mult;
        question = '$x × ? = $z';
        break;
      case 5:
        List<int> divs = [];
        for (int i = 1; i <= x; i++) {
          if (x % i == 0) divs.add(i);
        }
        int d = divs.isEmpty ? 1 : divs[random.nextInt(divs.length)];
        int z = x ~/ d;
        question = '$x ÷ ? = $z';
        break;
    }
    return question;
  }

  bool checkAnswer(String question, String recognizedAnswer) {
    if (question.isEmpty || recognizedAnswer.isEmpty || recognizedAnswer == '?')
      return false;
    final parts = question.split(' ');
    String cleaned = recognizedAnswer;
    try {
      /* ... checking logic ... */
      if (parts.length == 3 && parts[1] == '?') {
        int x = int.parse(parts[0]);
        int y = int.parse(parts[2]);
        if (cleaned == '<' && x < y) return true;
        if (cleaned == '>' && x > y) return true;
        if (cleaned == '=' && x == y) return true;
      } else if (parts.length == 5) {
        int? val = int.tryParse(cleaned);
        if (val == null) return false;
        if (parts[0] == '?') {
          int y = int.parse(parts[2]);
          String op = parts[1];
          int z = int.parse(parts[4]);
          if (op == '+') return (val + y) == z;
        } else if (parts[2] == '?') {
          int x = int.parse(parts[0]);
          String op = parts[1];
          int z = int.parse(parts[4]);
          if (op == '+') return (x + val) == z;
          if (op == '-') return (x - val) == z;
          if (op == '×') return (x * val) == z;
          if (op == '÷') return (val != 0 && x % val == 0 && x ~/ val == z);
        }
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  String calculateCorrectAnswer(String question) {
    if (question.isEmpty) return "";
    final parts = question.split(' ');
    if (parts.isEmpty) return "";
    try {
      /* ... calculation logic ... */
      if (parts.length == 3 && parts[1] == '?') {
        int x = int.parse(parts[0]);
        int y = int.parse(parts[2]);
        if (x < y) return "<";
        if (x > y) return ">";
        if (x == y) return "=";
      } else if (parts.length == 5) {
        if (parts[0] == '?') {
          int y = int.parse(parts[2]);
          String op = parts[1];
          int z = int.parse(parts[4]);
          if (op == '+') return (z - y).toString();
        } else if (parts[2] == '?') {
          int x = int.parse(parts[0]);
          String op = parts[1];
          int z = int.parse(parts[4]);
          if (op == '+') return (z - x).toString();
          if (op == '-') return (x - z).toString();
          if (op == '×') {
            if (x == 0) return z == 0 ? "any" : "none";
            if (z % x != 0) return "none";
            return (z ~/ x).toString();
          }
          if (op == '÷') {
            if (z == 0) return "none if x!=0";
            if (x % z != 0) return "none";
            return (x ~/ z).toString();
          }
        }
      }
    } catch (e) {
      return "";
    }
    return "";
  }
}
// --- END GAME LOGIC ---