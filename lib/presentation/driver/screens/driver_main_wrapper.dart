import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'driver_dashboard.dart';
import 'create_trip_screen.dart';
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

  // ✅ VEHICLE REG SCREEN KO DELETED/REMOVED
  final List<Widget> _screens = [
    const DriverDashboard(),      // Index 0
    const CreateTripScreen(),     // Index 1
    const DriverChatListScreen(), // Index 2
    const EarningsScreen(),       // Index 3
    const DriverProfileScreen(),  // Index 4 (Pehle yeh 5 par thi)
  ];

  @override
  Widget build(BuildContext context) {
    final driverId = _supabase.auth.currentUser?.id ?? "";

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A56C4),
          border: Border(
            top: BorderSide(color: Color(0xFF1245A8), width: 1),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.directions_bus_outlined,
                  activeIcon: Icons.directions_bus,
                  label: "My Trips",
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.add_circle_outline,
                  activeIcon: Icons.add_circle,
                  label: "Post Trip",
                ),
                _buildChatNavItem(driverId), // Index 2 automatically handled inside
                _buildNavItem(
                  index: 3,
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet,
                  label: "Wallet",
                ),
                // ✅ VEHICLE NAV ITEM POLISHED AND REMOVED FROM HERE
                _buildNavItem(
                  index: 4, // Index changed from 5 to 4
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: "Profile",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 20,
                color: isSelected ? Colors.white : Colors.white60,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatNavItem(String driverId) {
    final bool isSelected = _selectedIndex == 2;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = 2),
        behavior: HitTestBehavior.opaque,
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _supabase
              .from('messages')
              .stream(primaryKey: ['id'])
              .order('created_at', ascending: false),
          builder: (context, snapshot) {
            final allMessages = snapshot.data ?? [];
            int unreadCount = allMessages
                .where((m) =>
            m['receiver_id'] == driverId && m['is_read'] == false)
                .length;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 28,
                    height: 22,
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Icon(
                            isSelected ? Icons.chat : Icons.chat_outlined,
                            size: 20,
                            color: isSelected ? Colors.white : Colors.white60,
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF5252),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 13,
                                minHeight: 13,
                              ),
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Chats",
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : Colors.white60,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}