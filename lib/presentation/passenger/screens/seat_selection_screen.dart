import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';

class SeatSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> trip;
  const SeatSelectionScreen({super.key, required this.trip});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  List<int> _bookedSeats = [];
  int? _selectedSeat;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookedSeats();
  }

  Future<void> _fetchBookedSeats() async {
    try {
      final data = await Supabase.instance.client
          .from('bookings')
          .select('seat_number')
          .eq('trip_id', widget.trip['id']);

      setState(() {
        _bookedSeats = List<int>.from(data.map((item) => item['seat_number']));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedSeat == null) return;
    final user = Supabase.instance.client.auth.currentUser;

    try {
      await Supabase.instance.client.from('bookings').insert({
        'trip_id': widget.trip['id'],
        'passenger_id': user!.id,
        'seat_number': _selectedSeat,
        'status': 'confirmed'
      });

      await Supabase.instance.client.rpc('decrement_available_seats', params: {
        'row_id': widget.trip['id'],
      });

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      debugPrint("Booking Error: $e");
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Booking Confirmed!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Text("Your seat #$_selectedSeat is reserved for ${widget.trip['destination']}.", textAlign: TextAlign.center),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text("Awesome!", style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Choose Your Seat", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Driver Side Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
            color: Colors.blue[900],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Icon(Icons.directions_car_filled, color: Colors.white.withOpacity(0.5), size: 30),
                    const Text("DRIVER", style: TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
                const Text("VEHICLE FRONT", style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2)),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Seat Legend (Available, Selected, Booked)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(Icons.event_seat, Colors.grey[300]!, "Available"),
              const SizedBox(width: 20),
              _buildLegend(Icons.event_seat, Colors.blue[900]!, "Selected"),
              const SizedBox(width: 20),
              _buildLegend(Icons.event_seat, Colors.red[300]!, "Booked"),
            ],
          ),

          const SizedBox(height: 30),

          // Seat Layout Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
              ),
              itemCount: 15,
              itemBuilder: (context, index) {
                // Aisle (Rasta) logic
                if (index % 3 == 1) return const SizedBox.shrink();

                int seatNum = index + 1;
                bool isBooked = _bookedSeats.contains(seatNum);
                bool isSelected = _selectedSeat == seatNum;

                return GestureDetector(
                  onTap: isBooked ? null : () => setState(() => _selectedSeat = seatNum),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isBooked ? Colors.red[100] : isSelected ? Colors.blue[900] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                      ],
                      border: Border.all(
                        color: isBooked ? Colors.red[200]! : isSelected ? Colors.blue[900]! : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.event_seat,
                      color: isBooked ? Colors.red[400] : isSelected ? Colors.white : Colors.grey[400],
                      size: 30,
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Selected Seat", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(
                      _selectedSeat == null ? "None" : "Seat #$_selectedSeat",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(width: 30),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedSeat == null ? null : _confirmBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: const Text("Confirm & Pay", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(IconData icon, Color color, String label) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}