import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/items_provider.dart';

import '../../../../core/services/location_service.dart';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import '../../../../core/providers/storage_provider.dart';

// KYC imports
// KYC imports
import '../../../kyc/helpers/kyc_enforcement.dart';
import '../../../profile/presentation/screens/kyc_screen.dart';

// ... other imports

class AddListingScreen extends ConsumerStatefulWidget {
  const AddListingScreen({super.key});

  @override
  ConsumerState<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends ConsumerState<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  // ... controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _depositController = TextEditingController();
  final _originalPriceController = TextEditingController(); // NEW
  final _dimensionsController = TextEditingController(); // NEW
  final _salePriceController = TextEditingController(); // NEW: Distinct Sale Price

  String _selectedCategory = 'Electronics';
  String _selectedPeriod = 'Day';
  bool _isForSale = false;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    _originalPriceController.dispose(); // NEW
    _dimensionsController.dispose(); // NEW
    _salePriceController.dispose();
    super.dispose();
    super.dispose();
  }

  Future<void> _submitListing() async {
    // Check if user is logged in
    final currentUser = ref.read(currentUserProvider);

    if (currentUser == null) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text('You must be logged in to add a listing.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to auth screen
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
      return;
    }

    // KYC ENFORCEMENT: Check if user can list items
    final userAsync = ref.read(userModelProvider);
    debugPrint(
      '🔍 AddListing: UserAsync state: ${userAsync.when(data: (user) => user != null ? 'User loaded' : 'User is null', loading: () => 'Loading...', error: (e, _) => 'Error: $e')}',
    );

    return userAsync.when(
      data: (userModel) async {
        if (userModel != null) {
          debugPrint('🔍 AddListing: User KYC Status: ${userModel.kycStatus}');
          debugPrint(
            '🔍 AddListing: Can List Items: ${userModel.canListItems}',
          );

          // RELIABILITY FIX: Fetch fresh user data if local state says not approved
          // This prevents "Under Review" dialog if the user was just approved but stream is slightly behind
          UserModel effectiveUser = userModel;
          final firestoreService = ref.read(firestoreServiceProvider);

          if (!effectiveUser.canListItems) {
            try {
              final freshUser = await firestoreService.getUserModel(userModel.uid);
              if (freshUser != null) {
                 effectiveUser = freshUser;
                 debugPrint('✅ AddListing: Fetched fresh user data. Status: ${effectiveUser.kycStatus}');
              }
            } catch (e) {
              debugPrint('⚠️ AddListing: Failed to fetch fresh user data: $e');
            }
          }

          // KYC ENFORCEMENT & SELF-HEALING
          bool isApproved = effectiveUser.canListItems;

          // If still not approved, double-check the detailed KYC doc (Self-Healing)
          if (!isApproved) {
            try {
              final kycDoc = await firestoreService.getKycStatus(effectiveUser.uid).first;
              
              if (kycDoc != null && (kycDoc.status == 'approved' || kycDoc.status == 'verified')) {
                debugPrint('✅ AddListing: Self-Healing triggered! User was pending, but KYC doc is approved.');
                await firestoreService.syncUserKycStatus(effectiveUser.uid, 'approved');
                // Create a temporary trusted user/approved state
                isApproved = true; 
                // We don't overwrite effectiveUser here to avoid immutability complexity, but we set the flag
              }
            } catch (e) {
               debugPrint('⚠️ AddListing: Self-Healing check failed: $e');
            }
          }

          if (!isApproved) {
             final canList = await KycEnforcement.canUserListItems(
              context: context,
              user: effectiveUser,
              onStartKyc: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const KycScreen()),
                );
              },
            );
            if (!canList) return;
          }

          // Proceed with the effective user
          _proceedWithListing(effectiveUser);
        } else {
          debugPrint(
            '⚠️ WARNING: UserModel is null - user profile not created',
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please complete your profile setup first'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      loading: () {
        debugPrint('🔄 AddListing: User profile is loading...');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading your profile...'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      error: (error, stackTrace) {
        debugPrint('❌ AddListing: Error loading user profile: $error');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $error'),
            duration: const Duration(seconds: 3),
          ),
        );
      },
    );
  }

  void _proceedWithListing(UserModel userModel) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    // Check Subscription Limit
    if (!userModel.hasUnlimitedListings && userModel.itemsListed >= 5) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Limit Reached'),
          content: const Text(
            'You have reached the free limit of 5 listings. Upgrade to Lender Pro or Pro Max for unlimited listings!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF781C2E),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please go to Home > Subscribe to upgrade.'),
                  ),
                );
              },
              child: const Text('Upgrade Now'),
            ),
          ],
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Get current location
      final position = await LocationService.getCurrentLocation();
      if (position == null) {
        throw 'Location permission required to add listing';
      }

      // Calculate prices based on period
      final basePrice = double.parse(_priceController.text);
      double? pricePerDay;
      double? pricePerWeek;
      double? pricePerMonth;
      double? salePrice;

      if (_isForSale && _salePriceController.text.isNotEmpty) {
        salePrice = double.parse(_salePriceController.text);
      }

      // Rental Prices (Always calculated from base price if entered)
      if (_priceController.text.isNotEmpty) {
          switch (_selectedPeriod) {
            case 'Day':
              pricePerDay = basePrice;
              pricePerWeek = basePrice * 6; // Discount for week
              pricePerMonth = basePrice * 25; // Discount for month
              break;
            case 'Week':
              pricePerWeek = basePrice;
              pricePerDay = basePrice / 6;
              pricePerMonth = basePrice * 4;
              break;
            case 'Month':
              pricePerMonth = basePrice;
              pricePerWeek = basePrice / 4;
              pricePerDay = basePrice / 25;
              break;
          }
      }

      // Upload Images
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        final storageService = ref.read(storageServiceProvider);
        imageUrls = await storageService.uploadImages(
          _selectedImages,
          'listing_images',
        );
      }

      // Create product model
      final product = ProductModel(
        id: '', // Will be set by Firestore
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategory.toLowerCase(), // Simple ID generation
        categoryName: _selectedCategory,
        rentalPricePerDay: pricePerDay ?? 0,
        rentalPricePerWeek: pricePerWeek,
        rentalPricePerMonth: pricePerMonth,
        salePrice: salePrice,
        securityDeposit: _depositController.text.isNotEmpty
            ? double.parse(_depositController.text)
            : null,
        images: imageUrls,
        ownerId: currentUser.uid,
        ownerName: currentUser.displayName ?? 'User',
        location: ProductLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          address: 'Current Location', // TODO: Reverse geocode
          city: 'City',
          state: 'State',
          country: 'Country',
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'approved', // Auto-approve for MVP
        originalPrice: _originalPriceController.text.isNotEmpty
            ? double.tryParse(_originalPriceController.text)
            : null,
        dimensions: _dimensionsController.text.isNotEmpty
            ? _dimensionsController.text.trim()
            : null,
        isActive: true, // Default to true
        riskScore: 0, // Initial risk score
        isFlagged: false,
        transactionMode: (_isForSale && salePrice != null && (pricePerDay == null)) ? 'sell' : 'rent', // Heuristic: if sale only, sell. Else rent (default).
      );

      // Save to Firestore
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.addProduct(product);
      // await firestoreService.incrementItemsListed(currentUser.uid); // Method removed from service

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Listing created successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Clear form
      _titleController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _salePriceController.clear();
      _depositController.clear();
      _originalPriceController.clear();
      _dimensionsController.clear();
      setState(() {
        _selectedCategory = 'Electronics';
        _selectedPeriod = 'Day';
        _isForSale = false;
        _selectedImages.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            floating: true,
            title: const Text('Add Listing'),
            actions: [
              if (currentUser == null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    avatar: const Icon(Icons.lock, size: 16),
                    label: const Text('Login Required'),
                    backgroundColor: Colors.orange.shade100,
                  ),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Upload Section
                    if (_selectedImages.isEmpty)
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                            width: 2,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              Theme.of(
                                context,
                              ).colorScheme.secondary.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: InkWell(
                          onTap: _pickImages,
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 64,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Add Photos',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to upload images',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9))
                    else
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _selectedImages.length) {
                              return GestureDetector(
                                onTap: _pickImages,
                                child: Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.add_a_photo,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            }
                            // Show Thumbnail (using kIsWeb logic internally by Image.network/file usually,
                            // but XFile needs checking)
                            return Stack(
                              children: [
                                Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        _selectedImages[index].path,
                                      ), // Works for web blobs
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 16,
                                  top: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedImages.removeAt(index);
                                      });
                                    },
                                    child: const CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.black54,
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'Item Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g., Canon DSLR Camera',
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items:
                          [
                                'Electronics',
                                'Vehicles',
                                'Sports',
                                'Tools',
                                'Furniture',
                                'Clothing',
                              ]
                              .map(
                                (category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe your item...',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2),
                    const SizedBox(height: 16),

                    // Dimensions
                    TextFormField(
                      controller: _dimensionsController,
                      decoration: InputDecoration(
                        labelText: 'Dimensions / Specs',
                        hintText: 'e.g., 15x10x5 inches, 2kg',
                        prefixIcon: const Icon(Icons.straighten),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ).animate().fadeIn(delay: 450.ms).slideX(begin: -0.2),

                    const SizedBox(height: 24),

                    // Pricing Section
                    Text(
                      'Pricing',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2),
                    const SizedBox(height: 16),

                    // For Sale Toggle
                    SwitchListTile(
                      title: const Text('Available for Sale'),
                      subtitle: const Text(
                        'Enable if you want to sell this item',
                      ),
                      value: _isForSale,
                      onChanged: (value) {
                        setState(() {
                          _isForSale = value;
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2),
                    const SizedBox(height: 16),

                    // Original Price (Reference)
                    TextFormField(
                      controller: _originalPriceController,
                      decoration: InputDecoration(
                        labelText: 'Original Purchase Price (MRP)',
                        hintText: 'For reference only',
                        prefixIcon: const Icon(Icons.price_check),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ).animate().fadeIn(delay: 650.ms).slideX(begin: -0.2),
                    const SizedBox(height: 16),

                    // Rental Price
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _priceController,
                            decoration: InputDecoration(
                              labelText: 'Rental Price',
                              prefixIcon: const Icon(Icons.currency_rupee),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedPeriod,
                              decoration: InputDecoration(
                                labelText: 'Per',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: ['Day', 'Week', 'Month']
                                  .map(
                                    (period) => DropdownMenuItem(
                                      value: period,
                                      child: Text(period),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPeriod = value!;
                                });
                              },
                            ),
                          ),
                      ],
                    ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.2),
                    const SizedBox(height: 16),

                    // Security Deposit (Always visible for hybrid capability)
                    TextFormField(
                      controller: _depositController,
                      decoration: InputDecoration(
                        labelText: 'Security Deposit',
                        hintText: 'Optional',
                        prefixIcon: const Icon(Icons.security),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.2),
                    const SizedBox(height: 16),

                    // Sale Price Field (Conditional - below Security Deposit)
                    if (_isForSale) ...[
                      TextFormField(
                        controller: _salePriceController,
                        decoration: InputDecoration(
                          labelText: 'Sale Price',
                          prefixIcon: const Icon(Icons.monetization_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (_isForSale && (value == null || value.isEmpty)) {
                            return 'Please enter sale price';
                          }
                          return null;
                        },
                      ).animate().fadeIn(delay: 750.ms).slideX(begin: -0.2),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _submitListing,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check),
                            label: Text(
                              _isSubmitting ? 'Creating...' : 'Create Listing',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 900.ms)
                        .scale(begin: const Offset(0.9, 0.9)),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
