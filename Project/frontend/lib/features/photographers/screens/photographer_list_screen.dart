import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/photographer_provider.dart';
import 'photographer_detail_screen.dart';

class PhotographerListScreen extends StatefulWidget {
  const PhotographerListScreen({super.key});

  @override
  State<PhotographerListScreen> createState() => _PhotographerListScreenState();
}

class _PhotographerListScreenState extends State<PhotographerListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PhotographerProvider>().fetchPhotographers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photographers'),
      ),
      body: Consumer<PhotographerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          if (provider.photographers.isEmpty) {
            return const Center(child: Text('No photographers found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.photographers.length,
            itemBuilder: (context, index) {
              final photographer = provider.photographers[index];
              return Card(
                margin: const EdgeInsets.bottom(16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: photographer.profileImage != null
                        ? NetworkImage(photographer.profileImage!)
                        : null,
                    child: photographer.profileImage == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(photographer.name),
                  subtitle: Text(photographer.specialty),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      Text(photographer.rating.toString()),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhotographerDetailScreen(
                          photographer: photographer,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
