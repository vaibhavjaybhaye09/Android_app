import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../accounts/providers/auth_provider.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Profile'),
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
                  child: Icon(Icons.person, size: 60),
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
              user?.email ?? 'Guest User',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Customer', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            _buildInfoTile(Icons.person_outline, 'Full Name', 'Not Set'),
            _buildInfoTile(Icons.phone_outlined, 'Phone', 'Not Set'),
            _buildInfoTile(Icons.location_on_outlined, 'Location', 'Not Set'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Edit Profile'),
            ),
          ],
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
