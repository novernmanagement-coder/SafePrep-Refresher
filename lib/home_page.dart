import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'constants.dart';
import 'app_state.dart';
import 'app_state_persistence.dart';
import 'csv_loader.dart';
import 'mixpanel_service.dart';
import 'sixty_second_refresh_page.dart';
import 'rapid_fire_page.dart';
import 'flash_cards_page.dart';
import 'scenario_drills_page.dart';
import 'mnemonics_page.dart';
import 'instructor_tips_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AppState _state = AppState();

  // Marquee queue
  List<String> _marqueeItems = [];

  // Rapid Fire last session
  int? _rfCorrect;
  int? _rfIncorrect;
  int? _rfSkipped;

  @override
  void initState() {
    super.initState();
    _buildMarqueeQueue();
    _loadRapidFireResults();
    MixpanelService.instance.track('home_viewed');
  }

  Future<void> _buildMarqueeQueue() async {
    // Load facts from CSV
    final facts = await FactLoader.loadAll();
    final factStrings = facts.map((f) => f.fact).toList();

    // Load ads and brags from JSON
    List<String> ads = [];
    List<String> brags = [];
    try {
      final jsonStr = await rootBundle.loadString('assets/marquee_brand.json');
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      ads = List<String>.from(data['ads'] ?? []);
      brags = List<String>.from(data['brags'] ?? []);
    } catch (_) {}

    // Build interleaved queue: 5 facts → 1 ad → 1 brag → repeat
    final queue = <String>[];
    int factIdx = 0;
    int adIdx = 0;
    int bragIdx = 0;

    // Build enough cycles to fill ~3 full loops through facts
    final totalCycles = factStrings.isEmpty
        ? 1
        : (factStrings.length / 5).ceil() * 3;

    for (int cycle = 0; cycle < totalCycles; cycle++) {
      for (int i = 0; i < 5; i++) {
        if (factStrings.isNotEmpty) {
          queue.add(factStrings[factIdx % factStrings.length]);
          factIdx++;
        }
      }
      if (ads.isNotEmpty) {
        queue.add(ads[adIdx % ads.length]);
        adIdx++;
      }
      if (brags.isNotEmpty) {
        queue.add(brags[bragIdx % brags.length]);
        bragIdx++;
      }
    }

    if (mounted) setState(() => _marqueeItems = queue);
  }

  Future<void> _loadRapidFireResults() async {
    final prefs = await SharedPreferences.getInstance();
    final correct = prefs.getInt('rapidfire_correct');
    if (correct != null && mounted) {
      setState(() {
        _rfCorrect = correct;
        _rfIncorrect = prefs.getInt('rapidfire_incorrect') ?? 0;
        _rfSkipped = prefs.getInt('rapidfire_skipped') ?? 0;
      });
    }
  }

  Future<void> _pickExamDate() async {
    final initial =
        _state.examDate ?? DateTime.now().add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE8D5A0),
              onPrimary: Color(0xFF1A3A5C),
              surface: Color(0xFF1A3A5C),
              onSurface: Color(0xFFE8D5A0),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _state.examDate = picked);
      AppStatePersistence.save();
    }
  }

  Future<void> _openSafePrepManager() async {
    final uri = Uri.parse(AppStrings.safePrepManagerUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _go(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((_) => _loadRapidFireResults());
  }

  Widget _buildCountdownCard() {
    final days = _state.daysUntilExam;
    if (days == null) return const SizedBox();
    if (_state.examPassed) return const SizedBox();

    String dayLabel;
    String message;
    String countDisplay;

    if (_state.isExamDay) {
      dayLabel = 'TEST DAY ⭐';
      message = '60-Second Refresh as often as you feel the need.';
      countDisplay = '!';
    } else if (days > 7) {
      dayLabel = '$days days away';
      message = 'One or two tools per day. Steady pace.';
      countDisplay = '$days';
    } else if (days >= 3) {
      dayLabel = '$days days away';
      message =
          'Study the categories you feel you need to work on. Two or three sessions daily.';
      countDisplay = '$days';
    } else {
      dayLabel = '$days ${days == 1 ? 'day' : 'days'} away';
      message =
          'As many short bursts as you can fit in. Rapid Fire every chance you get.';
      countDisplay = '$days';
    }

    return GestureDetector(
      onTap: _pickExamDate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(AppSizes.cardCornerRadius),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exam date',
                    style: TextStyle(
                      fontSize: AppFonts.caption,
                      color: AppColors.subtleText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayLabel,
                    style: TextStyle(
                      fontSize: AppFonts.body,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: AppFonts.caption,
                      color: AppColors.subtleText,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            if (!_state.isExamDay) ...[
              const SizedBox(width: 12),
              Text(
                countDisplay,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton(
    String title,
    String description,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(AppSizes.cardCornerRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: AppFonts.caption,
                fontWeight: FontWeight.w600,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.subtleText,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRapidFireResult() {
    if (_rfCorrect == null) return const SizedBox();
    final total = (_rfCorrect ?? 0) + (_rfIncorrect ?? 0) + (_rfSkipped ?? 0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Text(
        '⚡ Last Rapid Fire: $_rfCorrect correct · $_rfIncorrect incorrect · $_rfSkipped skipped  ($total total)',
        style: TextStyle(
          fontSize: AppFonts.caption,
          color: AppColors.subtleText,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
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
                      const SizedBox(width: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Image.asset(
                            'Assets/splash.png',
                            width: 28,
                            height: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'REFRESHER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldText,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Marquee
            Container(
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.marqueeBackground,
                border: Border.all(color: AppColors.marqueeBorder),
                borderRadius: BorderRadius.circular(6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _marqueeItems.isEmpty
                    ? const SizedBox()
                    : MarqueeQueue(items: _marqueeItems),
              ),
            ),

            // Rapid Fire last session result
            _buildRapidFireResult(),

            const SizedBox(height: 12),

            // Scrollable body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Countdown card
                    _buildCountdownCard(),
                    if (_state.daysUntilExam != null && !_state.examPassed)
                      const SizedBox(height: 12),

                    // Tool grid — 2 columns
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.55,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildToolButton(
                          '⏱ 60-Second Refresh',
                          'Quick bursts. Keep knowledge fresh.',
                          () => _go(const SixtySecondRefreshPage()),
                        ),
                        _buildToolButton(
                          '⚡ Rapid Fire',
                          'Fast paced — no time to think, just react.',
                          () => _go(const RapidFirePage()),
                        ),
                        _buildToolButton(
                          '🃏 Flash Cards',
                          'The most proven method for retention.',
                          () => _go(const FlashCardsPage()),
                        ),
                        _buildToolButton(
                          '🎯 Scenario Drills',
                          'Real situations. Real retention.',
                          () => _go(const ScenarioDrillsPage()),
                        ),
                        _buildToolButton(
                          '🧠 Mnemonics',
                          'Acronyms that make the hard stuff stick.',
                          () => _go(const MnemonicsPage()),
                        ),
                        _buildToolButton(
                          '📖 Proctor Tips',
                          'Straight from the people who run them.',
                          () => _go(const InstructorTipsPage()),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Funnel
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.funnelBackground,
                        border: Border.all(color: AppColors.funnelBorder),
                        borderRadius: BorderRadius.circular(
                          AppSizes.cardCornerRadius,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Want to study the full curriculum? Try SafePrep Manager — we\'re so confident you\'ll pass the ServSafe® exam on your first attempt if you use SafePrep Manager, we\'ll give you your money back if you don\'t.',
                            style: TextStyle(
                              fontSize: AppFonts.caption,
                              color: AppColors.subtleText,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _openSafePrepManager,
                            child: Text(
                              'Get SafePrep Manager →',
                              style: TextStyle(
                                fontSize: AppFonts.body,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Footer
                    Text(
                      AppStrings.footerLine3,
                      style: TextStyle(
                        fontSize: AppFonts.footer,
                        color: AppColors.footerText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.footerLine1,
                      style: TextStyle(
                        fontSize: AppFonts.footer,
                        color: AppColors.footerText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── MarqueeQueue ─────────────────────────────────────────────────────────────
// Displays one item at a time, scrolls it across, then advances to the next.

class MarqueeQueue extends StatefulWidget {
  final List<String> items;
  const MarqueeQueue({super.key, required this.items});

  @override
  State<MarqueeQueue> createState() => _MarqueeQueueState();
}

class _MarqueeQueueState extends State<MarqueeQueue> {
  int _index = 0;
  String _currentItem = '';
  final ScrollController _scrollController = ScrollController();
  bool _running = true;

  @override
  void initState() {
    super.initState();
    if (widget.items.isNotEmpty) {
      _currentItem = widget.items[0];
      WidgetsBinding.instance.addPostFrameCallback((_) => _run());
    }
  }

  Future<void> _run() async {
    await Future.delayed(const Duration(seconds: 1));
    while (_running && mounted) {
      if (!_scrollController.hasClients) {
        await Future.delayed(const Duration(milliseconds: 200));
        continue;
      }

      final maxExtent = _scrollController.position.maxScrollExtent;

      if (maxExtent <= 0) {
        // Short text — just wait then advance
        await Future.delayed(const Duration(seconds: 4));
      } else {
        // Scroll across at a consistent speed: ~80px per second
        final durationMs = ((maxExtent / 80) * 1000).round().clamp(3000, 30000);
        await _scrollController.animateTo(
          maxExtent,
          duration: Duration(milliseconds: durationMs),
          curve: Curves.linear,
        );
      }

      if (!_running || !mounted) break;

      // Brief pause at end before switching
      await Future.delayed(const Duration(milliseconds: 600));
      if (!_running || !mounted) break;

      // Advance to next item
      _index = (_index + 1) % widget.items.length;
      if (mounted) {
        setState(() => _currentItem = widget.items[_index]);
      }

      // Reset scroll position for new item
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }

      // Brief pause before scrolling new item
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  @override
  void dispose() {
    _running = false;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          _currentItem,
          style: const TextStyle(fontSize: 12, color: AppColors.marqueeText),
        ),
      ),
    );
  }
}
