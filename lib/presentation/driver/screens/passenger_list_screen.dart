import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PassengerListScreen extends StatefulWidget {
  final String tripId;
  final String source;
  final String destination;

  const PassengerListScreen({
    super.key,
    required this.tripId,
    required this.source,
    required this.destination,
  });

  @override
  State<PassengerListScreen> createState() => _PassengerListScreenState();
}

class _PassengerListScreenState extends State<PassengerListScreen> {

  // --- UPDATED: Behter Error Handling aur Logging ---
  Future<void> _updateStatus(String bookingId, String newStatus, String? passengerId) async {
    // Check karein ke passengerId null to nahi
    if (passengerId == null || passengerId.isEmpty) {
      debugPrint("Error: Passenger ID is missing!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Passenger ID not found. Cannot send notification.")),
      );
      return;
    }

    try {
      // 1. Database mein booking status update karein
      await Supabase.instance.client
          .from('bookings')
          .update({'status': newStatus})
          .eq('id', bookingId);

      // 2. Notification text set karein
      String title = newStatus == 'confirmed' ? 'Booking Confirmed! ✅' : 'Request Rejected ❌';
      String message = newStatus == 'confirmed'
          ? 'Driver has accepted your request for ${widget.destination}.'
          : 'Sorry, your ride request for ${widget.destination} was rejected.';

      // 3. Notification insert karein (Ensure 'user_id' column name matches your DB)
      await Supabase.instance.client.from('notifications').insert({
        'user_id': passengerId,
        'title': title,
        'message': message,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Request ${newStatus == 'confirmed' ? 'Accepted' : 'Rejected'} & Notification Sent!"),
            backgroundColor: newStatus == 'confirmed' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      // Agar error aaye to console mein exact error print hoga
      debugPrint("SYSTEM ERROR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error details: ${e.toString().split('\n')[0]}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.source} ➔ ${widget.destination}"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Stream mein query ki bajaye manual filtering use karein agar version issue ho
        stream: Supabase.instance.client.from('bookings').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Manual filtering for trip_id
          final allData = snapshot.data ?? [];
          final bookings = allData.where((b) => b['trip_id'].toString() == widget.tripId.trim()).toList();

          if (bookings.isEmpty) {
            return const Center(child: Text("No bookings for this trip yet."));
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final b = bookings[index];
              final String status = (b['status'] ?? 'pending').toString().toLowerCase();
              final String? pId = b['passenger_id']; // ID nullable rakha hai safety ke liye

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: status == 'confirmed' ? Colors.green : (status == 'cancelled' ? Colors.red : Colors.orange),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  title: const Text("Passenger Request", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Status: ${status.toUpperCase()}"),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (status == 'pending') ...[
                            ElevatedButton.icon(
                              onPressed: () => _updateStatus(b['id'], 'confirmed', pId),
                              icon: const Icon(Icons.check),
                              label: const Text("Accept"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _updateStatus(b['id'], 'cancelled', pId),
                              icon: const Icon(Icons.close),
                              label: const Text("Reject"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            ),
                          ] else ...[
                            Text(
                              status == 'confirmed' ? "CONFIRMED ✅" : "REJECTED ❌",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: status == 'confirmed' ? Colors.green : Colors.red
                              ),
                            ),
                          ]
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}