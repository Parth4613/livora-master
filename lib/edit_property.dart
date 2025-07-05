import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/cache_utils.dart';

class EditPropertyPage extends StatefulWidget {
  final Map<String, dynamic> propertyData;
  const EditPropertyPage({Key? key, required this.propertyData})
    : super(key: key);

  @override
  State<EditPropertyPage> createState() => _EditPropertyPageState();
}

class _EditPropertyPageState extends State<EditPropertyPage> {
  final _formKey = GlobalKey<FormState>();

  // Payment Plan
  String? selectedPlan;
  Map<String, Map<String, double>> _planPrices = {};
  bool _isPlanPricesLoading = true;
  String? _planPricesError;

  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _rentController;
  late TextEditingController _securityDepositController;
  late TextEditingController _brokerageController;
  late TextEditingController _currentFlatmatesController;
  late TextEditingController _maxFlatmatesController;
  late TextEditingController _descriptionController;
  DateTime? _availableFrom;

  @override
  void initState() {
    super.initState();
    _fetchPlanPrices();
    _titleController = TextEditingController(
      text: widget.propertyData['title'] ?? '',
    );
    _locationController = TextEditingController(
      text: widget.propertyData['location'] ?? '',
    );
    _rentController = TextEditingController(
      text: widget.propertyData['rent']?.toString() ?? '',
    );
    _securityDepositController = TextEditingController(
      text: widget.propertyData['deposit']?.toString() ?? '',
    );
    _brokerageController = TextEditingController(
      text: widget.propertyData['brokerage']?.toString() ?? '',
    );
    _currentFlatmatesController = TextEditingController(
      text: widget.propertyData['currentFlatmates']?.toString() ?? '',
    );
    _maxFlatmatesController = TextEditingController(
      text: widget.propertyData['maxFlatmates']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.propertyData['description'] ?? '',
    );
    _availableFrom =
        widget.propertyData['availableFromDate'] != null &&
                widget.propertyData['availableFromDate'].toString().isNotEmpty
            ? DateTime.tryParse(widget.propertyData['availableFromDate'])
            : null;

    _fetchPlanPrices();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _rentController.dispose();
    _securityDepositController.dispose();
    _brokerageController.dispose();
    _currentFlatmatesController.dispose();
    _maxFlatmatesController.dispose();
    _descriptionController.dispose();
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

  void _pickAvailableFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _availableFrom ?? DateTime.now(),
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
        _availableFrom = picked;
      });
    }
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
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
      }

      // Set createdAt to now
      final now = DateTime.now();
      // Calculate expiryDate based on plan
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
          days = 0;
      }
      final expiryDate = now.add(Duration(days: days));
      final visibility = expiryDate.isAfter(now);

      // Update Firestore document directly
      final docId =
          widget.propertyData['key'] ??
          widget.propertyData['id'] ??
          widget.propertyData['propertyId'];
      if (docId != null) {
        await FirebaseFirestore.instance
            .collection('room_listings')
            .doc(docId)
            .update({
              'createdAt': now.toIso8601String(),
              'expiryDate': expiryDate.toIso8601String(),
              'visibility': visibility,
              'title': _titleController.text,
              'location': _locationController.text,
              'rent': double.tryParse(_rentController.text) ?? 0,
              'deposit': double.tryParse(_securityDepositController.text) ?? 0,
              'brokerage': double.tryParse(_brokerageController.text) ?? 0,
              'currentFlatmates':
                  int.tryParse(_currentFlatmatesController.text) ?? 0,
              'maxFlatmates': int.tryParse(_maxFlatmatesController.text) ?? 0,
              'availableFromDate':
                  _availableFrom != null
                      ? DateFormat('yyyy-MM-dd').format(_availableFrom!)
                      : '',
              'selectedPlan': selectedPlan,
            });
      }

      // Invalidate room cache to ensure fresh data
      await CacheUtils.invalidateRoomCache();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Room details updated!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.pop(context, {'updated': true});
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
          'Edit Room Details',
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
                subtitle: 'Room title and availability',
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
                  _buildTextField(
                    controller: TextEditingController(
                      text:
                          _availableFrom != null
                              ? DateFormat('yyyy-MM-dd').format(_availableFrom!)
                              : '',
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

              // Financial Details Section
              _buildSectionCard(
                title: 'Financial Details',
                subtitle: 'Rent and deposit information\n(per person)',
                icon: Icons.currency_rupee_rounded,
                children: [
                  _buildTextField(
                    controller: _rentController,
                    label: 'Monthly Rent (₹ per person)',
                    icon: Icons.currency_rupee_rounded,
                    keyboardType: TextInputType.number,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Enter monthly rent'
                                : null,
                  ),
                  _buildTextField(
                    controller: _securityDepositController,
                    label: 'Security Deposit (₹ per person)',
                    icon: Icons.lock_outline_rounded,
                    keyboardType: TextInputType.number,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Enter security deposit'
                                : null,
                  ),
                  _buildTextField(
                    controller: _brokerageController,
                    label: 'Brokerage (₹ per person)',
                    icon: Icons.account_balance_wallet_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),

              // Flatmate Details Section
              _buildSectionCard(
                title: 'Flatmate Details',
                subtitle: 'Current and maximum occupancy',
                icon: Icons.people_alt_rounded,
                children: [
                  _buildTextField(
                    controller: _currentFlatmatesController,
                    label: 'Current Flatmates',
                    icon: Icons.people_alt_rounded,
                    keyboardType: TextInputType.number,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Enter current number of flatmates'
                                : null,
                  ),
                  _buildTextField(
                    controller: _maxFlatmatesController,
                    label: 'Maximum Flatmates',
                    icon: Icons.group_add_rounded,
                    keyboardType: TextInputType.number,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Enter maximum number of flatmates'
                                : null,
                  ),
                ],
              ),

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