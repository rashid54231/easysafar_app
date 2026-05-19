import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  // --- UPDATED: Notification Panel Logic ---
  void _showNotificationPanel(BuildContext context, List<Map<String, dynamic>> pendingBookings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(20),
          height: 450,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50, height: 5,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              const Text("New Seat Requests", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: pendingBookings.length,
                  itemBuilder: (context, index) {
                    final booking = pendingBookings[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                            backgroundColor: Colors.blue[900],
                            child: const Icon(Icons.person, color: Colors.white)
                        ),
                        title: Text("Booking for ${booking['seats_booked']} Seat(s)", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text("Tap to view details and Accept/Reject", style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF0D47A1)),
                        onTap: () {
                          Navigator.pop(context);
                          // TripId ke sath PassengerListScreen par bhejein jahan Accept logic hai
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => PassengerListScreen(
                                      tripId: booking['trip_id'],
                                      source: "Notification",
                                      destination: ""
                                  )
                              )
                          ).then((_) => _refresh());
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: const Text("Dashboard", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 1)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          _buildNotificationBtn(),
          const SizedBox(width: 5),
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
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DriverProfileScreen()),
                    ).then((_) => _refresh());
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white24,
                    backgroundImage: livePic != null
                        ? NetworkImage(livePic)
                        : (_profilePicUrl != null ? NetworkImage(_profilePicUrl!) : null),
                    child: (livePic == null && _profilePicUrl == null)
                        ? const Icon(Icons.person, size: 20, color: Colors.white)
                        : null,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.blue[900],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Hello Driver!", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    Text("Manage Your Trips", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.white12),
                )
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client.from('trips').stream(primaryKey: ['id']).eq('driver_id', userId).order('created_at'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final trips = snapshot.data!;
                if (trips.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: trips.length,
                  itemBuilder: (context, index) => _buildTripCard(context, trips[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBtn() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      // Yahan hum pending bookings ko monitor kar rahe hain
      stream: Supabase.instance.client.from('bookings').stream(primaryKey: ['id']).eq('status', 'pending'),
      builder: (context, snapshot) {
        final pendingData = snapshot.data ?? [];
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(pendingData.isNotEmpty ? Icons.notifications_active_rounded : Icons.notifications_outlined),
              onPressed: () {
                if (pendingData.isNotEmpty) {
                  _showNotificationPanel(context, pendingData);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No new notifications")));
                }
              },
            ),
            if (pendingData.isNotEmpty)
              Positioned(
                right: 10, top: 12,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                  child: Text('${pendingData.length}', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTripCard(BuildContext context, Map<String, dynamic> trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PassengerListScreen(tripId: trip['id'], source: trip['source'], destination: trip['destination']))).then((_) => _refresh()),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.directions_car_filled_rounded, color: Colors.blue[900]),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${trip['source']} ➔ ${trip['destination']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text("Available Seats: ${trip['available_seats']}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
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
          Icon(Icons.directions_bus_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text("No Trips Found", style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}