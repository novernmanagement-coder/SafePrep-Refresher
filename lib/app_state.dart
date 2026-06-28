class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  // Purchase
  bool hasUnlockedApp = false;

  // Exam date
  DateTime? examDate;

  // Username (optional)
  String userName = '';

  // Days until exam
  int? get daysUntilExam {
    if (examDate == null) return null;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final examDateOnly = DateTime(
      examDate!.year,
      examDate!.month,
      examDate!.day,
    );
    return examDateOnly.difference(todayDate).inDays;
  }

  bool get isExamDay {
    final days = daysUntilExam;
    return days != null && days == 0;
  }

  bool get examPassed {
    final days = daysUntilExam;
    return days != null && days < 0;
  }

  // Countdown message
  String get countdownMessage {
    final days = daysUntilExam;
    if (days == null) return '';
    if (days > 7) return 'One or two tools per day. Steady pace.';
    if (days >= 3)
      return 'Study the categories you feel you need to work on. Two or three sessions daily.';
    if (days >= 1)
      return 'As many short bursts as you can fit in. Rapid Fire every chance you get.';
    if (days == 0) return '60-Second Refresh as often as you feel the need.';
    return '';
  }

  void reset() {
    hasUnlockedApp = false;
    examDate = null;
    userName = '';
  }
}
