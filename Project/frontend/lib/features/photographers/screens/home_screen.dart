import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:animations/animations.dart';
import 'dart:ui';

import '../../accounts/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import 'photographer_list_screen.dart';
import '../../bookings/screens/booking_list_screen.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../../chat/screens/chat_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profileData;
    final imageUrl = profile?['profile_picture'];

    final List<Widget> widgetOptions = [
      const PhotographerListScreen(),
      const BookingListScreen(),
      const ChatListScreen(),
      const UserProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: GNav(
                  rippleColor: Colors.grey[300]!,
                  hoverColor: Colors.grey[100]!,
                  gap: 8,
                  activeColor: const Color(0xFF1A1A1A),
                  iconSize: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  duration: const Duration(milliseconds: 400),
                  tabBackgroundColor: const Color(0xFF1A1A1A).withOpacity(0.05),
                  color: Colors.grey[600]!,
                  tabs: [
                    const GButton(
                      icon: Icons.explore_rounded,
                      text: 'Explore',
                    ),
                    const GButton(
                      icon: Icons.calendar_today_rounded,
                      text: 'Bookings',
                    ),
                    const GButton(
                      icon: Icons.chat_bubble_rounded,
                      text: 'Chat',
                    ),
                    GButton(
                      icon: Icons.person_rounded,
                      leading: _buildProfileIcon(imageUrl),
                      text: 'Profile',
                    ),
                  ],
                  selectedIndex: _selectedIndex,
                  onTabChange: _onItemTapped,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileIcon(String? imageUrl) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _selectedIndex == 3 ? const Color(0xFF1A1A1A) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: CircleAvatar(
        radius: 11,
        backgroundColor: Colors.grey[200],
        backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
            ? NetworkImage(imageUrl)
            : null,
        child: (imageUrl == null || imageUrl.isEmpty)
            ? const Icon(Icons.person, size: 14)
            : null,
      ),
    );
  }
}
