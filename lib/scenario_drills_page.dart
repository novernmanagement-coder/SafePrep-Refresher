import 'dart:math';
import 'package:flutter/material.dart';
import 'constants.dart';
import 'csv_loader.dart';
import 'home_page.dart';

class ScenarioDrillsPage extends StatefulWidget {
  const ScenarioDrillsPage({super.key});

  @override
  State<ScenarioDrillsPage> createState() => _ScenarioDrillsPageState();
}

enum _Phase { scenario, choices, result }

class _ScenarioDrillsPageState extends State<ScenarioDrillsPage> {
  List<ScenarioDrillModel> _scenarios = [];
  int _currentIndex = 0;
  ScenarioDrillModel? _current;

  _Phase _phase = _Phase.scenario;
  bool? _wasCorrect;
  int _selectedChoice = 0;

  double _scenarioOpacity = 0;
  double _choicesOpacity = 0;
  double _resultOpacity = 0;
  double _explanationOpacity = 0;
  double _nextButtonOpacity = 0;
  bool _isExplaining = false;

  final ScrollController _scrollController = ScrollController();

  String get _instructorImage {
    if (_wasCorrect == null)
      return _phase == _Phase.scenario
          ? 'Assets/instructor_asking.png'
          : 'Assets/instructor_waiting.png';
    if (_isExplaining) return 'Assets/instructor_explaining.png';
    return _wasCorrect!
        ? 'Assets/instructor_correct.png'
        : 'Assets/instructor_incorrect.png';
  }

  String? get _studentImage {
    if (_phase == _Phase.scenario) return null;
    if (_wasCorrect == null)
      return _choicesOpacity > 0 ? 'Assets/student_thinking.png' : null;
    if (_isExplaining) return 'Assets/student_listening.png';
    return _wasCorrect!
        ? 'Assets/student_correct.png'
        : 'Assets/student_incorrect.png';
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadScenarios();
    _showPhase1();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadScenarios() async {
    final all = await ScenarioDrillLoader.loadAll();
    final rng = Random();
    const ver = ScenarioDrillLoader.currentVersion;
    final mustHave = all.where((s) => s.servSafeVersion == ver).toList()
      ..shuffle(rng);
    final rest = all.where((s) => s.servSafeVersion != ver).toList()
      ..shuffle(rng);
    _scenarios = [...mustHave, ...rest];
    _currentIndex = 0;
    _current = _scenarios.isNotEmpty ? _scenarios[0] : null;
    if (mounted) setState(() {});
  }

  void _showPhase1() {
    if (_current == null) return;
    setState(() {
      _phase = _Phase.scenario;
      _wasCorrect = null;
      _selectedChoice = 0;
      _isExplaining = false;
      _scenarioOpacity = 0;
      _choicesOpacity = 0;
      _resultOpacity = 0;
      _explanationOpacity = 0;
      _nextButtonOpacity = 0;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) setState(() => _scenarioOpacity = 1);
    });
  }

