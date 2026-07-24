import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1624),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Hero header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 48, 28, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/role_selection.png',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppStrings.appName,
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE8F0FE),
                        height: 1.1,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Your daily commute, simplified',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5A7A9A),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Role selection card ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213A),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF2C3E52), width: 1),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        AppStrings.selectRole,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE8F0FE),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Choose your role to get started',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF5A7A9A),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Driver Button
                      _RoleButton(
                        title: 'Driver',
                        subtitle: 'I have a van and want to offer seats',
                        icon: Icons.drive_eta,
                        isPrimary: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LoginScreen(role: 'driver'),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Passenger Button
                      _RoleButton(
                        title: 'Passenger',
                        subtitle: 'I want to find and book a seat',
                        icon: Icons.person_pin_circle,
                        isPrimary: false,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LoginScreen(role: 'passenger'),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'You can change your role anytime in settings',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF3D5470),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _RoleButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isPrimary
        ? const Color(0xFF00D4AA).withOpacity(0.6)
        : const Color(0xFF2C3E52);
    final Color iconBg = isPrimary
        ? const Color(0xFF00D4AA).withOpacity(0.1)
        : const Color(0xFF1E2A3A);
    final Color iconColor = isPrimary
        ? const Color(0xFF00D4AA)
        : const Color(0xFF5A7A9A);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: const Color(0xFF00D4AA).withOpacity(0.05),
        highlightColor: const Color(0xFF00D4AA).withOpacity(0.03),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1624),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: isPrimary ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: iconColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(icon, size: 26, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE8F0FE),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5A7A9A),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}