import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  final _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _jobs = [];

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      final data = await _supabase
          .from('pickup_jobs')
          .select()
          .eq('transporter_id', user.id)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _jobs = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(String jobId, String newStatus) async {
    try {
      final response = await _supabase
          .from('pickup_jobs')
          .update({'status': newStatus})
          .eq('id', jobId)
          .select();

      debugPrint('STATUS UPDATE RESULT: $response');

      if (!mounted) return;

      if (response.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Update failed. Check RLS permissions.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus')),
      );

      await _loadJobs();
    } catch (e) {
      debugPrint('STATUS UPDATE ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _normalizeStatus(dynamic status) {
    return (status?.toString() ?? 'pending').toLowerCase().trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadJobs,
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
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadJobs,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_jobs.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadJobs,
        child: ListView(
          children: const [
            SizedBox(height: 160),
            Icon(Icons.assignment_outlined, size: 70),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No jobs assigned yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _jobs.length,
        itemBuilder: (context, index) {
          final job = _jobs[index];
          final status = _normalizeStatus(job['status']);
          final pickup = job['pickup_address']?.toString() ?? '-';
          final delivery = job['delivery_address']?.toString() ?? '-';
          final schedule = job['schedule_date']?.toString() ?? 'Not set';
          final jobId = job['id']?.toString() ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        child: Icon(Icons.local_shipping),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Job ${jobId.length > 8 ? jobId.substring(0, 8) : jobId}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _StatusChip(status: status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Pickup: $pickup'),
                  const SizedBox(height: 4),
                  Text('Delivery: $delivery'),
                  const SizedBox(height: 4),
                  Text('Schedule: $schedule'),
                  const SizedBox(height: 14),

                  // ACTION BUTTONS
                  if (status == 'accepted' || status == 'pending')
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _updateStatus(jobId, 'picked_up'),
                        icon: const Icon(Icons.inventory_2_outlined),
                        label: const Text('Mark as Picked Up'),
                      ),
                    )
                  else if (status == 'picked_up')
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _updateStatus(jobId, 'in_transit'),
                        icon: const Icon(Icons.local_shipping_outlined),
                        label: const Text('Mark as In Transit'),
                      ),
                    )
                  else if (status == 'in_transit')
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _updateStatus(jobId, 'delivered'),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Mark as Delivered'),
                        ),
                      )
                    else if (status == 'delivered')
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                'Delivered',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Text('Current status: $status'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case 'accepted':
      case 'pending':
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade800;
        text = status.toUpperCase();
        break;
      case 'picked_up':
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade800;
        text = 'PICKED UP';
        break;
      case 'in_transit':
        bg = Colors.indigo.shade100;
        fg = Colors.indigo.shade800;
        text = 'IN TRANSIT';
        break;
      case 'delivered':
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        text = 'DELIVERED';
        break;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
        text = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}