import 'dart:async';
import 'package:flutter/material.dart';
import 'constants.dart';
import 'csv_loader.dart';
import 'mixpanel_service.dart';
import 'home_page.dart';

class InstructorTipsPage extends StatefulWidget {
  const InstructorTipsPage({super.key});

  @override
  State<InstructorTipsPage> createState() => _InstructorTipsPageState();
}

class _InstructorTipsPageState extends State<InstructorTipsPage> {
  // ── ASSET PATHS — confirm/replace if actual filenames differ ──
  // "Asking" = default/neutral pose, shown for tip/memoryhook/scenario.
  // "Explaining" = shown specifically when the current tip is type 'trap',
  // since that's the moment she needs to slow down and walk through it.
  static const String _instructorAsking = 'Assets/instructor_asking.png';
  static const String _instructorExplaining =
      'Assets/instructor_explaining.png';

  static const Duration _tipHold = Duration(seconds: 8);
  static const Duration _bubbleTypeSpeed = Duration(milliseconds: 22);

  List<ProTipModel> _tips = [];
  int _tipIndex = 0;
  String _bubbleText = '';
  Timer? _typeTimer;
  Timer? _holdTimer;

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
    MixpanelService.instance.track('proctor_tips_viewed');
    _loadTips();
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _holdTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTips() async {
    var tips = await ProTipLoader.loadAll(shuffle: true);
    if (!mounted) return;
    setState(() => _tips = tips);
    if (tips.isNotEmpty) _typeCurrentTip();
  }

  void _typeCurrentTip() {
    if (_tips.isEmpty) return;
    final full = _tips[_tipIndex].content;
    _bubbleText = '';
    int charIndex = 0;
    _typeTimer?.cancel();
    _typeTimer = Timer.periodic(_bubbleTypeSpeed, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (charIndex >= full.length) {
        timer.cancel();
        _holdTimer = Timer(_tipHold, _advanceTip);
        return;
      }
      setState(() => _bubbleText += full[charIndex]);
      charIndex++;
    });
  }

  void _advanceTip() {
    if (!mounted || _tips.isEmpty) return;
    setState(() => _tipIndex = (_tipIndex + 1) % _tips.length);
    _typeCurrentTip();
  }

  void _goNext() {
    _typeTimer?.cancel();
    _holdTimer?.cancel();
    _advanceTip();
  }

  void _goPrev() {
    if (_tips.isEmpty) return;
    _typeTimer?.cancel();
    _holdTimer?.cancel();
    setState(() => _tipIndex = (_tipIndex - 1 + _tips.length) % _tips.length);
    _typeCurrentTip();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildTipStage()),
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

  Widget _buildTipStage() {
    if (_tips.isEmpty) {
      return Center(child: CircularProgressIndicator(color: AppColors.gold));
    }

    final tip = _tips[_tipIndex];
    final style = _typeStyle(tip.type);
    final isTrap = tip.type.toLowerCase() == 'trap';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Progress
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '${_tipIndex + 1} of ${_tips.length}',
              style: TextStyle(fontSize: 12, color: AppColors.subtleText),
            ),
          ),

          Expanded(
            child: Stack(
              children: [
                // Speech bubble — anchored above the instructor's position
                // (bottom-right), so it reads as coming from her.
                Positioned(
                  left: 0,
                  right: 90,
                  top: 0,
                  bottom: 140,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: _buildSpeechBubble(style, tip.type),
                  ),
                ),

                // FSME — eyes only, sitting to the instructor's left,
                // idle/looking around. No dialogue of her own here.
                Positioned(
                  right: 130,
                  bottom: 10,
                  child: const _FsmeEyesOnly(),
                ),

                // Instructor — bottom right, pose swaps on trap tips.
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Image.asset(
                      isTrap ? _instructorExplaining : _instructorAsking,
                      key: ValueKey(isTrap),
                      width: 110,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Manual override controls — auto-cycle still runs, these just
          // let the user jump ahead or back without waiting.
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _goPrev,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gold,
                      side: BorderSide(color: AppColors.gold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('← Previous'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _goNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.goldText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Next →'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechBubble(
    ({Color color, String label, String icon}) style,
    String type,
  ) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(4),
        ),
        border: Border.all(color: style.color, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: style.color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${style.icon}  ${style.label}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _bubbleText,
            style: const TextStyle(
              fontSize: AppFonts.body,
              color: Color(0xFF1A1A1A),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// FSME eyes-only companion — reuses the same idle blink/look pattern as
// the 60-Second Refresh command box, but with no terminal/dialogue here.
// Purely a presence sitting beside the instructor.
class _FsmeEyesOnly extends StatefulWidget {
  const _FsmeEyesOnly();

  @override
  State<_FsmeEyesOnly> createState() => _FsmeEyesOnlyState();
}

class _FsmeEyesOnlyState extends State<_FsmeEyesOnly> {
  static const Duration _blinkEvery = Duration(seconds: 4);
  static const Duration _lookEvery = Duration(seconds: 3);

  Timer? _blinkTimer;
  Timer? _lookTimer;
  bool _blinking = false;
  _EyeLook _look = _EyeLook.center;
  int _lookTick = 0;

  @override
  void initState() {
    super.initState();
    _blinkTimer = Timer.periodic(_blinkEvery, (_) => _doBlink());
    _lookTimer = Timer.periodic(_lookEvery, (_) => _doLook());
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _lookTimer?.cancel();
    super.dispose();
  }

  void _doBlink() {
    if (!mounted) return;
    setState(() => _blinking = true);
    Timer(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _blinking = false);
    });
  }

  void _doLook() {
    if (!mounted) return;
    _lookTick++;
    final roll = _lookTick % 3;
    final next = roll == 0
        ? _EyeLook.left
        : roll == 1
        ? _EyeLook.right
        : _EyeLook.center;
    setState(() => _look = next);
    if (next != _EyeLook.center) {
      Timer(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _look = _EyeLook.center);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        _FsmeEye(blinking: _blinking, look: _look),
        _FsmeEye(blinking: _blinking, look: _look),
      ],
    );
  }
}

enum _EyeLook { left, right, center }

class _FsmeEye extends StatelessWidget {
  final bool blinking;
  final _EyeLook look;

  const _FsmeEye({required this.blinking, required this.look});

  @override
  Widget build(BuildContext context) {
    const double size = 22;
    double pupilOffset = 0;
    if (look == _EyeLook.left) pupilOffset = -5;
    if (look == _EyeLook.right) pupilOffset = 5;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: blinking ? 3 : size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFFF8888), Color(0xFFCC0000), Color(0xFF2A0000)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x99FF0000), blurRadius: 8, spreadRadius: 1),
        ],
      ),
      child: blinking
          ? null
          : AnimatedAlign(
              duration: const Duration(milliseconds: 400),
              alignment: Alignment(pupilOffset / 10, 0),
              child: Container(
                width: size * 0.4,
                height: size * 0.4,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFF660000), Color(0xFF1A0000)],
                  ),
                ),
              ),
            ),
    );
  }
}
