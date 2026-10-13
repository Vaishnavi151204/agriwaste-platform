import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WasteDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> listing;

  const WasteDetailsScreen({
    super.key,
    required this.listing,
  });

  @override
  State<WasteDetailsScreen> createState() => _WasteDetailsScreenState();
}

class _WasteDetailsScreenState extends State<WasteDetailsScreen> {
  final _quantityController = TextEditingController();
  final _pickupController = TextEditingController();
  final _deliveryController = TextEditingController();

  bool _loading = false;
  bool _loadingAddress = true;

  String? _buyerAddress;
  double? _buyerLat;
  double? _buyerLng;

  @override
  void initState() {
    super.initState();
    _loadBuyerAddress();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _pickupController.dispose();
    _deliveryController.dispose();
    super.dispose();
  }

  Future<void> _loadBuyerAddress() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => _loadingAddress = false);
        return;
      }

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('address, latitude, longitude')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      final address = profile?['address']?.toString();
      final lat = double.tryParse(profile?['latitude']?.toString() ?? '');
      final lng = double.tryParse(profile?['longitude']?.toString() ?? '');

      setState(() {
        _buyerAddress = address;
        _buyerLat = lat;
        _buyerLng = lng;

        // Auto-fill
        _pickupController.text = 'Farmer location';
        if (address != null && address.isNotEmpty) {
          _deliveryController.text = address;
        }

        _loadingAddress = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAddress = false);
    }
  }

  double get _price {
    return double.tryParse(widget.listing['price_per_unit']?.toString() ?? '') ?? 0;
  }

  double get _availableQuantity {
    return double.tryParse(widget.listing['available_quantity']?.toString() ?? '') ??
        double.tryParse(widget.listing['quantity']?.toString() ?? '') ??
        0;
  }

  double get _selectedQuantity {
    return double.tryParse(_quantityController.text) ?? 0;
  }

  double get _total => _selectedQuantity * _price;

  double? get _farmerLat {
    return double.tryParse(widget.listing['latitude']?.toString() ?? '');
  }

  double? get _farmerLng {
    return double.tryParse(widget.listing['longitude']?.toString() ?? '');
  }

  Future<void> _placeOrder() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showMessage('Please login first.', error: true);
      return;
    }

    final quantity = _selectedQuantity;
    if (quantity <= 0) {
      _showMessage('Enter a valid quantity.', error: true);
      return;
    }
    if (quantity > _availableQuantity) {
      _showMessage('Only $_availableQuantity is available.', error: true);
      return;
    }
    if (_deliveryController.text.trim().isEmpty) {
      _showMessage('Please set your delivery address first.', error: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final supabase = Supabase.instance.client;
      final farmerId = widget.listing['farmer_id']?.toString();
      final listingId = widget.listing['id']?.toString();

      if (farmerId == null || listingId == null) {
        throw Exception('Invalid listing');
      }

      final newAvailable = _availableQuantity - quantity;

      final orderResponse = await supabase
          .from('orders')
          .insert({
        'buyer_id': user.id,
        'farmer_id': farmerId,
        'listing_id': listingId,
        'quantity': quantity,
        'total_amount': _total,
        'pickup_address': _pickupController.text.trim().isEmpty
            ? 'Farmer location'
            : _pickupController.text.trim(),
        'delivery_address': _deliveryController.text.trim(),
        'status': 'pending',
      })
          .select()
          .single();

      final orderId = orderResponse['id'].toString();

      await supabase.from('pickup_jobs').insert({
        'order_id': orderId,
        'farmer_id': farmerId,
        'buyer_id': user.id,
        'pickup_address': _pickupController.text.trim().isEmpty
            ? 'Farmer location'
            : _pickupController.text.trim(),
        'delivery_address': _deliveryController.text.trim(),
        'status': 'pending',
      });

      await supabase.from('waste_listings').update({
        'available_quantity': newAvailable,
        'status': newAvailable <= 0 ? 'sold' : 'available',
      }).eq('id', listingId);

      if (!mounted) return;
      _showMessage('Order placed successfully!');
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) context.go('/buyer/orders');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not place order: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startPaymentAndOrder() {
    if (_selectedQuantity <= 0) {
      _showMessage('Enter a valid quantity.', error: true);
      return;
    }
    if (_selectedQuantity > _availableQuantity) {
      _showMessage('Only $_availableQuantity is available.', error: true);
      return;
    }
    if (_deliveryController.text.trim().isEmpty) {
      _showMessage('Set your delivery address first from Buyer Dashboard.', error: true);
      return;
    }

    context.push('/buyer/payment', extra: {
      'amount': _total,
      'title': 'Order Payment',
      'onSuccess': () {
        if (context.canPop()) context.pop();
        _placeOrder();
      },
    });
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final wasteType = listing['waste_type']?.toString() ?? 'Farm Waste';
    final cropType = listing['crop_type']?.toString() ?? 'Unknown';
    final unit = listing['unit']?.toString() ?? 'kg';
    final description = listing['description']?.toString() ?? '';
    final hasFarmerLocation = _farmerLat != null && _farmerLng != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Waste Details')),
      body: _loadingAddress
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wasteType,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Crop: $cropType'),
                    const SizedBox(height: 6),
                    Text(
                      'Available: $_availableQuantity $unit',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Price: ₹$_price / $unit',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(description),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (hasFarmerLocation) ...[
              const Text(
                'Farmer Pickup Location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 200,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(_farmerLat!, _farmerLng!),
                      initialZoom: 13,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.agriwaste.platform',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(_farmerLat!, _farmerLng!),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            Text(
              'Place Order',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Quantity ($unit)',
                hintText: 'Max $_availableQuantity',
                prefixIcon: const Icon(Icons.scale_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _pickupController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Pickup Address',
                prefixIcon: Icon(Icons.agriculture),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _deliveryController,
              readOnly: true,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Delivery Address',
                prefixIcon: const Icon(Icons.home_outlined),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.edit_location_alt),
                  onPressed: () async {
                    await context.push('/buyer/set-address');
                    await _loadBuyerAddress();
                  },
                ),
              ),
            ),

            if (_buyerAddress == null || _buyerAddress!.isEmpty) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  await context.push('/buyer/set-address');
                  await _loadBuyerAddress();
                },
                icon: const Icon(Icons.add_location_alt),
                label: const Text('Set My Delivery Address'),
              ),
            ],

            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₹${_total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _loading ? null : _startPaymentAndOrder,
                child: _loading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Pay & Place Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}