
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';

import '../features/farmer/presentation/farmer_dashboard.dart';
import '../features/farmer/presentation/report_waste_screen.dart';
import '../features/farmer/presentation/my_listings_screen.dart';
import '../features/farmer/presentation/pickup_requests_screen.dart';

import '../features/buyer/presentation/buyer_dashboard.dart';
import '../features/buyer/presentation/browse_waste_screen.dart';
import '../features/buyer/presentation/waste_details_screen.dart';
import '../features/buyer/presentation/place_order_screen.dart';
import '../features/buyer/presentation/my_orders_screen.dart';
import '../features/buyer/presentation/ai_smart_order_screen.dart';
import '../features/buyer/presentation/mock_payment_screen.dart';

import '../features/transporter/presentation/transporter_dashboard.dart';
import '../features/transporter/presentation/available_jobs_screen.dart';
import '../features/transporter/presentation/my_jobs_screen.dart';
import '../features/buyer/presentation/set_address_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      // AUTH
      GoRoute(
        path: '/',
        redirect: (context, state) => '/login',
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/buyer/set-address',
        builder: (context, state) => const SetAddressScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // FARMER
      GoRoute(
        path: '/farmer',
        builder: (context, state) => const FarmerDashboard(),
      ),
      GoRoute(
        path: '/farmer/report-waste',
        builder: (context, state) => const ReportWasteScreen(),
      ),
      GoRoute(
        path: '/farmer/my-listings',
        builder: (context, state) => const MyListingsScreen(),
      ),
      GoRoute(
        path: '/farmer/pickups',
        builder: (context, state) => const PickupRequestsScreen(),
      ),

      // BUYER
      GoRoute(
        path: '/buyer',
        builder: (context, state) => const BuyerDashboard(),
      ),
      GoRoute(
        path: '/buyer/browse-waste',
        builder: (context, state) => const BrowseWasteScreen(),
      ),
      GoRoute(
        path: '/buyer/waste-details',
        builder: (context, state) {
          final listing = state.extra as Map<String, dynamic>;
          return WasteDetailsScreen(listing: listing);
        },
      ),
      GoRoute(
        path: '/buyer/place-order',
        builder: (context, state) {
          final listing = state.extra as Map<String, dynamic>;
          return PlaceOrderScreen(listing: listing);
        },
      ),
      GoRoute(
        path: '/buyer/orders',
        builder: (context, state) => const MyOrdersScreen(),
      ),
      GoRoute(
        path: '/buyer/ai-smart-order',
        builder: (context, state) => const AiSmartOrderScreen(),
      ),

      // MOCK PAYMENT
      GoRoute(
        path: '/buyer/payment',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;

          return MockPaymentScreen(
            amount: (extra['amount'] as num).toDouble(),
            title: extra['title']?.toString() ?? 'Payment',
            onSuccess: extra['onSuccess'] as VoidCallback,
          );
        },
      ),

      // TRANSPORTER
      GoRoute(
        path: '/transporter',
        builder: (context, state) => const TransporterDashboard(),
      ),
      GoRoute(
        path: '/transporter/available-jobs',
        builder: (context, state) => const AvailableJobsScreen(),
      ),
      GoRoute(
        path: '/transporter/my-jobs',
        builder: (context, state) => const MyJobsScreen(),
      ),
    ],
  );
});