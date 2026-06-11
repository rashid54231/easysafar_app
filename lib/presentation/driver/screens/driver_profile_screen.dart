import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final user = Supabase.instance.client.auth.currentUser;
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  // Controllers to update name and phone
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfileDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileDetails() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user!.id)
          .single();

      if (mounted) {
        setState(() {
          _profileData = data;
          _nameController.text = data['full_name'] ?? "";
          _phoneController.text = data['phone_number'] ?? data['phone'] ?? "";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error fetching profile: $e");
    }
  }

  // --- EDIT PROFILE BOTTOM SHEET ---
  void _showEditProfileBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 25,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Edit Profile Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: _updateProfileData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Save Updates", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 25),
            ],
          ),
        );
      },
    );
  }

  // --- DATABASE MEIN UPDATES SAVE KARNA ---
  Future<void> _updateProfileData() async {
    if (_nameController.text.trim().isEmpty) return;

    Navigator.pop(context);
    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.from('profiles').update({
        'full_name': _nameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
      }).eq('id', user!.id);

      await _fetchProfileDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated Successfully!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Update Profile Error: $e");
    }
  }

  // --- IMAGE PICK + UPLOAD ---
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      final file = File(image.path);
      final String fileName = '${user!.id}_${DateTime.now().millisecondsSinceEpoch}.png';

      await Supabase.instance.client.storage.from('avatars').upload(
        fileName,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      final String imageUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);

      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', user!.id);

      await _fetchProfileDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile Picture Updated Successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  ImageProvider? _getProfileImage() {
    if (_profileData?['avatar_url'] != null) {
      return NetworkImage(_profileData!['avatar_url']);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final String displayPhone = _profileData?['phone_number'] ?? _profileData?['phone'] ?? "Not added";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue[900],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white,
                          backgroundImage: _getProfileImage(),
                          child: _getProfileImage() == null
                              ? const Icon(Icons.person, size: 55, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _profileData?['full_name'] ?? "Driver Name",
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user?.email ?? "",
                    style: TextStyle(color: Colors.blue[100], fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildInfoTile(Icons.phone_android_rounded, "Phone Number", displayPhone),

                  const SizedBox(height: 20),

                  // FIXES HERE: Removed 'const' from Container and fixed 'black70' to black.withOpacity(0.7)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      onTap: _showEditProfileBottomSheet,
                      leading: Icon(Icons.edit_note_rounded, color: Colors.black.withOpacity(0.7), size: 26),
                      title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),

                  const SizedBox(height: 35),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Supabase.instance.client.auth.signOut();
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text("Logout Account", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue[900], size: 26),
        title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
      ),
    );
  }
}