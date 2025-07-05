import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/hostel_data.dart';
import '../utils/cache_utils.dart';

class EditHostelPGPage extends StatefulWidget {
  final Map<String, dynamic> hostelData;
  const EditHostelPGPage({Key? key, required this.hostelData})
    : super(key: key);

  @override
  State<EditHostelPGPage> createState() => _EditHostelPGPageState();
}

class _EditHostelPGPageState extends State<EditHostelPGPage> {
  final _formKey = GlobalKey<FormState>();
  late HostelData _hostelData;

  // Payment Plan
  String? selectedPlan;
  Map<String, Map<String, double>> _planPrices = {};
  bool _isPlanPricesLoading = true;
  String? _planPricesError;

  // Room Types
  Map<String, bool> _availableRoomTypes = {
    '1 Bed Room (Private)': false,
    '2 Bed Room': false,
    '3 Bed Room': false,
    '4+ Bed Room': false,
  };

  // Form controllers
  late TextEditingController _titleController;
  late TextEditingController _startingPriceController;
  DateTime? _availableFromDate; // Keep this as null initially

  @override
  void initState() {
    super.initState();
    // Convert the raw map to HostelData model
    _hostelData = HostelData.fromFirestore(widget.hostelData);
    _fetchPlanPrices();

    _titleController = TextEditingController(text: _hostelData.title);
    _startingPriceController = TextEditingController(
      text: _hostelData.startingAt.toString(),
    );

    // Keep _availableFrom as null to show blank field
    _availableFromDate = null;

    selectedPlan = _hostelData.selectedPlan;

    // Initialize room types from existing data
    _hostelData.roomTypes.forEach((roomType, isSelected) {
      if (_availableRoomTypes.containsKey(roomType)) {
        _availableRoomTypes[roomType] = isSelected;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _startingPriceController.dispose();
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
              .doc('list_hostelpg')
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
        if (_planPrices.isNotEmpty && !_planPrices.containsKey(selectedPlan)) {
          selectedPlan = _planPrices.keys.first;
        }
      });
    } catch (e) {
      setState(() {
        _planPricesError = 'Failed to load plan prices';
        _isPlanPricesLoading = false;
      });
    }
  }

