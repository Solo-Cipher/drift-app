import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/location_service.dart';
import '../models/trip_data.dart';

/// A text field with location autocomplete dropdown.
/// When a location is selected, it returns the ActivityLocation via onLocationSelected.
class LocationAutocompleteField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final ValueChanged<ActivityLocation?> onLocationSelected;
  final ActivityLocation? currentLocation;
  final String? labelText;
  final bool dense;

  const LocationAutocompleteField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    required this.onLocationSelected,
    this.currentLocation,
    this.labelText,
    this.dense = false,
  });

  @override
  State<LocationAutocompleteField> createState() => _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  late TextEditingController _controller;
  List<ResolvedLocation> _suggestions = [];
  bool _isSearching = false;
  Timer? _debounce;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Delay removal so tap on overlay items works
      Future.delayed(const Duration(milliseconds: 200), () {
        _removeOverlay();
      });
    }
  }

  void _onTextChanged(String value) {
    widget.onChanged(value);
    _debounce?.cancel();
    _removeOverlay();

    if (value.length < 3) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await searchLocations(value, limit: 5);
      if (mounted && _controller.text == value) {
        setState(() {
          _suggestions = results;
          _isSearching = false;
        });
        if (results.isNotEmpty && _focusNode.hasFocus) {
          _showOverlay();
        }
      }
    });
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
                itemBuilder: (context, index) {
                  final loc = _suggestions[index];
                  return InkWell(
                    onTap: () => _selectLocation(loc),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Color(0xFF6C63FF)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.name,
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  loc.displayName,
                                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF888888)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectLocation(ResolvedLocation loc) {
    _controller.text = loc.name;
    widget.onChanged(loc.name);
    widget.onLocationSelected(ActivityLocation(name: loc.name, lat: loc.lat, lng: loc.lng));
    _removeOverlay();
    setState(() => _suggestions = []);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: GoogleFonts.inter(fontSize: widget.dense ? 13 : 14),
        decoration: InputDecoration(
          labelText: widget.labelText,
          labelStyle: GoogleFonts.inter(fontSize: 12),
          isDense: widget.dense,
          contentPadding: widget.dense
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6C63FF))),
          suffixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C63FF))),
                )
              : widget.currentLocation != null
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.location_on, size: 16, color: Color(0xFF00BFA6)),
                    )
                  : null,
        ),
        onChanged: _onTextChanged,
      ),
    );
  }
}
