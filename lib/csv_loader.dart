import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

const String _baseUrl =
    'https://raw.githubusercontent.com/novernmanagement-coder/SafePrep_Content/main';
const String _versionUrl = '$_baseUrl/version.json';

const List<String> _remoteFiles = [
  'FinalTestQuestions5.csv',
  'MarqueeFacts.csv',
  'ServSafeProTips.csv',
  'ScenarioDrills.csv',
];

class CsvUpdater {
  static Future<void> syncIfNeeded() async {
    try {
      final response = await http
          .get(Uri.parse(_versionUrl))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return;
      final remoteVersion = jsonDecode(response.body) as Map<String, dynamic>;
      final localVersion = await _loadLocalVersion();
      for (final file in _remoteFiles) {
        final remoteVer = remoteVersion[file]?.toString() ?? '0';
        final localVer = localVersion[file]?.toString() ?? '0';
        if (remoteVer != localVer) {
          final success = await _downloadFile(file);
          if (success) localVersion[file] = remoteVer;
        }
      }
      await _saveLocalVersion(localVersion);
    } catch (e) {
      debugPrint('CSV sync skipped: $e');
    }
  }

  static Future<bool> _downloadFile(String fileName) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/$fileName'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return false;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(response.body, encoding: utf8);
      debugPrint('CSV updated: $fileName');
      return true;
    } catch (e) {
      debugPrint('CSV download failed ($fileName): $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> _loadLocalVersion() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/csv_version.json');
      if (!await file.exists()) return {};
      final content = await file.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveLocalVersion(Map<String, dynamic> version) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/csv_version.json');
      await file.writeAsString(jsonEncode(version));
    } catch (_) {}
  }
}

Future<List<String>> readCsvLines(String fileName) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    if (await file.exists()) {
      final content = await file.readAsString(encoding: utf8);
      return content
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
    }
  } catch (_) {}
  return _readAssetLines(fileName);
}

Future<List<String>> _readAssetLines(String fileName) async {
  final raw = await rootBundle.loadString('Assets/$fileName');
  return raw
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
}

List<String> splitCsvLine(String line) {
  final result = <String>[];
  final sb = StringBuffer();
  bool inQuotes = false;
  for (int i = 0; i < line.length; i++) {
    final c = line[i];
    if (c == '"') {
      inQuotes = !inQuotes;
    } else if (c == ',' && !inQuotes) {
      result.add(sb.toString().trim());
      sb.clear();
    } else {
      sb.write(c);
    }
  }
  result.add(sb.toString().trim());
  return result;
}

Future<List<String>> readAssetLines(String fileName) => readCsvLines(fileName);

// ─────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────
class QuestionModel {
  final String id;
  final String dot;
  final String questionText;
  final String answer1;
  final String answer2;
  final String answer3;
  final String answer4;
  final int correctAnswer;
  final String category;
  final String subcategory;
  final String explanation;
  final int mustInclude;
  final int difficulty;

  QuestionModel({
    required this.id,
    required this.dot,
    required this.questionText,
    required this.answer1,
    required this.answer2,
    required this.answer3,
    required this.answer4,
    required this.correctAnswer,
    required this.category,
    required this.subcategory,
    required this.explanation,
    required this.mustInclude,
    required this.difficulty,
  });
}

class FactModel {
  final String id;
  final String category;
  final String fact;
  FactModel({required this.id, required this.category, required this.fact});
}

class ProTipModel {
  final String id;
  final String type;
  final String category;
  final String content;
  final bool mustHave;

  ProTipModel({
    required this.id,
    required this.type,
    required this.category,
    required this.content,
    required this.mustHave,
  });
}

class ScenarioDrillModel {
  final String id;
  final String category;
  final int difficulty;
  final String servSafeVersion;
  final String scenario;
  final String choice1;
  final String choice2;
  final String choice3;
  final int correctChoice;
  final String explanation;

  ScenarioDrillModel({
    required this.id,
    required this.category,
    required this.difficulty,
    required this.servSafeVersion,
    required this.scenario,
    required this.choice1,
    required this.choice2,
    required this.choice3,
    required this.correctChoice,
    required this.explanation,
  });
}

