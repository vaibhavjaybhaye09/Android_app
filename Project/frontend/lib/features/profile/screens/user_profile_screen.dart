import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../accounts/providers/auth_provider.dart';
import '../../photographers/providers/photographer_provider.dart';
import '../../photographers/screens/create_post_screen.dart';
import '../../photographers/screens/create_service_screen.dart';
import '../../photographers/screens/add_portfolio_item_screen.dart';
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
      final profileProvider = context.read<ProfileProvider>();
      profileProvider.fetchProfile('user');
      
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser?.role == 'photographer') {
        context.read<PhotographerProvider>().fetchPhotographerPosts(authProvider.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final photographerProvider = context.watch<PhotographerProvider>();
    final user = authProvider.currentUser;
    final profile = profileProvider.profileData;
    
    // Check role from both local user object and fetched profile data
    final isPhotographer = user?.role == 'photographer' || profile?['role'] == 'photographer';

    // Fetch posts if they are a photographer and we don't have them yet
    if (isPhotographer && photographerProvider.photographerPosts.isEmpty && !photographerProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
         photographerProvider.fetchPhotographerPosts(user?.id ?? profile?['id'] ?? 0);
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A), letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (isPhotographer)
            IconButton(
              onPressed: () => _navigateToCreatePost(),
              icon: const Icon(Icons.add_box_outlined, color: Color(0xFF1A1A1A), size: 28),
            ),
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
              onRefresh: () async {
                await profileProvider.fetchProfile('user');
                if (isPhotographer) {
                  await photographerProvider.fetchPhotographerPosts(user!.id);
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildProfileHeader(profile, user),
                          const SizedBox(height: 24),
                          _buildStatsRow(isPhotographer, profile, photographerProvider),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Biography'),
                          const SizedBox(height: 8),
                          Text(
                            profile?['bio'] ?? 'No bio set',
                            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    if (isPhotographer) ...[
                      const Divider(height: 1),
                      _buildPhotographerActions(),
                      const Divider(height: 1),
                      _buildPhotographerPostsGrid(photographerProvider),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Interests'),
                            const SizedBox(height: 12),
                            _buildSkillsSection(profile),
                            const SizedBox(height: 32),
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
                            if (isPhotographer)
                              _buildActionItem(
                                icon: Icons.cloud_upload_outlined,
                                title: 'Upload & Share',
                                subtitle: 'Share new photos or services',
                                onTap: _navigateToCreatePost,
                              ),
                            _buildActionItem(
                              icon: Icons.notifications_none_outlined,
                              title: 'Notifications',
                              subtitle: 'Manage alerts and updates',
                              onTap: () {},
                            ),
                            _buildActionItem(
                              icon: Icons.help_outline_outlined,
                              title: 'Support',
                              subtitle: 'Contact our concierge service',
                              onTap: () {},
                            ),
                            if (!isPhotographer)
                              _buildActionItem(
                                icon: Icons.camera_alt_outlined,
                                title: 'Become a Photographer',
                                subtitle: 'Start sharing your work and services',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const EditProfileScreen(role: 'photographer'),
                                    ),
                                  ).then((_) => profileProvider.fetchProfile('user'));
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                    Center(
                      child: TextButton(
                        onPressed: () => _showLogoutDialog(context, authProvider),
                        child: const Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
      floatingActionButton: isPhotographer 
        ? FloatingActionButton(
            onPressed: _navigateToCreatePost,
            backgroundColor: Colors.black,
            child: const Icon(Icons.add, color: Colors.white),
          )
        : null,
    );
  }

  void _navigateToCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostScreen()),
    ).then((value) {
      if (value == true) {
        final authProvider = context.read<AuthProvider>();
        context.read<PhotographerProvider>().fetchPhotographerPosts(authProvider.currentUser!.id);
      }
    });
  }

  Widget _buildStatsRow(bool isPhotographer, Map<String, dynamic>? profile, PhotographerProvider provider) {
    if (!isPhotographer) return const SizedBox.shrink();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(provider.photographerPosts.length.toString(), "Posts"),
        _buildStatItem(profile?['followers_count']?.toString() ?? "0", "Followers"),
        _buildStatItem(profile?['following_count']?.toString() ?? "0", "Following"),
      ],
    );
  }

  Widget _buildPhotographerActions() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('PROFESSIONAL TOOLS'),
              TextButton.icon(
                onPressed: _navigateToCreatePost,
                icon: const Icon(Icons.add_a_photo, size: 16),
                label: const Text('Post'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildLargeActionCard(
                  icon: Icons.add_shopping_cart,
                  label: 'New Service',
                  subtitle: 'Price packages',
                  color: Colors.orange.shade50,
                  iconColor: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateServiceScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLargeActionCard(
                  icon: Icons.collections_outlined,
                  label: 'Add Portfolio',
                  subtitle: 'Showcase work',
                  color: Colors.blue.shade50,
                  iconColor: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddPortfolioItemScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargeActionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildPhotographerPostsGrid(PhotographerProvider provider) {
    if (provider.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (provider.photographerPosts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(Icons.add_a_photo_outlined, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("Share your first photo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            const Text("When you share photos, they'll appear on your profile.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            TextButton(
              onPressed: _navigateToCreatePost,
              child: const Text("Share your first photo", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: provider.photographerPosts.length,
      itemBuilder: (context, index) {
        final post = provider.photographerPosts[index];
        return CachedNetworkImage(
          imageUrl: post.file,
          fit: BoxFit.cover,
        );
      },
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
