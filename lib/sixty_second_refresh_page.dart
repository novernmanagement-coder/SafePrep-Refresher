import 'package:flutter/material.dart';
import 'constants.dart';
import 'csv_loader.dart';
import 'home_page.dart';

class SixtySecondRefreshPage extends StatefulWidget {
  const SixtySecondRefreshPage({super.key});

  @override
  State<SixtySecondRefreshPage> createState() => _SixtySecondRefreshPageState();
}

class _SixtySecondRefreshPageState extends State<SixtySecondRefreshPage> {
  static const int questionMs = 3000;
  static const int answerMs = 2000;

  static const Map<String, Color> categoryColors = {
    'Time & Temperature': Color(0xFFC0392B),
    'Cross-Contamination': Color(0xFFE67E22),
    'Food Preparation': Color(0xFF27AE60),
    'Receiving & Storage': Color(0xFF2980B9),
    'Personal Hygiene': Color(0xFF8E44AD),
    'Cleaning & Sanitizing': Color(0xFF16A085),
    'Facility & Equipment': Color(0xFF34495E),
    'Food Safety Management': Color(0xFFB7950B),
  };

  static const List<String> allCategories = [
    'Time & Temperature',
    'Cross-Contamination',
    'Food Preparation',
    'Receiving & Storage',
    'Personal Hygiene',
    'Cleaning & Sanitizing',
    'Facility & Equipment',
    'Food Safety Management',
  ];

  bool _isStopped = false;
  bool _showingBurst = false;
  bool _mustKnowMode = false;
  String _currentCategory = '';
  String _questionText = '';
  String _answerText = '';
  String _progressText = '';
  double _timerProgress = 0.0;
  bool _showAnswer = false;
  bool _animating = false;

  void _navigateHome() {
    setState(() => _isStopped = true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  Future<void> _startCategoryBursts(String category) async {
    setState(() {
      _isStopped = false;
      _showingBurst = true;
      _currentCategory = category;
    });

    List<QuestionModel> questions;
    if (_mustKnowMode) {
      final all = await QuestionLoader.loadByCategory(category);
      questions = all.where((q) => q.mustInclude == 1).toList();
      if (questions.isEmpty) questions = all;
    } else {
      questions = await QuestionLoader.loadByCategory(category);
    }

    if (questions.isEmpty) {
      if (mounted) setState(() => _showingBurst = false);
      return;
    }
    questions.shuffle();
    await _runBursts(questions);
    if (!_isStopped && mounted) setState(() => _showingBurst = false);
  }

  Future<void> _runBursts(List<QuestionModel> questions) async {
    int i = 0;
    while (!_isStopped && mounted) {
      final q = questions[i % questions.length];
      final answers = [q.answer1, q.answer2, q.answer3, q.answer4];
      final correctText = answers[q.correctAnswer];

      if (i > 0 && i % questions.length == 0) questions.shuffle();

      setState(() {
        _progressText = '${(i % questions.length) + 1} of ${questions.length}';
        _questionText = q.questionText;
        _answerText = correctText;
        _showAnswer = false;
        _timerProgress = 0.0;
        _animating = true;
      });

      await _animateTimer(questionMs);
      if (_isStopped || !mounted) return;

      setState(() => _showAnswer = true);
      await _animateTimer(answerMs);
      if (_isStopped || !mounted) return;

      setState(() => _animating = false);
      await Future.delayed(const Duration(milliseconds: 150));

      i++;
    }
  }

  Future<void> _animateTimer(int totalMs) async {
    final steps = totalMs ~/ 50;
    for (int s = 0; s <= steps; s++) {
      if (_isStopped || !mounted) return;
      setState(() => _timerProgress = s / steps);
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  Widget _buildCategoryGrid() {
    final rows = <Widget>[];
    for (int i = 0; i < allCategories.length; i += 2) {
      final cat1 = allCategories[i];
      final cat2 = i + 1 < allCategories.length ? allCategories[i + 1] : null;
      rows.add(
        Row(
          children: [
            Expanded(child: _buildCatButton(cat1)),
            const SizedBox(width: 10),
            Expanded(
              child: cat2 != null ? _buildCatButton(cat2) : const SizedBox(),
            ),
          ],
        ),
      );
      if (i + 2 < allCategories.length) rows.add(const SizedBox(height: 10));
    }

    rows.add(const SizedBox(height: 8));
    rows.add(
      Text(
        '\u2191  \u2191  \u2191',
        style: TextStyle(
          fontSize: 18,
          color: AppColors.gold,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
    rows.add(const SizedBox(height: 4));
    rows.add(
      GestureDetector(
        onTap: () => setState(() => _mustKnowMode = !_mustKnowMode),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: _mustKnowMode ? AppColors.gold : AppColors.cardBackground,
            border: Border.all(color: AppColors.gold),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                'TOGGLE SWITCH',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: _mustKnowMode
                      ? AppColors.goldText.withValues(alpha: 0.7)
                      : AppColors.subtleText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                _mustKnowMode
                    ? 'MODE: ServSafe\u00ae Test-Critical'
                    : 'MODE: All Questions',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _mustKnowMode ? AppColors.goldText : AppColors.gold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    return SingleChildScrollView(child: Column(children: rows));
  }

  Widget _buildCatButton(String category) {
    final color = categoryColors[category] ?? AppColors.gold;
    return SizedBox(
      height: 64,
      child: ElevatedButton(
        onPressed: () => _startCategoryBursts(category),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              category,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _mustKnowMode
                  ? 'MODE: ServSafe\u00ae Test-Critical'
                  : 'MODE: All Questions',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: _mustKnowMode
                    ? AppColors.gold
                    : Colors.white.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBurstPlayer() {
    final catColor = categoryColors[_currentCategory] ?? AppColors.gold;
    return Column(
      spacing: 12,
      children: [
        Text(
          _progressText,
          style: TextStyle(fontSize: 13, color: AppColors.subtleText),
          textAlign: TextAlign.center,
        ),
        if (_mustKnowMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'MUST KNOW',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.goldText,
                letterSpacing: 1.2,
              ),
            ),
          ),
        AnimatedOpacity(
          opacity: _animating ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: catColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _questionText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        AnimatedOpacity(
          opacity: _showAnswer ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF3BA776),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _answerText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Container(
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0xFFDDDDDD),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: _timerProgress,
              child: Container(
                decoration: BoxDecoration(
                  color: catColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: () => setState(() {
            _isStopped = true;
            _showingBurst = false;
          }),
          child: Text(
            '\u2190 Back to categories',
            style: TextStyle(fontSize: 13, color: AppColors.gold),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Column(
                spacing: 4,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _navigateHome,
                        child: Row(
                          children: [
                            Text(
                              'Safe',
                              style: TextStyle(
                                fontSize: AppFonts.header,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Image.asset(
                              'Assets/splash.png',
                              width: 36,
                              height: 36,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Prep™',
                              style: TextStyle(
                                fontSize: AppFonts.header,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '\u23f1 60-Second Refresh',
                    style: TextStyle(
                      fontSize: AppFonts.header,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    _showingBurst
                        ? _currentCategory
                        : 'Select a category to begin',
                    style: TextStyle(fontSize: 13, color: AppColors.subtleText),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _showingBurst
                    ? _buildBurstPlayer()
                    : _buildCategoryGrid(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _navigateHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.goldText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    '\u2190 Home',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
