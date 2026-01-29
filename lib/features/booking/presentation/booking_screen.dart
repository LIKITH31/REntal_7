import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/order_models.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../kyc/helpers/kyc_enforcement.dart';
import 'payment_screen.dart';
import '../../../core/providers/items_provider.dart'; // For firestoreServiceProvider
import '../../profile/presentation/screens/kyc_screen.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final ProductModel item;
  const BookingScreen({super.key, required this.item});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  DateTimeRange? _selectedDateRange;
  bool _isLoading = false;
  List<DateTimeRange> _bookedRanges = [];

  int get _durationDays => _selectedDateRange?.duration.inDays ?? 0;
  double get _totalPrice => (_durationDays * widget.item.rentalPricePerDay);

  @override
  void initState() {
    super.initState();
    _fetchBookedDates();
  }

  Future<void> _fetchBookedDates() async {
    final firestore = ref.read(firestoreServiceProvider);
    final booked = await firestore.getBookedDates(widget.item.id);
    if (mounted) {
      setState(() {
        _bookedRanges = booked;
      });
    }
  }

  bool _isDateBooked(DateTime day) {
    for (var range in _bookedRanges) {
      // Check if day falls within range (inclusive)
      if (day.isAfter(range.start.subtract(const Duration(days: 1))) && 
          day.isBefore(range.end.add(const Duration(days: 1)))) {
        return true;
      }
    }
    return false;
  }

  Future<void> _selectDates() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      // Visual Blocking of Dates
      selectableDayPredicate: (day, start, end) => !_isDateBooked(day),
    );
    
    if (picked != null) {
      // Double check range validity (in case user selected across a blocked range which picker might allow depending on impl)
      // Standard Flutter DateRangePicker usually prevents internal blocks if properly set, 
      // but let's verify no blocked date is INSIDE the range.
      bool hasOverlap = false;
      for (var range in _bookedRanges) {
         if (picked.start.isBefore(range.end) && picked.end.isAfter(range.start)) {
           hasOverlap = true;
           break;
         }
      }

      if (hasOverlap) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Selected range includes unavailable dates. Please choose another range.')),
           );
        }
        return;
      }

      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedDateRange == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.uid == widget.item.ownerId) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot book your own item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // KYC ENFORCEMENT: Check if user can book items
    final userAsync = ref.read(userModelProvider);
    debugPrint('🔍 Booking: UserAsync state: ${userAsync.runtimeType}');
    debugPrint('🔍 Booking: UserAsync hasValue: ${userAsync.hasValue}');
    debugPrint('🔍 Booking: UserAsync value: ${userAsync.value}');

    final userModelState = userAsync.value;
    if (userModelState != null) {
      UserModel effectiveUser = userModelState;
      final firestoreService = ref.read(firestoreServiceProvider);

      debugPrint('🔍 Booking: User KYC Status (Local): ${effectiveUser.kycStatus}');

      // RELIABILITY FIX: Fetch fresh user data if local state says not approved
      if (!effectiveUser.canBookItems) {
         try {
           final freshUser = await firestoreService.getUserModel(effectiveUser.uid);
           if (freshUser != null) {
             effectiveUser = freshUser;
             debugPrint('✅ Booking: Fetched fresh user data. Status: ${effectiveUser.kycStatus}');
           }
         } catch (e) {
           debugPrint('⚠️ Booking: Failed to fetch fresh user data: $e');
         }
      }

      // KYC ENFORCEMENT & SELF-HEALING
      bool isApproved = effectiveUser.canBookItems;

      // If still not approved, double-check the detailed KYC doc (Self-Healing)
      if (!isApproved) {
        try {
          final kycDoc = await firestoreService.getKycStatus(effectiveUser.uid).first;
          
          if (kycDoc != null && (kycDoc.status == 'approved' || kycDoc.status == 'verified')) {
            debugPrint('✅ Booking: Self-Healing triggered! User was pending, but KYC doc is approved.');
            await firestoreService.syncUserKycStatus(effectiveUser.uid, 'approved');
            isApproved = true; 
          }
        } catch (e) {
           debugPrint('⚠️ Booking: Self-Healing check failed: $e');
        }
      }

      if (!isApproved) {
         final canBook = await KycEnforcement.canUserBookItems(
          context: context,
          user: effectiveUser,
          onStartKyc: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const KycScreen()),
            );
          },
        );

        debugPrint('🔍 Booking: KYC Enforcement result: $canBook');
        if (!canBook) {
          debugPrint('❌ Booking blocked by KYC enforcement');
          return; 
        }
      }
    } else {
      debugPrint('⚠️ WARNING: UserModel is null - KYC enforcement bypassed!');
      // Don't proceed if user model is not available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for profile to load'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not logged in';

      final userId = user.uid;
      final orderId = const Uuid().v4();

      final now = DateTime.now();

      final startDateTime = DateTime(
        _selectedDateRange!.start.year,
        _selectedDateRange!.start.month,
        _selectedDateRange!.start.day,
        now.hour,
        now.minute,
        now.second,
      );

      final endDateTime = DateTime(
        _selectedDateRange!.end.year,
        _selectedDateRange!.end.month,
        _selectedDateRange!.end.day,
        now.hour,
        now.minute,
        now.second,
      );

      // Create main OrderModel
      final order = OrderModel(
        id: orderId,
        orderNumber:
            'ORD-${now.year}-${now.millisecondsSinceEpoch.toString().substring(8)}',
        orderType: 'rental',
        orderStatus: 'pending',
        paymentStatus: 'pending',
        depositAmount: 5000.0, // Fixed deposit amount
        finalAmount: _totalPrice,
        totalAmount: _totalPrice,
        taxAmount: _totalPrice * 0.05, // 5% tax
        userId: userId,
        createdAt: now,
        updatedAt: now,
      );

      // Create OrderItemModel
      final orderItem = OrderItemModel(
        id: const Uuid().v4(),
        productId: widget.item.id,
        productName: widget.item.title,
        quantity: 1,
        unitPrice: widget.item.rentalPricePerDay,
        totalPrice: _totalPrice,
        rentalStartDate: startDateTime,
        rentalEndDate: endDateTime,
        createdAt: now,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              order: order,
              items: [orderItem], // Pass list of items
              sourceProduct: widget.item,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Info
            Text(
              widget.item.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '\₹${widget.item.rentalPricePerDay}/day',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),

            // Date Picker
            InkWell(
              onTap: _selectDates,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDateRange == null
                          ? 'Select Dates'
                          : '${DateFormat("dd MMM").format(_selectedDateRange!.start)} - ${DateFormat("dd MMM").format(_selectedDateRange!.end)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),

            // Summary
            if (_selectedDateRange != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Booking Summary',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Duration: $_durationDays days'),
                  Text('\₹${_totalPrice.toStringAsFixed(2)}'),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\₹${_totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 48),

            // Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedDateRange == null || _isLoading
                    ? null
                    : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF781C2E), // Match Admin Theme
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('CONFIRM BOOKING'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
