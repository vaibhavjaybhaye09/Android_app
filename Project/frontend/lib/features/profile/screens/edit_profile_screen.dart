import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({required this.role, super.key});
  final String role;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  List<int> _selectedSkillIds = [];
  XFile? _imageFile;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>().profileData;
    if (profile != null) {
      _nameController.text = profile['display_name'] ?? '';
      _bioController.text = profile['bio'] ?? '';
      _locationController.text = profile['location'] ?? '';
      _cityController.text = profile['city'] ?? '';
      _areaController.text = profile['area'] ?? '';
      _pincodeController.text = profile['pincode'] ?? '';
      _selectedSkillIds = (profile['skills'] as List?)?.map((s) => s['id'] as int).toList() ?? [];
      _currentImageUrl = profile['profile_picture'];
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final Map<String, dynamic> data = {
      'display_name': _nameController.text,
      'bio': _bioController.text,
      'location': _locationController.text,
      'city': _cityController.text,
      'area': _areaController.text,
      'pincode': _pincodeController.text,
      'skill_ids': _selectedSkillIds,
    };
    
    if (_imageFile != null) {
      // Pass the XFile directly to handle cross-platform uploads
      data['profile_picture_file'] = _imageFile;
    }

    try {
      await context.read<ProfileProvider>().updateProfile(data);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSkills = context.watch<ProfileProvider>().skills;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile & Skills'),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.check)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _imageFile != null 
                        ? (kIsWeb 
                            ? NetworkImage(_imageFile!.path) 
                            : FileImage(File(_imageFile!.path)) as ImageProvider)
                        : (_currentImageUrl != null ? NetworkImage(_currentImageUrl!) : null),
                    child: (_imageFile == null && _currentImageUrl == null)
                        ? const Icon(Icons.person, size: 60)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Display Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Bio', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'General Location', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _pincodeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Pincode', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _areaController,
              decoration: const InputDecoration(labelText: 'Specific Area', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            const Text('Select Your Skills', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: allSkills.map((skill) {
                final isSelected = _selectedSkillIds.contains(skill['id']);
                return FilterChip(
                  label: Text(skill['name']),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedSkillIds.add(skill['id']);
                      } else {
                        _selectedSkillIds.remove(skill['id']);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
