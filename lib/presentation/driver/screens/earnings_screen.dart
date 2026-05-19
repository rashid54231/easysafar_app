import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Wallet"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('driver_earnings')
            .stream(primaryKey: ['driver_id'])
            .eq('driver_id', userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          num totalEarned = 0;
          int totalBookings = 0;

          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final data = snapshot.data!.first;
            totalEarned = data['total_earned'] ?? 0;
            totalBookings = data['total_bookings'] ?? 0;
          }

          return RefreshIndicator(
            onRefresh: () async {
              return await Future.delayed(const Duration(seconds: 1));
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Wallet Display
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.blue[900]!, Colors.blue[700]!]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text("Available Balance", style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 10),
                      Text(
                          "Rs. ${totalEarned.toString()}",
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // --- RATING REMOVED & BOOKINGS UPDATED TO FULL WIDTH ---
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 32),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Total Bookings", style: TextStyle(color: Colors.grey, fontSize: 14)),
                            Text(
                                totalBookings.toString(),
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  "* Amount will be added once the passenger's booking is confirmed.",
                  style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}