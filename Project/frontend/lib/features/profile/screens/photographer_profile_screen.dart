import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../accounts/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import 'edit_profile_screen.dart';

class PhotographerProfileScreen extends StatefulWidget {
  const PhotographerProfileScreen({super.key});

  @override
  State<PhotographerProfileScreen> createState() => _PhotographerProfileScreenState();
}

class _PhotographerProfileScreenState extends State<PhotographerProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchProfile('photographer');
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final user = authProvider.currentUser;
    final profile = profileProvider.profileData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photographer Dashboard'),
        actions: [
          IconButton(
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: profileProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 60,
                        child: Icon(Icons.camera_alt, size: 60),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          radius: 18,
                          child: const Icon(Icons.edit, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    profile?['display_name'] ?? user?.email ?? 'Photographer',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Chip(label: Text('Photographer')),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Equipment & Team'),
                  _buildInfoTile(Icons.camera_enhance_outlined, 'Camera Details', profile?['camera_details'] ?? 'Not Set'),
                  _buildInfoTile(Icons.camera_outlined, 'Lenses', profile?['lenses'] ?? 'Not Set'),
                  _buildInfoTile(Icons.group_outlined, 'Team Members', profile?['team_members_count']?.toString() ?? '1'),
                  const SizedBox(height: 24),
                  _buildSectionTitle('General Info'),
                  _buildInfoTile(Icons.location_on_outlined, 'Location', profile?['location'] ?? 'Not Set'),
                  _buildInfoTile(Icons.phone_outlined, 'Phone', profile?['phone_number'] ?? 'Not Set'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(role: 'photographer'),
                        ),
                      ).then((_) => profileProvider.fetchProfile('photographer'));
                    },
                    child: const Text('Edit Professional Profile'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0, left: 16),
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
      trailing: const Icon(Icons.chevron_right, size: 18),
    );
  }
}
