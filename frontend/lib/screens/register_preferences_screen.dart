import 'package:bookmind/screens/main_layout.dart';
import 'package:bookmind/screens/web_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:bookmind/services/api_service.dart';
import '../config/color.dart';

class RegisterPreferencesScreen extends StatefulWidget {
  final String username;
  final String email;
  final String password;

  const RegisterPreferencesScreen({
    super.key,
    required this.username,
    required this.email,
    required this.password,
  });

  @override
  State<RegisterPreferencesScreen> createState() =>
      _RegisterPreferencesScreenState();
}

class _RegisterPreferencesScreenState
    extends State<RegisterPreferencesScreen>
    with SingleTickerProviderStateMixin {

  final List<String> emotions = [
    "Happy", "Inspirational", "Dark", "Romantic",
    "Adventurous", "mysterious", "scary", "philosophical",
  ];

  final List<String> interests = [
    "fantasy", "historical", "biography", "self-help",
    "psychology", "business", "finance", "technology",
    "programming", "data-science", "art", "design",
    "poetry", "education", "travel", "health",
    "fitness", "mythology", "politics", "law",
    "environment", "spirituality", "children", "young-adult",
    "parenting", "sports", "cook",
  ];

  final Map<String, String> emotionEmoji = {
    "Happy": "😊", "Inspirational": "✨", "Dark": "🌑", "Romantic": "💕",
    "Adventurous": "🧭", "mysterious": "🔮", "scary": "👁️", "philosophical": "🧠",
  };

  final Map<String, String> interestEmoji = {
    "fantasy": "🧝", "historical": "🏛️", "biography": "📜", "self-help": "🌱",
    "psychology": "🧬", "business": "💼", "finance": "📈", "technology": "💻",
    "programming": "⌨️", "data-science": "📊", "art": "🎨", "design": "✏️",
    "poetry": "🪶", "education": "🎓", "travel": "✈️", "health": "🌿",
    "fitness": "🏋️", "mythology": "⚡", "politics": "🏛", "law": "⚖️",
    "environment": "🌍", "spirituality": "🕊️", "children": "🧸", "young-adult": "🌟",
    "parenting": "👨‍👧", "sports": "⚽", "cook": "🍳",
  };

  List<String> selectedEmotions = [];
  List<String> selectedInterests = [];
  bool loading = false;

  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> finishRegistration() async {
    setState(() => loading = true);

    try {
      await ApiService.register(
        widget.username,
        widget.email,
        widget.password,
        selectedInterests,
        selectedEmotions,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Welcome to BookMind 🎉"),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => MainLayout()),
        (_) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Decorative blobs
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -70,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(0.07),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: Column(
                children: [
                  // ── Top bar ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.border, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.07),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.arrow_back_rounded,
                                color: AppColors.primary, size: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                           Image.asset(
  'assets/images/logo.jpeg',
  height: 32,
),
                      ],
                    ),
                  ),

                  // ── Scrollable body ───────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Hero header ─────────────────────
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 26),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.accent, width: 2),
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                  child: const Icon(
                                      Icons.auto_awesome_rounded,
                                      color: AppColors.accent,
                                      size: 26),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Personalise Your Feed",
                                        style: TextStyle(
                                          fontFamily: 'Georgia',
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        "Pick your moods & interests so we can find perfect books for you.",
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: Colors.white60,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── Progress indicator ───────────────
                          Row(
                            children: [
                              _ProgressStep(
                                  label: "Account",
                                  done: true,
                                  isActive: false),
                              _ProgressLine(done: true),
                              _ProgressStep(
                                  label: "Preferences",
                                  done: false,
                                  isActive: true),
                              _ProgressLine(done: false),
                              _ProgressStep(
                                  label: "Done",
                                  done: false,
                                  isActive: false),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // ── Emotions section ─────────────────
                          _SectionHeader(
                            icon: "🎭",
                            title: "How do you want to feel?",
                            subtitle: "Pick moods that resonate with you",
                            count: selectedEmotions.length,
                          ),
                          const SizedBox(height: 14),

                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: emotions.map((e) {
                              final selected = selectedEmotions.contains(e);
                              return _EmotionTile(
                                label: e,
                                emoji: emotionEmoji[e] ?? "📖",
                                selected: selected,
                                onTap: () => setState(() {
                                  selected
                                      ? selectedEmotions.remove(e)
                                      : selectedEmotions.add(e);
                                }),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 32),

                          // ── Interests section ────────────────
                          _SectionHeader(
                            icon: "🎯",
                            title: "What are you into?",
                            subtitle: "Select all that spark your curiosity",
                            count: selectedInterests.length,
                          ),
                          const SizedBox(height: 14),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: interests.map((i) {
                              final selected = selectedInterests.contains(i);
                              return _InterestPill(
                                label: i,
                                emoji: interestEmoji[i] ?? "📚",
                                selected: selected,
                                onTap: () => setState(() {
                                  selected
                                      ? selectedInterests.remove(i)
                                      : selectedInterests.add(i);
                                }),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 36),

                          // ── Selection summary ────────────────
                          if (selectedEmotions.isNotEmpty ||
                              selectedInterests.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceWarm,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: AppColors.accent.withOpacity(0.4),
                                    width: 1),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded,
                                      color: AppColors.accent, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "${selectedEmotions.length} mood${selectedEmotions.length == 1 ? '' : 's'} · ${selectedInterests.length} interest${selectedInterests.length == 1 ? '' : 's'} selected",
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 20),

                          // ── Finish button ────────────────────
                          GestureDetector(
                            onTap: loading ? null : finishRegistration,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 17),
                              decoration: BoxDecoration(
                                gradient: loading
                                    ? const LinearGradient(
                                        colors: [
                                          AppColors.accentDark,
                                          AppColors.accentDark,
                                        ],
                                      )
                                    : AppColors.accentGradient,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: loading
                                    ? []
                                    : AppColors.glowShadow,
                              ),
                              child: loading
                                  ? const Center(
                                      child: SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.rocket_launch_rounded,
                                            color: Colors.white, size: 20),
                                        SizedBox(width: 10),
                                        Text(
                                          "Finish & Go to Home",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 36),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final int count;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkTextAlt,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.mediumText,
                ),
              ),
            ],
          ),
        ),
        if (count > 0)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$count",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmotionTile extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _EmotionTile({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.secondary,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.accent, size: 15),
            ],
          ],
        ),
      ),
    );
  }
}

class _InterestPill extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _InterestPill({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.moodAdventurous : AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? AppColors.moodAdventurous : AppColors.border,
            width: 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.moodAdventurous.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppColors.secondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  final String label;
  final bool done;
  final bool isActive;

  const _ProgressStep(
      {required this.label, required this.done, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? AppColors.accent
                : isActive
                    ? AppColors.primaryDark
                    : AppColors.border,
            border: Border.all(
              color: isActive ? AppColors.accent : Colors.transparent,
              width: 2,
            ),
          ),
          child: Icon(
            done ? Icons.check_rounded : Icons.circle,
            color: done
                ? Colors.white
                : isActive
                    ? AppColors.accent
                    : AppColors.lightText,
            size: done ? 16 : 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive
                ? AppColors.primaryDark
                : done
                    ? AppColors.accent
                    : AppColors.lightText,
          ),
        ),
      ],
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final bool done;

  const _ProgressLine({required this.done});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          gradient: done ? AppColors.warmGradient : null,
          color: done ? null : AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}