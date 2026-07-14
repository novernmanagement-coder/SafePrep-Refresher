import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'csv_loader.dart';
import 'mixpanel_service.dart';
import 'home_page.dart';

class RapidFirePage extends StatefulWidget {
  const RapidFirePage({super.key});

  @override
  State<RapidFirePage> createState() => _RapidFirePageState();
}

class _RapidFirePageState extends State<RapidFirePage>
    with TickerProviderStateMixin {
  static const int _questionDurationMs = 3000;
  static const int _answerDurationMs = 5000;
  static const int _slideInMs = 320;
  static const int _slideOutMs = 260;

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

  static const Map<String, Color> _categoryColors = {
    'Time & Temperature': Color(0xFFC0392B),
    'Cross-Contamination': Color(0xFFE67E22),
    'Food Preparation': Color(0xFF27AE60),
    'Receiving & Storage': Color(0xFF2980B9),
    'Personal Hygiene': Color(0xFF8E44AD),
    'Cleaning & Sanitizing': Color(0xFF16A085),
    'Facility & Equipment': Color(0xFF34495E),
    'Food Safety Management': Color(0xFFB7950B),
  };

  List<QuestionModel> _deck = [];
  int _currentIndex = 0;
  bool _isPaused = false;
  bool _isStopped = false;
  bool _answerTapped = false;
  int _correctSlot = 0;

  int _correct = 0;
  int _incorrect = 0;
  int _skipped = 0;

  // Guards rapid_fire_completed from firing more than once per session —
  // _stopAndExit can in principle be reached from more than one control.
  bool _completedFired = false;

  String _questionText = '';
  String _answerAText = '';
  String _answerBText = '';
  Color _bubbleColor = AppColors.gold;
  Color _accentColor = AppColors.gold;

  AnimationController? _slideController;
  Animation<Offset> _slideOffset = const AlwaysStoppedAnimation(Offset.zero);

  bool _answersVisible = false;
  Color _colorA = const Color(0xFF4A6FA5);
  Color _colorB = const Color(0xFF4A6FA5);
  bool _buttonsEnabled = true;

  double _timerProgress = 0.0;
  Color _timerColor = AppColors.gold;

  String? _selectedCategory;
  bool _showCategoryPicker = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _isStopped = true;
    _slideController?.dispose();
    super.dispose();
  }

  Future<void> _saveResults() async {
    if (_correct == 0 && _incorrect == 0 && _skipped == 0) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rapidfire_correct', _correct);
    await prefs.setInt('rapidfire_incorrect', _incorrect);
    await prefs.setInt('rapidfire_skipped', _skipped);
    await prefs.setString(
      'rapidfire_timestamp',
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> _startWithCategory(String? category) async {
    setState(() {
      _selectedCategory = category;
      _showCategoryPicker = false;
    });
    MixpanelService.instance.track(
      'rapid_fire_started',
      properties: {'category': category ?? 'All Categories'},
    );
    await _loadDeck();
    _runSession();
  }

  Future<void> _runSession() async {
    while (!_isStopped) {
      if (_currentIndex >= _deck.length) _currentIndex = 0;
      if (_deck.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        continue;
      }

      final q = _deck[_currentIndex];
      if (!mounted) return;
      setState(() {
        _answerTapped = false;
        _answersVisible = false;
        _timerProgress = 0.0;
        _timerColor = AppColors.gold;
        _buttonsEnabled = true;
        _colorA = const Color(0xFF4A6FA5);
        _colorB = const Color(0xFF4A6FA5);
        _applyQuestion(q);
      });

      await _slideIn();
      if (_isStopped) return;
      await _pausableDelay(_questionDurationMs, warningMs: 0);
      if (_isStopped) return;
      if (mounted) setState(() => _answersVisible = true);
      await _pausableDelay(_answerDurationMs, warningMs: 2000);
      if (_isStopped) return;
      if (!_answerTapped && mounted) setState(() => _skipped++);
      await Future.delayed(const Duration(milliseconds: 200));
      if (_isStopped) return;
      await _slideOut();
      _currentIndex++;
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  void _applyQuestion(QuestionModel q) {
    String category = q.category;
    if (category.toLowerCase() == 'pest management')
      category = 'Food Safety Management';
    _bubbleColor = _categoryColors[category] ?? AppColors.gold;
    _accentColor = _bubbleColor;
    _questionText = q.questionText;

    final answers = [q.answer1, q.answer2, q.answer3, q.answer4];
    final correctText = answers[q.correctAnswer];
    final wrongs = <String>[];
    for (int i = 0; i < answers.length; i++) {
      if (i != q.correctAnswer) wrongs.add(answers[i]);
    }
    wrongs.shuffle();

    _correctSlot = Random().nextInt(2);
    if (_correctSlot == 0) {
      _answerAText = correctText;
      _answerBText = wrongs[0];
    } else {
      _answerAText = wrongs[0];
      _answerBText = correctText;
    }
  }

  void _onAnswerA() {
    if (!_buttonsEnabled || _answerTapped) return;
    _answerTapped = true;
    _handleAnswer(isCorrect: _correctSlot == 0, tappedA: true);
  }

  void _onAnswerB() {
    if (!_buttonsEnabled || _answerTapped) return;
    _answerTapped = true;
    _handleAnswer(isCorrect: _correctSlot == 1, tappedA: false);
  }

  void _handleAnswer({required bool isCorrect, required bool tappedA}) {
    setState(() {
      _buttonsEnabled = false;
      if (isCorrect) {
        _correct++;
        if (tappedA) {
          _colorA = const Color(0xFF2E7D32);
          _colorB = const Color(0xFF888888);
        } else {
          _colorB = const Color(0xFF2E7D32);
          _colorA = const Color(0xFF888888);
        }
      } else {
        _incorrect++;
        if (tappedA) {
          _colorA = const Color(0xFFC62828);
          _colorB = const Color(0xFF2E7D32);
        } else {
          _colorB = const Color(0xFFC62828);
          _colorA = const Color(0xFF2E7D32);
        }
      }
    });
  }

  Future<void> _pausableDelay(int totalMs, {required int warningMs}) async {
    int elapsed = 0;
    while (elapsed < totalMs) {
      if (_isStopped || _answerTapped) return;
      if (!_isPaused) {
        await Future.delayed(const Duration(milliseconds: 100));
        elapsed += 100;
        if (mounted)
          setState(() {
            _timerProgress = elapsed / totalMs;
            if (warningMs > 0 && elapsed >= totalMs - warningMs)
              _timerColor = const Color(0xFFC62828);
          });
      } else {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  Future<void> _slideIn() async {
    _slideController?.dispose();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _slideInMs),
    );
    _slideOffset = Tween<Offset>(begin: const Offset(1.5, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _slideController!,
            curve: Curves.easeOutCubic,
          ),
        );
    if (mounted) setState(() {});
    await _slideController!.forward();
  }

  Future<void> _slideOut() async {
    _slideController?.dispose();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _slideOutMs),
    );
    _slideOffset = Tween<Offset>(begin: Offset.zero, end: const Offset(-1.5, 0))
        .animate(
          CurvedAnimation(parent: _slideController!, curve: Curves.easeInCubic),
        );
    if (mounted) setState(() {});
    await _slideController!.forward();
  }

  Future<void> _loadDeck({bool append = false}) async {
    final all = await QuestionLoader.loadAll(shuffle: false);
    List<QuestionModel> filtered = all;
    if (_selectedCategory != null) {
      filtered = all
          .where(
            (q) =>
                q.category.toLowerCase() == _selectedCategory!.toLowerCase() ||
                (q.category.toLowerCase() == 'pest management' &&
                    _selectedCategory == 'Food Safety Management'),
          )
          .toList();
    }
    filtered.shuffle();
    final newCards = filtered.take(50).toList();
    if (mounted)
      setState(() {
        if (append)
          _deck.addAll(newCards);
        else
          _deck = newCards;
      });
  }

  void _fireCompletedIfDone() {
    if (_completedFired) return;
    // Nothing to report if the session never got underway (category
    // picker still showing, no questions answered/skipped yet).
    if (_correct == 0 && _incorrect == 0 && _skipped == 0) return;
    _completedFired = true;
    MixpanelService.instance.track(
      'rapid_fire_completed',
      properties: {
        'correct': _correct,
        'incorrect': _incorrect,
        'skipped': _skipped,
      },
    );
  }

  Future<void> _stopAndExit() async {
    _isStopped = true;
    _fireCompletedIfDone();
    await _saveResults();
    if (mounted)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (_showCategoryPicker) return _buildCategoryPicker(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildCardArea()),
            _buildScoreCounters(),
            _buildControls(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _stopAndExit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.goldText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    '← Home',
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

  Widget _buildCategoryPicker(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _stopAndExit,
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
              ),
              Text(
                '⚡ Rapid Fire',
                style: TextStyle(
                  fontSize: AppFonts.header,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Select a category or go all in',
                style: TextStyle(
                  fontSize: AppFonts.caption,
                  color: AppColors.subtleText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _startWithCategory(null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.goldText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'All Categories',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.5,
                  children: allCategories.map((cat) {
                    final color = _categoryColors[cat] ?? AppColors.gold;
                    return ElevatedButton(
                      onPressed: () => _startWithCategory(cat),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(
                        cat,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _stopAndExit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.goldText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    '← Home',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _stopAndExit,
            child: Image.asset(
              'Assets/splash.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '⚡ Rapid Fire',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
                Text(
                  _selectedCategory ?? 'All Categories',
                  style: TextStyle(
                    fontSize: AppFonts.caption,
                    color: AppColors.subtleText,
                  ),
                ),
              ],
            ),
          ),
          _ctrlButton('Stop', _stopAndExit),
        ],
      ),
    );
  }

  Widget _buildCardArea() {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 3,
            color: _accentColor.withValues(alpha: 0.4),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: SlideTransition(
              position: _slideOffset,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildQuestionBubble(),
                  const SizedBox(height: 16),
                  AnimatedOpacity(
                    opacity: _answersVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: _buildAnswerButtons(),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 24,
          right: 24,
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _timerProgress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: _timerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionBubble() {
    return CustomPaint(
      painter: _BubblePainter(color: _bubbleColor),
      child: SizedBox(
        width: 320,
        height: 150,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Center(
            child: Text(
              _questionText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerButtons() {
    return SizedBox(
      width: 320,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _answerButton('A', _answerAText, _colorA, _onAnswerA),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _answerButton('B', _answerBText, _colorB, _onAnswerB),
            ),
          ],
        ),
      ),
    );
  }

  Widget _answerButton(
    String label,
    String text,
    Color bgColor,
    VoidCallback onTap,
  ) {
    return ElevatedButton(
      onPressed: _buttonsEnabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        disabledBackgroundColor: bgColor,
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, 72),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0x99FFFFFF),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCounters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: _scoreBox(
              '✓ Correct',
              '$_correct',
              const Color(0xFFE8F5E9),
              const Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _scoreBox(
              '✗ Incorrect',
              '$_incorrect',
              const Color(0xFFFFEBEE),
              const Color(0xFFC62828),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _scoreBox(
              '— Skipped',
              '$_skipped',
              const Color(0xFFF5F5F5),
              const Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreBox(String label, String value, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppFonts.caption,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ctrlButton(
            _isPaused ? '▶ Resume' : '⏸ Pause',
            () => setState(() => _isPaused = !_isPaused),
          ),
          const SizedBox(width: 12),
          _ctrlButton('Load More ＋', () => _loadDeck(append: true)),
        ],
      ),
    );
  }

  Widget _ctrlButton(String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.goldText,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(
          fontSize: AppFonts.body,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(label),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final Color color;
  const _BubblePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(20, 0)
      ..quadraticBezierTo(0, 0, 0, 20)
      ..lineTo(0, 100)
      ..quadraticBezierTo(0, 120, 20, 120)
      ..lineTo(30, 120)
      ..lineTo(20, 145)
      ..lineTo(60, 120)
      ..lineTo(300, 120)
      ..quadraticBezierTo(320, 120, 320, 100)
      ..lineTo(320, 20)
      ..quadraticBezierTo(320, 0, 300, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.color != color;
}
