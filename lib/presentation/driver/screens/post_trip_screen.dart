import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';

class PostTripScreen extends StatefulWidget {
  const PostTripScreen({super.key});

  @override
  State<PostTripScreen> createState() => _PostTripScreenState();
}

class _PostTripScreenState extends State<PostTripScreen> {
  final _sourceController = TextEditingController();
  final _destController = TextEditingController();
  final _priceController = TextEditingController();
  final _seatsController = TextEditingController();
  bool _isPosting = false;

  // Form Validation and Fields Text Verification
  bool _validateFields() {
    if (_sourceController.text.trim().isEmpty ||
        _destController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        _seatsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all the fields"), backgroundColor: Colors.orange),
      );
      return false;
    }
    return true;
  }

  Future<void> _publishTrip() async {
    if (!_validateFields()) return;

    setState(() => _isPosting = true);
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      setState(() => _isPosting = false);
      return;
    }

    try {
      // Pehle driver ki vehicle check karein
      final vehicleData = await Supabase.instance.client
          .from('vehicles')
          .select('id')
          .eq('driver_id', user.id)
          .maybeSingle();

      if (vehicleData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please add your vehicle in profile details first!"),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Trip insert karein (Clean format without color or model)
      await Supabase.instance.client.from('trips').insert({
        'driver_id': user.id,
        'vehicle_id': vehicleData['id'],
        'source': _sourceController.text.trim(),
        'destination': _destController.text.trim(),
        'departure_time': DateTime.now().add(const Duration(hours: 5)).toIso8601String(),
        'price_per_seat': double.parse(_priceController.text.trim()),
        'available_seats': int.parse(_seatsController.text.trim()),
        'status': 'active'
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Trip Published Successfully!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Error publishing trip: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to publish trip: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _destController.dispose();
    _priceController.dispose();
    _seatsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // Dark Theme dynamic mapping consistent with passenger view
      appBar: AppBar(
        title: const Text("Create a Trip", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Trip Route Details",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _sourceController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "From (e.g. Gilgit)",
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.location_on, color: Colors.orangeAccent),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.cyanAccent), borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _destController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "To (e.g. Hunza)",
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.my_location, color: Colors.cyanAccent),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.cyanAccent), borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                "Seats & Pricing",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Price/Seat",
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.attach_money, color: Colors.greenAccent),
                        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.cyanAccent), borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextField(
                      controller: _seatsController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Seats",
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.airline_seat_recline_normal, color: Colors.orangeAccent),
                        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.cyanAccent), borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isPosting ? null : _publishTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isPosting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Publish Trip", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}