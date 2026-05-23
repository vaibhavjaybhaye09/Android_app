import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/photographer_model.dart';
import '../../bookings/providers/booking_provider.dart';

class PhotographerDetailScreen extends StatelessWidget {
  final PhotographerModel photographer;

  const PhotographerDetailScreen({super.key, required this.photographer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(photographer.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: photographer.profileImage != null
                    ? NetworkImage(photographer.profileImage!)
                    : null,
                child: photographer.profileImage == null
                    ? const Icon(Icons.person, size: 60)
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              photographer.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              photographer.specialty,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  photographer.rating.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '\$${photographer.hourlyRate}/hr',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'About',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              photographer.bio ?? 'No bio available.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              'Portfolio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (photographer.portfolio.isEmpty)
              const Text('No portfolio images available.')
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: photographer.portfolio.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    photographer.portfolio[index],
                    fit: BoxFit.cover,
                  );
                },
              ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _showBookingDialog(context),
              child: const Text('Book Now'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDialog(BuildContext context) {
    final dateController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Book Photographer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'Date (YYYY-MM-DD)',
                  hintText: '2023-12-25',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await context.read<BookingProvider>().createBooking(
                      photographerId: photographer.id,
                      date: dateController.text,
                      notes: notesController.text,
                    );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Booking successful!'
                          : 'Booking failed. Please try again.'),
                    ),
                  );
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}
