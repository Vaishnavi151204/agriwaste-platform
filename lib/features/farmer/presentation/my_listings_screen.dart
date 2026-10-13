import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _listings = [];

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final data = await Supabase.instance.client
          .from('waste_listings')
          .select()
          .eq('farmer_id', user.id)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _listings = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load listings: $e')),
      );
    }
  }

  Future<void> _deleteListing(String id) async {
    try {
      await Supabase.instance.client
          .from('waste_listings')
          .delete()
          .eq('id', id);
      await _loadListings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete listing: $e')),
      );
    }
  }

  String _fmt(dynamic value) {
    final n = double.tryParse(value?.toString() ?? '') ?? 0;
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _listings.isEmpty
          ? RefreshIndicator(
        onRefresh: _loadListings,
        child: ListView(
          children: const [
            SizedBox(height: 180),
            Icon(Icons.inventory_2_outlined, size: 70),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No waste listings yet.',
                style: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'List your agricultural waste to see it here.',
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadListings,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _listings.length,
          itemBuilder: (context, index) {
            final listing = _listings[index];

            final wasteType =
                listing['waste_type']?.toString() ?? 'Waste';
            final cropType =
                listing['crop_type']?.toString() ?? 'Unknown crop';
            final originalQty = listing['quantity'];
            final availableQty = listing['available_quantity'];
            final unit = listing['unit']?.toString() ?? 'kg';
            final price = listing['price_per_unit'];
            final description =
                listing['description']?.toString() ?? '';

            final available = double.tryParse(
                availableQty?.toString() ?? '0') ??
                0;

            // Show SOLD when stock is finished
            final displayStatus =
            available <= 0 ? 'sold' : (listing['status']?.toString() ?? 'available');

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.recycling, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            wasteType,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Chip(
                          label: Text(
                            displayStatus.toUpperCase(),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Crop: $cropType'),
                    const SizedBox(height: 6),
                    Text('Original: ${_fmt(originalQty)} $unit'),
                    const SizedBox(height: 4),
                    Text(
                      'Available: ${_fmt(availableQty)} $unit',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: available <= 0
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Price: ₹${_fmt(price)} / $unit'),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(description),
                    ],
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          _deleteListing(listing['id'].toString());
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}