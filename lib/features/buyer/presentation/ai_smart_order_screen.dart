
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AiSmartOrderScreen extends StatefulWidget {
  const AiSmartOrderScreen({super.key});

  @override
  State<AiSmartOrderScreen> createState() => _AiSmartOrderScreenState();
}

class _AiSmartOrderScreenState extends State<AiSmartOrderScreen> {
  final _quantityController = TextEditingController();
  String? _selectedWasteType;
  bool _loading = false;
  bool _planReady = false;

  List<Map<String, dynamic>> _selectedFarmers = [];
  double _totalQuantity = 0;
  double _estimatedCost = 0;
  double _estimatedCo2 = 0;
  double _estimatedDistance = 0;
  double _optimizationScore = 0;
  String _reason = '';
  String _pickupDateText = '-';
  DateTime? _pickupDate;

  final List<String> _wasteTypes = [
    'Straw',
    'Husk',
    'Bagasse',
    'Cotton Waste',
    'Corn Residue',
    'Sugarcane Waste',
    'Other',
  ];

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _degToRad(double deg) => deg * pi / 180;

  double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  Future<void> _generatePlan() async {
    if (_selectedWasteType == null) {
      _show('Please select waste type');
      return;
    }

    final requiredQty =
        double.tryParse(_quantityController.text.trim()) ?? 0;

    if (requiredQty <= 0) {
      _show('Enter a valid quantity');
      return;
    }

    setState(() {
      _loading = true;
      _planReady = false;
    });

    try {
      final data = await Supabase.instance.client
          .from('waste_listings')
          .select()
          .eq('waste_type', _selectedWasteType!)
          .eq('status', 'available')
          .gt('available_quantity', 0);

      final listings = List<Map<String, dynamic>>.from(data);

      if (listings.isEmpty) {
        _show('No available listings found for $_selectedWasteType');
        setState(() => _loading = false);
        return;
      }

      final scored = <Map<String, dynamic>>[];

      for (final item in listings) {
        final available = _toDouble(item['available_quantity']);
        final price = _toDouble(item['price_per_unit']);
        final lat = _toDouble(item['latitude']);
        final lng = _toDouble(item['longitude']);

        final qtyScore = (available / requiredQty).clamp(0.0, 1.0) * 40;
        final priceScore = ((50 - price).clamp(0.0, 50.0) / 50) * 40;
        final locationScore = (lat != 0 && lng != 0) ? 20.0 : 5.0;

        scored.add({
          ...item,
          '_score': qtyScore + priceScore + locationScore,
          '_lat': lat,
          '_lng': lng,
          '_available': available,
          '_price': price,
          '_date': _parseDate(item['availability_date']),
        });
      }

      scored.sort(
            (a, b) => (b['_score'] as double).compareTo(a['_score'] as double),
      );

      final selected = <Map<String, dynamic>>[];
      double remaining = requiredQty;
      double total = 0;
      double totalDistance = 0;
      DateTime? maxDate;

      for (final item in scored) {
        if (remaining <= 0) break;

        final available = item['_available'] as double;
        if (available <= 0) continue;

        if (selected.isNotEmpty) {
          final last = selected.last;
          final dist = _haversine(
            last['_lat'],
            last['_lng'],
            item['_lat'],
            item['_lng'],
          );

          if (dist > 80 &&
              selected.length >= 2 &&
              remaining < requiredQty * 0.4) {
            continue;
          }
        }

        final take = available >= remaining ? remaining : available;

        selected.add({
          ...item,
          'selected_quantity': take,
        });

        total += take;
        remaining -= take;

        final d = item['_date'] as DateTime?;
        if (d != null && (maxDate == null || d.isAfter(maxDate))) {
          maxDate = d;
        }
      }

      if (selected.length >= 2) {
        for (int i = 0; i < selected.length - 1; i++) {
          totalDistance += _haversine(
            selected[i]['_lat'],
            selected[i]['_lng'],
            selected[i + 1]['_lat'],
            selected[i + 1]['_lng'],
          );
        }
      } else {
        totalDistance = selected.isEmpty ? 0 : 8;
      }

      if (total < requiredQty) {
        _show(
          'Only ${total.toStringAsFixed(0)} kg available. Not enough stock.',
        );
        setState(() => _loading = false);
        return;
      }

      maxDate ??= DateTime.now().add(const Duration(days: 2));

      final farmersCount = selected.length;
      final estimatedCost =
          (farmersCount * 120) + (total * 2.0) + (totalDistance * 8);
      final estimatedCo2 =
          (farmersCount * 1.4) + (total * 0.03) + (totalDistance * 0.12);

      double score = 90;
      if (farmersCount == 1) score = 97;
      if (farmersCount > 4) score -= (farmersCount - 4) * 4;
      if (totalDistance > 50) score -= 5;
      score = score.clamp(70, 98);

      final reason = farmersCount == 1
          ? 'One farmer has sufficient stock at a good price. Minimum transport needed.'
          : 'AI aggregated $farmersCount farmers using price, quantity and location closeness. Pickup scheduled on the latest availability date among selected farmers.';

      setState(() {
        _selectedFarmers = selected;
        _totalQuantity = total;
        _estimatedCost = estimatedCost;
        _estimatedCo2 = estimatedCo2;
        _estimatedDistance = totalDistance;
        _optimizationScore = score;
        _reason = reason;
        _pickupDate = maxDate;
        _pickupDateText = _formatDate(maxDate!);
        _planReady = true;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _show('Error generating plan: $e');
    }
  }

  Future<void> _acceptPlan() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      _show('Please login again');
      return;
    }

    setState(() => _loading = true);

    try {
      final supabase = Supabase.instance.client;
      final schedule = _pickupDate?.toIso8601String().split('T').first;

      for (final farmer in _selectedFarmers) {
        final listingId = farmer['id'];
        final qty = (farmer['selected_quantity'] as num).toDouble();
        final price = _toDouble(farmer['price_per_unit']);
        final total = qty * price;
        final farmerId = farmer['farmer_id'];

        final orderRes = await supabase.from('orders').insert({
          'buyer_id': user.id,
          'farmer_id': farmerId,
          'listing_id': listingId,
          'quantity': qty,
          'total_amount': total,
          'status': 'pending',
          'pickup_address': 'Farmer location',
          'delivery_address': 'Buyer location',
        }).select().single();

        final orderId = orderRes['id'];

        final currentAvailable = _toDouble(farmer['available_quantity']);
        final newAvailable = currentAvailable - qty;

        await supabase.from('waste_listings').update({
          'available_quantity': newAvailable,
          'status': newAvailable <= 0 ? 'sold' : 'available',
        }).eq('id', listingId);

        await supabase.from('pickup_jobs').insert({
          'order_id': orderId,
          'farmer_id': farmerId,
          'buyer_id': user.id,
          'pickup_address': 'Farmer location',
          'delivery_address': 'Buyer location',
          'status': 'pending',
          'schedule_date': schedule,
        });
      }

      if (!mounted) return;

      _show('AI Plan accepted! Pickup scheduled on $_pickupDateText');

      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) context.go('/buyer/orders');
    } catch (e) {
      if (!mounted) return;
      _show('Error accepting plan: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Smart Order'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🧠 Smart Waste Aggregation',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'AI selects farmers by price, quantity and location. Pickup date = latest availability date.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            DropdownButtonFormField<String>(
              value: _selectedWasteType,
              decoration: const InputDecoration(
                labelText: 'Waste Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.recycling),
              ),
              items: _wasteTypes
                  .map(
                    (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ),
              )
                  .toList(),
              onChanged: (v) => setState(() => _selectedWasteType = v),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _quantityController,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Required Quantity (kg)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.scale),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: _loading ? null : _generatePlan,
                icon: _loading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _loading ? 'AI is optimizing...' : 'Generate AI Plan',
                ),
              ),
            ),

            if (_planReady) ...[
              const SizedBox(height: 28),
              _buildPlanCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '🧠 AI PROCUREMENT PLAN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Score ${_optimizationScore.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            _infoRow('Waste Type', _selectedWasteType ?? '-'),
            _infoRow('Required', '${_quantityController.text} kg'),
            _infoRow('Fulfilled', '${_totalQuantity.toStringAsFixed(0)} kg'),
            _infoRow('Farmers Selected', '${_selectedFarmers.length}'),
            _infoRow(
              'Est. Route Distance',
              '${_estimatedDistance.toStringAsFixed(1)} km',
            ),
            _infoRow('Pickup Date', _pickupDateText),
            _infoRow(
              'Est. Transport Cost',
              '₹${_estimatedCost.toStringAsFixed(0)}',
            ),
            _infoRow('Est. CO₂', '${_estimatedCo2.toStringAsFixed(1)} kg'),

            const SizedBox(height: 16),
            const Text(
              'Selected Farmers',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),

            ..._selectedFarmers.map((f) {
              final qty = f['selected_quantity'];
              final price = f['price_per_unit'];
              final date = f['_date'] as DateTime?;
              final dateText = date != null ? _formatDate(date) : 'No date';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.agriculture,
                      size: 20,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${(qty as num).toStringAsFixed(0)} kg • ₹$price/kg • $dateText',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Why this plan?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _reason,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pickup Date Rule: latest availability date = $_pickupDateText',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Updated: payment opens before orders are created.
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _loading
                    ? null
                    : () {
                  final payAmount =
                      _estimatedCost + (_totalQuantity * 5);

                  context.push(
                    '/buyer/payment',
                    extra: {
                      'amount': payAmount,
                      'title': 'AI Smart Order Payment',
                      'onSuccess': () {
                        // Pop payment screen, then create orders.
                        if (context.canPop()) context.pop();
                        _acceptPlan();
                      },
                    },
                  );
                },
                child: _loading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text('Pay & Accept AI Plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}