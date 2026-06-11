import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../passenger/screens/chat_screen.dart'; // Apne chat screen ka sahi path check kar lein

class DriverChatListScreen extends StatelessWidget {
  const DriverChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final driverId = Supabase.instance.client.auth.currentUser!.id;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text("Passenger Bookings & Chats"),
        backgroundColor: Colors.blue[900],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // 🔥 FIX: Direct 'bookings' table se stream le rahe hain jahan passenger ka number save hota hai
        stream: Supabase.instance.client
            .from('bookings')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allBookings = snapshot.data!;

          // Hum sirf un bookings ko filter karenge jo is driver ke trips ki hain
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: Supabase.instance.client
                .from('trips')
                .select('id')
                .eq('driver_id', driverId),
            builder: (context, tripSnapshot) {
              if (!tripSnapshot.hasData) return const Center(child: CircularProgressIndicator());

              // Driver ke saare active trip IDs nikal lete hain
              final driverTripIds = tripSnapshot.data!.map((t) => t['id'].toString()).toList();

              // Sirf woh bookings rakhenge jo is driver ke trips ki hain
              final myPassengerBookings = allBookings.where((b) {
                return driverTripIds.contains(b['trip_id'].toString());
              }).toList();

              if (myPassengerBookings.isEmpty) {
                return const Center(child: Text("No bookings or chats yet", style: TextStyle(color: Colors.white60)));
              }

              return ListView.builder(
                itemCount: myPassengerBookings.length,
                itemBuilder: (context, index) {
                  final booking = myPassengerBookings[index];
                  final passengerId = booking['passenger_id'];
                  final tripId = booking['trip_id'].toString();

                  // Booking table se direct phone number uthayein
                  String passengerPhone = booking['passenger_phone']?.toString() ?? "No number";

                  // Passenger ka naam profiles table se lane ke liye FutureBuilder
                  return FutureBuilder<Map<String, dynamic>?>(
                    future: Supabase.instance.client
                        .from('profiles')
                        .select('full_name, phone_number')
                        .eq('id', passengerId)
                        .maybeSingle(),
                    builder: (context, profileSnapshot) {
                      String displayName = "Loading...";

                      if (profileSnapshot.hasData && profileSnapshot.data != null) {
                        displayName = profileSnapshot.data!['full_name'] ?? "Passenger";
                        // Fallback agar booking table mein number kisi wajah se khali ho to profile ka utha le
                        if (passengerPhone == "No number" && profileSnapshot.data!['phone_number'] != null) {
                          passengerPhone = profileSnapshot.data!['phone_number'].toString();
                        }
                      } else if (profileSnapshot.connectionState == ConnectionState.done) {
                        displayName = "Passenger";
                      }

                      return Card(
                        color: const Color(0xFF1C2331),
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(
                            displayName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ✅ PASSENGER NUMBER: Ab yeh har haal mein show hoga kyunki yeh direct booking row se aa raha hai
                                Row(
                                  children: [
                                    const Icon(Icons.phone, size: 14, color: Colors.cyanAccent),
                                    const SizedBox(width: 5),
                                    Text(
                                      passengerPhone,
                                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Pickup: ${booking['pickup_location'] ?? 'N/A'}",
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          trailing: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.cyanAccent),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  tripId: tripId,
                                  receiverId: passengerId,
                                  receiverName: displayName,
                                  // Chat screen ke andar direct call option ke liye number bhej rahe hain
                                  driverPhone: passengerPhone == "No number" ? null : passengerPhone,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}