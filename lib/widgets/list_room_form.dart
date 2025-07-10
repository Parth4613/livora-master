import 'package:buddy/api/map_location_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/firebase_storage_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'location_autocomplete_field.dart';
import 'validation_widgets.dart';
import '../utils/user_utils.dart';
import '../utils/cache_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/efficient_payment_service.dart';

class ListRoomForm extends StatefulWidget {
  const ListRoomForm({Key? key}) : super(key: key);

  @override
  State<ListRoomForm> createState() => _ListRoomFormState();
}

class _ListRoomFormState extends State<ListRoomForm>
    with TickerProviderStateMixin {
  late AnimationController _progressAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _progressAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabAnimation;

  int _currentStep = 0;
  final int _totalSteps = 8; // Updated from 7 to 8

  // Form controllers and data
  final _formKey = GlobalKey<FormState>();

  // Flat Details
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _brokerageController = TextEditingController(); // Added controller
  DateTime? _availableFromDate;
  String _roomType = 'Private';
  String _flatSize = '1BHK';
  String _furnishing = 'Furnished';
  bool _hasAttachedBathroom = true;

  // Current Flatmate Details
  int _currentFlatmates = 1;
  int _maxFlatmates = 2; // Assuming max 2 flatmates for simplicity
  String _genderComposition = 'Mixed';
  String _occupation = 'Mixed';

  // Facilities
  Map<String, bool> _facilities = {
    'WiFi': false,
    'Geyser': false,
    'Washing Machine': false,
    'Refrigerator': false,
    'Parking': false,
    'Power Backup': false,
    'Balcony': false,
    'Gym': false,
  };

  // Preferences
  String _lookingFor = 'Any';
  String _foodPreference = 'Doesn\'t Matter';
  String _smokingPolicy = 'Not Allowed';
  String _drinkingPolicy = 'Not Allowed';
  String _petsPolicy = 'Not Allowed';
  String _guestsPolicy = 'Allowed';

  // Photos
  final Map<String, String> _uploadedPhotoUrls = {
    'Room': '',
    'Washroom': '',
    'Kitchen': '',
    'Building': '',
  };
  final Map<String, bool> _photoLoadingStates = {
    'Room': false,
    'Washroom': false,
    'Kitchen': false,
    'Building': false,
  };
  final ImagePicker _picker = ImagePicker();
  final List<String> _requiredPhotoTypes = [
    'Room',
    'Washroom',
    'Kitchen',
    'Building',
  ];

  // Contact Details
  bool _sharePhoneNumber = true;

  // Payment Plan
  String _selectedPlan = '1Day';
  Map<String, Map<String, double>> _planPrices = {};
  bool _isPlanPricesLoading = true;
  String? _planPricesError;

  // Add these theme variables
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
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
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

    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _progressAnimationController.forward();
    _slideAnimationController.forward();
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _slideAnimationController.dispose();
    _fabAnimationController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _brokerageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Validate current step before proceeding
    bool isValid = true;

    switch (_currentStep) {
      case 0: // Basic Details Step - Only title is required
        if (_titleController.text.trim().isEmpty) {
          ValidationSnackBar.showError(context, 'Please enter a listing title');
          isValid = false;
        }
        break;
      case 1: // Location and Date Step - Location, picked location, and date are required
        if (_locationController.text.trim().isEmpty) {
          ValidationSnackBar.showError(context, 'Please enter location');
          isValid = false;
        } else if (_pickedLocation == null) {
          ValidationSnackBar.showError(context, 'Please pick a location on the map');
          isValid = false;
        } else if (_availableFromDate == null) {
          ValidationSnackBar.showError(context, 'Please select available from date');
          isValid = false;
        }
        break;
      case 2: // Pricing Step
        if (_rentController.text.trim().isEmpty) {
          ValidationSnackBar.showError(context, 'Please enter monthly rent');
          isValid = false;
        } else if (_depositController.text.trim().isEmpty) {
          ValidationSnackBar.showError(context, 'Please enter security deposit');
          isValid = false;
        }
        break;
      case 6: // Photos and Contact Step - All 4 photos are required
        // Check if all 4 photos are uploaded
        bool hasAllPhotos = _uploadedPhotoUrls.values.every((url) => url.isNotEmpty);
        if (!hasAllPhotos) {
          ValidationSnackBar.showError(context, 'Please upload all 4 required photos');
          isValid = false;
        }
        break;
      case 7: // Contact Details Step
        // No validation needed for switch
        break;
    }

    if (!isValid) return;

    if (_currentStep >= _totalSteps - 1) return;

    setState(() {
      _currentStep++;
    });
    _updateProgress();
    _triggerSlideAnimation();
  }

  void _previousStep() {
    if (_currentStep <= 0) return;

    setState(() {
      _currentStep--;
    });
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

  void _submitForm() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    // Get the plan price
    final planPrice = _planPrices[_selectedPlan]?['actual'] ?? 0.0;
    if (planPrice <= 0) {
      ValidationSnackBar.showError(context, 'Invalid plan price');
      return;
    }

    // Calculate expiry date based on selected plan
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

    // Prepare data
    final data = {
      'userId': userId ?? 'anonymous',
      'title': _titleController.text,
      'location': _locationController.text,
      'rent': _rentController.text,
      'deposit': _depositController.text,
      'brokerage': _brokerageController.text,
      'name': username, // Automatically use username from account
      'availableFromDate': _availableFromDate?.toIso8601String(),
      'roomType': _roomType,
      'flatSize': _flatSize,
      'furnishing': _furnishing,
      'hasAttachedBathroom': _hasAttachedBathroom,
      'currentFlatmates': _currentFlatmates,
      'maxFlatmates': _maxFlatmates,
      'genderComposition': _genderComposition,
      'occupation': _occupation,
      'facilities': _facilities,
      'lookingFor': _lookingFor,
      'foodPreference': _foodPreference,
      'smokingPolicy': _smokingPolicy,
      'drinkingPolicy': _drinkingPolicy,
      'petsPolicy': _petsPolicy,
      'guestsPolicy': _guestsPolicy,
      'uploadedPhotos': _uploadedPhotoUrls,
      'firstPhoto': _uploadedPhotoUrls.values.firstWhere(
        (url) => url.isNotEmpty,
        orElse: () => '',
      ),
      'timestamp':
          FieldValue.serverTimestamp(), // Use server timestamp for consistent sorting
      'createdAt':
          FieldValue.serverTimestamp(), // Use server timestamp instead of client time
      'selectedPlan': _selectedPlan,
      'expiryDate': expiryDate.toIso8601String(),
      'visibility': false, // Set to false initially, will be true after payment
      'paymentStatus': 'pending',
      'sharePhoneNumber': _sharePhoneNumber,
      'latitude': _pickedLocation?.latitude,
      'longitude': _pickedLocation?.longitude,
    };

    try {
      // First, create the listing with pending payment status
      final newRoomDocRef = await FirebaseFirestore.instance
          .collection('room_listings')
          .add(data);
      final newRoomDocId = newRoomDocRef.id;

      final geo = GeoFlutterFire();
      if (_pickedLocation != null) {
        final geoPoint = geo.point(
          latitude: _pickedLocation!.latitude,
          longitude: _pickedLocation!.longitude,
        );
        await FirebaseFirestore.instance
            .collection('room_listings')
            .doc(newRoomDocId)
            .set({
              'position': geoPoint.data,
            }, SetOptions(merge: true));
      }

      // Now process payment
              await EfficientPaymentService().processListingPayment(
        listingType: 'list_room',
        planName: _selectedPlan,
        amount: planPrice,
        listingId: newRoomDocId,
        context: context,
      );

      // Invalidate room cache to ensure fresh data
      await CacheUtils.invalidateRoomCache();
    } catch (e) {
      ValidationSnackBar.showError(context, 'Failed to submit: $e');
    }
  }

  Future<void> _uploadPhoto(String photoType) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (image == null) return;

      // Set loading state for this photo type
      if (!mounted) return;
      setState(() {
        _photoLoadingStates[photoType] = true;
      });

      // Upload to Firebase Storage
      String firebaseUrl = await FirebaseStorageService.uploadImage(kIsWeb ? image : image.path);

      if (!mounted) return;
      setState(() {
        _uploadedPhotoUrls[photoType] = firebaseUrl;
        _photoLoadingStates[photoType] = false;
      });

      ValidationSnackBar.showSuccess(context, 'Image uploaded successfully!');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _photoLoadingStates[photoType] = false;
      });
      ValidationSnackBar.showError(context, 'Failed to upload image: $e');
    }
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
              .doc('list_room')
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
        title: const Text('List Your Room'),
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

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildFlatDetailsStep();
      case 1:
        return _buildLocationAndDateStep();
      case 2:
        return _buildPricingStep();
      case 3:
        return _buildFlatmateDetailsStep();
      case 4:
        return _buildFacilitiesStep();
      case 5:
        return _buildPreferencesStep();
      case 6:
        return _buildPhotosAndContactStep();
      case 7:
        return _buildPaymentPlanStep();
      default:
        return Container();
    }
  }

  Widget _buildFlatDetailsStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader('🏠 Flat Details', 'Tell us about your property'),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildAnimatedTextField(
              controller: _titleController,
              label: 'Listing Title',
              hint: 'e.g, 1 BHK Flat in Kothrud, Pune – One Room Available',
              icon: Icons.title,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Room Type',
              _roomType,
              ['Private', 'Shared Room'],
              (value) => setState(() => _roomType = value),
              Icons.bed_outlined,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Flat Size',
              _flatSize,
              ['1RK', '1BHK', '2BHK', '3BHK', '4+ BHK'],
              (value) => setState(() => _flatSize = value),
              Icons.home_outlined,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Furnishing',
              _furnishing,
              ['Furnished', 'Semi-furnished', 'Unfurnished'],
              (value) => setState(() => _furnishing = value),
              Icons.chair_outlined,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSwitchCard(
              'Attached Bathroom',
              'Does the room have an attached bathroom?',
              _hasAttachedBathroom,
              (value) => setState(() => _hasAttachedBathroom = value),
              Icons.bathroom_outlined,
            ),

            const SizedBox(height: BuddyTheme.spacingXl),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationAndDateStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '📍 Location & Availability',
              'Where is your property located?',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            LocationAutocompleteField(
              controller: _locationController,
              label: 'Location',
              hint: 'Start typing to search for locations...',
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),

            const SizedBox(height: BuddyTheme.spacingXl),

            // Map Picker Button for Location
            ElevatedButton.icon(
              icon: Icon(Icons.map),
              label: Text(
                _pickedLocation == null
                    ? 'Pick Location on Map'
                    : 'Location Selected',
              ),
              onPressed: () async {
                final LatLng? result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            MapLocationPicker(initialLocation: _pickedLocation, showRadiusPicker: false),
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

            _buildDatePickerCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader('💰 Pricing Details', 'Set your rental terms'),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildAnimatedTextField(
              controller: _rentController,
              label: 'Monthly Rent per person (₹)',
              hint: 'Enter amount per person',
              icon: Icons.currency_rupee,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildAnimatedTextField(
              controller: _depositController,
              label: 'Security Deposit per person (₹)',
              hint: 'Enter deposit amount',
              icon: Icons.security,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildAnimatedTextField(
              controller: _brokerageController,
              label: 'Brokerage Amount per person (₹) (if any)',
              hint: 'Enter brokerage fee (if any)',
              icon: Icons.real_estate_agent,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildPricingTipCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildFlatmateDetailsStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '👥 Current Flatmates',
              'Tell us about your current flatmates',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildCounterCard(
              'Number of Current Flatmates',
              _currentFlatmates,
              (value) => setState(() => _currentFlatmates = value),
              Icons.people_outline,
            ),

            const SizedBox(height: BuddyTheme.spacingXl),

            _buildCounterCard(
              'Number of Max Flatmates',
              _maxFlatmates,
              (value) => setState(() => _maxFlatmates = value),
              Icons.people_outline,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Gender Composition',
              _genderComposition,
              ['Male Only', 'Female Only', 'Mixed'],
              (value) => setState(() => _genderComposition = value),
              Icons.people,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Occupation',
              _occupation,
              ['Students Only', 'Working Only', 'Mixed'],
              (value) => setState(() => _occupation = value),
              Icons.work_outline,
            ),

            const SizedBox(height: BuddyTheme.spacingXl),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilitiesStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '🏠 Facilities & Amenities',
              'What facilities are available?',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildFacilitiesGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '⚙️ Preferences & Rules',
              'Set your flatmate preferences',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            _buildSelectionCard(
              'Looking For',
              _lookingFor,
              ['Male', 'Female', 'Any'],
              (value) => setState(() => _lookingFor = value),
              Icons.search,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildSelectionCard(
              'Food Preference',
              _foodPreference,
              ['Veg', 'Non-Veg', 'Eggetarian', 'Doesn\'t Matter'],
              (value) => setState(() => _foodPreference = value),
              Icons.restaurant,
            ),

            const SizedBox(height: BuddyTheme.spacingLg),

            _buildPolicySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosAndContactStep() {
    return _buildStepContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              '📞 Contact and Photos',
              'Add contact details and photos',
            ),
            const SizedBox(height: BuddyTheme.spacingXl),

            Text(
              'Contact Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: BuddyTheme.spacingMd),

            _buildSwitchCard(
              'Share Phone Number',
              'Allow potential tenants to contact you via phone?',
              _sharePhoneNumber,
              (value) => setState(() => _sharePhoneNumber = value),
              Icons.phone_outlined,
            ),

            const SizedBox(height: BuddyTheme.spacingXl),

            _buildPhotoUploadSection(),

            const SizedBox(height: BuddyTheme.spacingXl),
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
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder:
          (
            BuildContext context,
            double value,
            Widget? child,
          ) => Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onSelect,
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
          ),
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
            '• Email notifications for interested flatmates\n'
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
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder:
          (BuildContext context, double value, Widget? child) =>
              Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: value,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
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
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 500),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder:
          (BuildContext context, double value, Widget? child) =>
              Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(
                        BuddyTheme.borderRadiusMd,
                      ),
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
                      validator: validator,
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
              ),
    );
  }

  Widget _buildSelectionCard(
    String title,
    String selectedValue,
    List<String> options,
    Function(String) onChanged,
    IconData icon,
  ) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder:
          (BuildContext context, double value, Widget? child) =>
              Transform.translate(
                offset: Offset(50 * (1 - value), 0),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    padding: const EdgeInsets.all(BuddyTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(
                        BuddyTheme.borderRadiusMd,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(icon, color: BuddyTheme.primaryColor),
                            const SizedBox(width: BuddyTheme.spacingSm),
                            Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: BuddyTheme.spacingMd),
                        Wrap(
                          spacing: BuddyTheme.spacingSm,
                          runSpacing: BuddyTheme.spacingSm,
                          children:
                              options
                                  .map(
                                    (option) => GestureDetector(
                                      onTap: () => onChanged(option),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: BuddyTheme.spacingMd,
                                          vertical: BuddyTheme.spacingSm,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              selectedValue == option
                                                  ? BuddyTheme.primaryColor
                                                  : scaffoldBg,
                                          borderRadius: BorderRadius.circular(
                                            BuddyTheme.borderRadiusSm,
                                          ),
                                          border: Border.all(
                                            color:
                                                selectedValue == option
                                                    ? BuddyTheme.primaryColor
                                                    : BuddyTheme.borderColor,
                                          ),
                                        ),
                                        child: Text(
                                          option,
                                          style: TextStyle(
                                            color:
                                                selectedValue == option
                                                    ? Colors.white
                                                    : textPrimary,
                                            fontWeight:
                                                selectedValue == option
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildSwitchCard(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 700),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder:
          (BuildContext context, double animValue, Widget? child) =>
              Transform.scale(
                scale: 0.8 + (0.2 * animValue),
                child: Opacity(
                  opacity: animValue,
                  child: Container(
                    padding: const EdgeInsets.all(BuddyTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(
                        BuddyTheme.borderRadiusMd,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: BuddyTheme.primaryColor),
                        const SizedBox(width: BuddyTheme.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                subtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: value,
                          onChanged: onChanged,
                          activeColor: BuddyTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildCounterCard(
    String title,
    int value,
    Function(int) onChanged,
    IconData icon,
  ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: Container(
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
              child: Row(
                children: [
                  Icon(icon, color: BuddyTheme.primaryColor),
                  const SizedBox(width: BuddyTheme.spacingMd),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: value > 0 ? () => onChanged(value - 1) : null,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(BuddyTheme.spacingXs),
                            child: Icon(
                              Icons.remove_circle_outline,
                              color:
                                  value > 0
                                      ? BuddyTheme.primaryColor
                                      : textSecondary,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BuddyTheme.spacingMd,
                          vertical: BuddyTheme.spacingSm,
                        ),
                        decoration: BoxDecoration(
                          color: BuddyTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            BuddyTheme.borderRadiusSm,
                          ),
                        ),
                        child: Text(
                          value.toString(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: BuddyTheme.primaryColor,
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onChanged(value + 1),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(BuddyTheme.spacingXs),
                            child: Icon(
                              Icons.add_circle_outline,
                              color: BuddyTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFacilitiesGrid() {
    List<Widget> rows = [];
    List<String> keys = _facilities.keys.toList();

    int i = 0;
    while (i < keys.length) {
      String facility = keys[i];
      bool isLongName = facility.length > 12;

      if (isLongName) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: BuddyTheme.spacingMd),
            child: _buildFacilityItem(
              facility,
              _facilities[facility]!,
              fullWidth: true,
            ),
          ),
        );
        i++;
      } else {
        final String facility1 = keys[i];
        final Widget firstItem = _buildFacilityItem(
          facility1,
          _facilities[facility1]!,
        );
        i++;
        if (i < keys.length) {
          final String facility2 = keys[i];
          final Widget secondItem = _buildFacilityItem(
            facility2,
            _facilities[facility2]!,
          );

          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: BuddyTheme.spacingSm),
              child: Row(
                children: [
                  Expanded(child: firstItem),
                  SizedBox(width: BuddyTheme.spacingSm),
                  Expanded(child: secondItem),
                ],
              ),
            ),
          );
          i++;
        } else {
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: BuddyTheme.spacingSm),
              child: Row(children: [Expanded(child: firstItem)]),
            ),
          );
        }
      }
    }

    return Column(children: rows);
  }

  Widget _buildFacilityItem(
    String facility,
    bool isSelected, {
    bool fullWidth = false,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: InkWell(
            onTap: () {
              setState(() {
                _facilities[facility] = !isSelected;
              });
            },
            child: Container(
              width: fullWidth ? double.infinity : null,
              padding: EdgeInsets.symmetric(
                horizontal: BuddyTheme.spacingMd,
                vertical: BuddyTheme.spacingSm,
              ),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? BuddyTheme.primaryColor.withOpacity(0.1)
                        : cardColor,
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
                border: Border.all(
                  color:
                      isSelected
                          ? BuddyTheme.primaryColor
                          : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Text(
                facility,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? BuddyTheme.primaryColor : textSecondary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDatePickerCard() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
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
                      Icon(
                        Icons.calendar_today_outlined,
                        color: BuddyTheme.primaryColor,
                      ),
                      const SizedBox(width: BuddyTheme.spacingSm),
                      Text(
                        'Available From',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BuddyTheme.spacingMd),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _availableFromDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          builder: (context, child) {
                            return Theme(
                              data: theme.copyWith(
                                colorScheme: theme.colorScheme.copyWith(
                                  primary: BuddyTheme.primaryColor,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            _availableFromDate = picked;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(
                        BuddyTheme.borderRadiusSm,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(BuddyTheme.spacingMd),
                        decoration: BoxDecoration(
                          color: scaffoldBg,
                          borderRadius: BorderRadius.circular(
                            BuddyTheme.borderRadiusSm,
                          ),
                          border: Border.all(color: BuddyTheme.borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event, color: BuddyTheme.primaryColor),
                            const SizedBox(width: BuddyTheme.spacingSm),
                            Text(
                              _availableFromDate != null
                                  ? '${_availableFromDate!.day}/${_availableFromDate!.month}/${_availableFromDate!.year}'
                                  : 'Select Date',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    _availableFromDate != null
                                        ? textPrimary
                                        : textSecondary,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.arrow_drop_down, color: textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPricingTipCard() {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder:
          (BuildContext context, double value, Widget? child) =>
              Transform.scale(
                scale: 0.9 + (0.1 * value),
                child: Opacity(
                  opacity: value,
                  child: Container(
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
                      borderRadius: BorderRadius.circular(
                        BuddyTheme.borderRadiusMd,
                      ),
                      border: Border.all(
                        color: BuddyTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outlined,
                              color: BuddyTheme.primaryColor,
                            ),
                            const SizedBox(width: BuddyTheme.spacingSm),
                            Text(
                              'Pricing Tips',
                              style: Theme.of(
                                context,
                              ).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: BuddyTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: BuddyTheme.spacingSm),
                        Text(
                          '• Research similar properties in your area\n'
                          '• Consider including utilities in rent\n'
                          '• Security deposit is typically 1-2 months rent\n'
                          '• Be transparent about additional charges',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: BuddyTheme.textSecondaryColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildPolicySection() {
    return Column(
      children: [
        _buildSelectionCard(
          'Smoking Policy',
          _smokingPolicy,
          ['Not Allowed', 'Allowed', 'Only Outside'],
          (value) => setState(() => _smokingPolicy = value),
          Icons.smoke_free,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildSelectionCard(
          'Drinking Policy',
          _drinkingPolicy,
          ['Not Allowed', 'Allowed', 'Occasionally'],
          (value) => setState(() => _drinkingPolicy = value),
          Icons.local_bar_outlined,
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        _buildSelectionCard(
          'Guests Policy',
          _guestsPolicy,
          ['Not Allowed', 'Allowed', 'Prior Permission'],
          (value) => setState(() => _guestsPolicy = value),
          Icons.people_outline,
        ),
        const SizedBox(height: BuddyTheme.spacingXl),
      ],
    );
  }

  Widget _buildPhotoUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Required Photos *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: BuddyTheme.spacingMd),
        Text(
          'Please upload all 4 required photos to proceed',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: BuddyTheme.textSecondaryColor),
        ),
        const SizedBox(height: BuddyTheme.spacingLg),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: BuddyTheme.spacingMd,
            crossAxisSpacing: BuddyTheme.spacingMd,
            childAspectRatio: 0.85,
          ),
          itemCount: _requiredPhotoTypes.length,
          itemBuilder: (context, index) {
            final photoType = _requiredPhotoTypes[index];
            final photoUrl = _uploadedPhotoUrls[photoType];
            final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
            final isLoading = _photoLoadingStates[photoType] ?? false;

            return _buildPhotoUploadCard(
              photoType: photoType,
              hasPhoto: hasPhoto,
              photoUrl: photoUrl,
              isLoading: isLoading,
            );
          },
        ),
      ],
    );
  }

  Widget _buildPhotoUploadCard({
    required String photoType,
    required bool hasPhoto,
    String? photoUrl,
    required bool isLoading,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
        border: Border.all(
          color:
              hasPhoto ? BuddyTheme.primaryColor : Colors.grey.withOpacity(0.3),
          width: hasPhoto ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : () => _uploadPhoto(photoType),
          borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
          child: Padding(
            padding: const EdgeInsets.all(BuddyTheme.spacingMd),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  SizedBox(
                    height: 40,
                    width: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(BuddyTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(height: BuddyTheme.spacingMd),
                  Text(
                    'Uploading...',
                    style: TextStyle(
                      color: BuddyTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else if (hasPhoto && photoUrl != null && photoUrl.isNotEmpty) ...[
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        BuddyTheme.borderRadiusSm,
                      ),
                      child: CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                        errorWidget:
                            (context, url, error) => const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 32,
                            ),
                      ),
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 40,
                    color: hasPhoto ? BuddyTheme.primaryColor : Colors.grey,
                  ),
                  const SizedBox(height: BuddyTheme.spacingMd),
                ],
                Text(
                  photoType,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: hasPhoto ? BuddyTheme.primaryColor : textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!hasPhoto && !isLoading) ...[
                  const SizedBox(height: BuddyTheme.spacingXs),
                  Text(
                    'Tap to upload',
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
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
              child: ScaleTransition(
                scale: _fabAnimation,
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
            ),
          ],
        ),
      ),
    );
  }
}