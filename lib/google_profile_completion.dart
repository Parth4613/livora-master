import 'package:flutter/material.dart';

class GoogleProfileCompletionPage extends StatefulWidget {
  @override
  _GoogleProfileCompletionPageState createState() => _GoogleProfileCompletionPageState();
}

class _GoogleProfileCompletionPageState extends State<GoogleProfileCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = isDark ? const Color(0xFF2C3E50) : const Color(0xFF4A90E2);
    final Color cardColor = isDark ? const Color(0xFF23272A) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF23272A) : const Color(0xFFE0E0E0);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E3A8A);
    final Color subtitleColor = isDark ? Colors.white70 : Colors.black54;
    final Color shadowColor = isDark ? const Color(0xFF2C3E50).withOpacity(0.3) : const Color(0xFF4A90E2).withOpacity(0.3);
    final Color hintColor = isDark ? Colors.white38 : Colors.black38;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF181A20) : const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'Complete Profile',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              height: 140,
              child: Icon(
                Icons.person_outline,
                size: 90,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Let\'s get to know you!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please enter your full name and mobile number to complete your profile setup',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: subtitleColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(fontSize: 16, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Enter your full name',
                        hintStyle: TextStyle(color: hintColor),
                        prefixIcon: Icon(Icons.person, color: primaryColor),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Enter your full name' : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(fontSize: 16, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Enter your mobile number',
                        hintStyle: TextStyle(color: hintColor),
                        prefixIcon: Icon(Icons.phone, color: primaryColor),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Enter your mobile number' : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          setState(() => _isLoading = true);
                          await Future.delayed(const Duration(milliseconds: 500));
                          Navigator.of(context).pop({
                            'username': _nameController.text.trim(),
                            'phone': _phoneController.text.trim(),
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text(
                        'Complete Registration',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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