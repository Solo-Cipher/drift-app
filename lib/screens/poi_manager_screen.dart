import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/poi_configs.dart';
import '../models/trip_data.dart';

/// Screen for managing Points of Interest for a specific day
class PoiManagerScreen extends StatefulWidget {
  final TripData trip;
  final int dayNumber;
  final ValueChanged<TripData> onSave;

  const PoiManagerScreen({
    super.key,
    required this.trip,
    required this.dayNumber,
    required this.onSave,
  });

  @override
  State<PoiManagerScreen> createState() => _PoiManagerScreenState();
}

class _PoiManagerScreenState extends State<PoiManagerScreen> {
  late List<TripPoiEntry> _dayPois;
  final _searchController = TextEditingController();
  List<Poi> _searchResults = [];
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _dayPois = widget.trip.tripPois
        .where((p) => p.dayNumber == widget.dayNumber)
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = PoiConfigs.search(query);
        // Filter to cities in the itinerary
        final tripCities = widget.trip.days.map((d) => d.location.toLowerCase()).toSet();
        _searchResults = _searchResults.where((p) => tripCities.contains(p.city.toLowerCase())).toList();
      }
    });
  }

  void _addPoi(Poi poi) {
    final entry = TripPoiEntry(
      id: 'poi_${poi.id}_${widget.dayNumber}_${DateTime.now().millisecondsSinceEpoch}',
      poiId: poi.id,
      name: poi.name,
      category: poi.category,
      typicalPriceOmr: poi.typicalPriceOmr,
      dayNumber: widget.dayNumber,
      notes: poi.notes,
      bookingUrl: poi.bookingUrl,
      requiresBooking: poi.category == PoiCategory.tour || poi.typicalPriceOmr > 5,
    );
    setState(() {
      _dayPois.add(entry);
    });
    _save();
  }

  void _addCustomPoi(String name) {
    if (name.trim().isEmpty) return;
    final entry = TripPoiEntry(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      poiId: 'custom',
      name: name.trim(),
      category: PoiCategory.other,
      dayNumber: widget.dayNumber,
    );
    setState(() {
      _dayPois.add(entry);
    });
    _searchController.clear();
    _searchResults = [];
    _save();
  }

  void _removePoi(TripPoiEntry entry) {
    setState(() {
      _dayPois.removeWhere((p) => p.id == entry.id);
    });
    _save();
  }

  void _toggleDone(TripPoiEntry entry) {
    setState(() {
      entry.isDone = !entry.isDone;
    });
    _save();
  }

  void _save() {
    final otherPois = widget.trip.tripPois.where((p) => p.dayNumber != widget.dayNumber).toList();
    final updatedTrip = widget.trip.copyWith(tripPois: [...otherPois, ..._dayPois]);
    widget.onSave(updatedTrip);
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.trip.days[widget.dayNumber - 1];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Day ${widget.dayNumber} — Places to Visit', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            Text(day.location, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.add),
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchController.clear();
                _searchResults = [];
              }
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          if (_showSearch) ...[
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: _search,
                    decoration: InputDecoration(
                      hintText: 'Search museums, cafes, tours...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        onTap: () => _addCustomPoi(_searchController.text),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add_circle, color: Color(0xFF6C63FF), size: 20),
                              const SizedBox(width: 8),
                              Text('Add "${_searchController.text}" as custom place',
                                  style: GoogleFonts.inter(color: const Color(0xFF6C63FF), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_searchResults.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      margin: const EdgeInsets.only(top: 4),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (_, i) {
                          final poi = _searchResults[i];

                          // Already added?
                          final alreadyAdded = _dayPois.any((p) => p.poiId == poi.id);
                          if (alreadyAdded) return const SizedBox.shrink();

                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
                              child: Icon(_categoryIcon(poi.category), size: 14, color: const Color(0xFF6C63FF)),
                            ),
                            title: Text(poi.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Text('${poi.city} · ${poiCategoryLabel(poi.category)}${poi.typicalPriceOmr > 0 ? " · ${poi.typicalPriceOmr.toStringAsFixed(0)} OMR" : ""}',
                                style: const TextStyle(fontSize: 11)),
                            trailing: const Icon(Icons.add, size: 18),
                            onTap: () => _addPoi(poi),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],

          // POI list
          Expanded(
            child: _dayPois.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.place_outlined, size: 48, color: Color(0xFFCCCCCC)),
                        const SizedBox(height: 12),
                        Text('No places added yet', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF999999))),
                        const SizedBox(height: 8),
                        const Text('Tap + to add cafes, museums, tours...', style: TextStyle(fontSize: 12, color: Color(0xFFBBBBBB))),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _dayPois.length,
                    itemBuilder: (_, i) {
                      final entry = _dayPois[i];
                      final knownPoi = entry.poiId != 'custom' ? PoiConfigs.getById(entry.poiId) : null;
                      return Dismissible(
                        key: Key(entry.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: const Color(0xFFFF6B6B),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _removePoi(entry),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: entry.isDone ? const Color(0xFF00BFA6) : const Color(0xFFEEEEEE)),
                          ),
                          child: ListTile(
                            leading: GestureDetector(
                              onTap: () => _toggleDone(entry),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: entry.isDone ? const Color(0xFF00BFA6) : Colors.transparent,
                                  border: Border.all(color: entry.isDone ? const Color(0xFF00BFA6) : const Color(0xFFCCCCCC)),
                                ),
                                child: entry.isDone ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                              ),
                            ),
                            title: Text(
                              entry.name,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                decoration: entry.isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            subtitle: Text(
                              '${poiCategoryLabel(entry.category)}${entry.typicalPriceOmr > 0 ? " · ${entry.typicalPriceOmr.toStringAsFixed(0)} OMR" : ""}${entry.requiresBooking ? " · Booking required" : ""}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: knownPoi?.notes != null
                                ? Tooltip(message: knownPoi!.notes!, child: const Icon(Icons.info_outline, size: 16, color: Color(0xFF999999)))
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(PoiCategory c) {
    switch (c) {
      case PoiCategory.museum: return Icons.museum;
      case PoiCategory.restaurant: return Icons.restaurant;
      case PoiCategory.cafe: return Icons.local_cafe;
      case PoiCategory.shop: return Icons.shopping_bag;
      case PoiCategory.monument: return Icons.account_balance;
      case PoiCategory.tour: return Icons.tour;
      case PoiCategory.temple: return Icons.temple_buddhist;
      case PoiCategory.beach: return Icons.beach_access;
      case PoiCategory.market: return Icons.storefront;
      default: return Icons.place;
    }
  }
}
