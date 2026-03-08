import 'package:flutter/material.dart';
import '../config/color.dart';
import 'login_screen.dart';
import 'register_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  BookMind Landing Screen  –  Libria-inspired redesign
// ─────────────────────────────────────────────────────────────────────────────

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  // ── Free Unsplash library background (Trinity College Dublin Long Room) ───
  static const String _libraryImageUrl =
      'https://images.unsplash.com/photo-1481627834876-b7833e8f5570'
      '?w=900&q=80&fit=crop';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ════════════════════════════════════════════════════
            //  HERO  –  library background with overlay content
            // ════════════════════════════════════════════════════
            SizedBox(
              height: sh * 0.62,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── Background photo ─────────────────────────
                  Image.network(
                    _libraryImageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: const Color(0xFF1A0E05),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accent,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1A0E05),
                    ),
                  ),

                  // ── Dark gradient overlay ────────────────────
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xAA000000),
                          Color(0x33000000),
                          Color(0xDD000000),
                        ],
                        stops: [0.0, 0.42, 1.0],
                      ),
                    ),
                  ),

                  // ── Foreground content ───────────────────────
                  SafeArea(
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: SlideTransition(
                        position: _slideUp,
                        child: Column(
                          children: [
                            // ── Nav bar ─────────────────────────
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/images/logo.jpeg',
                                    height: 32,
                                  ),
                                  const Spacer(),
                                  _HeroNavBtn(
                                    label: "Login",
                                    isPrimary: false,
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const LoginScreen()),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _HeroNavBtn(
                                    label: "Sign Up",
                                    isPrimary: true,
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const RegisterScreen()),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // ── Hero headline + CTA ──────────────
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  24, 0, 24, 34),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // Badge pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      border: Border.all(
                                        color:
                                            Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: AppColors.accent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 7),
                                        const Text(
                                          "AI-Powered Book Discovery",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  // Headline
                                  const Text(
                                    "For minds that\nwander and\nwords that last.",
                                    style: TextStyle(
                                      fontFamily: 'Georgia',
                                      fontSize: 38,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.13,
                                      letterSpacing: -0.8,
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  Text(
                                    "Discover books that match your mood,\npowered by AI and passionate readers.",
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color:
                                          Colors.white.withOpacity(0.70),
                                      height: 1.6,
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // ── CTA row (Explore + Join Free) ──
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const RegisterScreen()),
                                        ),
                                        child: Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 22,
                                                  vertical: 13),
                                          decoration: BoxDecoration(
                                            gradient:
                                                AppColors.accentGradient,
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.accent
                                                    .withOpacity(0.45),
                                                blurRadius: 20,
                                                offset:
                                                    const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: const Row(
                                            children: [
                                              Text(
                                                "Explore Library",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  fontSize: 13.5,
                                                ),
                                              ),
                                              SizedBox(width: 6),
                                              Icon(
                                                Icons.arrow_forward_rounded,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const RegisterScreen()),
                                        ),
                                        child: Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 22,
                                                  vertical: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            border: Border.all(
                                              color: Colors.white
                                                  .withOpacity(0.45),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: const Text(
                                            "Join Free",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ════════════════════════════════════════════════════
            //  BELOW HERO  –  features section
            // ════════════════════════════════════════════════════
            Container(
              color: AppColors.background,
              padding: const EdgeInsets.symmetric(
                  horizontal: 22, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Features label ────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 15,
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "WHY BOOKMIND",
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.hintText,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Everything you need to\nfind your next great read.",
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkTextAlt,
                      height: 1.25,
                      letterSpacing: -0.4,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── 3 Feature Cards in a Row ──────────────────
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _FeatureCard(
                            icon: Icons.psychology_rounded,
                            title: "AI Powered",
                            description: "Smart picks tailored to your mood & taste",
                            accentColor: AppColors.primary,
                            bgColors: [
                              AppColors.primary.withOpacity(0.10),
                              AppColors.primary.withOpacity(0.02),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FeatureCard(
                            icon: Icons.favorite_rounded,
                            title: "Personal",
                            description: "Your history shapes every suggestion",
                            accentColor: const Color(0xFFE85D75),
                            bgColors: [
                              const Color(0xFFE85D75).withOpacity(0.10),
                              const Color(0xFFE85D75).withOpacity(0.02),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FeatureCard(
                            icon: Icons.people_rounded,
                            title: "Community",
                            description: "Connect with passionate readers",
                            accentColor: const Color(0xFF2DA882),
                            bgColors: [
                              const Color(0xFF2DA882).withOpacity(0.10),
                              const Color(0xFF2DA882).withOpacity(0.02),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 44),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Vertical Feature Card (icon on top, text below) ─────────────────────────

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;
  final List<Color> bgColors;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.bgColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: bgColors,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon bubble
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(height: 12),
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: accentColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.mediumText,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Nav Button ──────────────────────────────────────────────────────────

class _HeroNavBtn extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _HeroNavBtn({
    required this.label,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return GestureDetector(
        onTap: onPressed,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: Colors.white.withOpacity(0.5), width: 1.5),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}