import 'package:flutter/material.dart';
import '../theme.dart';

enum ValidationState {
  none,
  success,
  error,
  warning,
  info,
}

class ValidationTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValidationState initialValidationState;
  final String? validationMessage;
  final bool showValidationIcon;
  final bool autoValidate;

  const ValidationTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.onTap,
    this.onChanged,
    this.initialValidationState = ValidationState.none,
    this.validationMessage,
    this.showValidationIcon = true,
    this.autoValidate = false,
  }) : super(key: key);

  @override
  State<ValidationTextField> createState() => _ValidationTextFieldState();
}

class _ValidationTextFieldState extends State<ValidationTextField>
    with SingleTickerProviderStateMixin {
  late ValidationState _validationState;
  String? _validationMessage;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _validationState = widget.initialValidationState;
    _validationMessage = widget.validationMessage;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _colorAnimation = ColorTween(
      begin: BuddyTheme.borderColor,
      end: _getValidationColor(_validationState),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getValidationColor(ValidationState state) {
    switch (state) {
      case ValidationState.success:
        return BuddyTheme.validationSuccessColor;
      case ValidationState.error:
        return BuddyTheme.validationErrorColor;
      case ValidationState.warning:
        return BuddyTheme.validationWarningColor;
      case ValidationState.info:
        return BuddyTheme.validationInfoColor;
      case ValidationState.none:
        return BuddyTheme.borderColor;
    }
  }

  Color _getValidationBgColor(ValidationState state) {
    switch (state) {
      case ValidationState.success:
        return BuddyTheme.validationSuccessBgColor;
      case ValidationState.error:
        return BuddyTheme.validationErrorBgColor;
      case ValidationState.warning:
        return BuddyTheme.validationWarningBgColor;
      case ValidationState.info:
        return BuddyTheme.validationInfoBgColor;
      case ValidationState.none:
        return Colors.transparent;
    }
  }

  Color _getValidationTextColor(ValidationState state) {
    switch (state) {
      case ValidationState.success:
        return BuddyTheme.validationSuccessTextColor;
      case ValidationState.error:
        return BuddyTheme.validationErrorTextColor;
      case ValidationState.warning:
        return BuddyTheme.validationWarningTextColor;
      case ValidationState.info:
        return BuddyTheme.validationInfoTextColor;
      case ValidationState.none:
        return BuddyTheme.textSecondaryColor;
    }
  }

  Widget _getValidationIcon(ValidationState state) {
    if (!widget.showValidationIcon || state == ValidationState.none) {
      return const SizedBox.shrink();
    }

    IconData iconData;
    switch (state) {
      case ValidationState.success:
        iconData = Icons.check_circle;
        break;
      case ValidationState.error:
        iconData = Icons.error;
        break;
      case ValidationState.warning:
        iconData = Icons.warning;
        break;
      case ValidationState.info:
        iconData = Icons.info;
        break;
      case ValidationState.none:
        return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            iconData,
            color: _getValidationColor(state),
            size: 20,
          ),
        );
      },
    );
  }

  void _updateValidationState(ValidationState state, [String? message]) {
    if (mounted) {
      setState(() {
        _validationState = state;
        _validationMessage = message;
      });
      
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
  }

  String? _validateField(String? value) {
    if (widget.validator != null) {
      return widget.validator!(value);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: _getValidationBgColor(_validationState),
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            border: Border.all(
              color: _getValidationColor(_validationState),
              width: _validationState != ValidationState.none ? 2.0 : 1.0,
            ),
          ),
          child: TextFormField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            enabled: widget.enabled,
            onTap: widget.onTap,
            onChanged: (value) {
              widget.onChanged?.call(value);
              
              if (widget.autoValidate) {
                final error = _validateField(value);
                if (error != null) {
                  _updateValidationState(ValidationState.error, error);
                } else if (value.isNotEmpty) {
                  _updateValidationState(ValidationState.success);
                } else {
                  _updateValidationState(ValidationState.none);
                }
              }
            },
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.suffixIcon != null) widget.suffixIcon!,
                  if (widget.showValidationIcon) _getValidationIcon(_validationState),
                ],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(BuddyTheme.spacingMd),
              labelStyle: TextStyle(
                color: _getValidationTextColor(_validationState),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        if (_validationMessage != null && _validationState != ValidationState.none)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(top: BuddyTheme.spacingXs),
            padding: const EdgeInsets.symmetric(
              horizontal: BuddyTheme.spacingSm,
              vertical: BuddyTheme.spacingXs,
            ),
            decoration: BoxDecoration(
              color: _getValidationBgColor(_validationState),
              borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
            ),
            child: Row(
              children: [
                Icon(
                  _getValidationIcon(_validationState).key == null 
                      ? Icons.info 
                      : Icons.error,
                  size: 16,
                  color: _getValidationTextColor(_validationState),
                ),
                const SizedBox(width: BuddyTheme.spacingXs),
                Expanded(
                  child: Text(
                    _validationMessage!,
                    style: TextStyle(
                      fontSize: BuddyTheme.fontSizeXs,
                      color: _getValidationTextColor(_validationState),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class ValidationDropdown<T> extends StatefulWidget {
  final String label;
  final String? hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemToString;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;
  final Widget? prefixIcon;
  final ValidationState initialValidationState;
  final String? validationMessage;
  final bool showValidationIcon;

  const ValidationDropdown({
    Key? key,
    required this.label,
    this.hint,
    required this.value,
    required this.items,
    required this.itemToString,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
    this.initialValidationState = ValidationState.none,
    this.validationMessage,
    this.showValidationIcon = true,
  }) : super(key: key);

  @override
  State<ValidationDropdown<T>> createState() => _ValidationDropdownState<T>();
}

class _ValidationDropdownState<T> extends State<ValidationDropdown<T>>
    with SingleTickerProviderStateMixin {
  late ValidationState _validationState;
  String? _validationMessage;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _validationState = widget.initialValidationState;
    _validationMessage = widget.validationMessage;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getValidationColor(ValidationState state) {
    switch (state) {
      case ValidationState.success:
        return BuddyTheme.validationSuccessColor;
      case ValidationState.error:
        return BuddyTheme.validationErrorColor;
      case ValidationState.warning:
        return BuddyTheme.validationWarningColor;
      case ValidationState.info:
        return BuddyTheme.validationInfoColor;
      case ValidationState.none:
        return BuddyTheme.borderColor;
    }
  }

  Color _getValidationBgColor(ValidationState state) {
    switch (state) {
      case ValidationState.success:
        return BuddyTheme.validationSuccessBgColor;
      case ValidationState.error:
        return BuddyTheme.validationErrorBgColor;
      case ValidationState.warning:
        return BuddyTheme.validationWarningBgColor;
      case ValidationState.info:
        return BuddyTheme.validationInfoBgColor;
      case ValidationState.none:
        return Colors.transparent;
    }
  }

  Color _getValidationTextColor(ValidationState state) {
    switch (state) {
      case ValidationState.success:
        return BuddyTheme.validationSuccessTextColor;
      case ValidationState.error:
        return BuddyTheme.validationErrorTextColor;
      case ValidationState.warning:
        return BuddyTheme.validationWarningTextColor;
      case ValidationState.info:
        return BuddyTheme.validationInfoTextColor;
      case ValidationState.none:
        return BuddyTheme.textSecondaryColor;
    }
  }

  Widget _getValidationIcon(ValidationState state) {
    if (!widget.showValidationIcon || state == ValidationState.none) {
      return const SizedBox.shrink();
    }

    IconData iconData;
    switch (state) {
      case ValidationState.success:
        iconData = Icons.check_circle;
        break;
      case ValidationState.error:
        iconData = Icons.error;
        break;
      case ValidationState.warning:
        iconData = Icons.warning;
        break;
      case ValidationState.info:
        iconData = Icons.info;
        break;
      case ValidationState.none:
        return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            iconData,
            color: _getValidationColor(state),
            size: 20,
          ),
        );
      },
    );
  }

  void _updateValidationState(ValidationState state, [String? message]) {
    if (mounted) {
      setState(() {
        _validationState = state;
        _validationMessage = message;
      });
      
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: _getValidationBgColor(_validationState),
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            border: Border.all(
              color: _getValidationColor(_validationState),
              width: _validationState != ValidationState.none ? 2.0 : 1.0,
            ),
          ),
          child: DropdownButtonFormField<T>(
            value: widget.value,
            items: widget.items.map((T item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(widget.itemToString(item)),
              );
            }).toList(),
            onChanged: (T? value) {
              widget.onChanged?.call(value);
              
              if (widget.validator != null) {
                final error = widget.validator!(value);
                if (error != null) {
                  _updateValidationState(ValidationState.error, error);
                } else if (value != null) {
                  _updateValidationState(ValidationState.success);
                } else {
                  _updateValidationState(ValidationState.none);
                }
              }
            },
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon,
              suffixIcon: _getValidationIcon(_validationState),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(BuddyTheme.spacingMd),
              labelStyle: TextStyle(
                color: _getValidationTextColor(_validationState),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        if (_validationMessage != null && _validationState != ValidationState.none)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(top: BuddyTheme.spacingXs),
            padding: const EdgeInsets.symmetric(
              horizontal: BuddyTheme.spacingSm,
              vertical: BuddyTheme.spacingXs,
            ),
            decoration: BoxDecoration(
              color: _getValidationBgColor(_validationState),
              borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
            ),
            child: Row(
              children: [
                Icon(
                  _getValidationIcon(_validationState).key == null 
                      ? Icons.info 
                      : Icons.error,
                  size: 16,
                  color: _getValidationTextColor(_validationState),
                ),
                const SizedBox(width: BuddyTheme.spacingXs),
                Expanded(
                  child: Text(
                    _validationMessage!,
                    style: TextStyle(
                      fontSize: BuddyTheme.fontSizeXs,
                      color: _getValidationTextColor(_validationState),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class ValidationSnackBar {
  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      ValidationState.success,
      Icons.check_circle,
    );
  }

  static void showError(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      ValidationState.error,
      Icons.error,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      ValidationState.warning,
      Icons.warning,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      ValidationState.info,
      Icons.info,
    );
  }

  static void _showSnackBar(
    BuildContext context,
    String message,
    ValidationState state,
    IconData icon,
  ) {
    Color backgroundColor;
    Color textColor;
    Color iconColor;

    switch (state) {
      case ValidationState.success:
        backgroundColor = BuddyTheme.validationSuccessColor;
        textColor = Colors.white;
        iconColor = Colors.white;
        break;
      case ValidationState.error:
        backgroundColor = BuddyTheme.validationErrorColor;
        textColor = Colors.white;
        iconColor = Colors.white;
        break;
      case ValidationState.warning:
        backgroundColor = BuddyTheme.validationWarningColor;
        textColor = Colors.black87;
        iconColor = Colors.black87;
        break;
      case ValidationState.info:
        backgroundColor = BuddyTheme.validationInfoColor;
        textColor = Colors.white;
        iconColor = Colors.white;
        break;
      case ValidationState.none:
        backgroundColor = BuddyTheme.validationNeutralColor;
        textColor = Colors.white;
        iconColor = Colors.white;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
            const SizedBox(width: BuddyTheme.spacingSm),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
        ),
        margin: const EdgeInsets.all(BuddyTheme.spacingMd),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: textColor,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

class ValidationProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<ValidationState> stepValidationStates;
  final Color? activeColor;
  final Color? inactiveColor;
  final double height;

  const ValidationProgressIndicator({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepValidationStates,
    this.activeColor,
    this.inactiveColor,
    this.height = 4.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(totalSteps, (index) {
            final isActive = index <= currentStep;
            final validationState = index < stepValidationStates.length 
                ? stepValidationStates[index] 
                : ValidationState.none;
            
            Color stepColor;
            if (isActive) {
              stepColor = activeColor ?? _getValidationColor(validationState);
            } else {
              stepColor = inactiveColor ?? BuddyTheme.borderColor;
            }

            return Expanded(
              child: Container(
                height: height,
                margin: EdgeInsets.only(
                  right: index < totalSteps - 1 ? 4.0 : 0.0,
                ),
                decoration: BoxDecoration(
                  color: stepColor,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: BuddyTheme.spacingSm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step ${currentStep + 1} of $totalSteps',
              style: TextStyle(
                fontSize: BuddyTheme.fontSizeSm,
                color: BuddyTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${((currentStep + 1) / totalSteps * 100).round()}% Complete',
              style: TextStyle(
                fontSize: BuddyTheme.fontSizeSm,
                color: BuddyTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getValidationColor(ValidationState state) {
    switch (state) {
      case ValidationState.success:
        return BuddyTheme.validationSuccessColor;
      case ValidationState.error:
        return BuddyTheme.validationErrorColor;
      case ValidationState.warning:
        return BuddyTheme.validationWarningColor;
      case ValidationState.info:
        return BuddyTheme.validationInfoColor;
      case ValidationState.none:
        return BuddyTheme.primaryColor;
    }
  }
}

class ValidationStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<ValidationState> stepValidationStates;
  final List<String> stepTitles;
  final Color? activeColor;
  final Color? inactiveColor;
  final double height;
  final bool showStepTitles;

  const ValidationStepIndicator({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepValidationStates,
    this.stepTitles = const [],
    this.activeColor,
    this.inactiveColor,
    this.height = 4.0,
    this.showStepTitles = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress bar
        Row(
          children: List.generate(totalSteps, (index) {
            final isActive = index <= currentStep;
            final validationState = index < stepValidationStates.length 
                ? stepValidationStates[index] 
                : ValidationState.none;
            
            Color stepColor;
            if (isActive) {
              stepColor = activeColor ?? _getValidationColor(validationState);
            } else {
              stepColor = inactiveColor ?? BuddyTheme.borderColor;
            }

            return Expanded(
              child: Container(
                height: height,
                margin: EdgeInsets.only(
                  right: index < totalSteps - 1 ? 4.0 : 0.0,
                ),
                decoration: BoxDecoration(
                  color: stepColor,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: BuddyTheme.spacingSm),
        
        // Step information
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step ${currentStep + 1} of $totalSteps',
              style: TextStyle(
                fontSize: BuddyTheme.fontSizeSm,
                color: BuddyTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${((currentStep + 1) / totalSteps * 100).round()}% Complete',
              style: TextStyle(
                fontSize: BuddyTheme.fontSizeSm,
                color: BuddyTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        // Step titles (optional)
        if (showStepTitles && stepTitles.isNotEmpty) ...[
          const SizedBox(height: BuddyTheme.spacingMd),
          Wrap(
            spacing: BuddyTheme.spacingSm,
            runSpacing: BuddyTheme.spacingXs,
            children: List.generate(totalSteps, (index) {
              final isActive = index <= currentStep;
              final validationState = index < stepValidationStates.length 
                  ? stepValidationStates[index] 
                  : ValidationState.none;
              final title = index < stepTitles.length ? stepTitles[index] : 'Step ${index + 1}';
              
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: BuddyTheme.spacingSm,
                  vertical: BuddyTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: isActive ? _getValidationBgColor(validationState) : Colors.transparent,
                  border: Border.all(
                    color: isActive ? _getValidationColor(validationState) : BuddyTheme.borderColor,
                    width: isActive ? 2.0 : 1.0,
                  ),
                  borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: BuddyTheme.fontSizeXs,
                    color: isActive ? _getValidationTextColor(validationState) : BuddyTheme.textSecondaryColor,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Color _getValidationColor(ValidationState state) {
    switch (state) {
      case ValidationState.success:
        return BuddyTheme.validationSuccessColor;
      case ValidationState.error:
        return BuddyTheme.validationErrorColor;
      case ValidationState.warning:
        return BuddyTheme.validationWarningColor;
      case ValidationState.info:
        return BuddyTheme.validationInfoColor;
      case ValidationState.none:
        return BuddyTheme.primaryColor;
    }
  }

  Color _getValidationBgColor(ValidationState state) {
    switch (state) {
      case ValidationState.success:
        return BuddyTheme.validationSuccessBgColor;
      case ValidationState.error:
        return BuddyTheme.validationErrorBgColor;
      case ValidationState.warning:
        return BuddyTheme.validationWarningBgColor;
      case ValidationState.info:
        return BuddyTheme.validationInfoBgColor;
      case ValidationState.none:
        return Colors.transparent;
    }
  }

  Color _getValidationTextColor(ValidationState state) {
    switch (state) {
      case ValidationState.success:
        return BuddyTheme.validationSuccessTextColor;
      case ValidationState.error:
        return BuddyTheme.validationErrorTextColor;
      case ValidationState.warning:
        return BuddyTheme.validationWarningTextColor;
      case ValidationState.info:
        return BuddyTheme.validationInfoTextColor;
      case ValidationState.none:
        return BuddyTheme.primaryColor;
    }
  }
}

class ValidationFieldGroup extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final ValidationState validationState;
  final String? validationMessage;
  final EdgeInsetsGeometry? padding;

  const ValidationFieldGroup({
    Key? key,
    required this.title,
    this.subtitle,
    required this.children,
    this.validationState = ValidationState.none,
    this.validationMessage,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(BuddyTheme.spacingMd),
      decoration: BoxDecoration(
        color: _getValidationBgColor(validationState),
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
        border: Border.all(
          color: _getValidationColor(validationState),
          width: validationState != ValidationState.none ? 2.0 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getValidationIcon(validationState),
                color: _getValidationColor(validationState),
                size: 20,
              ),
              const SizedBox(width: BuddyTheme.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: BuddyTheme.fontSizeMd,
                        fontWeight: FontWeight.w600,
                        color: _getValidationTextColor(validationState),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: BuddyTheme.fontSizeSm,
                          color: BuddyTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (validationMessage != null && validationState != ValidationState.none) ...[
            const SizedBox(height: BuddyTheme.spacingSm),
            Container(
              padding: const EdgeInsets.all(BuddyTheme.spacingSm),
              decoration: BoxDecoration(
                color: _getValidationColor(validationState).withOpacity(0.1),
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusSm),
              ),
              child: Text(
                validationMessage!,
                style: TextStyle(
                  fontSize: BuddyTheme.fontSizeSm,
                  color: _getValidationTextColor(validationState),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: BuddyTheme.spacingMd),
          ...children,
        ],
      ),
    );
  }

  Color _getValidationColor(ValidationState state) {
    switch (state) {
      case ValidationState.success:
        return BuddyTheme.validationSuccessColor;
      case ValidationState.error:
        return BuddyTheme.validationErrorColor;
      case ValidationState.warning:
        return BuddyTheme.validationWarningColor;
      case ValidationState.info:
        return BuddyTheme.validationInfoColor;
      case ValidationState.none:
        return BuddyTheme.borderColor;
    }
  }

  Color _getValidationBgColor(ValidationState state) {
    switch (state) {
      case ValidationState.success:
        return BuddyTheme.validationSuccessBgColor;
      case ValidationState.error:
        return BuddyTheme.validationErrorBgColor;
      case ValidationState.warning:
        return BuddyTheme.validationWarningBgColor;
      case ValidationState.info:
        return BuddyTheme.validationInfoBgColor;
      case ValidationState.none:
        return Colors.transparent;
    }
  }

  Color _getValidationTextColor(ValidationState state) {
    switch (state) {
      case ValidationState.success:
        return BuddyTheme.validationSuccessTextColor;
      case ValidationState.error:
        return BuddyTheme.validationErrorTextColor;
      case ValidationState.warning:
        return BuddyTheme.validationWarningTextColor;
      case ValidationState.info:
        return BuddyTheme.validationInfoTextColor;
      case ValidationState.none:
        return BuddyTheme.textPrimaryColor;
    }
  }

  IconData _getValidationIcon(ValidationState state) {
    switch (state) {
      case ValidationState.success:
        return Icons.check_circle;
      case ValidationState.error:
        return Icons.error;
      case ValidationState.warning:
        return Icons.warning;
      case ValidationState.info:
        return Icons.info;
      case ValidationState.none:
        return Icons.article;
    }
  }
} 