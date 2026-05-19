import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase lazmi hai badge ke liye
import 'driver_dashboard.dart';
import 'create_trip_screen.dart';
import 'vehicle_reg_screen.dart';
import 'earnings_screen.dart';
import 'driver_profile_screen.dart';
import 'driver_chat_list_screen.dart';

class DriverMainWrapper extends StatefulWidget {
  const DriverMainWrapper({super.key});

  @override
  State<DriverMainWrapper> createState() => _DriverMainWrapperState();
}

class _DriverMainWrapperState extends State<DriverMainWrapper> {
  int _selectedIndex = 0;
  final _supabase = Supabase.instance.client;

  // Screens ki list (Chat Screen index 2 par hai)
  final List<Widget> _screens = [
    const DriverDashboard(),      // 0
    const CreateTripScreen(),     // 1
    const DriverChatListScreen(), // 2
    const EarningsScreen(),       // 3
    const VehicleRegScreen(),     // 4
    const DriverProfileScreen(),  // 5
  ];

  @override
  Widget build(BuildContext context) {
    // Current Driver ki ID
    final driverId = _supabase.auth.currentUser?.id ?? "";

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue[900],
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus),
            label: "My Trips",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: "Post Trip",
          ),

          // --- CHATS ICON WITH REAL-TIME NOTIFICATION BADGE ---
          BottomNavigationBarItem(
            icon: StreamBuilder<List<Map<String, dynamic>>>(
              // Real-time messages fetch ho rahe hain
              stream: _supabase
                  .from('messages')
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                final allMessages = snapshot.data ?? [];

                // Sirf wo messages jo is driver ke liye hain aur abhi tak Read (false) nahi huay
                int unreadCount = allMessages.where((m) =>
                m['receiver_id'] == driverId &&
                    m['is_read'] == false
                ).length;

                return Badge(
                  label: Text(unreadCount.toString()),
                  isLabelVisible: unreadCount > 0, // Agar 0 message hain toh badge nahi dikhega
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.chat_outlined),
                );
              },
            ),
            activeIcon: const Icon(Icons.chat),
            label: "Chats",
          ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: "Wallet",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.drive_eta_outlined),
            activeIcon: Icon(Icons.drive_eta),
            label: "Vehicle",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}