import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TransporterDashboard extends StatelessWidget {
  const TransporterDashboard({super.key});

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transporter Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.local_shipping, size: 80),
            const SizedBox(height: 16),
            Text(
              'Welcome, Transporter',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),

            // Available Jobs
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.work_outline),
                ),
                title: const Text(
                  'Available Jobs',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('See pickup requests waiting for transporter'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => context.push('/transporter/available-jobs'),
              ),
            ),
            const SizedBox(height: 16),

            // My Jobs
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.assignment_turned_in_outlined),
                ),
                title: const Text(
                  'My Jobs',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Jobs you have accepted'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => context.push('/transporter/my-jobs'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}