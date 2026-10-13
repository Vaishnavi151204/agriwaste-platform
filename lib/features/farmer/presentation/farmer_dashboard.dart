import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FarmerDashboard extends StatelessWidget {
  const FarmerDashboard({super.key});

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();

    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // -------------------------
              // WELCOME
              // -------------------------
              Text(
                'Welcome, Farmer!',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                user?.email ?? 'Farmer',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium,
              ),

              const SizedBox(height: 24),

              // -------------------------
              // REPORT WASTE
              // -------------------------
              SizedBox(
                width: double.infinity,
                height: 145,
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      context.go('/farmer/report-waste');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [

                          CircleAvatar(
                            radius: 32,
                            backgroundColor:
                            Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            child: Icon(
                              Icons.agriculture_rounded,
                              size: 34,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary,
                            ),
                          ),

                          const SizedBox(width: 18),

                          Expanded(
                            child: Column(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [

                                Text(
                                  'Report Farm Waste',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                const Text(
                                  'List agricultural waste for buyers.',
                                ),
                              ],
                            ),
                          ),

                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // -------------------------
              // QUICK ACTIONS
              // -------------------------
              Text(
                'Quick Actions',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [

                  // MY LISTINGS
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.inventory_2_outlined,
                      title: 'My Listings',
                      onTap: () {
                        context.go('/farmer/my-listings');
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  // PICKUP REQUESTS
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.local_shipping_outlined,
                      title: 'Pickup Requests',
                      onTap: () {
                        context.go('/farmer/pickups');
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // -------------------------
              // HOW IT WORKS
              // -------------------------
              Text(
                'How AgriWaste Works',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _InfoCard(
                icon: Icons.recycling_rounded,
                title: 'Report Waste',
                text:
                'Add your available agricultural waste.',
              ),

              _InfoCard(
                icon: Icons.storefront_rounded,
                title: 'Connect With Buyers',
                text:
                'Buyers can discover your available waste.',
              ),

              _InfoCard(
                icon: Icons.local_shipping_rounded,
                title: 'Arrange Pickup',
                text:
                'Waste can be collected through transport.',
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// ACTION CARD
// =====================================================

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 20,
          ),
          child: Column(
            children: [

              Icon(
                icon,
                size: 32,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),

              const SizedBox(height: 10),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// INFORMATION CARD
// =====================================================

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context)
              .colorScheme
              .primary,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(text),
      ),
    );
  }
}