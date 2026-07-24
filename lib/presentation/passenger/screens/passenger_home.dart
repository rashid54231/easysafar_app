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
                    colors: [Colors.blue[900]!.withOpacity(0.9), Colors.blue[900]!.withOpacity(0.5)],
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
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => searchQuery = val),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search destination...",
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
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
                    margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1C2331), Color(0xFF0D1117)]),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
                          child: Stack(
                            children: [
                              Image.asset(
                                'assets/images/trip_cover.png',
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 100,
                                  color: Colors.black26,
                                ),
                              ),
                              Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.transparent, Color(0xFF1C2331)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 15, left: 20, right: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_month, size: 14, color: Colors.cyanAccent),
                                          const SizedBox(width: 5),
                                          Text(trip['departure_date'] ?? "Today", style: const TextStyle(color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[900]!.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.access_time_rounded, size: 14, color: Colors.cyanAccent),
                                          const SizedBox(width: 5),
                                          Text(
                                            _formatTime(trip['departure_time']),
                                            style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.orangeAccent),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("From: ${trip['source'] ?? 'N/A'}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(trip['destination'] ?? "Dest", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                ),
                              ),
                              Text("Rs. ${trip['price_per_seat']}", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          color: Colors.black12,
                          child: Row(
                            children: [
                              const CircleAvatar(radius: 18, child: Icon(Icons.person)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(trip['driver_name'] ?? "Driver", style: const TextStyle(color: Colors.white)),
                                    Text("${trip['vehicle_name'] ?? 'Car'}", style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Seats ${trip['available_seats']} left", style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                              ElevatedButton(
                                onPressed: () => _showBookingSheet(trip),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
                                child: const Text("Book Now", style: TextStyle(color: Color(0xFF0D1117), fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
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
