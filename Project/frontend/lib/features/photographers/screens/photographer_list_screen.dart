import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/photographer_provider.dart';
import 'photographer_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import '../../../models/post_model.dart';
import '../../../models/photographer_model.dart';
import 'package:animations/animations.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import '../widgets/shimmer_widgets.dart';

class PhotographerListScreen extends StatefulWidget {
  const PhotographerListScreen({super.key});

  @override
  State<PhotographerListScreen> createState() => _PhotographerListScreenState();
}

class _PhotographerListScreenState extends State<PhotographerListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _categories = [
    'All',
    'Wedding',
    'Portrait',
    'Event',
    'Fashion',
    'Commercial',
    'Nature'
  ];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PhotographerProvider>().fetchPhotographers();
      context.read<PhotographerProvider>().fetchNearbyFeed();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.8),
              elevation: 0,
              centerTitle: true,
              title: const Text(
                'PhotoHub',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  letterSpacing: -1.5,
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF1A1A1A),
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: const Color(0xFF1A1A1A),
                indicatorWeight: 4,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
                tabs: const [
                  Tab(text: 'EXPLORE'),
                  Tab(text: 'NEARBY'),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: Color(0xFF1A1A1A)),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExploreTab(),
          _buildNearbyFeedTab(),
        ],
      ),
    );
  }

  Widget _buildExploreTab() {
    return CustomScrollView(
      slivers: [
        _buildCategoryFilter(),
        _buildPhotographerGrid(),
      ],
    );
  }

  Widget _buildNearbyFeedTab() {
    return Consumer<PhotographerProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 3,
            itemBuilder: (context, index) => const ShimmerLoading(
              isLoading: true,
              child: PostCardShimmer(),
            ),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off_outlined, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Update your profile location (City & Pincode) to see nearby photographers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () => provider.fetchNearbyFeed(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.nearbyFeed.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.network(
                  'https://assets9.lottiefiles.com/packages/lf20_v76p8r8m.json',
                  height: 200,
                  repeat: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'No nearby posts yet',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to share your work!',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.nearbyFeed.length,
          itemBuilder: (context, index) {
            final post = provider.nearbyFeed[index];
            return _NearbyPostCard(post: post);
          },
        );
      },
    );
  }

  Widget _buildCategoryFilter() {
    return SliverToBoxAdapter(
      child: Container(
        height: 60,
        color: Colors.white,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFF0095F6),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? Colors.transparent : const Color(0xFFE0E0E0),
                  ),
                ),
                showCheckmark: false,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPhotographerGrid() {
    return Consumer<PhotographerProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const ShimmerLoading(
                  isLoading: true,
                  child: PhotographerCardShimmer(),
                ),
                childCount: 3,
              ),
            ),
          );
        }

        if (provider.error != null) {
          return SliverFillRemaining(
            child: Center(child: Text('Error: ${provider.error}')),
          );
        }

        if (provider.photographers.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: Text('No photographers found')),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final photographer = provider.photographers[index];
                return _AnimatedPhotographerCard(
                  photographer: photographer,
                  index: index,
                );
              },
              childCount: provider.photographers.length,
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedPhotographerCard extends StatefulWidget {
  final dynamic photographer;
  final int index;

  const _AnimatedPhotographerCard({
    required this.photographer,
    required this.index,
  });

  @override
  State<_AnimatedPhotographerCard> createState() => _AnimatedPhotographerCardState();
}

class _AnimatedPhotographerCardState extends State<_AnimatedPhotographerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _PhotographerCard(photographer: widget.photographer),
      ),
    );
  }
}

class _PhotographerCard extends StatelessWidget {
  final dynamic photographer;

  const _PhotographerCard({required this.photographer});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Vibrate.feedback(FeedbackType.light);
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (context, animation, secondaryAnimation) =>
                PhotographerDetailScreen(photographer: photographer),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image with Hero
            Hero(
              tag: 'photographer_image_${photographer.id}',
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: (photographer.portfolio.isNotEmpty)
                          ? photographer.portfolio[0]
                          : 'https://images.unsplash.com/photo-1542038784456-1ea8e935640e',
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          color: Color(0xFF1A1A1A),
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF0F0F0), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundImage: photographer.profileImage != null
                          ? CachedNetworkImageProvider(photographer.profileImage!)
                          : null,
                      child: photographer.profileImage == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          photographer.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              photographer.specialty,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.circle, size: 4, color: Colors.grey),
                            const SizedBox(width: 8),
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              photographer.rating.toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${photographer.hourlyRate}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0095F6),
                        ),
                      ),
                      const Text(
                        'per hour',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF8E8E8E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyPostCard extends StatefulWidget {
  final PostModel post;

  const _NearbyPostCard({required this.post});

  @override
  State<_NearbyPostCard> createState() => _NearbyPostCardState();
}

class _NearbyPostCardState extends State<_NearbyPostCard> with SingleTickerProviderStateMixin {
  late AnimationController _likeController;
  late Animation<double> _likeAnimation;
  bool _showHeartOverlay = false;

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _likeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(_likeController);
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    setState(() => _showHeartOverlay = true);
    _likeController.forward(from: 0.0).then((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _showHeartOverlay = false);
      });
    });
    Vibrate.feedback(FeedbackType.medium);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: widget.post.photographer['profile']?['profile_picture'] != null
                      ? CachedNetworkImageProvider(widget.post.photographer['profile']['profile_picture'])
                      : null,
                  child: widget.post.photographer['profile']?['profile_picture'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.photographer['profile']?['display_name'] ?? widget.post.photographer['email'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: Color(0xFF0095F6)),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.post.photographerLocation?.area}, ${widget.post.photographerLocation?.city}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  'ID: #${widget.post.id}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          GestureDetector(
            onDoubleTap: _handleDoubleTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Hero(
                  tag: 'post_image_${widget.post.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: CachedNetworkImage(
                      imageUrl: widget.post.file,
                      width: double.infinity,
                      height: 350,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (_showHeartOverlay)
                  ScaleTransition(
                    scale: _likeAnimation,
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 100,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        widget.post.isLikedByUser ? Icons.favorite : Icons.favorite_border,
                        color: widget.post.isLikedByUser ? Colors.red : Colors.black,
                      ),
                      onPressed: () {
                        Vibrate.feedback(FeedbackType.light);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.chat_bubble_outline),
                    const SizedBox(width: 16),
                    const Icon(Icons.send_outlined),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${widget.post.likesCount} likes',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                if (widget.post.caption != null && widget.post.caption!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      children: [
                        TextSpan(
                          text: '${widget.post.photographer['profile']?['display_name'] ?? widget.post.photographer['email']} ',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        TextSpan(text: widget.post.caption),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '${widget.post.createdAt.day}/${widget.post.createdAt.month}/${widget.post.createdAt.year}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
