import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/maptiler_autocomplete.dart';
import '../theme.dart';

class LocationAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final Function(AutocompleteResult)? onLocationSelected;
  final String? initialValue;
  final Function(bool)? onFocusChanged;

  const LocationAutocompleteField({
    Key? key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.onLocationSelected,
    this.initialValue,
    this.onFocusChanged,
  }) : super(key: key);

  @override
  State<LocationAutocompleteField> createState() => _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  final MapTilerAutocompleteService _autocompleteService = MapTilerAutocompleteService();
  final FocusNode _focusNode = FocusNode();
  
  List<AutocompleteResult> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  String _errorMessage = '';
  
  // Debounce timer for search
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    
    // Set initial value if provided
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      widget.controller.text = widget.initialValue!;
    }
  }

  void _startSessionIfNeeded() {
    // Start a new session if the field is empty and gets focus
    if (_focusNode.hasFocus && widget.controller.text.isEmpty) {
      _autocompleteService.startNewSession();
    }
  }

  void _resetSession() {
    _autocompleteService.startNewSession();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _showSuggestions = _focusNode.hasFocus && _suggestions.isNotEmpty;
    });
    widget.onFocusChanged?.call(_focusNode.hasFocus);
    _startSessionIfNeeded();
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Cancel previous timer
      _debounceTimer?.cancel();
      
      // Set new timer for debouncing
      _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
        final results = await _autocompleteService.searchPlaces(query);
        
        if (mounted) {
          setState(() {
            _suggestions = results;
            _showSuggestions = _focusNode.hasFocus && results.isNotEmpty;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load suggestions: $e';
          _isLoading = false;
          _suggestions = [];
        });
      }
    }
  }

  void _onSuggestionSelected(AutocompleteResult result) {
    widget.controller.text = result.formattedAddress;
    widget.onLocationSelected?.call(result);
    
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
    });
    _focusNode.unfocus();
    _resetSession(); // Reset session after selection
  }

  void _onTextChanged(String value) {
    if (value.isEmpty) {
      _resetSession(); // Reset session if cleared
    }
    _searchPlaces(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main text field
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF23262F)
                : const Color.fromARGB(255, 226, 227, 231),
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
            controller: widget.controller,
            focusNode: _focusNode,
            maxLines: widget.maxLines,
            onChanged: _onTextChanged,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              prefixIcon: Icon(widget.icon, color: BuddyTheme.primaryColor),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.transparent,
            ),
          ),
        ),
        
        // Error message
        if (_errorMessage.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
        
        // Suggestions dropdown
        if (_showSuggestions && (_suggestions.isNotEmpty || widget.controller.text.isNotEmpty)) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF23262F)
                  : Colors.white,
              borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: (_suggestions.isNotEmpty ? 1 : 0) + _suggestions.length,
              itemBuilder: (context, index) {
                // First suggestion: user-typed text
                if (index == 0 && widget.controller.text.isNotEmpty) {
                  final typedText = widget.controller.text;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        widget.controller.text = typedText;
                        setState(() {
                          _showSuggestions = false;
                          _suggestions = [];
                        });
                        _focusNode.unfocus();
                        _resetSession();
                        if (widget.onLocationSelected != null) {
                          widget.onLocationSelected!(
                            AutocompleteResult(
                              id: '',
                              name: typedText,
                              address: '',
                              city: '',
                              state: '',
                              country: '',
                              postcode: '',
                              formattedAddress: typedText,
                              latitude: null,
                              longitude: null,
                              type: '',
                              relevance: 1.0,
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.edit_location_alt, color: BuddyTheme.primaryColor, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Use "$typedText"',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                // MapTiler suggestions
                final suggestion = _suggestions[index - 1 + (widget.controller.text.isNotEmpty ? 0 : 1)];
                final displayText = suggestion.formattedAddress.isNotEmpty
                    ? suggestion.formattedAddress
                    : (suggestion.name.isNotEmpty
                        ? suggestion.name
                        : (suggestion.address.isNotEmpty
                            ? suggestion.address
                            : 'Unknown place'));
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onSuggestionSelected(suggestion),
                    borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: BuddyTheme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  displayText,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (suggestion.formattedAddress.isNotEmpty && 
                              suggestion.formattedAddress != suggestion.name && suggestion.formattedAddress != displayText) ...[
                            const SizedBox(height: 4),
                            Text(
                              suggestion.formattedAddress,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
} 