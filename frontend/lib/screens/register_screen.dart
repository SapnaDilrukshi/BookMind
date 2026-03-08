import 'package:bookmind/screens/Admin/admin_login_screen.dart';
import 'package:flutter/material.dart';
import '../config/color.dart';
import 'register_preferences_screen.dart';
import 'login_screen.dart';

// ── Simulated set of already-registered emails ──────────────────────────────
// Replace this with your real backend / Firebase check.
const _existingEmails = {
  'test@example.com',
  'admin@bookmind.com',
  'user@bookmind.com',
};

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;

  // ── Validation error strings (null = no error) ────────────────────────────
  String? _usernameError;
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
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ── Validation logic ──────────────────────────────────────────────────────
  bool _validate() {
    String? usernameErr;
    String? emailErr;
    String? passwordErr;

    // 1. Username
    if (_username.text.trim().isEmpty) {
      usernameErr = "Username is required.";
    }

    // 2. Email – format check
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    final emailVal = _email.text.trim();
    if (emailVal.isEmpty) {
      emailErr = "Email is required.";
    } else if (!emailRegex.hasMatch(emailVal)) {
      emailErr = "Please enter a valid email address.";
    } else if (_existingEmails.contains(emailVal.toLowerCase())) {
      // 3. Already-registered email
      emailErr = "This email is already registered. Please log in.";
    }

    // 4. Password – minimum 6 characters
    if (_password.text.isEmpty) {
      passwordErr = "Password is required.";
    } else if (_password.text.length < 6) {
      passwordErr = "Password must be at least 6 characters.";
    }

    setState(() {
      _usernameError = usernameErr;
      _emailError = emailErr;
      _passwordError = passwordErr;
    });

    return usernameErr == null && emailErr == null && passwordErr == null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Decorative background blobs ──────────────────
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
            bottom: 80,
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
                      // Back button
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
                      // ── Logo – increased from 32 → 48 ──────
                      Image.asset(
                        'assets/images/logo.jpeg',
                        height: 48,
                      ),
                      const Spacer(),
                      // Admin Login button – top right
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminLoginScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryDark.withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.admin_panel_settings_outlined,
                                  color: AppColors.accent, size: 14),
                              SizedBox(width: 6),
                              Text(
                                "Admin",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Centered Card ─────────────────────────────
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: FadeTransition(
                        opacity: _fadeIn,
                        child: SlideTransition(
                          position: _slideUp,
                          child: Container(
                            width: 320,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                  color: AppColors.border, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.primaryDark.withOpacity(0.10),
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
                                // ── Card header bar ───────────────
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 28, horizontal: 28),
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
                                        width: 68,
                                        height: 68,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.accent,
                                            width: 2,
                                          ),
                                          color:
                                              Colors.white.withOpacity(0.1),
                                        ),
                                        child: const Icon(
                                          Icons.person_add_outlined,
                                          size: 30,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        "Join BookMind",
                                        style: TextStyle(
                                          fontFamily: 'Georgia',
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "Create your account and discover amazing books",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color:
                                              Colors.white.withOpacity(0.6),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // ── Form fields ───────────────────
                                Padding(
                                  padding: const EdgeInsets.all(28),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // ── Username ──────────────────
                                      const _FieldLabel(label: "Username"),
                                      const SizedBox(height: 8),
                                      _StyledTextField(
                                        controller: _username,
                                        hintText: "Choose a username",
                                        prefixIcon:
                                            Icons.person_outline_rounded,
                                        hasError: _usernameError != null,
                                      ),
                                      if (_usernameError != null)
                                        _ErrorText(message: _usernameError!),

                                      const SizedBox(height: 20),

                                      // ── Email ─────────────────────
                                      const _FieldLabel(label: "Email"),
                                      const SizedBox(height: 8),
                                      _StyledTextField(
                                        controller: _email,
                                        hintText: "Enter your email",
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        prefixIcon: Icons.email_outlined,
                                        hasError: _emailError != null,
                                      ),
                                      if (_emailError != null)
                                        _ErrorText(message: _emailError!),

                                      const SizedBox(height: 20),

                                      // ── Password ──────────────────
                                      const _FieldLabel(label: "Password"),
                                      const SizedBox(height: 8),
                                      _StyledTextField(
                                        controller: _password,
                                        hintText: "Create a strong password",
                                        obscureText: _obscurePassword,
                                        prefixIcon:
                                            Icons.lock_outline_rounded,
                                        hasError: _passwordError != null,
                                        suffixIcon: GestureDetector(
                                          onTap: () => setState(() =>
                                              _obscurePassword =
                                                  !_obscurePassword),
                                          child: Icon(
                                            _obscurePassword
                                                ? Icons
                                                    .visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      if (_passwordError != null)
                                        _ErrorText(message: _passwordError!),

                                      const SizedBox(height: 30),

                                      // ── Continue button ───────────
                                      GestureDetector(
                                        onTap: () {
                                          if (_validate()) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    RegisterPreferencesScreen(
                                                  username:
                                                      _username.text.trim(),
                                                  email: _email.text.trim(),
                                                  password:
                                                      _password.text.trim(),
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          decoration: BoxDecoration(
                                            gradient:
                                                AppColors.accentGradient,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            boxShadow:
                                                AppColors.glowShadow,
                                          ),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Continue",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(
                                                Icons.arrow_forward_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 22),

                                      // ── Divider ───────────────────
                                      Row(
                                        children: [
                                          const Expanded(
                                              child: Divider(
                                                  color: AppColors.border)),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12),
                                            child: Text(
                                              "OR",
                                              style: TextStyle(
                                                color: AppColors.mediumText
                                                    .withOpacity(0.7),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ),
                                          const Expanded(
                                              child: Divider(
                                                  color: AppColors.border)),
                                        ],
                                      ),

                                      const SizedBox(height: 18),

                                      // ── Login link ────────────────
                                      Center(
                                        child: RichText(
                                          text: TextSpan(
                                            text:
                                                "Already have an account? ",
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              color: AppColors.mediumText,
                                            ),
                                            children: [
                                              WidgetSpan(
                                                child: GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            const LoginScreen(),
                                                      ),
                                                    );
                                                  },
                                                  child: const Text(
                                                    "Login",
                                                    style: TextStyle(
                                                      fontSize: 13.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          AppColors.primary,
                                                      decoration:
                                                          TextDecoration
                                                              .underline,
                                                      decorationColor:
                                                          AppColors.primary,
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
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Footer ────────────────────────────────────
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

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        letterSpacing: 1.6,
      ),
    );
  }
}

/// Red inline error message shown below a field.
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
      style: const TextStyle(
        fontSize: 14.5,
        color: AppColors.darkTextAlt,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColors.lightText,
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.surfaceWarm,
        prefixIcon: Icon(prefixIcon,
            color: hasError ? Colors.redAccent : AppColors.primary, size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: hasError ? Colors.redAccent : AppColors.border,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: hasError ? Colors.redAccent : AppColors.accent,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
    );
  }
}