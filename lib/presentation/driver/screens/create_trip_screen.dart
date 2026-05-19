import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  // --- Controllers ---
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _priceController = TextEditingController();
  final _seatsController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _vehicleNameController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _vehicleModelController = TextEditingController();

  DateTime? _selectedTime;
  bool _isLoading = false;

  // Time Picker Function
  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        _selectedTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      });
    }
  }

  // Trip Publish Function (Updated to stay on screen)
  Future<void> _publishTrip() async {
    // Validation
    if (_fromController.text.isEmpty || _toController.text.isEmpty ||
        _priceController.text.isEmpty || _seatsController.text.isEmpty ||
        _driverNameController.text.isEmpty || _driverPhoneController.text.isEmpty ||
        _vehicleNameController.text.isEmpty || _selectedTime == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please fill all details and select time"),
            backgroundColor: Colors.orange
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;

      // Supabase Insert
      await Supabase.instance.client.from('trips').insert({
        'driver_id': user!.id,
        'source': _fromController.text.trim(),
        'destination': _toController.text.trim(),
        'price_per_seat': int.parse(_priceController.text.trim()),
        'available_seats': int.parse(_seatsController.text.trim()),
        'departure_time': _selectedTime!.toIso8601String(),
        'status': 'active',
        'driver_name': _driverNameController.text.trim(),
        'driver_phone': _driverPhoneController.text.trim(),
        'vehicle_name': _vehicleNameController.text.trim(),
        'vehicle_model': _vehicleModelController.text.trim(),
        'vehicle_color': _vehicleColorController.text.trim(),
      });

      if (mounted) {
        // Loading band karein taake button wapis aa jaye
        setState(() => _isLoading = false);

        // Success Message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Trip Published Successfully! ✅"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Note: Navigator.pop() yahan se hata diya hai taake white screen na aaye
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error: ${e.toString()}"),
              backgroundColor: Colors.red
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Post a New Trip"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Route Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            _buildTextField(_fromController, "From (Source)", Icons.trip_origin),
            _buildTextField(_toController, "To (Destination)", Icons.location_on),

            const Divider(height: 40),
            const Text("Driver & Vehicle Info", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            _buildTextField(_driverNameController, "Driver Full Name", Icons.person),
            _buildTextField(_driverPhoneController, "Contact Number", Icons.phone, type: TextInputType.phone),
            _buildTextField(_vehicleNameController, "Vehicle Name (e.g. Corolla)", Icons.directions_car),

            Row(
              children: [
                Expanded(child: _buildTextField(_vehicleModelController, "Model/Year", Icons.grid_3x3)),
                const SizedBox(width: 10),
                Expanded(child: _buildTextField(_vehicleColorController, "Vehicle Color", Icons.palette)),
              ],
            ),

            const Divider(height: 40),
            const Text("Seats & Pricing", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildTextField(_priceController, "Price/Seat", Icons.money, type: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _buildTextField(_seatsController, "Total Seats", Icons.event_seat, type: TextInputType.number)),
              ],
            ),

            const SizedBox(height: 20),
            ListTile(
              title: Text(_selectedTime == null ? "Select Departure Time" : "Departure: ${_selectedTime!.hour}:${_selectedTime!.minute}"),
              trailing: const Icon(Icons.access_time, color: Colors.blue),
              tileColor: Colors.blue[50],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: _pickTime,
            ),

            const SizedBox(height: 30),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _publishTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("Publish Trip", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue[900], size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }
}