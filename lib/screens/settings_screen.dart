import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/trip_data.dart';

class SettingsScreen extends StatefulWidget {
  final TripData trip;
  const SettingsScreen({super.key, required this.trip});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _tripNameController;
  late TextEditingController _traveler1Controller;
  late TextEditingController _traveler2Controller;
  late String _currency;
  late String _tripType;
  late bool _alertsEnabled;
  late bool _weatherAlerts;
  late bool _priceAlerts;
  late bool _closureAlerts;

  final List<Map<String, dynamic>> _tripTypes = [
    {'label': 'Couple Trip', 'icon': Icons.favorite},
    {'label': 'Guys Trip', 'icon': Icons.group},
    {'label': 'Solo Trip', 'icon': Icons.person},
    {'label': 'Family Trip', 'icon': Icons.family_restroom},
  ];

  @override
  void initState() {
    super.initState();
    _tripNameController = TextEditingController(text: widget.trip.title);
    _traveler1Controller = TextEditingController(text: '');
    _traveler2Controller = TextEditingController(text: '');
    _currency = widget.trip.currency;
    _tripType = 'Couple Trip';
    _alertsEnabled = true;
    _weatherAlerts = true;
    _priceAlerts = true;
    _closureAlerts = true;
  }

  @override
  void dispose() {
    _tripNameController.dispose();
    _traveler1Controller.dispose();
    _traveler2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white, elevation: 0, scrolledUnderElevation: 0, surfaceTintColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: () {
              final selectedType = _tripTypes.firstWhere((t) => t['label'] == _tripType);
              Navigator.pop(context, {
                'tripType': _tripType,
                'tripTypeIcon': selectedType['icon'],
                'currency': _currency,
              });
            },
            child: Text('Done', style: GoogleFonts.inter(color: const Color(0xFF6C63FF), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Trip'),
          _buildCard(children: [
            _buildTextField('Trip Name', _tripNameController, Icons.card_travel),
            const Divider(height: 1),
            _buildTextField('Traveler 1', _traveler1Controller, Icons.person),
            const Divider(height: 1),
            _buildTextField('Traveler 2', _traveler2Controller, Icons.person_outline),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.attach_money, size: 20, color: Color(0xFF6C63FF)),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Currency', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600))),
                  DropdownButton<String>(
                    value: _currency,
                    underline: const SizedBox(),
                    items: ['OMR', 'USD', 'EUR', 'AED', 'INR'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)))).toList(),
                    onChanged: (v) => setState(() => _currency = v ?? 'OMR'),
                  ),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionTitle('Trip Type'),
          _buildCard(children: [
            ..._tripTypes.map((type) {
              final isSelected = _tripType == type['label'];
              return InkWell(
                onTap: () => setState(() => _tripType = type['label']),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(type['icon'], size: 20, color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF999999)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(type['label'], style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF1A1A2E)))),
                      if (isSelected) const Icon(Icons.check, size: 18, color: Color(0xFF6C63FF)),
                    ],
                  ),
                ),
              );
            }),
          ]),

          const SizedBox(height: 24),
          _buildSectionTitle('Notifications'),
          _buildCard(children: [
            _buildSwitch('Enable Alerts', _alertsEnabled, Icons.notifications, (v) => setState(() => _alertsEnabled = v)),
            const Divider(height: 1),
            _buildSwitch('Weather Warnings', _weatherAlerts, Icons.cloud, (v) => setState(() => _weatherAlerts = v), enabled: _alertsEnabled),
            const Divider(height: 1),
            _buildSwitch('Price Alerts', _priceAlerts, Icons.trending_up, (v) => setState(() => _priceAlerts = v), enabled: _alertsEnabled),
            const Divider(height: 1),
            _buildSwitch('Closure Checks', _closureAlerts, Icons.event_busy, (v) => setState(() => _closureAlerts = v), enabled: _alertsEnabled),
          ]),

          const SizedBox(height: 24),
          _buildSectionTitle('About'),
          _buildCard(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('D R I F T', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w300, letterSpacing: 4, color: const Color(0xFF6C63FF))),
                  ),
                  const SizedBox(height: 8),
                  Text('Smart travel itinerary planner', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF888888))),
                  const SizedBox(height: 4),
                  Text('Version 1.0.0', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFBBBBBB))),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF999999), letterSpacing: 0.5)),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6C63FF)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF888888)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, IconData icon, ValueChanged<bool> onChanged, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: enabled ? const Color(0xFF6C63FF) : const Color(0xFFCCCCCC)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: enabled ? const Color(0xFF1A1A2E) : const Color(0xFFBBBBBB)))),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: const Color(0xFF6C63FF),
          ),
        ],
      ),
    );
  }
}
