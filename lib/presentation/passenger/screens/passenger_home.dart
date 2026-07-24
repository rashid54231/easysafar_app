import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easysafar/presentation/providers/notification_provider.dart';
import 'package:easysafar/presentation/providers/chat_provider.dart';
import 'package:easysafar/presentation/passenger/screens/passenger_notifications_screen.dart';
import 'package:easysafar/presentation/passenger/screens/passenger_chat_list_screen.dart';
import 'my_bookings_screen.dart';
import 'profile_screen.dart';

class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TripsListBody(),
    const PassengerChatListScreen(),
    const MyBookingsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? "Find Your Ride" :
          (_currentIndex == 1 ? "Messages" :
          (_currentIndex == 2 ? "My Bookings" : "My Profile")),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 0.5),
        ),
        centerTitle: false,
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_currentIndex == 0)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Consumer<NotificationProvider>(
                builder: (context, provider, _) {
                  return IconButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PassengerNotificationsScreen()),
                      );
                      provider.refreshUnreadCount();
                    },
                    icon: Badge(
                      label: provider.unreadCount > 0 ? Text('${provider.unreadCount}') : null,
                      isLabelVisible: provider.unreadCount > 0,
                      child: const Icon(Icons.notifications_none_rounded, size: 28),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.cyanAccent,
        unselectedItemColor: Colors.white54,
        backgroundColor: Colors.blue[900],
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: "Explore"),
          BottomNavigationBarItem(
            icon: Consumer<ChatProvider>(
              builder: (context, provider, _) {
                return Badge(
                  label: provider.globalUnreadCount > 0 ? Text('${provider.globalUnreadCount}') : null,
                  isLabelVisible: provider.globalUnreadCount > 0,
                  child: const Icon(Icons.chat_bubble_rounded),
                );
              },
            ),
            label: "Chats",
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.confirmation_number_rounded), label: "Tickets"),
          const BottomNavigationBarItem(icon: Icon(Icons.account_circle_rounded), label: "Account"),
        ],
      ),
    );
  }
}

class TripsListBody extends StatefulWidget {
  const TripsListBody({super.key});
  @override
  State<TripsListBody> createState() => _TripsListBodyState();
}

class _TripsListBodyState extends State<TripsListBody> {
  String searchQuery = "";
  final _supabase = Supabase.instance.client;

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return "TBD";
    try {
      final dateTime = DateTime.parse(timeStr);
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? "PM" : "AM";
      return "$hour:$minute $period";
    } catch (e) {
      return "TBD";
    }
  }

  void _showBookingSheet(Map<String, dynamic> trip) {
    int selectedSeats = 1;
    final TextEditingController pickupController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final int maxSeats = trip['available_seats'];
    final int pricePerSeat = trip['price_per_seat'] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C2331),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Confirm Your Booking", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: pickupController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Pickup Location",
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.my_location, color: Colors.cyanAccent),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.cyanAccent), borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Your Contact Number",
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.phone_android_rounded, color: Colors.cyanAccent),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.cyanAccent), borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Number of Seats:", style: TextStyle(color: Colors.white, fontSize: 16)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.orangeAccent),
                        onPressed: selectedSeats > 1 ? () => setSheetState(() => selectedSeats--) : null,
                      ),
                      Text("$selectedSeats", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.cyanAccent),
                        onPressed: selectedSeats < maxSeats ? () => setSheetState(() => selectedSeats++) : null,
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(color: Colors.white12),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Price:", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  Text("Rs. ${selectedSeats * pricePerSeat}", style: const TextStyle(color: Colors.cyanAccent, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: () {
                    if (pickupController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter pickup location")));
                    } else if (phoneController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your contact number")));
                    } else {
                      _confirmBooking(trip, selectedSeats, pickupController.text.trim(), phoneController.text.trim());
                    }
                  },
                  child: const Text("Confirm Booking", style: TextStyle(color: Color(0xFF0D1117), fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmBooking(Map<String, dynamic> trip, int seats, String pickup, String phone) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('bookings').insert({
        'trip_id': trip['id'],
        'passenger_id': userId,
        'seats_booked': seats,
        'pickup_location': pickup,
        'passenger_phone': phone,
        'total_price': seats * (trip['price_per_seat'] ?? 0),
        'status': 'pending',
      });

      await _supabase.from('trips').update({
        'available_seats': trip['available_seats'] - seats
      }).eq('id', trip['id']);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking Successful! Go to Chats tab to contact driver."), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                child: Image.asset(
                  'assets/images/passenger_hero.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.blue[900]),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                  gradient: LinearGradient(
                    colors: [Colors.blue[900]!.withValues(alpha: 0.9), Colors.blue[900]!.withValues(alpha: 0.5)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Where are you going?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => searchQuery = val),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search destination...",
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.cyanAccent),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase.from('trips').stream(primaryKey: ['id']),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final trips = snapshot.data!.where((t) =>
              t['status'] == 'active' &&
                  t['destination'].toString().toLowerCase().contains(searchQuery.toLowerCase())
              ).toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 20),
                itemCount: trips.length,
                itemBuilder: (context, index) {
                  final trip = trips[index];
                  return Container(
                    margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2C3E52), width: 1),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Small Thumbnail Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset(
                                'assets/images/trip_cover.png',
                                width: 110,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 110,
                                  height: 80,
                                  color: const Color(0xFF2C3E52),
                                  child: const Icon(Icons.image_not_supported, color: Colors.white54),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "${trip['source'] ?? 'N/A'} → ${trip['destination'] ?? 'N/A'}",
                                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 13, color: Color(0xFF00D4AA)),
                                      const SizedBox(width: 5),
                                      Text(trip['departure_date'] ?? "Today", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 13, color: Color(0xFF00D4AA)),
                                      const SizedBox(width: 5),
                                      Text(_formatTime(trip['departure_time']), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text("Rs. ${trip['price_per_seat']}", style: const TextStyle(color: Color(0xFF00D4AA), fontSize: 15, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Driver info
                            Row(
                              children: [
                                const CircleAvatar(radius: 12, backgroundColor: Colors.white24, child: Icon(Icons.person, size: 16, color: Colors.white)),
                                const SizedBox(width: 8),
                                Text(trip['driver_name'] ?? "Driver", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                            // Action
                            Row(
                              children: [
                                Text("${trip['available_seats']} Seats", style: const TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 32,
                                  child: ElevatedButton(
                                    onPressed: () => _showBookingSheet(trip),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00D4AA),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text("Book", style: TextStyle(color: Color(0xFF0F1624), fontSize: 13, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

