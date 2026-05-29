import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/photographer_model.dart';
import '../../../models/post_model.dart';
import '../../../models/service_model.dart';
import '../../../models/portfolio_item_model.dart';
import '../../bookings/providers/booking_provider.dart';
import '../providers/photographer_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../chat/providers/chat_provider.dart';
import '../../chat/screens/chat_detail_screen.dart';

class PhotographerDetailScreen extends StatefulWidget {
  final PhotographerModel photographer;

  const PhotographerDetailScreen({super.key, required this.photographer});

  @override
  State<PhotographerDetailScreen> createState() => _PhotographerDetailScreenState();
}

class _PhotographerDetailScreenState extends State<PhotographerDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PhotographerProvider>().fetchPhotographerPosts(widget.photographer.id);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.photographer.name,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileStatsHeader(),
                    const SizedBox(height: 16),
                    _buildBio(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.black,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on_outlined)),
                    Tab(icon: Icon(Icons.video_library_outlined)),
                    Tab(icon: Icon(Icons.person_pin_outlined)),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsGrid(),
            _buildVideosGrid(),
            _buildAboutTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBookButton(),
    );
  }

  Widget _buildProfileStatsHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey[200],
          backgroundImage: widget.photographer.profileImage != null
              ? CachedNetworkImageProvider(widget.photographer.profileImage!)
              : null,
          child: widget.photographer.profileImage == null
              ? const Icon(Icons.person, size: 40, color: Colors.grey)
              : null,
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem("Posts", widget.photographer.postsCount.toString()),
              _buildStatItem("Followers", widget.photographer.followersCount.toString()),
              _buildStatItem("Following", widget.photographer.followingCount.toString()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String count) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildBio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.photographer.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (widget.photographer.isVerified)
              const Icon(Icons.verified, color: Colors.blue, size: 16),
          ],
        ),
        Text(
          widget.photographer.specialty,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          widget.photographer.bio ?? "Capturing the beauty of every moment. Available for bookings worldwide.",
          style: const TextStyle(fontSize: 14),
        ),
        if (widget.photographer.location != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(widget.photographer.location!, style: const TextStyle(color: Colors.blue, fontSize: 14)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0095F6),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Follow", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              final chatProvider = context.read<ChatProvider>();
              final conversation = await chatProvider.startConversation(widget.photographer.id);
              if (conversation != null && mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatDetailScreen(conversation: conversation)),
                );
              }
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFDBDBDB)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Message", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildPostsGrid() {
    return Consumer<PhotographerProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final images = provider.photographerPosts.where((p) => p.postType == 'image').toList();
        if (images.isEmpty) {
          return const Center(child: Text("No posts yet"));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            final post = images[index];
            return InkWell(
              onTap: () => _showPostDetail(post),
              child: CachedNetworkImage(
                imageUrl: post.file,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[200]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVideosGrid() {
    return Consumer<PhotographerProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final videos = provider.photographerPosts.where((p) => p.postType == 'video').toList();
        if (videos.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text("No Reels Yet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 0.6,
          ),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final post = videos[index];
            return InkWell(
              onTap: () => _showPostDetail(post),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: post.file,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[200]),
                  ),
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(Icons.play_circle_outline, color: Colors.white, size: 24),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAboutTab() {
    return Consumer<PhotographerProvider>(
      builder: (context, provider, child) {
        // Since we don't have a specific fetch for these in provider yet, 
        // we might rely on the photographer details or wait for provider update.
        // For now, let's assume we can fetch them or they are in the model.
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Services & Pricing", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (provider.photographerServices.isEmpty)
                const Text("No services listed yet.", style: TextStyle(color: Colors.grey))
              else
                ...provider.photographerServices.map((s) => _buildServiceItem(s.title, s.description, "\$${s.price}")),
              
              const SizedBox(height: 24),
              const Text("Portfolio Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (provider.photographerPortfolio.isEmpty)
                const Text("No portfolio items listed yet.", style: TextStyle(color: Colors.grey))
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: provider.photographerPortfolio.length,
                  itemBuilder: (context, index) {
                    final item = provider.photographerPortfolio[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: item.image ?? '',
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.image)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceItem(String title, String desc, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(desc, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          ),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        ],
      ),
    );
  }

  Widget _buildBottomBookButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: ElevatedButton(
        onPressed: () => _showBookingSheet(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text("Book Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showPostDetail(PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: widget.photographer.profileImage != null
                      ? CachedNetworkImageProvider(widget.photographer.profileImage!)
                      : null,
                ),
                title: Text(widget.photographer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(post.location ?? "New York"),
                trailing: const Icon(Icons.more_horiz),
              ),
              CachedNetworkImage(
                imageUrl: post.file,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(post.isLikedByUser ? Icons.favorite : Icons.favorite_border,
                              color: post.isLikedByUser ? Colors.red : Colors.black),
                          onPressed: () => context.read<PhotographerProvider>().toggleLike(post.id),
                        ),
                        IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () {}),
                        IconButton(icon: const Icon(Icons.send_outlined), onPressed: () {}),
                        const Spacer(),
                        const Icon(Icons.bookmark_border),
                      ],
                    ),
                    Text("${post.likesCount} likes", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black),
                        children: [
                          TextSpan(text: "${widget.photographer.name} ", style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: post.caption ?? ""),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("View all ${post.commentsCount} comments", style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BookingSheet(photographer: widget.photographer),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class _BookingSheet extends StatefulWidget {
  final PhotographerModel photographer;

  const _BookingSheet({required this.photographer});

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  DateTime? _selectedDate;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Book Session', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Select Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDBDBDB)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20, color: Color(0xFF0095F6)),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate == null ? 'Choose a date' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    style: TextStyle(color: _selectedDate == null ? Colors.grey[600] : Colors.black, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Notes (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tell the photographer about your requirements...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDBDBDB)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0095F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Confirm Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBooking() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a date')));
      return;
    }

    setState(() => _isLoading = true);

    final success = await context.read<BookingProvider>().createBooking(
          photographerId: widget.photographer.id,
          date: _selectedDate!.toIso8601String().split('T')[0],
          notes: _notesController.text,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Booking request sent successfully!' : 'Failed to create booking. Please try again.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
