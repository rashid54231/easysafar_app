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

  Future<void> _publishTrip() async {
    setState(() => _isPosting = true);
    final user = Supabase.instance.client.auth.currentUser;

    try {
      // Pehle gari ki ID lein
      final vehicle = await Supabase.instance.client
          .from('vehicles')
          .select('id')
          .eq('driver_id', user!.id)
          .single();

      // Trip insert karein
      await Supabase.instance.client.from('trips').insert({
        'driver_id': user.id,
        'vehicle_id': vehicle['id'],
        'source': _sourceController.text.trim(),
        'destination': _destController.text.trim(),
        'departure_time': DateTime.now().add(const Duration(hours: 5)).toIso8601String(), // Example 5 hours later
        'price_per_seat': double.parse(_priceController.text),
        'available_seats': int.parse(_seatsController.text),
        'status': 'active'
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trip Published!")));
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create a Trip")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _sourceController, decoration: const InputDecoration(labelText: "From (e.g. Gilgit)")),
              const SizedBox(height: 15),
              TextField(controller: _destController, decoration: const InputDecoration(labelText: "To (e.g. Hunza)")),
              const SizedBox(height: 15),
              TextField(controller: _priceController, decoration: const InputDecoration(labelText: "Price per Seat"), keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              TextField(controller: _seatsController, decoration: const InputDecoration(labelText: "Available Seats"), keyboardType: TextInputType.number),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isPosting ? null : _publishTrip,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, minimumSize: const Size(double.infinity, 50)),
                child: _isPosting ? const CircularProgressIndicator(color: Colors.white) : const Text("Publish Trip", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }
}