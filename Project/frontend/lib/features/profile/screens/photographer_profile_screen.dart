import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../accounts/providers/auth_provider.dart';

class PhotographerProfileScreen extends StatelessWidget {
  const PhotographerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

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
      body: SingleChildScrollView(
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
              user?.email ?? 'Photographer',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Chip(label: Text('Photographer')),
            const SizedBox(height: 32),
            _buildSectionTitle('Equipment & Team'),
            _buildInfoTile(Icons.camera_enhance_outlined, 'Camera Details', 'Not Set'),
            _buildInfoTile(Icons.camera_outlined, 'Lenses', 'Not Set'),
            _buildInfoTile(Icons.group_outlined, 'Team Members', '1'),
            const SizedBox(height: 24),
            _buildSectionTitle('General Info'),
            _buildInfoTile(Icons.location_on_outlined, 'Location', 'Not Set'),
            _buildInfoTile(Icons.phone_outlined, 'Phone', 'Not Set'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
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
