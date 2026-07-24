import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  final String role;
  const SignupScreen({super.key, required this.role});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await AuthRepository().signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
        role: widget.role,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Signup Successful! Please check your email for verification."),
            backgroundColor: const Color(0xFF00D4AA),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen(role: widget.role)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: const Color(0xFFE05252),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Color(0xFF8FA3BF),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF2C3E52), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF5A7A9A), size: 20),
      filled: true,
      fillColor: const Color(0xFF0F1624),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2C3E52), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2C3E52), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF00D4AA), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE05252), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE05252), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDriver = widget.role == 'driver';

    return Scaffold(
      backgroundColor: const Color(0xFF0F1624),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/signup_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF0F1624)),
            ),
          ),
          // Dark Overlay for readability
          Positioned.fill(
            child: Container(
              color: const Color(0xFF0F1624).withValues(alpha: 0.7),
            ),
          ),
          SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Top nav ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2A3A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2C3E52), width: 1),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFF8FA3BF),
                          size: 16,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2A3A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF00D4AA).withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDriver ? Icons.drive_eta_rounded : Icons.person_pin_circle_rounded,
                            size: 13,
                            color: const Color(0xFF00D4AA),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isDriver ? 'Driver' : 'Passenger',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF00D4AA),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Hero section ──
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4AA).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF00D4AA).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_add_rounded,
                        size: 30,
                        color: Color(0xFF00D4AA),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Create\nAccount',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE8F0FE),
                        height: 1.1,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Create your account to get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5A7A9A),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Form card ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 36, 20, 32),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213A),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF2C3E52), width: 1),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        // Full Name
                        _buildLabel('Full Name'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(fontSize: 15, color: Color(0xFFE8F0FE)),
                          decoration: _inputDecoration(
                            hint: 'Ali Hassan',
                            icon: Icons.person_outline_rounded,
                          ),
                          validator: (v) => v!.isEmpty ? "Enter your name" : null,
                        ),

                        const SizedBox(height: 20),

                        // Email
                        _buildLabel('Email Address'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 15, color: Color(0xFFE8F0FE)),
                          decoration: _inputDecoration(
                            hint: 'you@example.com',
                            icon: Icons.email_outlined,
                          ),
                          validator: (v) => !v!.contains('@') ? "Invalid email" : null,
                        ),

                        const SizedBox(height: 20),

                        // Password
                        _buildLabel('Password'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(fontSize: 15, color: Color(0xFFE8F0FE)),
                          decoration: _inputDecoration(
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                          ).copyWith(
                            suffixIcon: GestureDetector(
                              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                              child: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF5A7A9A),
                                size: 20,
                              ),
                            ),
                          ),
                          validator: (v) => v!.length < 6 ? "Minimum 6 characters" : null,
                        ),

                        const SizedBox(height: 12),

                        // Password hint — ✅ NO const on children list
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 13,
                              color: Color(0xFF5A7A9A),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Minimum 6 characters required',
                              style: TextStyle(fontSize: 12, color: Color(0xFF5A7A9A)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Sign Up Button
                        _isLoading
                            ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00D4AA),
                            strokeWidth: 2.5,
                          ),
                        )
                            : Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00D4AA), Color(0xFF00A896)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00D4AA).withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _handleSignup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Color(0xFF0F1624),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Divider — ✅ NO const on children list
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(color: Color(0xFF2C3E52), thickness: 0.8),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or',
                                style: TextStyle(fontSize: 12, color: Color(0xFF5A7A9A)),
                              ),
                            ),
                            const Expanded(
                              child: Divider(color: Color(0xFF2C3E52), thickness: 0.8),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Login link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Already have an account?",
                              style: TextStyle(fontSize: 14, color: Color(0xFF5A7A9A)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LoginScreen(role: widget.role),
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF00D4AA),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
);
  }
}
//hello
//weg
//
