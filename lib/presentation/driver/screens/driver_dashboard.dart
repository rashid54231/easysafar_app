import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easysafar/presentation/providers/notification_provider.dart';
import 'package:easysafar/presentation/driver/screens/driver_notifications_screen.dart';
import 'passenger_list_screen.dart';
import 'driver_profile_screen.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final userId = Supabase.instance.client.auth.currentUser!.id;
  String? _profilePicUrl;

  @override
  void initState() {
    super.initState();
    _loadProfilePic();
  }

  Future<void> _loadProfilePic() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .single();
      if (mounted) {
        setState(() {
          _profilePicUrl = data['avatar_url'];
        });
      }
    } catch (e) {
      debugPrint("Profile pic error: $e");
    }
  }

  void _refresh() {
    _loadProfilePic();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1624),
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: -0.5,
            color: Color(0xFFE8F0FE),
          ),
        ),
        backgroundColor: const Color(0xFF0F1624),
        foregroundColor: const Color(0xFFE8F0FE),
        actions: [
          _buildNotificationBtn(),
          const SizedBox(width: 4),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('profiles')
                .stream(primaryKey: ['id'])
                .eq('id', userId),
            builder: (context, snapshot) {
              String? livePic;
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                livePic = snapshot.data!.first['avatar_url'];
              }
              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DriverProfileScreen()),
                    ).then((_) => _refresh());
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF00D4AA).withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF1E2A3A),
                      backgroundImage: livePic != null
                          ? NetworkImage(livePic)
                          : (_profilePicUrl != null
                          ? NetworkImage(_profilePicUrl!)
                          : null),
                      child: (livePic == null && _profilePicUrl == null)
                          ? const Icon(Icons.person,
                          size: 20, color: Color(0xFF5A7A9A))
                          : null,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF0F1624),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Background Image
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/driver_hero.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF16213A)),
                    ),
                  ),
                  // Dark Gradient Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            const Color(0xFF0F1624).withOpacity(0.9),
                            const Color(0xFF0F1624).withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF2C3E52).withOpacity(0.5), width: 1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Hello Driver!",
                              style: TextStyle(
                                color: Color(0xFF00D4AA),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Manage Your Trips",
                              style: TextStyle(
                                color: Color(0xFFE8F0FE),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _refresh,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D4AA),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00D4AA).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.refresh_rounded,
                              color: Color(0xFF0F1624),
                              size: 22,
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

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('trips')
                  .stream(primaryKey: ['id'])
                  .eq('driver_id', userId)
                  .order('created_at'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00D4AA),
                      strokeWidth: 2.5,
                    ),
                  );
                }
                final trips = snapshot.data!;
                if (trips.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: trips.length,
                  itemBuilder: (context, index) =>
                      _buildTripCard(context, trips[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBtn() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final unreadCount = provider.unreadCount;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(
                unreadCount > 0
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_outlined,
                color: unreadCount > 0
                    ? const Color(0xFF00D4AA)
                    : const Color(0xFF5A7A9A),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DriverNotificationsScreen(),
                  ),
                );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 10,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF00D4AA),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Color(0xFF0F1624),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTripCard(BuildContext context, Map<String, dynamic> trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2C3E52), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        splashColor: const Color(0xFF00D4AA).withOpacity(0.05),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PassengerListScreen(
              tripId: trip['id'],
              source: trip['source'],
              destination: trip['destination'],
            ),
          ),
        ).then((_) => _refresh()),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/images/trip_cover.png',
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4AA).withOpacity(0.1),
                      border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.3), width: 1),
                    ),
                    child: const Icon(Icons.directions_car_filled_rounded, color: Color(0xFF00D4AA)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${trip['source']} -> ${trip['destination']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFFE8F0FE),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.event_seat_rounded,
                          size: 13,
                          color: Color(0xFF5A7A9A),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Available Seats: ${trip['available_seats']}",
                          style: const TextStyle(
                            color: Color(0xFF5A7A9A),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF5A7A9A),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/empty_trips.png',
            width: 160,
            height: 160,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFF00D4AA).withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.2), width: 1),
              ),
              child: const Icon(Icons.directions_bus_outlined, size: 44, color: Color(0xFF00D4AA)),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "No Trips Found",
            style: TextStyle(
              color: Color(0xFFE8F0FE),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Your trips will appear here",
            style: TextStyle(
              color: Color(0xFF5A7A9A),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
