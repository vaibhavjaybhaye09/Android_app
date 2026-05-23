import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../accounts/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import 'edit_profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Account',
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A), letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showLogoutDialog(context, authProvider),
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF1A1A1A)),
          ),
        ],
      ),
      body: profileProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: const Color(0xFF1A1A1A),
              onRefresh: () => profileProvider.fetchProfile('user'),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildProfileHeader(profile, user),
                    const SizedBox(height: 40),
                    _buildSectionTitle('Biography'),
                    const SizedBox(height: 12),
                    _buildProfileSection(
                      content: profile?['bio'] ?? 'No bio set',
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Interests'),
                    const SizedBox(height: 12),
                    _buildSkillsSection(profile),
                    const SizedBox(height: 40),
                    _buildSectionTitle('Management'),
                    const SizedBox(height: 8),
                    _buildActionItem(
                      icon: Icons.person_outline,
                      title: 'Edit Profile',
                      subtitle: 'Update your personal details',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(role: 'user'),
                          ),
                        ).then((_) => profileProvider.fetchProfile('user'));
                      },
                    ),
                    _buildActionItem(
                      icon: Icons.notifications_none_outlined,
                      title: 'Notifications',
                      subtitle: 'Manage alerts and updates',
                      onTap: () {},
                    ),
                    _buildActionItem(
                      icon: Icons.help_outline,
                      title: 'Support',
                      subtitle: 'Contact our concierge service',
                      onTap: () {},
                    ),
                    const SizedBox(height: 60),
                    Center(
                      child: TextButton(
                        onPressed: () => _showLogoutDialog(context, authProvider),
                        child: const Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: Color(0xFF8E8E8E),
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic>? profile, dynamic user) {
    final imageUrl = profile?['profile_picture'];
    
    return Row(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF0F0F0), width: 4),
              ),
              child: CircleAvatar(
                radius: 46,
                backgroundColor: const Color(0xFFF8F9FA),
                backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                    ? CachedNetworkImageProvider(imageUrl)
                    : null,
                child: (imageUrl == null || imageUrl.isEmpty)
                    ? const Icon(Icons.person, size: 40, color: Color(0xFFDBDBDB))
                    : null,
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile?['display_name'] ?? user?.email?.split('@')[0] ?? 'User',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Color(0xFF0095F6)),
                  const SizedBox(width: 6),
                  Text(
                    profile?['location'] ?? 'Location not set',
                    style: const TextStyle(
                      color: Color(0xFF8E8E8E),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection({required String content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Text(
        content,
        style: TextStyle(
          fontSize: 15,
          color: Colors.grey[800],
          height: 1.6,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildSkillsSection(Map<String, dynamic>? profile) {
    final skills = profile?['skills'] as List? ?? [];
    if (skills.isEmpty) {
      return Text(
        'Add your interests to find matching photographers.',
        style: TextStyle(color: Colors.grey[500], fontSize: 14, fontStyle: FontStyle.italic),
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: skills.map((s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF1A1A1A).withOpacity(0.1)),
        ),
        child: Text(
          s['name'],
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 22, color: const Color(0xFF1A1A1A)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFDBDBDB)),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
