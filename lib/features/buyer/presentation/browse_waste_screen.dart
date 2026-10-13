import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BrowseWasteScreen extends StatefulWidget {
  const BrowseWasteScreen({super.key});

  @override
  State<BrowseWasteScreen> createState() => _BrowseWasteScreenState();
}

class _BrowseWasteScreenState extends State<BrowseWasteScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _listings = [];

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Only show listings that still have stock and are available
      final data = await _supabase
          .from('waste_listings')
          .select()
          .gt('available_quantity', 0)
          .eq('status', 'available')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _listings = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Farm Waste'),
        actions: [
          IconButton(
            onPressed: _loadListings,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 60),
              const SizedBox(height: 16),
              const Text(
                'Could not load waste listings',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadListings,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_listings.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadListings,
        child: ListView(
          children: const [
            SizedBox(height: 180),
            Icon(Icons.inventory_2_outlined, size: 70),
            SizedBox(height: 20),
            Center(
              child: Text(
                'No waste listings found.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            Center(child: Text('Farmers need to list waste first.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadListings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _listings.length,
        itemBuilder: (context, index) {
          return _WasteCard(listing: _listings[index]);
        },
      ),
    );
  }
}

class _WasteCard extends StatelessWidget {
  final Map<String, dynamic> listing;

  const _WasteCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    final wasteType = listing['waste_type']?.toString() ?? 'Farm Waste';
    final cropType = listing['crop_type']?.toString() ?? 'Unknown crop';

    // Always prefer available_quantity (remaining stock)
    final availableQty = double.tryParse(
      listing['available_quantity']?.toString() ?? '',
    ) ??
        double.tryParse(listing['quantity']?.toString() ?? '0') ??
        0.0;

    final unit = listing['unit']?.toString() ?? 'kg';
    final price = listing['price_per_unit']?.toString() ?? '0';
    final status = listing['status']?.toString() ?? 'available';
    final description = listing['description']?.toString() ?? '';

    // Safety: hide sold / zero stock even if query missed them
    if (status.toLowerCase() == 'sold' || availableQty <= 0) {
      return const SizedBox.shrink();
    }

    final availableText = availableQty == availableQty.roundToDouble()
        ? availableQty.toInt().toString()
        : availableQty.toStringAsFixed(2);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.push('/buyer/waste-details', extra: listing);
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.eco_rounded,
                      size: 30,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wasteType,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Crop: $cropType'),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.scale_outlined,
                      label: 'Available',
                      value: '$availableText $unit',
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.currency_rupee_rounded,
                      label: 'Price',
                      value: '₹$price/$unit',
                    ),
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Available for purchase',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}