// ─────────────────────────────────────────────────────────────────
// LOADERS
// ─────────────────────────────────────────────────────────────────
class QuestionLoader {
  static Future<List<QuestionModel>> loadAll({bool shuffle = true}) async {
    final lines = await readCsvLines('FinalTestQuestions5.csv');
    final questions = <QuestionModel>[];

    for (int i = 1; i < lines.length; i++) {
      final parts = splitCsvLine(lines[i]);
      if (parts.length < 13) continue;

      int correctAnswer = 0;
      final parsed = int.tryParse(parts[7]);
      if (parsed != null && parsed >= 1 && parsed <= 4)
        correctAnswer = parsed - 1;

      final mustInclude = int.tryParse(parts[11]) ?? 0;
      final difficulty = (int.tryParse(parts[12]) ?? 2).clamp(1, 3);

      questions.add(
        QuestionModel(
          id: parts[0],
          dot: parts[1],
          questionText: parts[2],
          answer1: parts[3],
          answer2: parts[4],
          answer3: parts[5],
          answer4: parts[6],
          correctAnswer: correctAnswer,
          category: _normalizeCategory(parts[8]),
          subcategory: parts[9],
          explanation: parts[10],
          mustInclude: mustInclude,
          difficulty: difficulty,
        ),
      );
    }

    if (shuffle) questions.shuffle();
    return questions;
  }

  static Future<List<QuestionModel>> loadByCategory(
    String category, {
    bool shuffle = true,
  }) async {
    final all = await loadAll(shuffle: false);
    final filtered = all
        .where((q) => q.category.toLowerCase() == category.toLowerCase())
        .toList();
    if (shuffle) filtered.shuffle();
    return filtered;
  }

  static String _normalizeCategory(String category) {
    if (category.toLowerCase() == 'pest management')
      return 'Food Safety Management';
    return category;
  }
}

class FactLoader {
  static Future<List<FactModel>> loadAll({bool shuffle = true}) async {
    final lines = await readCsvLines('MarqueeFacts.csv');
    final facts = <FactModel>[];
    for (int i = 1; i < lines.length; i++) {
      final parts = splitCsvLine(lines[i]);
      if (parts.length != 3) continue;
      facts.add(FactModel(id: parts[0], category: parts[1], fact: parts[2]));
    }
    if (shuffle) facts.shuffle();
    return facts;
  }

  static Future<List<FactModel>> loadByCategory(
    String category, {
    bool shuffle = true,
  }) async {
    final all = await loadAll(shuffle: false);
    final filtered = all
        .where((f) => f.category.toLowerCase() == category.toLowerCase())
        .toList();
    if (shuffle) filtered.shuffle();
    return filtered;
  }
}

class ProTipLoader {
  static Future<List<ProTipModel>> loadAll({bool shuffle = false}) async {
    final lines = await readCsvLines('ServSafeProTips.csv');
    final tips = <ProTipModel>[];
    for (int i = 1; i < lines.length; i++) {
      final parts = splitCsvLine(lines[i]);
      if (parts.length < 5) continue;
      tips.add(
        ProTipModel(
          id: parts[0],
          type: parts[1],
          category: parts[2],
          content: parts[3],
          mustHave: parts[4] == '1',
        ),
      );
    }
    if (shuffle) tips.shuffle();
    return tips;
  }
}

class ScenarioDrillLoader {
  static const String currentVersion = '8';

  static Future<List<ScenarioDrillModel>> loadAll() async {
    final lines = await readCsvLines('ScenarioDrills.csv');
    final drills = <ScenarioDrillModel>[];
    for (int i = 1; i < lines.length; i++) {
      final parts = splitCsvLine(lines[i]);
      if (parts.length < 10) continue;
      final correct = int.tryParse(parts[8]) ?? 1;
      drills.add(
        ScenarioDrillModel(
          id: parts[0],
          category: parts[1],
          difficulty: int.tryParse(parts[2]) ?? 2,
          servSafeVersion: parts[3],
          scenario: parts[4],
          choice1: parts[5],
          choice2: parts[6],
          choice3: parts[7],
          correctChoice: correct.clamp(1, 3),
          explanation: parts[9],
        ),
      );
    }
    return drills;
  }
}

extension QuestionShuffleX on QuestionModel {
  QuestionModel shuffled() {
    final answers = [answer1, answer2, answer3, answer4];
    final indices = [0, 1, 2, 3]..shuffle();
    final newCorrect = indices.indexOf(correctAnswer);
    return QuestionModel(
      id: id,
      dot: dot,
      questionText: questionText,
      answer1: answers[indices[0]],
      answer2: answers[indices[1]],
      answer3: answers[indices[2]],
      answer4: answers[indices[3]],
      correctAnswer: newCorrect,
      category: category,
      subcategory: subcategory,
      explanation: explanation,
      mustInclude: mustInclude,
      difficulty: difficulty,
    );
  }
}

void debugPrint(String message) => print(message);
