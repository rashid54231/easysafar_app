import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import 'signup_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.directions_bus_rounded, size: 80, color: AppColors.primaryBlue),
              const SizedBox(height: 20),
              const Text(
                AppStrings.appName,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
              ),
              const SizedBox(height: 40),
              const Text(
                AppStrings.selectRole,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Driver Button
              _RoleButton(
                title: "Driver",
                subtitle: "I have a van and want to offer seats",
                icon: Icons.drive_eta,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  // FIX: 'const' hata diya gaya hai kyunki 'role' dynamic hai
                    builder: (_) => SignupScreen(role: 'driver'))),
              ),

              const SizedBox(height: 16),

              // Passenger Button
              _RoleButton(
                title: "Passenger",
                subtitle: "I want to find and book a seat",
                icon: Icons.person_pin_circle,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  // FIX: 'const' hata diya gaya hai
                    builder: (_) => SignupScreen(role: 'passenger'))),
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
  final VoidCallback onTap;

  const _RoleButton({required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        padding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          // FIX: Colors.blueOutline ki jagah AppColors.primaryBlue ya Colors.blue use karein
          side: const BorderSide(color: AppColors.primaryBlue),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 30, color: AppColors.primaryBlue),
          const SizedBox(width: 15),
          // Wrap with Expanded taake lambe text par overflow error na aaye
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }
}