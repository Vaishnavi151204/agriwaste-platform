import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.eco_rounded,
                    size: 80,
                    color: colors.primary,
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'AgriWaste',
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Agricultural Waste Marketplace',
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 50),

                  Text(
                    'Who are you?',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 24),

                  _RoleButton(
                    icon: Icons.agriculture,
                    title: 'Farmer',
                    subtitle: 'Sell agricultural waste',
                    onPressed: () {
                      context.go('/signup');
                    },
                  ),

                  const SizedBox(height: 16),

                  _RoleButton(
                    icon: Icons.business,
                    title: 'Buyer',
                    subtitle: 'Buy agricultural waste',
                    onPressed: () {
                      context.go('/signup');
                    },
                  ),

                  const SizedBox(height: 16),

                  _RoleButton(
                    icon: Icons.local_shipping,
                    title: 'Transporter',
                    subtitle: 'Manage waste pickups',
                    onPressed: () {
                      context.go('/signup');
                    },
                  ),

                  const SizedBox(height: 30),

                  TextButton(
                    onPressed: () {
                      context.go('/login');
                    },
                    child: const Text(
                      'Already have an account? Login',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  const _RoleButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 40,
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios),
              ],
            ),
          ),
        ),
      ),
    );
  }
}