import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../../accounts/providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({required this.role, super.key});
  final String role;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>().profileData;
    if (profile != null) {
      if (widget.role == 'photographer') {
        _controllers['display_name'] = TextEditingController(text: profile['display_name']);
        _controllers['camera_details'] = TextEditingController(text: profile['camera_details']);
        _controllers['lenses'] = TextEditingController(text: profile['lenses']);
        _controllers['location'] = TextEditingController(text: profile['location']);
        _controllers['phone_number'] = TextEditingController(text: profile['phone_number']);
      } else {
        _controllers['full_name'] = TextEditingController(text: profile['full_name']);
        _controllers['location'] = TextEditingController(text: profile['location']);
        _controllers['phone_number'] = TextEditingController(text: profile['phone_number']);
      }
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final data = _controllers.map((key, value) => MapEntry(key, value.text));
    final success = await context.read<ProfileProvider>().updateProfile(widget.role, data);
    
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.check)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: _controllers.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.bottom(16.0),
              child: TextFormField(
                controller: e.value,
                decoration: InputDecoration(
                  labelText: e.key.replaceAll('_', ' ').toUpperCase(),
                  border: const OutlineInputBorder(),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
