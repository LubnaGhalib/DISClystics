import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';


class ProfileSetupScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> registrationData;

  const ProfileSetupScreen({
    super.key,
    required this.userId,
    required this.registrationData,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  @override
  void initState() {
    super.initState();
    // Set initial name from registration data
    _nameController.text =
    '${widget.registrationData['firstName']} ${widget.registrationData['lastName']}';
  }

  File? _profileImage;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  bool _isSaving = false;


  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      // Show image source selection
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, ImageSource.camera),
                child: const Text('Camera'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, ImageSource.gallery),
                child: const Text('Gallery'),
              ),
            ],
          ),
        ),
      );

      if (source == null || !mounted) return;

      // Handle permissions based on platform and source
      Permission permission = Permission.camera;
      if (source == ImageSource.gallery) {
        if (Platform.isAndroid) {
          final androidInfo = await DeviceInfoPlugin().androidInfo;
          permission = (androidInfo.version.sdkInt >= 33)
              ? Permission.photos
              : Permission.storage;
        } else {
          permission = Permission.photos;
        }
      }

      // Request and check permission status
      final PermissionStatus status = await permission.request();
      if (!mounted) return;

      if (status.isGranted) {
        final XFile? image = await picker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 800,
        );

        if (image != null && mounted) {
          setState(() => _profileImage = File(image.path));
        }
      } else if (status.isPermanentlyDenied) {
        if (!mounted) return;
        await _showPermissionDialog(permission);
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('Error: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('Unexpected error: ${e.toString()}');
    }
  }

  Future<void> _showPermissionDialog(Permission permission) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(
          'Please enable ${_getPermissionName(permission)} access in settings',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );

    if (result == true) {
      await openAppSettings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please restart the app after changing permissions')),
      );
    }
  }

  String _getPermissionName(Permission permission) {
    if (permission == Permission.camera) return 'Camera';
    if (permission == Permission.photos) return 'Photos';
    if (permission == Permission.storage) return 'Storage';
    return 'required';
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You don\'t have permission to perform this action';
        case 'resource-exhausted':
          return 'Storage limit exceeded. Try a smaller image';
        default:
          return 'Server error: ${error.message}';
      }
    }
    return error.toString().replaceAll('Exception:', '').trim();
  }

  Future<void> _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        // Get current user ID securely
        final userId = FirebaseAuth.instance.currentUser!.uid;
        String? imageUrl;

        if (_profileImage != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('profile_pictures/$userId');
          await storageRef.putFile(_profileImage!);
          imageUrl = await storageRef.getDownloadURL();
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId) // ← Should come from auth
            .set({
          'name': _nameController.text.trim(),
          'age': int.parse(_ageController.text),
          'occupation': _occupationController.text,
          'profilePicture': imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } on FirebaseException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getErrorMessage(e)),
            backgroundColor: Colors.red,),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text('Almost there!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : null,
                        child: _profileImage == null
                            ? const Icon(Icons.add_a_photo, size: 40)
                            : null,
                      ),
                      if (_profileImage != null)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setState(() => _profileImage = null),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Please enter your age';
                    final age = int.tryParse(value);
                    if (age == null) return 'Enter a valid number';
                    if (age < 13) return 'Minimum age is 13';
                    if (age > 120) return 'Enter a valid age';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _occupationController,
                  decoration: const InputDecoration(
                    labelText: 'Occupation',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter your occupation' : null,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isSaving ? null : _submitProfile,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator()
                      : const Text('Save Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}