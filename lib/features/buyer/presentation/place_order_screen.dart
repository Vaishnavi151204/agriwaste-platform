import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlaceOrderScreen extends StatefulWidget {
  final Map<String, dynamic> listing;

  const PlaceOrderScreen({super.key, required this.listing});

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  final _quantityController = TextEditingController();
  bool _loading = false;

  late double _availableQuantity;
  late double _pricePerUnit;
  late String _unit;
  late String _listingId;

  @override
  void initState() {
    super.initState();
    _listingId = widget.listing['id'].toString();

    _availableQuantity = double.tryParse(
        widget.listing['available_quantity']?.toString() ?? '') ??
        double.tryParse(widget.listing['quantity']?.toString() ?? '0') ??
        0;

    _pricePerUnit = double.tryParse(
        widget.listing['price_per_unit']?.toString() ?? '0') ??
        0;

    _unit = widget.listing['unit']?.toString() ?? 'kg';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  double get _enteredQuantity =>
      double.tryParse(_quantityController.text.trim()) ?? 0;

  double get _totalAmount => _enteredQuantity * _pricePerUnit;

  Future<void> _placeOrder() async {
    final quantity = _enteredQuantity;

    if (quantity <= 0) {
      _show('Enter valid quantity', error: true);
      return;
    }
    if (quantity > _availableQuantity) {
      _show('Only ${_fmt(_availableQuantity)} $_unit left', error: true);
      return;
    }

    setState(() => _loading = true);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      _show('Login again', error: true);
      setState(() => _loading = false);
      return;
    }

    try {
      final newAvailable = _availableQuantity - quantity;

      // 1. Create the order
      await supabase.from('orders').insert({
        'buyer_id': user.id,
        'listing_id': _listingId,
        'quantity': quantity,
        'total_amount': _totalAmount,
        'status': 'pending',
      });

      // 2. FORCE reduce available quantity (this is the key)
      await supabase.from('waste_listings').update({
        'available_quantity': newAvailable,
        'status': newAvailable <= 0 ? 'sold' : 'available',
      }).eq('id', _listingId);

      if (!mounted) return;

      _show('Order placed successfully!');

      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;

      // Go to orders and force refresh
      context.go('/buyer/orders');
    } catch (e) {
      debugPrint('ORDER ERROR: $e');
      if (!mounted) return;
      _show('Error: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  void _show(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wasteType = widget.listing['waste_type']?.toString() ?? 'Waste';
    final cropType = widget.listing['crop_type']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Place Order')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const CircleAvatar(
                          radius: 28, child: Icon(Icons.eco, size: 28)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(wasteType,
                                style: const TextStyle(
                                    fontSize: 19, fontWeight: FontWeight.bold)),
                            if (cropType.isNotEmpty) Text('Crop: $cropType'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text('Available Now',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('${_fmt(_availableQuantity)} $_unit',
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              const Text('Price', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('₹${_fmt(_pricePerUnit)} / $_unit',
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 22),
              TextFormField(
                controller: _quantityController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'How much do you want?',
                  hintText: 'Maximum ${_fmt(_availableQuantity)}',
                  suffixText: _unit,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.scale),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                      Text('₹${_fmt(_totalAmount)}',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _placeOrder,
                  icon: _loading
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline),
                  label:
                  Text(_loading ? 'Placing Order...' : 'Confirm Order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}