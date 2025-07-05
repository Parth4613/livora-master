import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/cache_utils.dart';

class EditServicePage extends StatefulWidget {
  final String serviceId;
  final Map<String, dynamic> serviceData;

  const EditServicePage({
    Key? key,
    required this.serviceId,
    required this.serviceData,
  }) : super(key: key);

  @override
  State<EditServicePage> createState() => _EditServicePageState();
}

class _EditServicePageState extends State<EditServicePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Payment Plan
  String? selectedPlan;
  Map<String, Map<String, double>> _planPrices = {};
  bool _isPlanPricesLoading = true;
  String? _planPricesError;

  // Common Fields
  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Service Type
  late String _serviceType;

  // Form controllers for different service types
  final TextEditingController _seatingCapacityController =
      TextEditingController();
  final TextEditingController _monthlyChargesController =
      TextEditingController();
  final TextEditingController _monthlyPriceController = TextEditingController();
  final TextEditingController _priceRangeMinController =
      TextEditingController();
  final TextEditingController _priceRangeMaxController =
      TextEditingController();
  final TextEditingController _pricingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPlanPrices();
    _serviceType = widget.serviceData['serviceType'] ?? 'Other';
    selectedPlan = widget.serviceData['selectedPlan'];

    // Initialize controllers based on service type
    switch (_serviceType) {
      case 'Library':
        _seatingCapacityController.text =
            widget.serviceData['seatingCapacity']?.toString() ?? '';
        _monthlyChargesController.text =
            widget.serviceData['charges']?.toString() ?? '';
        break;
      case 'Café':
        _seatingCapacityController.text =
            widget.serviceData['seatingCapacity']?.toString() ?? '';
        _monthlyPriceController.text =
            widget.serviceData['monthlyPrice']?.toString() ?? '';
        break;
      case 'Mess':
        _seatingCapacityController.text =
            widget.serviceData['seatingCapacity']?.toString() ?? '';
        _monthlyPriceController.text =
            widget.serviceData['charges']?.toString() ?? '';
        break;
      case 'Other':
        _pricingController.text =
            widget.serviceData['pricing']?.toString() ?? '';
        break;
    }

    // Initialize common fields
    _serviceNameController.text = widget.serviceData['serviceName'] ?? '';
    _locationController.text = widget.serviceData['location'] ?? '';
    _descriptionController.text = widget.serviceData['description'] ?? '';
  }

  @override
  void dispose() {
    _seatingCapacityController.dispose();
    _monthlyChargesController.dispose();
    _monthlyPriceController.dispose();
    _priceRangeMinController.dispose();
    _priceRangeMaxController.dispose();
    _pricingController.dispose();
    _serviceNameController.dispose();
    _locationController.dispose();
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
        if (_planPrices.isNotEmpty && selectedPlan == null) {
          selectedPlan = _planPrices.keys.first;
        }
      });
    } catch (e) {
      setState(() {
        _isPlanPricesLoading = false;
        _planPricesError = e.toString();
      });
    }
  }

  Future<void> _updateServiceDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final plan = selectedPlan ?? widget.serviceData['selectedPlan'] ?? '1Day';
    Duration planDuration;
    switch (plan) {
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
    final DateTime now = DateTime.now();
    final expiryDate = now.add(planDuration);
    try {
      final Map<String, dynamic> data = {
        'serviceType': _serviceType,
        'serviceName': _serviceNameController.text,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'selectedPlan': plan,
        'createdAt': now.toIso8601String(),
        'expiryDate': expiryDate.toIso8601String(),
        'visibility': true,
      };

      // Add service-specific fields for editing
      if (_serviceType == 'Library') {
        data['seatingCapacity'] =
            int.tryParse(_seatingCapacityController.text) ?? 0;
        data['charges'] = _monthlyChargesController.text;
      } else if (_serviceType == 'Café') {
        data['priceRange'] = _monthlyPriceController.text;
      } else if (_serviceType == 'Mess') {
        data['seatingCapacity'] =
            int.tryParse(_seatingCapacityController.text) ?? 0;
        data['charges'] = _monthlyPriceController.text;
      } else if (_serviceType == 'Other') {
        data['pricing'] = _pricingController.text;
      }

      await FirebaseFirestore.instance
          .collection('service_listings')
          .doc(widget.serviceId)
          .update(data);

      // Invalidate service cache to ensure fresh data
      await CacheUtils.invalidateServiceCache();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Service details updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
              Expanded(
                child: Column(
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
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator:
            validator ??
            (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              if (keyboardType == TextInputType.number &&
                  int.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF4A9EFF), size: 20),
          prefixText: prefixText,
          prefixStyle: const TextStyle(color: Colors.white),
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

  Widget _buildServiceDetailsSection() {
    switch (_serviceType) {
      case 'Library':
        return _buildSectionCard(
          title: 'Library Details',
          subtitle: 'Enter library specific details',
          icon: Icons.local_library_rounded,
          children: [
            _buildTextField(
              controller: _seatingCapacityController,
              label: 'Seating Capacity',
              icon: Icons.chair_rounded,
              keyboardType: TextInputType.number,
            ),
            _buildTextField(
              controller: _monthlyChargesController,
              label: 'Monthly Charges',
              icon: Icons.currency_rupee_rounded,
              keyboardType: TextInputType.number,
              prefixText: '₹ ',
            ),
          ],
        );
      case 'Café':
        return _buildSectionCard(
          title: 'Café Details',
          subtitle: 'Enter café specific details',
          icon: Icons.local_cafe_rounded,
          children: [
            _buildTextField(
              controller: _monthlyPriceController,
              label: 'Price range per person',
              icon: Icons.currency_rupee_rounded,
              keyboardType: TextInputType.number,
              prefixText: '₹ ',
            ),
          ],
        );

      case 'Mess':
        return _buildSectionCard(
          title: 'Mess Details',
          subtitle: 'Enter mess specific details',
          icon: Icons.restaurant_rounded,
          children: [
            _buildTextField(
              controller: _seatingCapacityController,
              label: 'Seating Capacity',
              icon: Icons.chair_rounded,
              keyboardType: TextInputType.number,
            ),
            _buildTextField(
              controller: _monthlyPriceController,
              label: 'Monthly Price',
              icon: Icons.currency_rupee_rounded,
              keyboardType: TextInputType.number,
              prefixText: '₹ ',
            ),
          ],
        );

      case 'Other':
        return _buildSectionCard(
          title: 'Service Details',
          subtitle: 'Enter service specific details',
          icon: Icons.miscellaneous_services_rounded,
          children: [
            _buildTextField(
              controller: _pricingController,
              label: 'Pricing',
              icon: Icons.currency_rupee_rounded,
              keyboardType: TextInputType.number,
              prefixText: '₹ ',
            ),
          ],
        );

      default:
        return Container();
    }
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
          'Edit Service Details',
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
              // Service-specific fields
              _buildServiceDetailsSection(),

              // Payment Plan Section
              _buildPaymentPlanSection(),

              const SizedBox(height: 20),

              // Update Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateServiceDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A9EFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              strokeWidth: 2,
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Update Details',
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