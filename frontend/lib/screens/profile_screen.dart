import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/data_service.dart';
import '../config/config.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _aboutController = TextEditingController();
  File? _image;
  final UserService _userService = UserService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _userService.getProfile();
      _aboutController.text = user['aboutMe'] ?? '';
      // Update provider user? Ideally yes.
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if(picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
       await _userService.updateProfile(_aboutController.text, _image);
       // Reload profile to get fresh URLs and data
       final updatedUser = await _userService.getProfile();
       Provider.of<AuthProvider>(context, listen: false).updateUser(updatedUser);
       
       setState(() {
          _image = null; // Force reload from network
       });

       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
       setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
     final user = Provider.of<AuthProvider>(context).user;
     return Scaffold(
       appBar: AppBar(title: const Text('Edit Profile')),
       body: SingleChildScrollView(
         padding: const EdgeInsets.all(24),
         child: Column(
           children: [
             GestureDetector(
               onTap: _pickImage,
               child: Consumer<AuthProvider>(
                 builder: (ctx, auth, _) {
                   // Add timestamp to bust cache
                   final picUrl = auth.user?['profilePicture'];
                   final fullUrl = picUrl != null 
                      ? '${Config.baseUrl}/$picUrl?v=${DateTime.now().millisecondsSinceEpoch}' 
                      : null;
                   
                   final ImageProvider? bgImage = _image != null 
                      ? FileImage(_image!) 
                      : (fullUrl != null ? NetworkImage(fullUrl) : null);

                   return CircleAvatar(
                     radius: 50,
                     backgroundImage: bgImage,
                     onBackgroundImageError: bgImage != null ? (exception, stackTrace) {
                        print('Image Load Error: $exception');
                     } : null,
                     child: bgImage == null ? const Icon(Icons.camera_alt, size: 40) : null,
                   );
                 }
               ),
             ),
             const SizedBox(height: 16),
             Text(user?['username'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
             Text(user?['email'] ?? '', style: const TextStyle(color: Colors.grey)),
             const SizedBox(height: 32),
             TextField(
               controller: _aboutController,
               decoration: const InputDecoration(labelText: 'About Me', alignLabelWithHint: true),
               maxLines: 4,
             ),
             const SizedBox(height: 24),
             if(_isLoading) const CircularProgressIndicator()
             else ElevatedButton(onPressed: _save, child: const Text('Save Changes')),
             const SizedBox(height: 16),
             TextButton(
               onPressed: _showChangePasswordDialog,
               child: const Text('Change Password', style: TextStyle(color: Colors.redAccent)),
             ),
           ],
         ),
       ),
     );
  }

  void _showChangePasswordDialog() {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldController, obscureText: true, decoration: const InputDecoration(labelText: 'Old Password')),
            TextField(controller: newController, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
            TextField(controller: confirmController, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm New Password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (newController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                return;
              }
              try {
                final authService = AuthService();
                await authService.changePassword(oldController.text, newController.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
