import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/cache_utils.dart';

class EditFlatmatePage extends StatefulWidget {
  final String flatmateId;
  final Map<String, dynamic> flatmateData;

  const EditFlatmatePage({
    Key? key,
    required this.flatmateId,
    required this.flatmateData,
  }) : super(key: key);

  @override
  State<EditFlatmatePage> createState() => _EditFlatmatePageState();
}

class _EditFlatmatePageState extends State<EditFlatmatePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  DateTime? _selectedDate;

  // Payment Plan
  String? selectedPlan;
  Map<String, Map<String, double>> _planPrices = {};
  bool _isPlanPricesLoading = true;
  String? _planPricesError;

  // Form controllers
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _minBudgetController = TextEditingController();
  final TextEditingController _maxBudgetController = TextEditingController();
  final TextEditingController _moveInDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPlanPrices();
    // Initialize controllers with existing data
    _locationController.text = widget.flatmateData['location'] ?? '';
    _minBudgetController.text =
        widget.flatmateData['minBudget']?.toString() ?? '';
    _maxBudgetController.text =
        widget.flatmateData['maxBudget']?.toString() ?? '';
    selectedPlan = widget.flatmateData['selectedPlan'];

    if (widget.flatmateData['moveInDate'] != null) {
      if (widget.flatmateData['moveInDate'] is Timestamp) {
        _selectedDate =
            (widget.flatmateData['moveInDate'] as Timestamp).toDate();
      } else if (widget.flatmateData['moveInDate'] is String) {
        _selectedDate = DateTime.tryParse(widget.flatmateData['moveInDate']);
      }
      if (_selectedDate != null) {
        _moveInDateController.text = DateFormat(
          'dd/MM/yyyy',
        ).format(_selectedDate!);
      }
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
              .doc('room_request')
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

        // Set initial selected plan if none is selected
        if (_planPrices.isNotEmpty && selectedPlan == null) {
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

  @override
  void dispose() {
    _locationController.dispose();
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    _moveInDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
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
        _selectedDate = picked;
        _moveInDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _updateFlatmateDetails() async {
    if (!_formKey.currentState!.validate()) return;

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

    setState(() {
      _isLoading = true;
    });

    // Calculate expiry date based on selected plan
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
    final now = DateTime.now();
    final expiryDate = now.add(Duration(days: days));

    try {      final data = {
        'location': _locationController.text,
        'minBudget': int.tryParse(_minBudgetController.text) ?? 0,
        'maxBudget': int.tryParse(_maxBudgetController.text) ?? 0,
        'moveInDate':
            _selectedDate != null ? _selectedDate!.toIso8601String() : null,
        'selectedPlan': selectedPlan,
        'createdAt': now.toIso8601String(),
        'expiryDate': expiryDate.toIso8601String(),
        'visibility': true,  // Set visibility back to true when updating
      };

      await FirebaseFirestore.instance
          .collection('roomRequests')
          .doc(widget.flatmateId)
          .update(data);

      // Invalidate flatmate cache to ensure fresh data
      await CacheUtils.invalidateFlatmateCache();

      if (mounted) {
        Navigator.pop(context); // Return to previous screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Details updated successfully'),
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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
    int maxLines = 1,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    String? prefixText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        enabled: true,  // Ensure the field is always enabled
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
          prefixText: prefixText,
          prefixStyle: const TextStyle(color: Colors.white),
          suffixIcon:
              readOnly
                  ? Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  )
                  : null,
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
          'Edit Flatmate Details',
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
              // Location Details Section
              _buildSectionCard(
                title: 'Location Preferences',
                subtitle: 'Where you want to live',
                icon: Icons.location_on_rounded,
                children: [
                  _buildTextField(
                    controller: _locationController,
                    label: 'Preferred Location(s)',
                    icon: Icons.location_on_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter preferred location(s)';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              // Budget Details Section (Fixed Layout)
              _buildSectionCard(
                title: 'Budget Range',
                subtitle: 'Your budget preferences\n(₹ per month)',
                icon: Icons.currency_rupee_rounded,
                children: [
                  _buildTextField(
                    controller: _minBudgetController,
                    label: 'Minimum Budget',
                    icon: Icons.currency_rupee_rounded,
                    keyboardType: TextInputType.number,
                    prefixText: '₹ ',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter minimum budget';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter valid amount';
                      }
                      return null;
                    },
                  ),
                  _buildTextField(
                    controller: _maxBudgetController,
                    label: 'Maximum Budget',
                    icon: Icons.currency_rupee_rounded,
                    keyboardType: TextInputType.number,
                    prefixText: '₹ ',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter maximum budget';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter valid amount';
                      }
                      final min = int.tryParse(_minBudgetController.text) ?? 0;
                      final max = int.tryParse(value) ?? 0;
                      if (max < min) {
                        return 'Maximum should be greater than minimum';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              // Move-in Details Section
              _buildSectionCard(
                title: 'Move-in Details',
                subtitle: 'When you plan to move in',
                icon: Icons.date_range_rounded,
                children: [
                  _buildTextField(
                    controller: _moveInDateController,
                    label: 'Move-in Date',
                    icon: Icons.date_range_rounded,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select move-in date';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              // Payment Plan Section
              _buildPaymentPlanSection(),

              const SizedBox(height: 20),

              // Update Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateFlatmateDetails,
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