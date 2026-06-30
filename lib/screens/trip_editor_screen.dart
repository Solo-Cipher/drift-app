import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/trip_data.dart';
import '../data/city_configs.dart';
import '../data/trip_generator.dart';

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
  late String _selectedCountry;

  static const List<String> _availableCountries = [
    'vietnam',
    'sri_lanka',
    'indonesia',
    'scotland',
    'mauritius',
    'thailand',
    'japan',
    'turkey',
    'morocco',
  ];

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _startDate = _trip.baseStartDate;
    _endDate = _startDate.add(Duration(days: _trip.totalDays - 1));
    _selectedCountry = _trip.days.isNotEmpty ? _trip.days.first.country.toLowerCase().replaceAll(' ', '_') : 'vietnam';
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
            colorScheme: Theme.of(context).colorScheme.copyWith(primary: const Color.fromRGBO(108, 99, 255, 1)),
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
            colorScheme: Theme.of(context).colorScheme.copyWith(primary: const Color.fromRGBO(108, 99, 255, 1)),
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

    // Regenerate days using the trip generator to preserve cost data
    final regeneratedTrip = TripGenerator.generate(
      countryKey: _selectedCountry,
      startDate: newStart,
      endDate: newEnd,
    );

    List<TripDay> newDays = [];
    for (int i = 0; i < newTotalDays; i++) {
      final dayDate = newStart.add(Duration(days: i));
      final dateStr = '${months[dayDate.month - 1]} ${dayDate.day}';
      if (i < _trip.days.length) {
        // Keep existing day data but update day number and date
        newDays.add(_trip.days[i].copyWith(
          day: i + 1,
          date: dateStr,
        ));
      } else {
        // Use generated day for new days (includes cost estimates)
        final genDay = regeneratedTrip.days[i];
        newDays.add(genDay.copyWith(
          day: i + 1,
          date: dateStr,
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
        totalBudget: regeneratedTrip.totalBudget,
      );
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
    final config = CityConfigs.get(_selectedCountry);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text('Edit Trip', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white, elevation: 0, scrolledUnderElevation: 0, surfaceTintColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: () {
              // Country changes already regenerate days on the fly.
              // Just return the current _trip which already has updated days and title.
              Navigator.pop(context, _trip);
            },
            child: Text('Save', style: GoogleFonts.inter(color: const Color(0xFF6C63FF), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Trip Destination Country
          _buildCountrySelector(config),
          const SizedBox(height: 16),

          // Date range card
          _buildDateRangeCard(),
          const SizedBox(height: 16),

          // Destination-specific summary
          _buildDestinationSummary(config),
        ],
      ),
    );
  }

  Widget _buildCountrySelector(CityConfig config) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C63FF), Color(0xFF4A42D0)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.public, size: 22, color: Colors.white),
              const SizedBox(width: 10),
              Text('Trip Destination', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCountry,
                dropdownColor: const Color(0xFF4A42D0),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                items: _availableCountries.map((key) {
                  final c = CityConfigs.get(key);
                  return DropdownMenuItem(
                    value: key,
                    child: Row(
                      children: [
                        Text(c.flagEmoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(c.country),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null && value != _selectedCountry) {
                    setState(() {
                      _selectedCountry = value;
                      // Regenerate days for the new destination
                      final regeneratedTrip = TripGenerator.generate(
                        countryKey: value,
                        startDate: _startDate,
                        endDate: _endDate,
                      );
                      _trip = _trip.copyWith(
                        title: regeneratedTrip.title,
                        subtitle: regeneratedTrip.subtitle,
                        days: regeneratedTrip.days,
                        totalBudget: regeneratedTrip.totalBudget,
                      );
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeCard() {
    return Container(
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
    );
  }

  Widget _buildDestinationSummary(CityConfig config) {
    return Container(
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
              Text(config.flagEmoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text('${config.country} Quick Info', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.monetization_on, 'Currency', '${config.currency} (${config.currencySymbol})'),
          _buildInfoRow(Icons.language, 'Language', config.language),
          _buildInfoRow(Icons.schedule, 'Timezone', config.timezone),
          _buildInfoRow(Icons.local_taxi, 'Taxi', config.primaryTaxiApp),
          _buildInfoRow(Icons.emergency, 'Emergency', config.emergencyNumber),
          _buildInfoRow(Icons.power, 'Power', '${config.voltage}, ${config.plugType}'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFAB40).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFFFFAB40)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Changing the destination updates Smart Alerts, travel tips, car rental estimates, and packing recommendations automatically.',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF666666), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6C63FF)),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF999999))),
          ),
          Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF333333)))),
        ],
      ),
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
}
