import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import '../api/map_location_picker.dart';
import 'location_autocomplete_field.dart';
import '../api/maptiler_autocomplete.dart';
import 'validation_widgets.dart';
import '../utils/user_utils.dart';
import '../utils/cache_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/efficient_payment_service.dart';

class ListServiceForm extends StatefulWidget {
  const ListServiceForm({Key? key}) : super(key: key);

  @override
  State<ListServiceForm> createState() => _ListServiceFormState();
}

class _ListServiceFormState extends State<ListServiceForm>
    with TickerProviderStateMixin {
  late AnimationController _progressAnimationController;
  late AnimationController _slideAnimationController;

  late Animation<double> _progressAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isNavigating = false;
  DateTime _lastNavigationTime = DateTime.now();

  int _currentStep = 0;
  final int _totalSteps = 6;

  // Form controllers and data
  final _formKey = GlobalKey<FormState>();

  String _selectedPlan = '1Day';
  Map<String, Map<String, double>> _planPrices = {};
  bool _isPlanPricesLoading = true;
  String? _planPricesError;

  // Basic Service Details
  String _serviceType = 'Library';
  final _serviceNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Timings
  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;
  String _offDay = 'None';

  // Library-specific fields
  String _libraryType = 'Public';
  final _seatingCapacityController = TextEditingController();
  String _acStatus = 'AC';
  final _chargesController = TextEditingController();
  String _chargeType = 'Per Hour';
  bool _hasInternet = true;
  bool _hasStudyCabin = true;

  // Café-specific fields
  String _cuisineType = 'Multi-cuisine';
  bool _hasSeating = true;
  final _priceRangeController = TextEditingController();
  bool _hasWifi = true;
  bool _hasPowerSockets = true;

  // Mess-specific fields
  String _foodType =
      'Veg and Non-Veg'; // Changed from 'Both' to match the options
  final _monthlyPriceController = TextEditingController();
  Map<String, bool> _mealTimings = {
    'Breakfast': false,
    'Lunch': true,
    'Dinner': false,
  };
  bool _hasHomeDelivery = false;
  bool _hasTiffinService = false;
  // Other service fields
  final _pricingController = TextEditingController();
  final _serviceTypeOtherController = TextEditingController();
  final _usefulnessController = TextEditingController();

  // Photo fields
  String? _coverPhotoUrl;
  List<String> _additionalPhotoUrls = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> _serviceTypes = ['Library', 'Café', 'Mess', 'Other'];
  final List<String> _offDays = [
    'None',
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  late ThemeData theme;
  late Color scaffoldBg;
  late Color cardColor;
  late Color textPrimary;
  late Color textSecondary;

  LatLng? _pickedLocation;

  @override
  void initState() {
    super.initState();
    _fetchPlanPrices();

    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _progressAnimationController.forward();
    _slideAnimationController.forward();
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _slideAnimationController.dispose();
    _serviceNameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _seatingCapacityController.dispose();
    _chargesController.dispose();
    _priceRangeController.dispose();
    _monthlyPriceController.dispose();
    _pricingController.dispose();
    _serviceTypeOtherController.dispose();
    _usefulnessController.dispose();
    super.dispose();
  }

  Future<void> _fetchPlanPrices() async {
    setState(() {
      _isPlanPricesLoading = true;
      _planPricesError = null;
    });
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('plan_prices')
              .doc('list_service')
              .collection('day_wise_prices')
              .get();
      Map<String, Map<String, double>> prices = {};
      for (var d in doc.docs) {
        final data = d.data();
        double? actual =
            (data['actual_price'] is int)
                ? (data['actual_price'] as int).toDouble()
                : (data['actual_price'] as num?)?.toDouble();
        double? discounted =
            (data['discounted_price'] is int)
                ? (data['discounted_price'] as int).toDouble()
                : (data['discounted_price'] as num?)?.toDouble();
        prices[d.id] = {'actual': actual ?? 0, 'discounted': discounted ?? 0};
      }
      // Map Firestore keys to your plan keys
      Map<String, String> firestoreToPlanKey = {
        '1 day': '1Day',
        '7 days': '7Day',
        '15 days': '15Day',
        '1 month': '1Month',
      };
      Map<String, Map<String, double>> mappedPrices = {};
      firestoreToPlanKey.forEach((firestoreKey, planKey) {
        if (prices.containsKey(firestoreKey)) {
          mappedPrices[planKey] = prices[firestoreKey]!;
        }
      });
      setState(() {
        _planPrices = mappedPrices;
        _isPlanPricesLoading = false;
        if (_planPrices.isNotEmpty && !_planPrices.containsKey(_selectedPlan)) {
          _selectedPlan = _planPrices.keys.first;
        }
      });
    } catch (e) {
      setState(() {
        _planPricesError = 'Failed to load plan prices';
        _isPlanPricesLoading = false;
      });
    }
  }

  void _nextStep() {
    // Validate current step before proceeding
    bool isValid = true;
    
    switch (_currentStep) {
      case 0: // Service Type Step
        // No validation needed for service type selection
        break;
      case 1: // Basic Details Step
        if (_serviceNameController.text.trim().isEmpty) {
          ValidationSnackBar.showError(context, 'Please enter service name');
          isValid = false;
        } else if (_locationController.text.trim().isEmpty) {
          ValidationSnackBar.showError(context, 'Please enter location');
          isValid = false;
        }
        break;
      case 2: // Timings Step (removed contact validation)
        // No validation needed since contact is auto-filled
        break;
      case 3: // Specific Details Step
        if (_serviceType == 'Library') {
          if (_seatingCapacityController.text.trim().isEmpty) {
            ValidationSnackBar.showError(context, 'Please enter seating capacity');
            isValid = false;
          } else if (_chargesController.text.trim().isEmpty) {
            ValidationSnackBar.showError(context, 'Please enter monthly charge');
            isValid = false;
          }
        } else if (_serviceType == 'Café') {
          if (_priceRangeController.text.trim().isEmpty) {
            ValidationSnackBar.showError(context, 'Please enter price range');
            isValid = false;
          }
        } else if (_serviceType == 'Mess') {
          if (_seatingCapacityController.text.trim().isEmpty) {
            ValidationSnackBar.showError(context, 'Please enter seating capacity');
            isValid = false;
          } else if (_monthlyPriceController.text.trim().isEmpty) {
            ValidationSnackBar.showError(context, 'Please enter monthly price');
            isValid = false;
          }
        }
        break;
      case 4: // Photos Step - At least one photo is required
        // Check if at least one photo is uploaded (cover photo or additional photos)
        bool hasAnyPhoto = (_coverPhotoUrl != null && _coverPhotoUrl!.isNotEmpty) || 
                          _additionalPhotoUrls.isNotEmpty;
        if (!hasAnyPhoto) {
          ValidationSnackBar.showError(context, 'Please upload at least one photo');
          isValid = false;
        }
        break;
    }
    
    if (!isValid) return;

    if (_isNavigating || _currentStep >= _totalSteps - 1) return;

    final now = DateTime.now();
    if (now.difference(_lastNavigationTime).inMilliseconds < 300) return;

    _isNavigating = true;
    _lastNavigationTime = now;

    setState(() {
      _currentStep++;
    });

    _isNavigating = false;
    _updateProgress();
    _triggerSlideAnimation();
  }

  void _previousStep() {
    if (_isNavigating || _currentStep <= 0) return;

    final now = DateTime.now();
    if (now.difference(_lastNavigationTime).inMilliseconds < 300) return;

    _isNavigating = true;
    _lastNavigationTime = now;

    setState(() {
      _currentStep--;
    });

    _isNavigating = false;
    _updateProgress();
    _triggerSlideAnimation();
  }

  void _updateProgress() {
    _progressAnimationController.reset();
    _progressAnimationController.forward();
  }

  void _triggerSlideAnimation() {
    _slideAnimationController.reset();
    _slideAnimationController.forward();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ValidationSnackBar.showError(context, 'Please fill all required fields');
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            const Text('Creating listing and processing payment...'),
          ],
        ),
      ),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Navigator.of(context).pop(); // Close loading dialog
        ValidationSnackBar.showError(context, 'User not authenticated');
        return;
      }

      final userId = user.uid;

      // Get the plan price
      final planPrice = _planPrices[_selectedPlan]?['actual'] ?? 0.0;
      if (planPrice <= 0) {
        Navigator.of(context).pop(); // Close loading dialog
        ValidationSnackBar.showError(context, 'Invalid plan price');
        return;
      }

      // Plan expiry logic
      Duration planDuration;
      switch (_selectedPlan) {
        case '1Day':
          planDuration = const Duration(days: 1);
          break;
        case '7Day':
          planDuration = const Duration(days: 7);
          break;
        case '15Day':
          planDuration = const Duration(days: 15);
          break;
        case '1Month':
          planDuration = const Duration(days: 30);
          break;
        default:
          planDuration = const Duration(days: 1);
      }
      final now = DateTime.now();
      final expiryDate = now.add(planDuration);

      // Get username automatically from user account
      final username = await UserUtils.getCurrentUsername();
      // Get phone number automatically from user account
      final userPhone = await UserUtils.getCurrentUserPhone();

      final data = {
        'userId': userId,
        'serviceType': _serviceType,
        'serviceName': _serviceNameController.text,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'contact': userPhone ?? '', // Automatically use phone from account
        'ownerName': username, // Automatically use username from account
        'openingTime':
            _openingTime != null ? _openingTime!.format(context) : null,
        'closingTime':
            _closingTime != null ? _closingTime!.format(context) : null,
        'offDay': _offDay,
        'createdAt': now.toIso8601String(),
        'coverPhoto': _coverPhotoUrl,
        'additionalPhotos': _additionalPhotoUrls,
        // Library-specific
        if (_serviceType == 'Library') ...{
          'libraryType': _libraryType,
          'seatingCapacity': int.tryParse(_seatingCapacityController.text) ?? 0,
          'acStatus': _acStatus,
          'charges': _chargesController.text,
          'chargeType': _chargeType,
          'hasInternet': _hasInternet,
          'hasStudyCabin': _hasStudyCabin,
        },
        // Café-specific
        if (_serviceType == 'Café') ...{
          'cuisineType': _cuisineType,
          'hasSeating': _hasSeating,
          'priceRange': _priceRangeController.text,
          'hasWifi': _hasWifi,
          'hasPowerSockets': _hasPowerSockets,
        },
        // Mess-specific
        if (_serviceType == 'Mess') ...{
          'foodType': _foodType,
          'charges': _monthlyPriceController.text,
          'seatingCapacity': int.tryParse(_seatingCapacityController.text) ?? 0,
          'mealTimings': _mealTimings,
          'hasHomeDelivery': _hasHomeDelivery,
          'hasTiffinService': _hasTiffinService,
        },
        // Other
        if (_serviceType == 'Other') ...{
          'pricing': _pricingController.text,
          'serviceTypeOther': _serviceTypeOtherController.text,
          'usefulness': _usefulnessController.text,
        },
        'selectedPlan': _selectedPlan,
        'expiryDate': expiryDate.toIso8601String(),
        'visibility': false, // Set to false initially, will be true after payment
        'paymentStatus': 'pending',
        'latitude': _pickedLocation?.latitude,
        'longitude': _pickedLocation?.longitude,
      };

      // First, create the listing with pending payment status
      final newServiceDocRef = await FirebaseFirestore.instance.collection('service_listings').add(data);
      final newServiceDocId = newServiceDocRef.id;

      final geo = GeoFlutterFire();
      if (_pickedLocation != null) {
        final geoPoint = geo.point(
          latitude: _pickedLocation!.latitude,
          longitude: _pickedLocation!.longitude,
        );
        await FirebaseFirestore.instance
            .collection('service_listings')
            .doc(newServiceDocId)
            .set({
              'position': geoPoint.data,
            }, SetOptions(merge: true));
      }

      // Close loading dialog
      Navigator.of(context).pop();

      // Now process payment
      print('Starting payment process for listing: $newServiceDocId');
      print('Plan: $_selectedPlan, Amount: $planPrice');
      
      try {
        await EfficientPaymentService().processListingPayment(
          listingType: 'list_service',
          planName: _selectedPlan,
          amount: planPrice,
          listingId: newServiceDocId,
          context: context,
        );
        print('Payment process completed successfully');
      } catch (paymentError) {
        print('Payment error: $paymentError');
        ValidationSnackBar.showError(context, 'Payment failed: $paymentError');
        return;
      }

      // Invalidate service cache to ensure fresh data
      await CacheUtils.invalidateServiceCache();
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      ValidationSnackBar.showError(context, 'Failed to submit: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    scaffoldBg = theme.scaffoldBackgroundColor;
    cardColor =
        theme.brightness == Brightness.dark
            ? const Color(0xFF23262F)
            : const Color.fromARGB(255, 226, 227, 231);
    textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;
    textSecondary =
        theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.black54;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text('List Your Service'),
        backgroundColor: scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProgressIndicator(),
                    _buildCurrentStepContent(),
                  ],
                ),
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingLg),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of $_totalSteps',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: BuddyTheme.textSecondaryColor,
                ),
              ),
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Text(
                    '${((_currentStep + _progressAnimation.value) / _totalSteps * 100).round()}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BuddyTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: BuddyTheme.spacingXs),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: (_currentStep + _progressAnimation.value) / _totalSteps,
                backgroundColor: BuddyTheme.dividerColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                  BuddyTheme.primaryColor,
                ),
                minHeight: 6,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepContainer({required Widget child}) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: BuddyTheme.spacingLg),
        child: child,
      ),
    );
  }

  Widget _buildServiceTypeStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '🏢 Service Type',
              'What type of service are you listing?',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildServiceTypeCards(),

            const SizedBox(height: BuddyTheme.spacingXl),

            _buildServiceTypeInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicDetailsStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '📝 Basic Details',
              'Tell us about your ${_serviceType.toLowerCase()}',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildAnimatedTextField(
              controller: _serviceNameController,
              label: 'Service Name',
              hint: 'Enter the name of your ${_serviceType.toLowerCase()}',
              icon: Icons.business,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            LocationAutocompleteField(
              controller: _locationController,
              label: 'Location',
              hint: 'Start typing to search for locations...',
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            // Map Picker Button for Location
            ElevatedButton.icon(
              icon: Icon(Icons.map),
              label: Text(_pickedLocation == null ? 'Pick Location on Map' : 'Location Selected'),
              onPressed: () async {
                final LatLng? result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapLocationPicker(
                      initialLocation: _pickedLocation,
                      showRadiusPicker: false,
                    ),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _pickedLocation = result;
                  });
                }
              },
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildAnimatedTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Brief overview of your service',
              icon: Icons.description_outlined,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingsAndContactStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '🕒 Timings & Contact',
              'When are you open and how to reach you?',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildTimingsCard(),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Off Day',
              _offDay,
              _offDays,
              (value) => setState(() => _offDay = value),
              Icons.event_busy,
            ),

            const SizedBox(height: BuddyTheme.spacingXl),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificDetailsStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              _getSpecificDetailsTitle(),
              'Provide ${_serviceType.toLowerCase()}-specific information',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildSpecificDetailsForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '📸 Photos',
              'Add photos to showcase your service',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildPhotoUploadSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentPlanStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '💰 Payment Plan',
              'Choose how long to keep your listing active',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),
            if (_isPlanPricesLoading)
              const Center(child: CircularProgressIndicator())
            else if (_planPricesError != null)
              Center(
                child: Text(
                  _planPricesError!,
                  style: TextStyle(color: Colors.red),
                ),
              )
            else if (_planPrices.isEmpty)
              Center(
                child: Text(
                  'No plans available',
                  style: TextStyle(color: Colors.red),
                ),
              )
            else
              ..._planPrices.entries
                  .map(
                    (plan) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: BuddyTheme.spacingMd,
                      ),
                      child: _buildPlanCard(
                        plan.key,
                        plan.value['actual'] ?? 0,
                        discountedPrice: plan.value['discounted'] ?? 0,
                        isSelected: _selectedPlan == plan.key,
                        onSelect:
                            () => setState(() => _selectedPlan = plan.key),
                      ),
                    ),
                  )
                  .toList(),
            const SizedBox(height: BuddyTheme.spacingXl),
            _buildPlanInfoCard(),

            const SizedBox(height: BuddyTheme.spacingXl),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    String planName,
    double actualPrice, {
    double discountedPrice = 0,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    String duration = planName;
    bool hasDiscount = discountedPrice > 0 && discountedPrice < actualPrice;
    String formattedActual = '₹${actualPrice.toStringAsFixed(0)}';
    String formattedDiscounted =
        hasDiscount ? '₹${discountedPrice.toStringAsFixed(0)}' : '';
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onSelect,
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(BuddyTheme.spacingMd),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? BuddyTheme.primaryColor.withOpacity(0.1)
                            : cardColor,
                    borderRadius: BorderRadius.circular(
                      BuddyTheme.borderRadiusMd,
                    ),
                    border: Border.all(
                      color:
                          isSelected
                              ? BuddyTheme.primaryColor
                              : Colors.grey.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color:
                            isSelected
                                ? BuddyTheme.primaryColor
                                : Colors.grey,
                      ),
                      const SizedBox(width: BuddyTheme.spacingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              duration,
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? BuddyTheme.primaryColor
                                        : textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: BuddyTheme.spacingXs),
                            Text(
                              'Keep your listing active for ${duration.toLowerCase()}',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasDiscount) ...[
                        Text(
                          formattedDiscounted,
                          style: TextStyle(
                            color:
                                isSelected
                                    ? BuddyTheme.primaryColor
                                    : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formattedActual,
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ] else ...[
                        Text(
                          formattedActual,
                          style: TextStyle(
                            color:
                                isSelected
                                    ? BuddyTheme.primaryColor
                                    : textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlanInfoCard() {
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BuddyTheme.primaryColor.withOpacity(0.1),
            BuddyTheme.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
        border: Border.all(color: BuddyTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: BuddyTheme.primaryColor),
              const SizedBox(width: BuddyTheme.spacingSm),
              Text(
                'Plan Benefits',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: BuddyTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: BuddyTheme.spacingSm),
          Text(
            '• Your listing will be active for the selected duration\n'
            '• Featured placement in search results\n'
            '• Email notifications for interested users\n'
            '• Option to extend duration later',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: BuddyTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(String title, String subtitle) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: BuddyTheme.spacingXs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BuddyTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceTypeCards() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: BuddyTheme.spacingSm,
        mainAxisSpacing: BuddyTheme.spacingSm,
      ),
      itemCount: _serviceTypes.length,
      itemBuilder: (context, index) {
        String serviceType = _serviceTypes[index];
        bool isSelected = _serviceType == serviceType;

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Opacity(
                opacity: value,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _serviceType = serviceType;
                      });
                    },
                    borderRadius: BorderRadius.circular(
                      BuddyTheme.borderRadiusMd,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? BuddyTheme.primaryColor.withOpacity(0.1)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(
                          BuddyTheme.borderRadiusMd,
                        ),
                        border: Border.all(
                          color:
                              isSelected
                                  ? BuddyTheme.primaryColor
                                  : BuddyTheme.borderColor,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getServiceTypeIcon(serviceType),
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: BuddyTheme.spacingSm),
                          Text(
                            serviceType,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color:
                                  isSelected
                                      ? BuddyTheme.primaryColor
                                      : BuddyTheme.textPrimaryColor,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildServiceTypeInfo() {
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BuddyTheme.primaryColor.withOpacity(0.1),
            BuddyTheme.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
        border: Border.all(color: BuddyTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: BuddyTheme.primaryColor),
              const SizedBox(width: BuddyTheme.spacingSm),
              Text(
                'Selected: $_serviceType',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: BuddyTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: BuddyTheme.spacingSm),
          Text(
            _getServiceTypeDescription(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: BuddyTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingsCard() {
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: BuddyTheme.primaryColor),
              const SizedBox(width: BuddyTheme.spacingSm),
              Text(
                'Operating Hours',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: BuddyTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: _buildTimePickerButton(
                  'Opening Time',
                  _openingTime,
                  (time) => setState(() => _openingTime = time),
                ),
              ),
              const SizedBox(width: BuddyTheme.spacingMd),
              Expanded(
                child: _buildTimePickerButton(
                  'Closing Time',
                  _closingTime,
                  (time) => setState(() => _closingTime = time),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerButton(
    String label,
    TimeOfDay? time,
    Function(TimeOfDay) onTimeSelected,
  ) {
    return Material(
      color: cardColor,
      child: InkWell(
        onTap: () async {
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: time ?? TimeOfDay.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(
                    context,
                  ).colorScheme.copyWith(primary: BuddyTheme.primaryColor),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            onTimeSelected(picked);
          }
        },
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
        child: Container(
          padding: const EdgeInsets.all(BuddyTheme.spacingMd),
          decoration: BoxDecoration(
            color: BuddyTheme.backgroundSecondaryColor,
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
            border: Border.all(color: BuddyTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: BuddyTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: BuddyTheme.spacingXs),
              Text(
                time != null ? time.format(context) : 'Select Time',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      time != null
                          ? BuddyTheme.textPrimaryColor
                          : BuddyTheme.textSecondaryColor,
                  fontWeight:
                      time != null ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecificDetailsForm() {
    switch (_serviceType) {
      case 'Library':
        return _buildLibraryDetails();
      case 'Café':
        return _buildCafeDetails();
      case 'Mess':
        return _buildMessDetails();
      case 'Other':
        return _buildOtherDetails();
      default:
        return Container();
    }
  }

  Widget _buildLibraryDetails() {
    return Column(
      children: [
        _buildSelectionCard(
          'Library Type',
          _libraryType,
          ['Public', 'Private', 'Subscription-based'],
          (value) => setState(() => _libraryType = value),
          Icons.library_books,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildAnimatedTextField(
          controller: _seatingCapacityController,
          label: 'Seating Capacity',
          hint: 'Number of seats available',
          icon: Icons.event_seat,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter seating capacity';
            }
            final intValue = int.tryParse(value);
            if (intValue == null) {
              return 'Please enter a valid number';
            }
            if (intValue <= 0) {
              return 'Seating capacity must be greater than 0';
            }
            return null;
          },
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildSelectionCard(
          'AC Status',
          _acStatus,
          ['AC', 'Non-AC', 'Both'],
          (value) => setState(() => _acStatus = value),
          Icons.ac_unit,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildAnimatedTextField(
          controller: _chargesController,
          label: 'Monthly Charges (₹)',
          hint: 'Enter monthly amount',
          icon: Icons.currency_rupee,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildSwitchCard(
          'Internet Facility',
          'WiFi available for users',
          _hasInternet,
          (value) => setState(() => _hasInternet = value),
          Icons.wifi,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildSwitchCard(
          'Study Cabin',
          'Private study cabins available',
          _hasStudyCabin,
          (value) => setState(() => _hasStudyCabin = value),
          Icons.meeting_room,
        ),

        const SizedBox(height: BuddyTheme.spacingXl),
      ],
    );
  }

  Widget _buildCafeDetails() {
    return Column(
      children: [
        _buildSelectionCard(
          'Cuisine Type',
          _cuisineType,
          ['Indian', 'Fast Food', 'Multi-cuisine'],
          (value) => setState(() => _cuisineType = value),
          Icons.restaurant,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildSwitchCard(
          'Seating Available',
          'Dine-in seating facility',
          _hasSeating,
          (value) => setState(() => _hasSeating = value),
          Icons.chair,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildAnimatedTextField(
          controller: _priceRangeController,
          label: 'Price Range (₹ per person)',
          hint: 'e.g., 100-300',
          icon: Icons.currency_rupee,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildSwitchCard(
          'WiFi Available',
          'Free WiFi for customers',
          _hasWifi,
          (value) => setState(() => _hasWifi = value),
          Icons.wifi,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildSwitchCard(
          'Power Sockets',
          'Charging points for laptops',
          _hasPowerSockets,
          (value) => setState(() => _hasPowerSockets = value),
          Icons.power,
        ),
      ],
    );
  }

  Widget _buildMessDetails() {
    return Column(
      children: [
        _buildSelectionCard(
          'Food Type',
          _foodType,
          ['Veg', 'Non-Veg', 'Veg and Non-Veg'],
          (String value) {
            setState(() {
              _foodType = value;
            });
          },
          Icons.restaurant_menu,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildAnimatedTextField(
          controller: _seatingCapacityController,
          label: 'Seating Capacity',
          hint: 'Number of seats available',
          icon: Icons.event_seat,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter seating capacity';
            }
            final intValue = int.tryParse(value);
            if (intValue == null) {
              return 'Please enter a valid number';
            }
            if (intValue <= 0) {
              return 'Seating capacity must be greater than 0';
            }
            return null;
          },
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildAnimatedTextField(
          controller: _monthlyPriceController,
          label: 'Monthly Price (₹)',
          hint: 'Enter monthly amount',
          icon: Icons.currency_rupee,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildMealTimingsCard(),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildSwitchCard(
          'Home Delivery',
          'Food delivery service available',
          _hasHomeDelivery,
          (value) => setState(() => _hasHomeDelivery = value),
          Icons.delivery_dining,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildSwitchCard(
          'Tiffin Service',
          'Tiffin packing service available',
          _hasTiffinService,
          (value) => setState(() => _hasTiffinService = value),
          Icons.bakery_dining,
        ),
      ],
    );
  }

  Widget _buildOtherDetails() {
    return Column(
      children: [
        _buildAnimatedTextField(
          controller: _pricingController,
          label: 'Pricing',
          hint: 'Enter service pricing details',
          icon: Icons.currency_rupee,
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildAnimatedTextField(
          controller: _serviceTypeOtherController,
          label: 'Type of Service',
          hint: 'Specify the type of service',
          icon: Icons.category_outlined,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildAnimatedTextField(
          controller: _usefulnessController,
          label: 'Usefulness for Students/Flat Seekers',
          hint: 'How does this help flat seekers/students?',
          icon: Icons.school_outlined,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildPhotoUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCoverPhotoSection(),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildAdditionalPhotosSection(),
      ],
    );
  }

  Widget _buildCoverPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cover Photo *',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: BuddyTheme.spacingSm),
        Text(
          'Please upload at least one photo to proceed',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: BuddyTheme.textSecondaryColor),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        InkWell(
          onTap: _selectCoverPhoto,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
              border: Border.all(color: BuddyTheme.borderColor),
              image:
                  _coverPhotoUrl != null
                      ? DecorationImage(
                        image: NetworkImage(_coverPhotoUrl!),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                _coverPhotoUrl == null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 48,
                            color: BuddyTheme.textSecondaryColor,
                          ),
                          const SizedBox(height: BuddyTheme.spacingSm),
                          Text(
                            'Click to add cover photo',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: BuddyTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    )
                    : null,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Photos',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: BuddyTheme.spacingSm),
        Text(
          'Add more photos of your service',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: BuddyTheme.textSecondaryColor),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: BuddyTheme.spacingSm,
            mainAxisSpacing: BuddyTheme.spacingSm,
          ),
          itemCount: _additionalPhotoUrls.length + 1,
          itemBuilder: (context, index) {
            if (index == _additionalPhotoUrls.length) {
              return _buildAddPhotoButton();
            }
            return _buildPhotoThumbnail(_additionalPhotoUrls[index]);
          },
        ),
      ],
    );
  }

  Widget _buildPhotoThumbnail(String photoUrl) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
            border: Border.all(color: BuddyTheme.borderColor),
            image: DecorationImage(
              image: NetworkImage(photoUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: () => _removePhoto(photoUrl),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return InkWell(
      onTap: _selectAdditionalPhoto,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
          border: Border.all(color: BuddyTheme.borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 32,
              color: BuddyTheme.textSecondaryColor,
            ),
            const SizedBox(height: BuddyTheme.spacingXs),
            Text(
              'Add Photo',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: BuddyTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectCoverPhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploading cover photo...'),
          duration: Duration(seconds: 1),
        ),
      );
      try {
        String url = await FirebaseStorageService.uploadImage(image.path);
        setState(() {
          _coverPhotoUrl = url;
        });
        ValidationSnackBar.showSuccess(context, 'Cover photo uploaded!');
      } catch (e) {
        ValidationSnackBar.showError(context, 'Failed to upload: $e');
      }
    }
  }

  void _selectAdditionalPhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploading photo...'),
          duration: Duration(seconds: 1),
        ),
      );
      try {
        String url = await FirebaseStorageService.uploadImage(image.path);
        setState(() {
          _additionalPhotoUrls.add(url);
        });
        ValidationSnackBar.showSuccess(context, 'Photo uploaded!');
      } catch (e) {
        ValidationSnackBar.showError(context, 'Failed to upload: $e');
      }
    }
  }

  void _removePhoto(String photoUrl) {
    setState(() {
      _additionalPhotoUrls.remove(photoUrl);
    });
  }

  Widget _buildMealTimingsCard() {
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_menu, color: BuddyTheme.primaryColor),
              const SizedBox(width: BuddyTheme.spacingSm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meals',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '(Select the meals provided by you)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BuddyTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: BuddyTheme.spacingMd),
          Wrap(
            spacing: BuddyTheme.spacingSm,
            runSpacing: BuddyTheme.spacingSm,
            children:
                _mealTimings.entries.map((entry) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _mealTimings[entry.key] = !entry.value;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BuddyTheme.spacingSm,
                        vertical: BuddyTheme.spacingXs,
                      ),
                      decoration: BoxDecoration(
                        color:
                            entry.value
                                ? BuddyTheme.primaryColor
                                : BuddyTheme.primaryColor.withOpacity(0.1),
                        border: Border.all(
                          color: BuddyTheme.primaryColor.withOpacity(
                            entry.value ? 1 : 0.3,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(
                          BuddyTheme.borderRadiusSm,
                        ),
                      ),
                      child: Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              entry.value
                                  ? Colors.white
                                  : BuddyTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(BuddyTheme.spacingLg),
        decoration: BoxDecoration(
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: BuddyTheme.spacingMd,
                    ),
                    side: BorderSide(color: BuddyTheme.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        BuddyTheme.borderRadiusMd,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back, color: BuddyTheme.primaryColor),
                      const SizedBox(width: BuddyTheme.spacingSm),
                      Text(
                        'Previous',
                        style: TextStyle(color: BuddyTheme.primaryColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: BuddyTheme.spacingMd),
            ],
            Expanded(
              flex: _currentStep == 0 ? 1 : 1,
              child: ElevatedButton(
                onPressed:
                    _currentStep == _totalSteps - 1 ? _submitForm : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BuddyTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: BuddyTheme.spacingMd,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      BuddyTheme.borderRadiusMd,
                    ),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentStep == _totalSteps - 1
                          ? 'Submit Listing'
                          : 'Next',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: BuddyTheme.spacingXs),
                    Icon(
                      _currentStep == _totalSteps - 1
                          ? Icons.check
                          : Icons.arrow_forward,
                      color: cardColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                maxLines: maxLines,
                validator:
                    validator ??
                    (value) {
                      if (value == null || value.isEmpty) {
                        return 'This field is required';
                      }
                      return null;
                    },
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                  prefixIcon: Icon(icon, color: BuddyTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      BuddyTheme.borderRadiusMd,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: cardColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwitchCard(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
        border: Border.all(color: BuddyTheme.borderColor),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
        ),
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: BuddyTheme.primaryColor),
      ),
    );
  }

  Widget _buildSelectionCard(
    String label,
    String value,
    List<String> options,
    Function(String) onChanged,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
        border: Border.all(color: BuddyTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: BuddyTheme.primaryColor),
              const SizedBox(width: BuddyTheme.spacingSm),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: BuddyTheme.spacingMd),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items:
                  options.map((option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getServiceTypeIcon(String type) {
    switch (type) {
      case 'Library':
        return '📚';
      case 'Café':
        return '☕';
      case 'Mess':
        return '🍱';
      case 'Other':
        return '🏢';
      default:
        return '🏢';
    }
  }

  String _getServiceTypeDescription() {
    switch (_serviceType) {
      case 'Library':
        return 'A quiet space for students to study and research with facilities like WiFi, AC, etc.';
      case 'Café':
        return 'A cozy spot for students to grab food and beverages, with seating and power outlets.';
      case 'Mess':
        return 'Regular meal service with monthly subscription options and tiffin facilities.';
      case 'Other':
        return 'List any other service that could be useful for students.';
      default:
        return '';
    }
  }

  String _getSpecificDetailsTitle() {
    switch (_serviceType) {
      case 'Library':
        return '📚 Library Details';
      case 'Café':
        return '☕ Café Details';
      case 'Mess':
        return '🍱 Mess Details';
      case 'Other':
        return '🏢 Service Details';
      default:
        return '📝 Service Details';
    }
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildServiceTypeStep();
      case 1:
        return _buildBasicDetailsStep();
      case 2:
        return _buildTimingsAndContactStep();
      case 3:
        return _buildSpecificDetailsStep();
      case 4:
        return _buildPhotosStep();
      case 5:
        return _buildPaymentPlanStep();
      default:
        return Container();
    }
  }
}