import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/models/user_model.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import 'my_listings_screen.dart';
import '../../../rentals/presentation/screens/rentals_screen.dart';
import 'favorites_screen.dart';
import 'payment_methods_screen.dart';
import 'notifications_screen.dart';
import 'help_support_screen.dart';
import 'kyc_screen.dart';
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userModelProvider);

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (currentUser) {
        // FIX: Primary check should be against FirebaseAuth User, not Firestore Model
        // If Auth User exists but Firestore Model is null, we should still show Profile (with fallback)
        final authUser = ref.watch(currentUserProvider);

        if (authUser == null) {
          return _buildGuestView(context);
        }
        
        // If Model is null but Auth is present, create a fallback model
        final displayUser = currentUser ?? UserModel(
          uid: authUser.uid, 
          email: authUser.email ?? '', 
          displayName: authUser.displayName ?? 'User',
          createdAt: DateTime.now(),
        );

        return _buildProfileView(context, ref, displayUser);
      },
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline,
                size: 100,
                color: Colors.grey.shade400,
              ).animate().fadeIn().scale(),
              const SizedBox(height: 24),
              Text(
                'Sign in to view your profile',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
              Text(
                'Create listings, manage rentals, and more',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('Sign In'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms).scale(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileView(BuildContext context, WidgetRef ref, dynamic currentUser) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            floating: true,
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {},
              ).animate().fadeIn().scale(),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Profile Picture
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(delay: 200.ms)
                    .shimmer(delay: 800.ms, duration: 1500.ms),
                const SizedBox(height: 16),
                Text(
                  currentUser.displayName ?? 'User',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 8),
                Text(
                  currentUser.email ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 8),

                if (currentUser.role == 'admin') ...[
                   Padding(
                     padding: const EdgeInsets.only(bottom: 20.0),
                     child: SizedBox(
                       width: double.infinity,
                       child: ElevatedButton.icon(
                         onPressed: () {
                           Navigator.push(
                             context,
                             MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                           );
                         },
                         icon: const Icon(Icons.admin_panel_settings),
                         label: const Text('Admin Dashboard'),
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.blueGrey.shade900,
                           foregroundColor: Colors.white,
                           padding: const EdgeInsets.symmetric(vertical: 16),
                         ),
                       ),
                     ),
                   ),
                ],

                if (currentUser.kycStatus == 'verified')
                  Chip(
                    avatar: const Icon(Icons.verified, size: 16, color: Colors.white),
                    label: const Text('Verified', style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.green,
                  ).animate().fadeIn(delay: 500.ms).scale()
                else 
                   Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const KycScreen()),
                        );
                      },
                      icon: const Icon(Icons.verified_user, color: Colors.white),
                      label: Text(
                        currentUser.kycStatus == 'pending' ? 'KYC Verification Pending' : 'Verify Identity Now',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF781C2E), // Explicit Burgundy to match theme
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        elevation: 4,
                      ),
                    ),
                  ),

                const SizedBox(height: 32),
                // Stats Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Items Listed',
                          '12',
                          Icons.inventory,
                          Colors.blue,
                          0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Rentals',
                          '24',
                          Icons.receipt_long,
                          Colors.purple,
                          100,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Rating',
                          '4.8',
                          Icons.star,
                          Colors.orange,
                          200,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Menu Items
                _buildMenuItem(
                  context,
                  'My Listings',
                  Icons.inventory_2_outlined,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyListingsScreen()),
                    );
                  },
                  300,
                ),
                _buildMenuItem(
                  context,
                  'My Rentals',
                  Icons.receipt_long_outlined,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RentalsScreen()),
                    );
                  },
                  350,
                ),
                _buildMenuItem(
                  context,
                  'Favorites',
                  Icons.favorite_outline,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                    );
                  },
                  400,
                ),
                _buildMenuItem(
                  context,
                  'Payment Methods',
                  Icons.payment,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()),
                    );
                  },
                  450,
                ),
                _buildMenuItem(
                  context,
                  'Notifications',
                  Icons.notifications_outlined,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                    );
                  },
                  500,
                ),
                _buildMenuItem(
                  context,
                  'Help & Support',
                  Icons.help_outline,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                    );
                  },
                  550,
                ),
                _buildMenuItem(
                  context,
                  'About',
                  Icons.info_outline,
                  () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Rental App',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(Icons.share_location, size: 50),
                      children: [
                        const Text('A platform to rent and lend items easily.'),
                        const SizedBox(height: 10),
                        const Text('Developed with Flutter & Firebase.'),
                      ],
                    );
                  },
                  600,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Sign Out'),
                            content: const Text('Are you sure you want to sign out?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Sign Out'),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirmed == true) {
                          await ref.read(authServiceProvider).signOut();
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 700.ms).scale(),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    int delay,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.7),
            color,
          ],
        ),
        boxShadow: [
            BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
    int delay,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ).animate().fadeIn(delay: delay.ms).slideX(begin: -0.2),
    );
  }
}