  Future<void> _transitionToPhase2() async {
    if (_current == null) return;
    setState(() => _phase = _Phase.choices);
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) setState(() => _choicesOpacity = 1);
  }

  void _onChoiceSelected(int choiceIndex) {
    if (_phase != _Phase.choices) return;
    setState(() {
      _selectedChoice = choiceIndex;
      _phase = _Phase.result;
    });
    _transitionToPhase3(choiceIndex == _current!.correctChoice);
  }

  Future<void> _transitionToPhase3(bool isCorrect) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _wasCorrect = isCorrect;
      _choicesOpacity = 0;
    });
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() => _resultOpacity = 1);
    await Future.delayed(Duration(milliseconds: isCorrect ? 1500 : 800));
    if (!mounted) return;
    setState(() => _isExplaining = true);
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    setState(() => _explanationOpacity = 1);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _nextButtonOpacity = 1);
  }

  void _onNextScenario() {
    _currentIndex++;
    if (_currentIndex >= _scenarios.length) {
      _currentIndex = 0;
      _scenarios.shuffle(Random());
    }
    _current = _scenarios[_currentIndex];
    _showPhase1();
  }

  Color _choiceColor(int oneBased) {
    if (_wasCorrect == null) return AppColors.gold;
    if (oneBased == _current!.correctChoice) return const Color(0xFF3BA776);
    if (oneBased == _selectedChoice && !_wasCorrect!)
      return const Color(0xFFE05C5C);
    return const Color(0xFF999999);
  }

  String get _counterText => _scenarios.isEmpty
      ? 'No scenarios available'
      : 'Scenario ${_currentIndex + 1} of ${_scenarios.length}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
              GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                ),
                child: Image.asset(
                  'Assets/splash.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Prep\u2122',
                style: TextStyle(
                  fontSize: AppFonts.header,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '\ud83c\udfaf Scenario Drills',
            style: TextStyle(
              fontSize: AppFonts.header,
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'All categories',
            style: TextStyle(
              fontSize: AppFonts.caption,
              color: AppColors.subtleText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterPanel() {
    final studentAsset = _studentImage;
    return Column(
      children: [
        SizedBox(
          height: 148,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: studentAsset != null
                    ? Image.asset(
                        studentAsset,
                        key: ValueKey(studentAsset),
                        height: 148,
                        fit: BoxFit.contain,
                      )
                    : const SizedBox(width: 90, key: ValueKey('none')),
              ),
              const SizedBox(width: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Image.asset(
                  _instructorImage,
                  key: ValueKey(_instructorImage),
                  height: 148,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
        if (studentAsset != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    'You',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: AppColors.subtleText),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 90,
                  child: Text(
                    'Instructor',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: AppColors.subtleText),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                _buildCharacterPanel(),
                const SizedBox(height: 8),
                _buildScenarioBubble(),
                const SizedBox(height: 12),
                if (_phase == _Phase.choices) _buildChoices(),
                if (_wasCorrect != null) ...[
                  const SizedBox(height: 12),
                  _buildResultBanner(),
                ],
                if (_explanationOpacity > 0) ...[
                  const SizedBox(height: 12),
                  _buildExplanationBubble(),
                ],
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
        _buildBottomButtons(context),
      ],
    );
  }

  Widget _buildScenarioBubble() {
    return AnimatedOpacity(
      opacity: _scenarioOpacity,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDDDDD)),
        ),
        child: Column(
          children: [
            Text(
              _current?.scenario ?? 'Loading...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppFonts.question,
                color: Color(0xFF1A1A1A),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _counterText,
              style: TextStyle(fontSize: 11, color: AppColors.subtleText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoices() {
    final bool enabled = _phase == _Phase.choices;
    return AnimatedOpacity(
      opacity: _choicesOpacity,
      duration: const Duration(milliseconds: 180),
      child: Column(
        children: [
          _choiceButton(1, 'A.  ${_current?.choice1 ?? ''}', enabled),
          const SizedBox(height: 8),
          _choiceButton(2, 'B.  ${_current?.choice2 ?? ''}', enabled),
          const SizedBox(height: 8),
          _choiceButton(3, 'C.  ${_current?.choice3 ?? ''}', enabled),
          const SizedBox(height: 4),
          Text(
            'Which is the BEST response?',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: AppColors.subtleText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _choiceButton(int index, String text, bool enabled) {
    final color = _choiceColor(index);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? () => _onChoiceSelected(index) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 48),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: AppFonts.body),
        ),
        child: Text(text, softWrap: true),
      ),
    );
  }

  Widget _buildResultBanner() {
    final isCorrect = _wasCorrect ?? false;
    return AnimatedOpacity(
      opacity: _resultOpacity,
      duration: const Duration(milliseconds: 250),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isCorrect ? const Color(0xFF3BA776) : const Color(0xFFE05C5C),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          isCorrect
              ? '\u2713  Correct!'
              : '\u2717  Not quite \u2014 see the explanation below',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: AppFonts.subheader,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildExplanationBubble() {
    return AnimatedOpacity(
      opacity: _explanationOpacity,
      duration: const Duration(milliseconds: 350),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDDDDD)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\ud83d\udcd6  Explanation',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.subtleText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _current?.explanation ?? '',
              style: const TextStyle(
                fontSize: AppFonts.body,
                color: Color(0xFF1A1A1A),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Column(
        spacing: 8,
        children: [
          Stack(
            children: [
              if (_phase == _Phase.scenario)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _transitionToPhase2,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.goldText,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(fontSize: AppFonts.body),
                    ),
                    child: const Text('Show me my choices  \u2192'),
                  ),
                ),
              if (_nextButtonOpacity > 0)
                AnimatedOpacity(
                  opacity: _nextButtonOpacity,
                  duration: const Duration(milliseconds: 250),
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _onNextScenario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.goldText,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(fontSize: AppFonts.body),
                      ),
                      child: const Text('Next Scenario  \u2192'),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                foregroundColor: AppColors.gold,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: AppColors.gold),
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
    );
  }
}