  // Exactly copied from EditPropertyPage
  void _pickAvailableFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _availableFromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFF4A9EFF)),
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
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      // Validate that at least one room type is selected
      if (!_availableRoomTypes.values.any((isSelected) => isSelected)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select at least one room type'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }
      if (selectedPlan == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a payment plan'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }      // Calculate expiry date
      int days = 0;
      switch (selectedPlan) {
        case '1Day':
          days = 1;
          break;
        case '7Day':
          days = 7;
          break;
        case '15Day':
          days = 15;
          break;
        case '1Month':
          days = 30;
          break;
        default:
          days = 1;
      }
      
      try {        final now = DateTime.now();
        final expiryDate = now.add(Duration(days: days));
        final docId = widget.hostelData['key'] ?? widget.hostelData['id'];
        
        print('Debug: Updating hostel listing - DocId: $docId'); // Debug log
        
        if (docId == null) {
          throw Exception('Document ID not found');
        }
        
        await FirebaseFirestore.instance
            .collection('hostel_listings')
            .doc(docId)
            .update({
              'title': _titleController.text,
              'hostelType': _hostelData.hostelType,
              'hostelFor': _hostelData.hostelFor,          'startingAt':
              _startingPriceController.text.isNotEmpty
                  ? double.parse(_startingPriceController.text).round() // Convert to double first, then round to integer
                  : 0,
              'contactPerson': _hostelData.contactPerson,
              'phone': _hostelData.phone,
              'email': _hostelData.email,
              'address': _hostelData.address,
              'landmark': _hostelData.landmark,
              'roomTypes': _availableRoomTypes,
              'facilities': _hostelData.facilities,
              'hasEntryTimings': _hostelData.hasEntryTimings,
              'entryTime': _hostelData.entryTime,
              'smokingPolicy': _hostelData.smokingPolicy,
              'drinkingPolicy': _hostelData.drinkingPolicy,
              'guestsPolicy': _hostelData.guestsPolicy,
              'petsPolicy': _hostelData.petsPolicy,
              'foodType': _hostelData.foodType,
              'availableFromDate': _availableFromDate?.toIso8601String(),
              'minimumStay': _hostelData.minimumStay,
              'bookingMode': _hostelData.bookingMode,
              'uploadedPhotos': _hostelData.uploadedPhotos,
              'description': _hostelData.description,
              'offers': _hostelData.offers,
              'specialFeatures': _hostelData.specialFeatures,              'createdAt': now.toIso8601String(),
              'selectedPlan': selectedPlan,
              'expiryDate': expiryDate.toIso8601String(),
              'visibility': true, // Always set to true when resubmitting
            });        if (mounted) {
          // Invalidate hostel cache to ensure fresh data
          await CacheUtils.invalidateHostelCache();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Hostel details updated!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          Navigator.pop(context, {'updated': true});
        }
      } catch (e) {
        print('Error updating hostel listing: $e'); // Debug log
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update listing: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D36),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A9EFF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF4A9EFF), size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF4A9EFF), size: 20),
          filled: true,
          fillColor: const Color(0xFF3A3D46),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4A9EFF), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildRoomTypesSection() {
    return _buildSectionCard(
      title: 'Available Room Types',
      subtitle: 'Select room types you offer',
      icon: Icons.bed_rounded,
      children: [
        Column(
          children:
              _availableRoomTypes.entries.map((entry) {
                final roomType = entry.key;
                final isSelected = entry.value;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        _availableRoomTypes[roomType] = value ?? false;
                      });
                    },
                    title: Text(
                      roomType,
                      style: const TextStyle(color: Colors.white),
                    ),
                    activeColor: const Color(0xFF4A9EFF),
                    checkColor: Colors.white,
                    fillColor: MaterialStateProperty.resolveWith<Color>(
                      (states) =>
                          states.contains(MaterialState.selected)
                              ? const Color(0xFF4A9EFF)
                              : Colors.transparent,
                    ),
                    side: const BorderSide(color: Colors.white, width: 1),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaymentPlanSection() {
    return _buildSectionCard(
      title: 'Payment Plan',
      subtitle: 'Select visibility duration',
      icon: Icons.timer_rounded,
      children: [
        _isPlanPricesLoading
            ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A9EFF)),
              ),
            )
            : _planPricesError != null
            ? Text(_planPricesError!, style: TextStyle(color: Colors.red))
            : _planPrices.isEmpty
            ? Center(
              child: Text(
                'No plans available',
                style: TextStyle(color: Colors.red),
              ),
            )
            : Column(
              children:
                  _planPrices.entries.map((entry) {
                    String planName = entry.key;
                    Map<String, double> planData = entry.value;
                    bool hasDiscount =
                        (planData['discounted'] ?? 0) > 0 &&
                        (planData['discounted'] ?? 0) <
                            (planData['actual'] ?? 0);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              selectedPlan = planName;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  selectedPlan == planName
                                      ? const Color(0xFF4A9EFF).withOpacity(0.1)
                                      : const Color(0xFF3A3D46),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    selectedPlan == planName
                                        ? const Color(0xFF4A9EFF)
                                        : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        planName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (hasDiscount) ...[
                                            Text(
                                              '₹${planData['discounted']?.toStringAsFixed(0) ?? ''}',
                                              style: const TextStyle(
                                                color: Color(0xFF4A9EFF),
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '₹${planData['actual']?.toStringAsFixed(0) ?? ''}',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.5,
                                                ),
                                                fontSize: 14,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ] else
                                            Text(
                                              '₹${planData['actual']?.toStringAsFixed(0) ?? ''}',
                                              style: const TextStyle(
                                                color: Color(0xFF4A9EFF),
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (selectedPlan == planName)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4A9EFF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D23),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Hostel/PG Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Details Section
              _buildSectionCard(
                title: 'Basic Details',
                subtitle: 'Hostel title and availability',
                icon: Icons.home_rounded,
                children: [
                  _buildTextField(
                    controller: _titleController,
                    label: 'Listing Title',
                    icon: Icons.title_rounded,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Enter listing title'
                                : null,
                  ),
                  // Modified Available From field - now shows blank initially
                  _buildTextField(
                    controller: TextEditingController(
                      text:
                          _availableFromDate != null
                              ? DateFormat(
                                'yyyy-MM-dd',
                              ).format(_availableFromDate!)
                              : '', // This will be empty initially
                    ),
                    label: 'Available From',
                    icon: Icons.date_range_rounded,
                    readOnly: true,
                    onTap: _pickAvailableFrom,
                    validator:
                        (value) =>
                            (value == null || value.isEmpty)
                                ? 'Select available from date'
                                : null,
                  ),
                ],
              ),

              // Pricing Section
              _buildSectionCard(
                title: 'Pricing Details',
                subtitle: 'Starting price information',
                icon: Icons.currency_rupee_rounded,
                children: [
                  _buildTextField(
                    controller: _startingPriceController,
                    label: 'Room Starting at (₹)',
                    icon: Icons.currency_rupee_rounded,
                    keyboardType: TextInputType.number,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Enter starting price'
                                : null,
                  ),
                ],
              ),

              // Room Types Section
              _buildRoomTypesSection(),

              // Payment Plan Section
              _buildPaymentPlanSection(),

              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A9EFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Resubmit Listing',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}