import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  Map<String, dynamic>? _profileData;
  String? _localImagePath;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        setState(() {
          _profileData = data;
          _nameController.text = data['full_name'] ?? "";
          _phoneController.text = data['phone_number'] ?? data['phone'] ?? "";
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

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
                  prefixIcon: Icon(Icons.person_outline),
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
                child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 25),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateProfileData() async {
    if (_nameController.text.trim().isEmpty) return;

    Navigator.pop(context);
    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('profiles').update({
        'full_name': _nameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
      }).eq('id', user.id);

      await _loadUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated Successfully!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Update Profile Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating profile: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteOldAvatar() async {
    try {
      final oldUrl = _profileData?['avatar_url'];
      if (oldUrl == null || oldUrl.isEmpty) return;

      final oldFileName = oldUrl.split('avatars/').last;
      if (oldFileName.isNotEmpty) {
        await supabase.storage.from('avatars').remove([oldFileName]);
      }
    } catch (e) {
      debugPrint("Delete old avatar error: $e");
    }
  }
  Future<void> _pickAndUploadImage() async {
    try {
      PermissionStatus status = await Permission.photos.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        status = await Permission.photos.request();
      }
      if (status.isDenied || status.isPermanentlyDenied) {
        status = await Permission.storage.status;
        if (status.isDenied || status.isPermanentlyDenied) {
          status = await Permission.storage.request();
        }
      }
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Storage permission is required to pick images"),
              backgroundColor: Colors.orange,
            ),
          );
          await openAppSettings();
        }
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (image == null) return;

      setState(() {
        _isLoading = true;
        _localImagePath = image.path;
      });

      final user = supabase.auth.currentUser;
      if (user == null) return;

      await _deleteOldAvatar();

      final file = File(image.path);
      final fileName = '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      debugPrint("Uploading to avatars bucket: $fileName");

      await supabase.storage.from('avatars').upload(
        fileName,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      final imageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      debugPrint("Upload success, URL: $imageUrl");

      await supabase.from('profiles').update({
        'avatar_url': imageUrl,
      }).eq('id', user.id);

      debugPrint("Profile updated with avatar_url");

      await _loadUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Picture Updated!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Upload error details: $e");
      String errorMsg = "Upload failed";
      if (e.toString().contains('Bucket not found')) {
        errorMsg = "Storage bucket not found. Please create 'avatars' bucket in Supabase Dashboard > Storage.";
      } else if (e.toString().contains('permission')) {
        errorMsg = "Permission denied. Check storage bucket policies.";
      } else {
        errorMsg = "Upload error: $e";
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  ImageProvider? _getProfileImage() {
    if (_localImagePath != null) {
      return FileImage(File(_localImagePath!));
    }
    if (_profileData?['avatar_url'] != null) {
      final cacheBust = DateTime.now().millisecondsSinceEpoch;
      return NetworkImage('${_profileData!['avatar_url']}?t=$cacheBust');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = supabase.auth.currentUser?.email ?? "User Email";
    final displayPhone = _profileData?['phone_number'] ?? _profileData?['phone'] ?? "Not added";

    return SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                child: SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/profile_cover.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue[900]!, Colors.blue[700]!],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black.withValues(alpha: 0.4), Colors.blue[900]!.withValues(alpha: 0.5)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _getProfileImage(),
                          child: _getProfileImage() == null && !_isLoading
                              ? Icon(Icons.person, size: 60, color: Colors.blue[900])
                              : (_isLoading && _localImagePath == null ? const CircularProgressIndicator() : null),
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

          Text(
            _profileData?['full_name'] ?? "Passenger",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
          Text(
            userEmail,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),

          const SizedBox(height: 25),

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
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.phone, color: Colors.blue, size: 22),
                        ),
                        title: const Text("Phone Number", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        subtitle: Text(displayPhone, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.person_outline, color: Colors.blue, size: 22),
                        ),
                        title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                        onTap: _showEditProfileBottomSheet,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

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
                      backgroundColor: Colors.red[50]!.withValues(alpha: 0.3),
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

