import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'presentation/auth/screens/role_selection_screen.dart';
import 'presentation/driver/screens/driver_dashboard.dart';
import 'presentation/passenger/screens/passenger_home.dart';
// Naya Wrapper import karna mat bhooliyega
import 'presentation/driver/screens/driver_main_wrapper.dart';

class EasySafarApp extends StatelessWidget {
  const EasySafarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Easysafar',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;

        if (session == null) {
          return const RoleSelectionScreen();
        }

        return FutureBuilder(
          key: ValueKey(session.user.id),
          future: Supabase.instance.client
              .from('profiles')
              .select('user_role')
              .eq('id', session.user.id)
              .maybeSingle(),
          builder: (context, AsyncSnapshot roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (roleSnapshot.hasError) {
              return Scaffold(
                body: Center(child: Text("Database Error: ${roleSnapshot.error}")),
              );
            }

            if (roleSnapshot.hasData && roleSnapshot.data != null) {
              final String role = roleSnapshot.data['user_role'] ?? '';

              if (role.toLowerCase() == 'driver') {
                // CHNAGE YAHAN HAI: Ab ye DriverMainWrapper par bhejega
                return const DriverMainWrapper();
              } else if (role.toLowerCase() == 'passenger') {
                return const PassengerHome();
              }
            }

            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text("Profile not found!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ElevatedButton(
                      onPressed: () => Supabase.instance.client.auth.signOut(),
                      child: const Text("Go Back / Logout"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}