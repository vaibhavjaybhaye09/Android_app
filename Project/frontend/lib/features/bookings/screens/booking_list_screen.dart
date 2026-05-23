import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchMyBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          if (provider.bookings.isEmpty) {
            return const Center(child: Text('No bookings found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.bookings.length,
            itemBuilder: (context, index) {
              final booking = provider.bookings[index];
              return Card(
                margin: const EdgeInsets.bottom(16),
                child: ListTile(
                  title: Text('Booking with ${booking.photographer.name}'),
                  subtitle: Text('Date: ${booking.date}\nStatus: ${booking.status}'),
                  trailing: Text(
                    '\$${booking.totalPrice}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
