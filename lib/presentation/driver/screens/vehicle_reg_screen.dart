import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleRegScreen extends StatefulWidget {
  const VehicleRegScreen({super.key});

  @override
  State<VehicleRegScreen> createState() => _VehicleRegScreenState();
}

class _VehicleRegScreenState extends State<VehicleRegScreen> {
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();

  Future<void> _saveVehicle() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    try {
      await Supabase.instance.client.from('vehicles').upsert({
        'driver_id': userId,
        'model': _modelController.text,
        'plate_number': _plateController.text,
        'color': _colorController.text,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vehicle Registered!"), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vehicle & Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Supabase.instance.client.auth.signOut(),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
              const SizedBox(height: 20),
              TextField(controller: _modelController, decoration: const InputDecoration(labelText: "Vehicle Model", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(controller: _plateController, decoration: const InputDecoration(labelText: "Plate Number", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(controller: _colorController, decoration: const InputDecoration(labelText: "Color", border: OutlineInputBorder())),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveVehicle,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
                  child: const Text("Update Vehicle Info"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}