import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'my_bookings_screen.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';

class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  int _currentIndex = 0;
  int _unreadNotifications = 0;
  int _unreadMessages = 0;
  final _supabase = Supabase.instance.client;

  final List<Widget> _screens = [
    const TripsListBody(),
    const PassengerChatListScreen(),
    const MyBookingsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _listenToNotifications();
    _listenToUnreadMessages();
  }

  void _listenToNotifications() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .listen((data) {
      final unread = data.where((n) => n['is_read'] == false).toList();
      if (mounted) {
        setState(() {
          _unreadNotifications = unread.length;
        });
      }
    });
  }

  void _listenToUnreadMessages() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', user.id)
        .listen((data) {
      final unread = data.where((m) => m['is_read'] == false).toList();
      if (mounted) {
        setState(() {
          _unreadMessages = unread.length;
        });
      }
    });
  }

  Future<void> _refreshBadgeCount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .eq('is_read', false);

    if (mounted) {
      setState(() {
        _unreadNotifications = response.length;
      });
    }
  }

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
              child: IconButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  );
                  _refreshBadgeCount();
                },
                icon: Badge(
                  label: _unreadNotifications > 0 ? Text('$_unreadNotifications') : null,
                  isLabelVisible: _unreadNotifications > 0,
                  child: const Icon(Icons.notifications_none_rounded, size: 28),
                ),
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
            icon: Badge(
              label: _unreadMessages > 0 ? Text('$_unreadMessages') : null,
              isLabelVisible: _unreadMessages > 0,
              child: const Icon(Icons.chat_bubble_rounded),
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

  // NEW: Booking Form Sheet (Updated with clean logic)
  void _showBookingSheet(Map<String, dynamic> trip) {
    int selectedSeats = 1;
    final TextEditingController pickupController = TextEditingController();
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
                    } else {
                      _confirmBooking(trip, selectedSeats, pickupController.text.trim());
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

  // Database confirmation logic (Updated to use your new columns)
  Future<void> _confirmBooking(Map<String, dynamic> trip, int seats, String pickup) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // 1. Insert into bookings table
      await _supabase.from('bookings').insert({
        'trip_id': trip['id'],
        'passenger_id': userId,
        'seats_booked': seats,
        'pickup_location': pickup,
        'total_price': seats * (trip['price_per_seat'] ?? 0),
        'status': 'pending',
      });

      // 2. Update available seats
      await _supabase.from('trips').update({
        'available_seats': trip['available_seats'] - seats
      }).eq('id', trip['id']);

      if (mounted) {
        Navigator.pop(context); // Close sheet
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking Successful!")));
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
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 25),
          decoration: BoxDecoration(
            color: Colors.blue[900],
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
          child: Container(
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
            child: TextField(
              onChanged: (val) => setState(() => searchQuery = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search destination...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.cyanAccent),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
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
                        Padding(
                          padding: const EdgeInsets.only(top: 15, left: 20),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month, size: 14, color: Colors.cyanAccent),
                              const SizedBox(width: 5),
                              Text(trip['departure_date'] ?? "TBD", style: const TextStyle(color: Colors.white70)),
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
                                    Text("${trip['vehicle_name'] ?? 'Car'} • ${trip['vehicle_color'] ?? ''}", style: const TextStyle(color: Colors.white54, fontSize: 11)),
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
                              Text("💺 ${trip['available_seats']} left", style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
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

class PassengerChatListScreen extends StatelessWidget {
  const PassengerChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myId = Supabase.instance.client.auth.currentUser!.id;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('messages')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final myMessages = snapshot.data!.where((m) =>
        m['sender_id'] == myId || m['receiver_id'] == myId
        ).toList();

        final uniqueChats = <String, Map<String, dynamic>>{};
        for (var msg in myMessages) {
          String otherId = msg['sender_id'] == myId ? msg['receiver_id'] : msg['sender_id'];
          if (!uniqueChats.containsKey(otherId)) {
            uniqueChats[otherId] = msg;
          }
        }

        final chatList = uniqueChats.values.toList();
        if (chatList.isEmpty) return const Center(child: Text("No messages yet", style: TextStyle(color: Colors.white60)));

        return ListView.builder(
          itemCount: chatList.length,
          itemBuilder: (context, index) {
            final chat = chatList[index];
            String otherId = chat['sender_id'] == myId ? chat['receiver_id'] : chat['sender_id'];
            String tripId = chat['trip_id'].toString();

            return FutureBuilder(
              future: Future.wait([
                Supabase.instance.client.from('profiles').select().eq('id', otherId).maybeSingle(),
                Supabase.instance.client.from('trips').select('driver_phone').eq('id', tripId).maybeSingle(),
              ]),
              builder: (context, AsyncSnapshot<List<dynamic>> combinedSnap) {
                if (combinedSnap.connectionState == ConnectionState.waiting) {
                  return const ListTile(title: Text("Loading...", style: TextStyle(color: Colors.white54)));
                }

                final profileData = combinedSnap.data?[0];
                final tripData = combinedSnap.data?[1];

                String name = profileData?['full_name'] ?? "User";
                String? phone = tripData?['driver_phone']?.toString();

                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(chat['content'] ?? "",
                      style: const TextStyle(color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis
                  ),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(
                    tripId: tripId,
                    receiverId: otherId,
                    receiverName: name,
                    driverPhone: phone,
                  ))),
                );
              },
            );
          },
        );
      },
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() { super.initState(); _markAllAsRead(); }

  Future<void> _markAllAsRead() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await Supabase.instance.client.from('notifications').update({'is_read': true}).eq('user_id', user.id).eq('is_read', false);
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(title: const Text("Notifications"), backgroundColor: Colors.blue[900]),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client.from('notifications').stream(primaryKey: ['id']).order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final myNotes = snapshot.data!.where((n) => n['user_id'] == userId).toList();
          return ListView.builder(
            itemCount: myNotes.length,
            itemBuilder: (context, index) {
              final note = myNotes[index];
              return ListTile(
                title: Text(note['title'] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(note['message'] ?? "", style: const TextStyle(color: Colors.white70)),
              );
            },
          );
        },
      ),
    );
  }
}