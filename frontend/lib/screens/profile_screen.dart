import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import '../config/config.dart';
import 'dart:typed_data';
import '../providers/auth_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _aboutController = TextEditingController();
  XFile? _image;
  Uint8List? _imageBytes;
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
    if(picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _image = picked;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
       await _userService.updateProfile(_aboutController.text, _image);
       if (!mounted) return;
       
       // Reload profile to get fresh URLs and data
       final updatedUser = await _userService.getProfile();
       if (!mounted) return;
       
       Provider.of<AuthProvider>(context, listen: false).updateUser(updatedUser);
       
       setState(() {
          _image = null;
          _imageBytes = null; // Force reload from network
       });

       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
       if (mounted) setState(() => _isLoading = false);
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
                   
                    ImageProvider bgImage;
                    if (_imageBytes != null) {
                      bgImage = MemoryImage(_imageBytes!);
                    } else if (fullUrl != null) {
                      bgImage = NetworkImage(fullUrl);
                    } else {
                      bgImage = const AssetImage('assets/images/defaultProfile.jpg');
                    }

                    return CircleAvatar(
                      radius: 50,
                      backgroundImage: bgImage,
                      onBackgroundImageError: (exception, stackTrace) {
                        debugPrint('Image Load Error: $exception');
                      },
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
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully')));
              } catch (e) {
                if (!mounted) return;
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
