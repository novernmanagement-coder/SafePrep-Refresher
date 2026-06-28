import 'package:shared_preferences/shared_preferences.dart';
import 'app_state.dart';

class AppStatePersistence {
  static const _keyUnlocked = 'hasUnlockedApp';
  static const _keyExamDate = 'examDate';
  static const _keyUserName = 'userName';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final state = AppState();
    state.hasUnlockedApp = prefs.getBool(_keyUnlocked) ?? false;
    state.userName = prefs.getString(_keyUserName) ?? '';
    final examDateStr = prefs.getString(_keyExamDate);
    if (examDateStr != null) {
      state.examDate = DateTime.tryParse(examDateStr);
    }
  }

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final state = AppState();
    await prefs.setBool(_keyUnlocked, state.hasUnlockedApp);
    await prefs.setString(_keyUserName, state.userName);
    if (state.examDate != null) {
      await prefs.setString(_keyExamDate, state.examDate!.toIso8601String());
    } else {
      await prefs.remove(_keyExamDate);
    }
  }

  static Future<void> delete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
