import 'package:flutter/material.dart';
import 'constants.dart';
import 'csv_loader.dart';
import 'home_page.dart';

class InstructorTipsPage extends StatefulWidget {
  const InstructorTipsPage({super.key});

  @override
  State<InstructorTipsPage> createState() => _InstructorTipsPageState();
}

class _InstructorTipsPageState extends State<InstructorTipsPage> {
  List<ProTipModel> _tips = [];

  static ({Color color, String label, String icon}) _typeStyle(String type) =>
      switch (type.toLowerCase()) {
        'tip' => (color: const Color(0xFF2980B9), label: 'TIP', icon: '💡'),
        'trap' => (color: const Color(0xFFC0392B), label: 'TRAP', icon: '⚠'),
        'memoryhook' => (
          color: const Color(0xFF8E44AD),
          label: 'MEMORY HOOK',
          icon: '🧠',
        ),
        'scenario' => (
          color: const Color(0xFF16A085),
          label: 'SCENARIO',
          icon: '📋',
        ),
        _ => (
          color: const Color(0xFF4A6FA5),
          label: type.toUpperCase(),
          icon: '•',
        ),
      };

  @override
  void initState() {
    super.initState();
    _loadTips();
  }

  Future<void> _loadTips() async {
    var tips = await ProTipLoader.loadAll(shuffle: true);
    if (mounted) setState(() => _tips = tips);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildTipsList()),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                  ),
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
                'Prep™',
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
            "📖 Instructor's Playbook",
            style: TextStyle(
              fontSize: AppFonts.header,
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '25+ years of ServSafe\u00ae expertise',
            style: TextStyle(
              fontSize: AppFonts.caption,
              color: AppColors.subtleText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsList() {
    if (_tips.isEmpty)
      return Center(child: CircularProgressIndicator(color: AppColors.gold));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: _tips.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final tip = _tips[i];
        final style = _typeStyle(tip.type);
        return _buildTipCard(
          content: tip.content,
          typeLabel: style.label,
          icon: style.icon,
          accentColor: style.color,
        );
      },
    );
  }

  Widget _buildTipCard({
    required String content,
    required String typeLabel,
    required String icon,
    required Color accentColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardCornerRadius),
        border: Border(bottom: BorderSide(color: accentColor, width: 3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$icon  $typeLabel',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: AppFonts.body,
              color: Color(0xFF1A1A1A),
              height: 1.57,
            ),
          ),
        ],
      ),
    );
  }
}
