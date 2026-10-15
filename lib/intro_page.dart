import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'constants.dart';
import 'app_state.dart';
import 'app_state_persistence.dart';
import 'home_page.dart';
import 'mixpanel_service.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  DateTime _examDate = DateTime.now().add(const Duration(days: 7));
  int? _selectedQuickDays;

  @override
  void initState() {
    super.initState();
    MixpanelService.instance.track('intro_viewed');
    AppState().examDate = _examDate;
    AppStatePersistence.save();
  }

  void _selectQuickDays(int days) {
    final date = DateTime.now().add(Duration(days: days));
    setState(() {
      _selectedQuickDays = days;
      _examDate = date;
    });
    AppState().examDate = date;
    AppStatePersistence.save();
  }

  Future<void> _pickExamDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate,
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
      setState(() {
        _examDate = picked;
        _selectedQuickDays = -1;
      });
      AppState().examDate = picked;
      AppStatePersistence.save();
    }
  }

  // Refresher is free: "Start studying" marks the app as unlocked (so this page is skipped
  // on the next launch) and goes straight to the tools.
  void _start() {
    MixpanelService.instance.track('start_tapped');
    AppState().hasUnlockedApp = true;
    AppStatePersistence.save();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  Future<void> _openSafePrepManager() async {
    final uri = Uri.parse(AppStrings.safePrepManagerUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String get _examDateFormatted {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[_examDate.month - 1]} ${_examDate.day}, ${_examDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSizes.pageMargin,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
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
                          'Prep\u2122',
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

              // Tagline
              Text(
                'These study tools can be used in 60-second timeframes or utilized as a full study guide.',
                style: TextStyle(
                  fontSize: AppFonts.body,
                  color: AppColors.subtleText,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Tool grid — 2 columns
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.0,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildToolCard(
                    '\u23f1 60-Second Refresh',
                    'Quick bursts. Keep knowledge fresh.',
                  ),
                  _buildToolCard(
                    '\u26a1 Rapid Fire',
                    'Fast paced \u2014 no time to think, just react.',
                  ),
                  _buildToolCard(
                    '\uD83C\uDCCF Flash Cards',
                    'The most proven method for retention.',
                  ),
                  _buildToolCard(
                    '\uD83C\uDFAF Scenario Drills',
                    'Real situations. Real retention.',
                  ),
                  _buildToolCard(
                    '\uD83E\uDDE0 Mnemonics',
                    'Acronyms that make the hard stuff stick.',
                  ),
                  _buildToolCard(
                    '\uD83D\uDCD6 Proctor Tips',
                    'Straight from the people who run them.',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Exam date section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(
                    AppSizes.cardCornerRadius,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'When is your ServSafe\u00ae exam?',
                      style: TextStyle(
                        fontSize: AppFonts.body,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select an option so we can tailor your coaching messages.',
                      style: TextStyle(
                        fontSize: AppFonts.caption,
                        color: AppColors.subtleText,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick-tap buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickDayButton('1\u20132 Days', 2),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildQuickDayButton('3\u20136 Days', 5),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: _buildQuickDayButton('7+ Days', 14)),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // OR divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.cardBorder)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.subtleText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.cardBorder)),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Exact date picker
                    GestureDetector(
                      onTap: _pickExamDate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedQuickDays == -1
                              ? AppColors.gold
                              : AppColors.background,
                          border: Border.all(
                            color: _selectedQuickDays == -1
                                ? AppColors.gold
                                : AppColors.cardBorder,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'I know my exact date',
                              style: TextStyle(
                                fontSize: AppFonts.caption,
                                fontWeight: FontWeight.w600,
                                color: _selectedQuickDays == -1
                                    ? AppColors.goldText
                                    : AppColors.gold,
                              ),
                            ),
                            Text(
                              _selectedQuickDays == -1
                                  ? _examDateFormatted
                                  : 'Tap to select \u2192',
                              style: TextStyle(
                                fontSize: AppFonts.caption,
                                color: _selectedQuickDays == -1
                                    ? AppColors.goldText
                                    : AppColors.subtleText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Start button (Refresher is free)
              SizedBox(
                width: double.infinity,
                height: AppSizes.primaryButtonHeight,
                child: ElevatedButton(
                  onPressed: _start,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.goldText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSizes.buttonCornerRadius,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Start studying \u2192',
                    style: TextStyle(
                      fontSize: AppFonts.button,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
                      'Want to study the full curriculum? Try SafePrep Manager \u2014 we\'re so confident you\'ll pass the ServSafe\u00ae exam on your first attempt if you use SafePrep Manager, we\'ll give you your money back if you don\'t.',
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
                        'Get SafePrep Manager \u2192',
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
              const SizedBox(height: 4),
              Text(
                AppStrings.footerLine2,
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
    );
  }

  Widget _buildQuickDayButton(String label, int days) {
    final isSelected = _selectedQuickDays == days;
    return GestureDetector(
      onTap: () => _selectQuickDays(days),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : AppColors.background,
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.cardBorder,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.goldText : AppColors.subtleText,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildToolCard(String title, String description) {
    return Container(
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
    );
  }
}
