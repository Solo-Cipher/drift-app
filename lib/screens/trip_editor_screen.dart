import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/trip_data.dart';
import '../services/closure_checker.dart';
import '../widgets/location_autocomplete_field.dart';

class TripEditorScreen extends StatefulWidget {
  final TripData trip;
  const TripEditorScreen({super.key, required this.trip});

  @override
  State<TripEditorScreen> createState() => _TripEditorScreenState();
}

class _TripEditorScreenState extends State<TripEditorScreen> {
  late TripData _trip;
  late DateTime _startDate;
  late DateTime _endDate;
  // Track activity locations per day: dayIndex -> list of ActivityLocation?
  Map<int, List<ActivityLocation?>> _editorActivityLocations = {};
  // Notification count for badge
  List<ClosureNotification> _editorNotifications = [];

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _startDate = _trip.baseStartDate;
    _endDate = _startDate.add(Duration(days: _trip.totalDays - 1));
    // Initialize activity locations from existing trip data
    for (int i = 0; i < _trip.days.length; i++) {
      _editorActivityLocations[i] = List<ActivityLocation?>.from(_trip.days[i].activityLocations);
    }
    _editorNotifications = checkClosures(_trip);
  }

  String _formatDate(DateTime d) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      helpText: 'Select trip start date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(primary: const Color(0xFF6C63FF)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (picked.isAfter(_endDate)) {
        _endDate = picked.add(const Duration(days: 1));
      }
      _applyNewRange(picked, _endDate);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate.add(const Duration(days: 1)),
      lastDate: DateTime(2030, 12, 31),
      helpText: 'Select trip end date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(primary: const Color(0xFF6C63FF)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _applyNewRange(_startDate, picked);
    }
  }

  void _applyNewRange(DateTime newStart, DateTime newEnd) {
    final newTotalDays = newEnd.difference(newStart).inDays + 1;
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final newStartStr = '${months[newStart.month - 1]} ${newStart.day}, ${newStart.year}';
    final newEndStr = '${months[newEnd.month - 1]} ${newEnd.day}, ${newEnd.year}';

    List<TripDay> newDays = [];
    for (int i = 0; i < newTotalDays; i++) {
      final dayDate = newStart.add(Duration(days: i));
      final dateStr = '${months[dayDate.month - 1]} ${dayDate.day}';
      if (i < _trip.days.length) {
        newDays.add(_trip.days[i].copyWith(
          day: i + 1,
          date: dateStr,
        ));
      } else {
        newDays.add(TripDay(
          day: i + 1,
          date: dateStr,
          location: 'New destination',
          country: 'Vietnam',
          title: 'Day ${i + 1}',
          description: 'Add your plans for this day',
          activities: [],
          icon: Icons.explore,
          color: const Color(0xFF6C63FF),
        ));
      }
    }

    setState(() {
      _startDate = newStart;
      _endDate = newEnd;
      _trip = _trip.copyWith(
        startDate: newStartStr,
        endDate: newEndStr,
        totalDays: newTotalDays,
        days: newDays,
        baseStartDate: newStart,
      );
      // Reinit activity locations for new days
      _editorActivityLocations.clear();
      for (int i = 0; i < newDays.length; i++) {
        _editorActivityLocations[i] = List<ActivityLocation?>.from(newDays[i].activityLocations);
      }
      _editorNotifications = checkClosures(_trip);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Trip: ${_formatDate(newStart)} — ${_formatDate(newEnd)} ($newTotalDays days)'),
        backgroundColor: const Color(0xFF00BFA6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text('Edit Trip', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white, elevation: 0, scrolledUnderElevation: 0, surfaceTintColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _trip),
            child: Text('Save', style: GoogleFonts.inter(color: const Color(0xFF6C63FF), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Date range card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calendar_month, size: 20, color: Color(0xFF6C63FF)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Trip Dates', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
                          Text('Change start or end date — all days update', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF888888))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDateRow(label: 'Start', date: _formatDate(_startDate), icon: Icons.flight_takeoff, onTap: _pickStartDate),
                const SizedBox(height: 10),
                _buildDateRow(label: 'End', date: _formatDate(_endDate), icon: Icons.flight_land, onTap: _pickEndDate),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timelapse, size: 14, color: Color(0xFF6C63FF)),
                      const SizedBox(width: 6),
                      Text('${_trip.totalDays} days total', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6C63FF))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Day editor cards
          ..._trip.days.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEEEEEE))),
              child: ExpansionTile(
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: day.color, shape: BoxShape.circle),
                  child: Center(child: Text('${day.day}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
                ),
                title: Text(day.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                subtitle: Text('${day.date} · ${day.location}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF888888))),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEditField('Title', day.title, (v) => _updateDay(index, day.copyWith(title: v))),
                        _buildEditField('Location', day.location, (v) => _updateDay(index, day.copyWith(location: v))),
                        _buildEditField('Description', day.description, (v) => _updateDay(index, day.copyWith(description: v)), maxLines: 2),

                        const SizedBox(height: 12),
                        // Transportation section
                        Row(
                          children: [
                            const Icon(Icons.directions, size: 16, color: Color(0xFF6C63FF)),
                            const SizedBox(width: 6),
                            Text('Transportation', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF6C63FF))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildTransportPicker(index, day),
                        if (day.transportDuration != null || day.transportCost != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (day.transportDuration != null)
                                Expanded(child: _buildEditField('Duration', day.transportDuration!, (v) => _updateDay(index, day.copyWith(transportDuration: v)))),
                              if (day.transportDuration != null && day.transportCost != null) const SizedBox(width: 8),
                              if (day.transportCost != null)
                                Expanded(child: _buildEditField('Cost', day.transportCost!, (v) => _updateDay(index, day.copyWith(transportCost: v)))),
                            ],
                          ),
                        ],

                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),

                        // Activities section
                        Row(
                          children: [
                            const Icon(Icons.local_activity, size: 16, color: Color(0xFF00BFA6)),
                            const SizedBox(width: 6),
                            Text('Activities', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF00BFA6))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...day.activities.asMap().entries.map((actEntry) {
                          final locs = _editorActivityLocations[index] ?? [];
                          final currentLoc = actEntry.key < locs.length ? locs[actEntry.key] : null;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: LocationAutocompleteField(
                                    initialValue: actEntry.value,
                                    onLocationSelected: (loc) {
                                      setState(() {
                                        _editorActivityLocations[index] = _editorActivityLocations[index] ?? [];
                                        while (_editorActivityLocations[index]!.length <= actEntry.key) {
                                          _editorActivityLocations[index]!.add(null);
                                        }
                                        _editorActivityLocations[index]![actEntry.key] = loc;
                                      });
                                    },
                                    onChanged: (v) => _updateActivity(index, actEntry.key, v),
                                    currentLocation: currentLoc,
                                    dense: true,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16, color: Color(0xFFCCCCCC)),
                                  onPressed: () => _removeActivity(index, actEntry.key),
                                ),
                              ],
                            ),
                          );
                        }),
                        TextButton.icon(
                          onPressed: () => _addActivity(index),
                          icon: const Icon(Icons.add, size: 16, color: Color(0xFF00BFA6)),
                          label: Text('Add activity', style: GoogleFonts.inter(color: const Color(0xFF00BFA6), fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTransportPicker(int dayIndex, TripDay day) {
    return Row(
      children: [
        // Arrival transport
        Expanded(
          child: DropdownButtonFormField<TransportMode?>(
            value: day.arrivalTransport,
            decoration: InputDecoration(
              labelText: 'Arrival',
              labelStyle: GoogleFonts.inter(fontSize: 12),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('—')),
              ...TransportMode.values.map((m) => DropdownMenuItem(
                value: m,
                child: Row(
                  children: [
                    Icon(getTransportIcon(m), size: 14, color: getTransportColor(m)),
                    const SizedBox(width: 6),
                    Text(getTransportLabel(m), style: GoogleFonts.inter(fontSize: 12)),
                  ],
                ),
              )),
            ],
            onChanged: (v) => _updateDay(dayIndex, day.copyWith(arrivalTransport: v)),
          ),
        ),
        const SizedBox(width: 8),
        // Departure transport
        Expanded(
          child: DropdownButtonFormField<TransportMode?>(
            value: day.departureTransport,
            decoration: InputDecoration(
              labelText: 'Departure',
              labelStyle: GoogleFonts.inter(fontSize: 12),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('—')),
              ...TransportMode.values.map((m) => DropdownMenuItem(
                value: m,
                child: Row(
                  children: [
                    Icon(getTransportIcon(m), size: 14, color: getTransportColor(m)),
                    const SizedBox(width: 6),
                    Text(getTransportLabel(m), style: GoogleFonts.inter(fontSize: 12)),
                  ],
                ),
              )),
            ],
            onChanged: (v) => _updateDay(dayIndex, day.copyWith(departureTransport: v)),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRow({required String label, required String date, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FE),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF6C63FF)),
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF888888))),
            const SizedBox(width: 8),
            Expanded(child: Text(date, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E)))),
            const Icon(Icons.edit_calendar, size: 16, color: Color(0xFF6C63FF)),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(String label, String value, ValueChanged<String> onChanged, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF666666))),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: value,
            maxLines: maxLines,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6C63FF))),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _updateDay(int index, TripDay newDay) {
    setState(() {
      final days = List<TripDay>.from(_trip.days);
      // Merge in the editor's activity locations
      final locs = _editorActivityLocations[index];
      if (locs != null) {
        days[index] = newDay.copyWith(activityLocations: locs);
      } else {
        days[index] = newDay;
      }
      _trip = _trip.copyWith(days: days);
      _editorNotifications = checkClosures(_trip);
    });
  }

  void _updateActivity(int dayIndex, int activityIndex, String value) {
    setState(() {
      final days = List<TripDay>.from(_trip.days);
      final activities = List<String>.from(days[dayIndex].activities);
      activities[activityIndex] = value;
      days[dayIndex] = days[dayIndex].copyWith(activities: activities);
      _trip = _trip.copyWith(days: days);
    });
  }

  void _addActivity(int dayIndex) {
    setState(() {
      final days = List<TripDay>.from(_trip.days);
      final activities = List<String>.from(days[dayIndex].activities);
      activities.add('New activity');
      days[dayIndex] = days[dayIndex].copyWith(activities: activities);
      _trip = _trip.copyWith(days: days);
      // Add null location entry
      _editorActivityLocations[dayIndex] = _editorActivityLocations[dayIndex] ?? [];
      _editorActivityLocations[dayIndex]!.add(null);
    });
  }

  void _removeActivity(int dayIndex, int activityIndex) {
    setState(() {
      final days = List<TripDay>.from(_trip.days);
      final activities = List<String>.from(days[dayIndex].activities);
      activities.removeAt(activityIndex);
      days[dayIndex] = days[dayIndex].copyWith(activities: activities);
      _trip = _trip.copyWith(days: days);
      // Remove location entry
      _editorActivityLocations[dayIndex]?.removeAt(activityIndex);
      _editorNotifications = checkClosures(_trip);
    });
  }
}
