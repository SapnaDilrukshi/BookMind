import 'package:bookmind/screens/main_layout.dart';
import 'package:flutter/material.dart';
import '../config/color.dart';
import '../services/api_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;
  bool loading = false;

  // ── Inline validation error strings (null = no error) ─────────────────────
  String? _emailError;
  String? _passwordError;

  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ── Client-side validation ─────────────────────────────────────────────────
  bool _validate() {
    String? emailErr;
    String? passwordErr;

    // Email format
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    final emailVal = _email.text.trim();
    if (emailVal.isEmpty) {
      emailErr = "Email is required.";
    } else if (!emailRegex.hasMatch(emailVal)) {
      emailErr = "Please enter a valid email address.";
    }

    // Password – must be at least 6 characters
    if (_password.text.isEmpty) {
      passwordErr = "Password is required.";
    } else if (_password.text.length < 6) {
      passwordErr = "Password must be at least 6 characters.";
    }

    setState(() {
      _emailError = emailErr;
      _passwordError = passwordErr;
    });

    return emailErr == null && passwordErr == null;
  }

  Future<void> login() async {
    // Run client-side checks first
    if (!_validate()) return;

    setState(() => loading = true);

    try {
      final user = await ApiService.login(
        _email.text.trim(),
        _password.text.trim(),
      );

      // Clear any leftover errors on success
      setState(() {
        _emailError = null;
        _passwordError = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Welcome ${user["username"]} 👋"),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainLayout()),
      );
    } catch (e) {
      final errMsg = e.toString();

      // Show wrong-password / invalid-credentials errors inline under the
      // password field so the user knows exactly what to fix.
      final isCredentialError = errMsg.toLowerCase().contains('password') ||
          errMsg.toLowerCase().contains('invalid') ||
          errMsg.toLowerCase().contains('credentials') ||
          errMsg.toLowerCase().contains('incorrect') ||
          errMsg.toLowerCase().contains('wrong');

      if (isCredentialError) {
        setState(() {
          _passwordError = "Incorrect password. Please try again.";
        });
      } else {
        // Generic / network errors → snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Decorative blobs ─────────────────────────────
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(0.07),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top Nav ──────────────────────────────────
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
                        height: 48,
                      ),
                    ],
                  ),
                ),

                // ── Centered narrow card ──────────────────────
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 16),
                      child: FadeTransition(
                        opacity: _fadeIn,
                        child: SlideTransition(
                          position: _slideUp,
                          child: Center(
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 320),
                              child: _LoginCard(
                                email: _email,
                                password: _password,
                                obscurePassword: _obscurePassword,
                                loading: loading,
                                emailError: _emailError,
                                passwordError: _passwordError,
                                onTogglePassword: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                                onLogin: login,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Footer ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    "© 2025 BookMind · All rights reserved",
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.mediumText.withOpacity(0.5),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Login Card ───────────────────────────────────────────────────────────────

class _LoginCard extends StatelessWidget {
  final TextEditingController email;
  final TextEditingController password;
  final bool obscurePassword;
  final bool loading;
  final String? emailError;
  final String? passwordError;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;

  const _LoginCard({
    required this.email,
    required this.password,
    required this.obscurePassword,
    required this.loading,
    required this.onTogglePassword,
    required this.onLogin,
    this.emailError,
    this.passwordError,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: AppColors.accent.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accent, width: 2),
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 26,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Login to find your next read",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),

          // ── Form ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Email field ──────────────────────────────
                const _FieldLabel(label: "Email"),
                const SizedBox(height: 8),
                _StyledTextField(
                  controller: email,
                  hintText: "Your email",
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  hasError: emailError != null,
                ),
                if (emailError != null) _ErrorText(message: emailError!),

                const SizedBox(height: 18),

                // ── Password field ───────────────────────────
                const _FieldLabel(label: "Password"),
                const SizedBox(height: 8),
                _StyledTextField(
                  controller: password,
                  hintText: "Your password",
                  obscureText: obscurePassword,
                  prefixIcon: Icons.lock_outline_rounded,
                  hasError: passwordError != null,
                  suffixIcon: GestureDetector(
                    onTap: onTogglePassword,
                    child: Icon(
                      obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: passwordError != null
                          ? Colors.redAccent
                          : AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
                if (passwordError != null)
                  _ErrorText(message: passwordError!),

                const SizedBox(height: 26),

                // ── Login button ─────────────────────────────
                GestureDetector(
                  onTap: loading ? null : onLogin,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: loading
                          ? const LinearGradient(colors: [
                              AppColors.accentDark,
                              AppColors.accentDark,
                            ])
                          : AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: loading ? [] : AppColors.glowShadow,
                    ),
                    child: loading
                        ? const Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── OR divider ───────────────────────────────
                Row(
                  children: [
                    const Expanded(
                        child: Divider(color: AppColors.border)),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "OR",
                        style: TextStyle(
                          color: AppColors.mediumText.withOpacity(0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Expanded(
                        child: Divider(color: AppColors.border)),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Register link ────────────────────────────
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.mediumText,
                      ),
                      children: [
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Create Account",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        letterSpacing: 1.6,
      ),
    );
  }
}

/// Red inline error shown below a field.
class _ErrorText extends StatelessWidget {
  final String message;
  const _ErrorText({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 13, color: Colors.redAccent),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 11.5,
                color: Colors.redAccent,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool hasError;

  const _StyledTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 14, color: AppColors.darkTextAlt),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
            color: AppColors.lightText, fontSize: 13.5),
        filled: true,
        fillColor: AppColors.surfaceWarm,
        prefixIcon: Icon(prefixIcon,
            color: hasError ? Colors.redAccent : AppColors.primary, size: 19),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError ? Colors.redAccent : AppColors.border,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError ? Colors.redAccent : AppColors.accent,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
      ),
    );
  }
}