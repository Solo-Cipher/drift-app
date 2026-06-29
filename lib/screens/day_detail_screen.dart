import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/trip_data.dart';

class DayDetailScreen extends StatelessWidget {
  final TripDay day;
  final String tripTitle;
  final String currency;

  const DayDetailScreen({super.key, required this.day, required this.tripTitle, this.currency = 'OMR'});

  String _buildMapUrl() {
    if (day.lat != null && day.lng != null) {
      return 'https://www.google.com/maps/search/?api=1&query=${day.lat},${day.lng}';
    }
    final query = Uri.encodeComponent('${day.location}, ${day.country}');
    return 'https://www.google.com/maps/search/?api=1&query=$query';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text('Day ${day.day} — ${day.location}', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: day.color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Open in Google Maps button at top
            if (day.lat != null || day.lng != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final url = Uri.parse(_buildMapUrl());
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: Text('Open in Google Maps', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: day.color,
                    side: BorderSide(color: day.color.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            _buildDetailsPanel(context, isWide: false),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsPanel(BuildContext context, {required bool isWide}) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 24 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: day.color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('Day ${day.day}  ·  ${day.date}', style: GoogleFonts.inter(color: day.color, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          Text(day.title, style: GoogleFonts.inter(fontSize: isWide ? 28 : 24, fontWeight: FontWeight.w800, color: const Color(0xFF1A1A2E), height: 1.1)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Color(0xFF888888)),
              const SizedBox(width: 4),
              Text(day.location, style: GoogleFonts.inter(color: const Color(0xFF888888), fontSize: 14)),
            ],
          ),
          const SizedBox(height: 20),
          Text(day.description, style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF444444), height: 1.6)),
          const SizedBox(height: 24),

          // Transportation — primary section
          if (day.arrivalTransport != null || day.departureTransport != null) ...[
            _buildSectionTitle('Transportation'),
            const SizedBox(height: 12),
            _buildTransportCard(),
            const SizedBox(height: 24),
          ],

          // Activities — secondary section
          if (day.activities.isNotEmpty) ...[
            _buildSectionTitle('Activities'),
            const SizedBox(height: 12),
            ...day.activities.asMap().entries.map((entry) {
              final hasPin = entry.key < day.activityLocations.length && day.activityLocations[entry.key] != null;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(color: day.color.withOpacity(0.1), shape: BoxShape.circle),
                      child: Center(child: Text('${entry.key + 1}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: day.color))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(entry.value, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF333333), height: 1.4))),
                    if (hasPin)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Icon(Icons.location_on, size: 14, color: day.color.withOpacity(0.6)),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
          ],

          // Cost
          if (day.totalCost > 0) ...[
            _buildSectionTitle('Day Cost Estimate'),
            const SizedBox(height: 12),
            _buildCostCard(),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E)));
  }

  Widget _buildTransportCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          if (day.arrivalTransport != null) _buildTransportRow('Arrival', day.arrivalTransport!),
          if (day.arrivalTransport != null && day.departureTransport != null)
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
          if (day.departureTransport != null) _buildTransportRow('Departure', day.departureTransport!),
          if (day.transportDuration != null || day.transportCost != null) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (day.transportDuration != null)
                  Row(children: [
                    const Icon(Icons.access_time, size: 14, color: Color(0xFF888888)),
                    const SizedBox(width: 4),
                    Text(day.transportDuration!, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF666666))),
                  ]),
                if (day.transportCost != null)
                  Text('${day.transportCost} $currency', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF6C63FF))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransportRow(String label, TransportMode mode) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: getTransportColor(mode).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(getTransportIcon(mode), size: 18, color: getTransportColor(mode)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF999999))),
            Text(getTransportLabel(mode), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF333333))),
          ],
        ),
      ],
    );
  }

  Widget _buildCostCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          if (day.transportCost != null) _buildCostRow('Transport', day.transportCost!),
          if (day.accommodationCost != null) _buildCostRow('Accommodation', day.accommodationCost!),
          if (day.foodCost != null) _buildCostRow('Food & Drinks', day.foodCost!),
          const Divider(height: 20),
          _buildCostRow('Day Total', '${day.totalCost.toInt()}', isTotal: true),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: isTotal ? 15 : 13, fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400, color: isTotal ? const Color(0xFF1A1A2E) : const Color(0xFF666666))),
          Text('$amount $currency', style: GoogleFonts.inter(fontSize: isTotal ? 16 : 13, fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500, color: isTotal ? const Color(0xFF6C63FF) : const Color(0xFF333333))),
        ],
      ),
    );
  }
}
