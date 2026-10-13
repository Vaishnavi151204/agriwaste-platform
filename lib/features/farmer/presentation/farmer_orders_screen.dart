import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FarmerOrdersScreen extends StatefulWidget {
  const FarmerOrdersScreen({super.key});

  @override
  State<FarmerOrdersScreen> createState() =>
      _FarmerOrdersScreenState();
}

class _FarmerOrdersScreenState
    extends State<FarmerOrdersScreen> {
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await Supabase.instance.client
          .from('orders')
          .select()
          .eq('farmer_id', user.id)
          .order(
        'created_at',
        ascending: false,
      );

      if (!mounted) return;

      setState(() {
        _orders =
        List<Map<String, dynamic>>.from(response);
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

  Future<void> _updateStatus(
      String orderId,
      String status,
      ) async {
    try {
      await Supabase.instance.client
          .from('orders')
          .update({
        'status': status,
        'updated_at':
        DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      await _loadOrders();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order ${status.toLowerCase()}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update order.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Orders'),
        actions: [
          IconButton(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 70,
            ),
            SizedBox(height: 16),
            Text(
              'No orders yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Buyer orders will appear here.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          return _FarmerOrderCard(
            order: _orders[index],
            onUpdateStatus: _updateStatus,
          );
        },
      ),
    );
  }
}

class _FarmerOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  final Future<void> Function(
      String,
      String,
      ) onUpdateStatus;

  const _FarmerOrderCard({
    required this.order,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final status =
        order['status']?.toString() ?? 'pending';

    final quantity =
        order['quantity']?.toString() ?? '0';

    final unit =
        order['unit']?.toString() ?? 'kg';

    final total =
        order['total_amount']?.toString() ?? '0';

    final pickup =
        order['pickup_address']?.toString() ?? '-';

    final delivery =
        order['delivery_address']?.toString() ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  size: 30,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'New Buyer Order',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    status.toUpperCase(),
                  ),
                ),
              ],
            ),

            const Divider(height: 28),

            Text('Quantity: $quantity $unit'),

            const SizedBox(height: 8),

            Text(
              'Total: ₹$total',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Pickup: $pickup',
            ),

            const SizedBox(height: 6),

            Text(
              'Delivery: $delivery',
            ),

            if (status == 'pending') ...[
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        onUpdateStatus(
                          order['id'].toString(),
                          'rejected',
                        );
                      },
                      child: const Text(
                        'Reject',
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        onUpdateStatus(
                          order['id'].toString(),
                          'accepted',
                        );
                      },
                      child: const Text(
                        'Accept',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

