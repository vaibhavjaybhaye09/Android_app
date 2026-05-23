import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../accounts/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import 'edit_profile_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchProfile('user');
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
        title: const Text('My Profile'),
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
                  _buildProfileHeader(profile, user),
                  const SizedBox(height: 32),
                  _buildSkillsSection(profile),
                  const SizedBox(height: 24),
                  _buildInfoSection(profile),
                  const SizedBox(height: 32),
                  _buildServicesSection(profile),
                  const SizedBox(height: 32),
                  _buildPortfolioSection(profile),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(role: 'user'),
                        ),
                      ).then((_) => profileProvider.fetchProfile('user'));
                    },
                    child: const Text('Edit Profile & Skills'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic>? profile, dynamic user) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 60,
          child: Icon(Icons.person, size: 60),
        ),
        const SizedBox(height: 16),
        Text(
          profile?['display_name'] ?? user?.email ?? 'User',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        if (profile?['location'] != null)
          Text(profile!['location'], style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildSkillsSection(Map<String, dynamic>? profile) {
    final skills = profile?['skills'] as List? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Skills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: skills.map((s) => Chip(label: Text(s['name']))).toList(),
        ),
        if (skills.isEmpty) const Text('No skills added yet', style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildInfoSection(Map<String, dynamic>? profile) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Bio'),
          subtitle: Text(profile?['bio'] ?? 'No bio set'),
        ),
      ],
    );
  }

  Widget _buildServicesSection(Map<String, dynamic>? profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.between,
          children: [
            const Text('Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.add_circle_outline)),
          ],
        ),
        const Text('Feature coming soon: List your services for hire.', style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildPortfolioSection(Map<String, dynamic>? profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.between,
          children: [
            const Text('Portfolio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.add_a_photo_outlined)),
          ],
        ),
        const Text('Feature coming soon: Showcase your best work.', style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
