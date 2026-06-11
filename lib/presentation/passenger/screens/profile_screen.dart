import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart'; // Aapke project ke rangon ke liye

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  String? _imageUrl;
  String? _fullName;
  final _nameController = TextEditingController(); // Name edit karne ke liye controller

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase
            .from('profiles')
            .select('avatar_url, full_name')
            .eq('id', user.id)
            .single();

        setState(() {
          _imageUrl = data['avatar_url'];
          _fullName = data['full_name'];
          _nameController.text = _fullName ?? ""; // Controller mein purana naam set karna
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  // --- EDIT NAME FUNCTIONALITY (Naya Function) ---
  void _showEditProfileDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // Keyboard ke upar dikhane ke liye
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Update Full Name",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProfileName,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateProfileName() async {
    if (_nameController.text.trim().isEmpty) return;

    Navigator.pop(context); // Dialog band karne ke liye
    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('profiles').update({
        'full_name': _nameController.text.trim(),
      }).eq('id', user.id);

      setState(() {
        _fullName = _nameController.text.trim();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Name Updated Successfully!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Update Name Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );

      if (image == null) return;

      setState(() => _isLoading = true);
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final file = File(image.path);
      final fileName = '${user.id}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage.from('profiles').upload(
        fileName,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      final imageUrl = supabase.storage.from('profiles').getPublicUrl(fileName);

      await supabase.from('profiles').update({
        'avatar_url': imageUrl,
      }).eq('id', user.id);

      setState(() {
        _imageUrl = imageUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Picture Updated!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Upload Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = supabase.auth.currentUser?.email ?? "User Email";

    return SingleChildScrollView(
      child: Column(
        children: [
          // --- TOP PROFILE HEADER ---
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[900]!, Colors.blue[700]!],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                ),
              ),
              Positioned(
                bottom: -50,
                child: Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 5),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                          child: _imageUrl == null && !_isLoading
                              ? Icon(Icons.person, size: 60, color: Colors.blue[900])
                              : (_isLoading ? const CircularProgressIndicator() : null),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 5,
                        child: GestureDetector(
                          onTap: _isLoading ? null : _pickAndUploadImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 60),

          // --- USER INFO ---
          Text(
            _fullName ?? "Passenger",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
          Text(
            userEmail,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),

          const SizedBox(height: 25),

          // --- OPTIONS ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "General Settings",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey),
                ),
                const SizedBox(height: 15),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.person_outline, color: Colors.blue, size: 22),
                    ),
                    title: const Text("Edit Profile Name", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    onTap: _showEditProfileDialog, // 👈 Ab ye function call hoga click karne par
                  ),
                ),

                const SizedBox(height: 40),

                // --- LOGOUT ---
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton.icon(
                    onPressed: () => supabase.auth.signOut(),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text("Logout Account", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      side: BorderSide(color: Colors.red[100]!, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      backgroundColor: Colors.red[50]!.withOpacity(0.3),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}