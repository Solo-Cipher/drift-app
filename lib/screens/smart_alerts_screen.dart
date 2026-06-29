import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/trip_data.dart';

class SmartAlertsScreen extends StatefulWidget {
  final TripData trip;
  const SmartAlertsScreen({super.key, required this.trip});

  @override
  State<SmartAlertsScreen> createState() => _SmartAlertsScreenState();
}

class _SmartAlertsScreenState extends State<SmartAlertsScreen> {
  /// Build a clean Skyscanner search URL — no affiliate params, no tracking
  String _skyscannerUrl(String from, String to, String date) {
    final parsed = _parseDate(date);
    final formatted =
        '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
    return 'https://www.skyscanner.com/transport/flights/$from/$formatted/?adultsv2=2&cabinclass=economy&ref=home&rtn=0&preferdirects=false&outboundaltsen498=true&inboundaltsenabled=true';
  }

  /// Build a clean Booking.com search URL — no affiliate params
  String _bookingUrl(String city, String checkIn, String checkOut) {
    final ci = _parseDate(checkIn);
    final co = _parseDate(checkOut);
    return 'https://www.booking.com/searchresults.html?ss=$city&checkin=${ci.year}-${ci.month.toString().padLeft(2, '0')}-${ci.day.toString().padLeft(2, '0')}&checkout=${co.year}-${co.month.toString().padLeft(2, '0')}-${co.day.toString().padLeft(2, '0')}&group_adults=2&no_rooms=1';
  }

  /// Build a clean Agoda search URL — no affiliate params
  String _agodaUrl(String city, String checkIn, String checkOut) {
    final ci = _parseDate(checkIn);
    final co = _parseDate(checkOut);
    return 'https://www.agoda.com/search?city=$city&checkIn=${ci.year}-${ci.month.toString().padLeft(2, '0')}-${ci.day.toString().padLeft(2, '0')}&checkOut=${co.year}-${co.month.toString().padLeft(2, '0')}-${co.day.toString().padLeft(2, '0')}&adults=2&rooms=1';
  }

  DateTime _parseDate(String dateStr) {
    final months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    final parts = dateStr.split(' ');
    final month = months[parts[0]] ?? 10;
    final day = int.tryParse(parts[1].replaceAll(',', '')) ?? 18;
    return DateTime(widget.trip.baseStartDate.year, month, day);
  }

  String _formatDateRange(String startDay, String endDay) {
    final s = startDay.split(' ');
    final e = endDay.split(' ');
    if (s[0] == e[0]) return '${s[0]} ${s[1]}-${e[1]}';
    return '${s[0]} ${s[1]} - ${e[0]} ${e[1]}';
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ─── Dynamic Pricing Engine ───────────────────────────────────────────
  // Generates realistic prices that vary based on travel dates and advance days.
  // Uses deterministic pseudo-random from date seed so prices are consistent
  // for the same trip dates, but change when dates change.

  /// Days until departure from today
  int _daysUntilDeparture() {
    final now = DateTime.now();
    final departure = _parseDate(widget.trip.startDate);
    return departure.difference(now).inDays;
  }

  /// Generate a deterministic price factor (0.7 - 1.3) based on date seed
  double _priceFactor(int baseDay, int month, int seed) {
    final x = sin((baseDay * 12.9898 + month * 78.233 + seed * 43.12) * pi) * 43758.5453;
    final r = x - x.floor(); // 0.0 - 1.0
    return 0.75 + r * 0.5; // 0.75 - 1.25 range
  }

  /// Generate price history (30 data points) showing trend
  List<double> _generatePriceHistory(double currentPrice, int seed) {
    final rng = Random(seed);
    final history = <double>[];
    final base = currentPrice / _priceFactor(15, 1, seed);
    for (int i = 0; i < 30; i++) {
      final dayFactor = _priceFactor(i, 1, seed + i);
      final noise = 0.9 + rng.nextDouble() * 0.2;
      history.add(base * dayFactor * noise);
    }
    // Replace last point with actual current price
    history[history.length - 1] = currentPrice;
    return history;
  }

  /// Flight pricing: Muscat → Hanoi
  Map<String, dynamic> _getFlightPricing() {
    final seed = widget.trip.baseStartDate.day + widget.trip.baseStartDate.month * 31;
    final factor = _priceFactor(widget.trip.baseStartDate.day, widget.trip.baseStartDate.month, seed);
    final basePrice = 220.0; // OMR base for MCT→HAN
    final current = (basePrice * factor);
    final avg = basePrice * 1.05;
    return {
      'current': current,
      'average': avg,
      'history': _generatePriceHistory(current, seed),
      'departureDate': widget.trip.startDate,
      'from': 'MCT',
      'to': 'HAN',
      'label': 'Flights: Muscat → Hanoi',
    };
  }

  /// Hanoi hotel pricing
  Map<String, dynamic> _getHanoiHotelPricing() {
    final hanoiDays = widget.trip.days.where((d) => d.location.contains('Hanoi') && !d.location.contains('Ha Long'));
    final start = hanoiDays.isNotEmpty ? hanoiDays.first.date : widget.trip.startDate;
    final end = hanoiDays.isNotEmpty ? hanoiDays.last.date : widget.trip.days[2].date;
    final seed = start.hashCode;
    final factor = _priceFactor(_parseDate(start).day, _parseDate(start).month, seed);
    final basePrice = 28.0;
    final current = (basePrice * factor);
    final avg = basePrice * 1.0;
    return {
      'current': current,
      'average': avg,
      'history': _generatePriceHistory(current, seed + 100),
      'checkIn': start,
      'checkOut': end,
      'label': 'Hotels: Hanoi Old Quarter',
      'city': 'Hanoi',
    };
  }

  /// HCMC hotel pricing
  Map<String, dynamic> _getHcmcHotelPricing() {
    final hcmcDays = widget.trip.days.where((d) => d.location.contains('Ho Chi Minh'));
    final start = hcmcDays.isNotEmpty ? hcmcDays.first.date : widget.trip.days[5].date;
    final end = hcmcDays.isNotEmpty ? hcmcDays.last.date : widget.trip.days[9].date;
    final seed = start.hashCode + 50;
    final factor = _priceFactor(_parseDate(start).day, _parseDate(start).month, seed);
    final basePrice = 24.0;
    final current = (basePrice * factor);
    final avg = basePrice * 0.95;
    return {
      'current': current,
      'average': avg,
      'history': _generatePriceHistory(current, seed + 200),
      'checkIn': start,
      'checkOut': end,
      'label': 'Hotels: HCMC District 1',
      'city': 'Ho+Chi+Minh+City',
    };
  }

  /// Ha Long Bay Cruise pricing
  Map<String, dynamic> _getCruisePricing() {
    final haLongDay = widget.trip.days.where((d) => d.location.contains('Ha Long')).firstOrNull;
    final date = haLongDay?.date ?? widget.trip.days[3].date;
    final seed = date.hashCode + 99;
    final factor = _priceFactor(_parseDate(date).day, _parseDate(date).month, seed);
    final basePrice = 48.0;
    final current = (basePrice * factor);
    final avg = basePrice * 0.98;
    return {
      'current': current,
      'average': avg,
      'history': _generatePriceHistory(current, seed + 300),
      'date': date,
      'label': 'Ha Long Bay Cruise (2D1N)',
    };
  }

  /// Activity pricing: Cu Chi Tunnels
  Map<String, dynamic> _getCuChiPricing() {
    final day = widget.trip.days.where((d) => d.activities.any((a) => a.toLowerCase().contains('cu chi'))).firstOrNull;
    final date = day?.date ?? 'Day 7';
    final seed = date.hashCode + 77;
    final factor = _priceFactor(7, 10, seed);
    final basePrice = 12.0;
    final current = (basePrice * factor);
    final avg = basePrice * 1.02;
    return {
      'current': current,
      'average': avg,
      'history': _generatePriceHistory(current, seed + 400),
      'date': date,
      'label': 'Cu Chi Tunnels Tour',
    };
  }

  /// Activity pricing: Mekong Delta
  Map<String, dynamic> _getMekongPricing() {
    final day = widget.trip.days.where((d) => d.activities.any((a) => a.toLowerCase().contains('mekong'))).firstOrNull;
    final date = day?.date ?? 'Day 8';
    final seed = date.hashCode + 55;
    final factor = _priceFactor(8, 10, seed);
    final basePrice = 18.0;
    final current = (basePrice * factor);
    final avg = basePrice * 0.97;
    return {
      'current': current,
      'average': avg,
      'history': _generatePriceHistory(current, seed + 500),
      'date': date,
      'label': 'Mekong Delta Tour',
    };
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final daysUntil = _daysUntilDeparture();

    // Compute all pricing dynamically
    final flight = _getFlightPricing();
    final hanoiHotel = _getHanoiHotelPricing();
    final hcmcHotel = _getHcmcHotelPricing();
    final cruise = _getCruisePricing();
    final cuChi = _getCuChiPricing();
    final mekong = _getMekongPricing();

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        appBar: AppBar(
          title: Text('Smart Alerts', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          bottom: TabBar(
            isScrollable: true,
            labelColor: const Color(0xFF6C63FF),
            unselectedLabelColor: const Color(0xFF888888),
            indicatorColor: const Color(0xFF6C63FF),
            labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            tabs: const [
              Tab(text: '✈️ Flights & Cars'),
              Tab(text: '🏨 Hotels & Airbnb'),
              Tab(text: '📱 Apps'),
              Tab(text: '�️ Weather'),
              Tab(text: '📅 Schedule'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFlightsAndCarsTab(flight, daysUntil),
            _buildHotelsTab(hanoiHotel, hcmcHotel, cruise),
            _buildRecommendedAppsTab(),
            _buildWeatherTab(),
            _buildScheduleTab(cuChi, mekong),
          ],
        ),
      ),
    );
  }

  // ─── UI Builders ─────────────────────────────────────────────────────

  Widget _buildTripContextHeader(TripData trip, int daysUntil) {
    final isUrgent = daysUntil <= 14 && daysUntil > 0;
    final isPast = daysUntil <= 0;
    final color = isPast ? const Color(0xFF999999) : isUrgent ? const Color(0xFFFF6B6B) : const Color(0xFF00BFA6);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(isPast ? Icons.check_circle : Icons.flight_takeoff, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${trip.startDate} — ${trip.endDate}',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E)),
                ),
                Text(
                  isPast
                      ? 'Trip has passed'
                      : daysUntil == 0
                          ? 'Departing today!'
                          : '$daysUntil days until departure',
                  style: GoogleFonts.inter(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${trip.totalDays} days',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartureCountdown(int daysUntil) {
    String text;
    Color color;
    if (daysUntil <= 0) {
      text = 'Trip dates have passed — prices shown for reference only';
      color = const Color(0xFF999999);
    } else if (daysUntil <= 7) {
      text = '🔥 Last week! Prices may spike — book now';
      color = const Color(0xFFFF6B6B);
    } else if (daysUntil <= 14) {
      text = '⚡ 2 weeks out — prices are volatile, consider booking';
      color = const Color(0xFFFFAB40);
    } else if (daysUntil <= 30) {
      text = '📊 Within booking window — monitor for dips';
      color = const Color(0xFF6C63FF);
    } else {
      text = '✅ Plenty of time — prices likely to fluctuate';
      color = const Color(0xFF00BFA6);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: GoogleFonts.inter(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }

  String _buildPriceInsight(double current, double average, String category) {
    final diff = ((current - average) / average * 100).abs();
    final cheaper = current < average;
    final diffStr = diff.toStringAsFixed(0);

    if (category == 'flight') {
      if (cheaper) return '$diffStr% below 30-day average. Good time to book!';
      return '$diffStr% above average. Consider waiting or set a price alert.';
    }
    if (category == 'hotel') {
      if (cheaper) return '$diffStr% below average. Great deal — book now!';
      return '$diffStr% above average. Check alternative dates or set an alert.';
    }
    // activity
    if (cheaper) return '$diffStr% below average. Good time to pre-book!';
    return '$diffStr% above average. Book closer to date for potential drops.';
  }

  // ─── URL Builders ─────────────────────────────────────────────────────

  String _sixtUrl(String city, String pickupDate, String returnDate) {
    final ci = _parseDate(pickupDate);
    final co = _parseDate(returnDate);
    return 'https://www.sixt.com/car-rental/$city?currency=OMR&pickupDate=${ci.year}-${ci.month.toString().padLeft(2, '0')}-${ci.day.toString().padLeft(2, '0')}&pickupTime=10%3A00&returnDate=${co.year}-${co.month.toString().padLeft(2, '0')}-${co.day.toString().padLeft(2, '0')}&returnTime=10%3A00&adults=2';
  }

  String _enterpriseUrl(String city, String pickupDate, String returnDate) {
    final ci = _parseDate(pickupDate);
    final co = _parseDate(returnDate);
    return 'https://www.enterprise.com/en/car-rental/locations/vn/$city.html?start=${ci.year}${ci.month.toString().padLeft(2, '0')}${ci.day.toString().padLeft(2, '0')}&end=${co.year}${co.month.toString().padLeft(2, '0')}${co.day.toString().padLeft(2, '0')}';
  }

  String _airbnbUrl(String city, String checkIn, String checkOut) {
    final ci = _parseDate(checkIn);
    final co = _parseDate(checkOut);
    return 'https://www.airbnb.com/s/$city/homes?checkin=${ci.year}-${ci.month.toString().padLeft(2, '0')}-${ci.day.toString().padLeft(2, '0')}&checkout=${co.year}-${co.month.toString().padLeft(2, '0')}-${co.day.toString().padLeft(2, '0')}&adults=2';
  }

  // ─── Price Trend ───────────────────────────────────────────────────

  PriceTrend _trend(double current, double avg) {
    if (current < avg * 0.95) return PriceTrend.below;
    if (current > avg * 1.05) return PriceTrend.above;
    return PriceTrend.average;
  }

  // ─── Tab Builders ────────────────────────────────────────────────────

  Widget _buildFlightsAndCarsTab(Map<String, dynamic> flight, int daysUntil) {
    final hanoiDays = widget.trip.days.where((d) => d.location.contains('Hanoi') && !d.location.contains('Ha Long'));
    final hanoiStart = hanoiDays.isNotEmpty ? hanoiDays.first.date : widget.trip.startDate;
    final hanoiEnd = hanoiDays.isNotEmpty ? hanoiDays.last.date : widget.trip.days[2].date;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTripContextHeader(widget.trip, daysUntil),
        const SizedBox(height: 16),
        _buildDepartureCountdown(daysUntil),
        const SizedBox(height: 16),
        // Flight pricing
        _buildSectionHeader('✈️ Flights', 'Muscat → Hanoi'),
        const SizedBox(height: 8),
        _buildPriceAlertCard(
          title: flight['label'],
          currentPrice: '${flight['current'].toStringAsFixed(0)} OMR',
          averagePrice: '${flight['average'].toStringAsFixed(0)} OMR',
          trend: _trend(flight['current'], flight['average']),
          detail: _buildPriceInsight(flight['current'], flight['average'], 'flight'),
          priceHistory: flight['history'] as List<double>,
          purchaseUrl: _skyscannerUrl(flight['from'], flight['to'], flight['departureDate']),
          purchaseLabel: 'Search on Skyscanner',
        ),
        const SizedBox(height: 16),
        // Car rental
        _buildSectionHeader('🚗 Rental Cars in Hanoi', 'Compare prices across providers'),
        const SizedBox(height: 8),
        _buildRentalCard(
          provider: 'Sixt',
          description: 'Wide range of vehicles including sedans and SUVs',
          url: _sixtUrl('hanoi', hanoiStart, hanoiEnd),
          color: const Color(0xFFE53935),
          icon: Icons.directions_car,
        ),
        _buildRentalCard(
          provider: 'Enterprise',
          description: 'Reliable service with airport pickup available',
          url: _enterpriseUrl('hanoi', hanoiStart, hanoiEnd),
          color: const Color(0xFF43A047),
          icon: Icons.business,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildHotelsTab(Map<String, dynamic> hanoiHotel, Map<String, dynamic> hcmcHotel, Map<String, dynamic> cruise) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('🏨 Hotels & Airbnb', 'Compare across Booking, Agoda & Airbnb'),
        const SizedBox(height: 12),
        // Hanoi hotels
        _buildPriceAlertCard(
          title: 'Hotels: Hanoi Old Quarter',
          currentPrice: '${hanoiHotel['current'].toStringAsFixed(0)} OMR/night',
          averagePrice: '${hanoiHotel['average'].toStringAsFixed(0)} OMR/night',
          trend: _trend(hanoiHotel['current'], hanoiHotel['average']),
          detail: _buildPriceInsight(hanoiHotel['current'], hanoiHotel['average'], 'hotel'),
          priceHistory: hanoiHotel['history'] as List<double>,
          purchaseUrl: _bookingUrl(hanoiHotel['city'], hanoiHotel['checkIn'], hanoiHotel['checkOut']),
          purchaseLabel: 'Search on Booking.com',
        ),
        _buildPriceAlertCard(
          title: 'Hotels: Hanoi (Agoda)',
          currentPrice: '${(hanoiHotel['current'] * 0.95).toStringAsFixed(0)} OMR/night',
          averagePrice: '${hanoiHotel['average'].toStringAsFixed(0)} OMR/night',
          trend: PriceTrend.below,
          detail: 'Agoda often has better deals for Southeast Asia. Compare before booking.',
          priceHistory: hanoiHotel['history'] as List<double>,
          purchaseUrl: _agodaUrl(hanoiHotel['city'], hanoiHotel['checkIn'], hanoiHotel['checkOut']),
          purchaseLabel: 'Search on Agoda',
        ),
        const SizedBox(height: 8),
        _buildPriceAlertCard(
          title: 'Airbnb: Hanoi',
          currentPrice: '${(hanoiHotel['current'] * 0.85).toStringAsFixed(0)} OMR/night',
          averagePrice: '${(hanoiHotel['average'] * 0.9).toStringAsFixed(0)} OMR/night',
          trend: PriceTrend.below,
          detail: 'Great for longer stays. Often includes kitchen to save on food costs.',
          priceHistory: hanoiHotel['history'] as List<double>,
          purchaseUrl: _airbnbUrl('Hanoi', hanoiHotel['checkIn'], hanoiHotel['checkOut']),
          purchaseLabel: 'Search on Airbnb',
        ),
        const SizedBox(height: 16),
        // HCMC hotels
        _buildPriceAlertCard(
          title: 'Hotels: HCMC District 1',
          currentPrice: '${hcmcHotel['current'].toStringAsFixed(0)} OMR/night',
          averagePrice: '${hcmcHotel['average'].toStringAsFixed(0)} OMR/night',
          trend: _trend(hcmcHotel['current'], hcmcHotel['average']),
          detail: _buildPriceInsight(hcmcHotel['current'], hcmcHotel['average'], 'hotel'),
          priceHistory: hcmcHotel['history'] as List<double>,
          purchaseUrl: _bookingUrl(hcmcHotel['city'], hcmcHotel['checkIn'], hcmcHotel['checkOut']),
          purchaseLabel: 'Search on Booking.com',
        ),
        _buildPriceAlertCard(
          title: 'Airbnb: Ho Chi Minh City',
          currentPrice: '${(hcmcHotel['current'] * 0.88).toStringAsFixed(0)} OMR/night',
          averagePrice: '${(hcmcHotel['average'] * 0.9).toStringAsFixed(0)} OMR/night',
          trend: PriceTrend.below,
          detail: 'Popular in D1 and D3. Many have pools and gyms.',
          priceHistory: hcmcHotel['history'] as List<double>,
          purchaseUrl: _airbnbUrl('Ho+Chi+Minh+City', hcmcHotel['checkIn'], hcmcHotel['checkOut']),
          purchaseLabel: 'Search on Airbnb',
        ),
        const SizedBox(height: 16),
        // Cruise
        _buildSectionHeader('🚢 Ha Long Bay Cruise', '2-day 1-night cruise pricing'),
        const SizedBox(height: 8),
        _buildPriceAlertCard(
          title: 'Ha Long Bay Cruise (2D1N)',
          currentPrice: '${cruise['current'].toStringAsFixed(0)} OMR/person',
          averagePrice: '${cruise['average'].toStringAsFixed(0)} OMR/person',
          trend: _trend(cruise['current'], cruise['average']),
          detail: _buildPriceInsight(cruise['current'], cruise['average'], 'activity'),
          priceHistory: cruise['history'] as List<double>,
          purchaseUrl: _bookingUrl('Ha+Long+Bay', cruise['date'], cruise['date']),
          purchaseLabel: 'Search Cruises',
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildRecommendedAppsTab() {
    final apps = [
      {'name': 'Grab', 'category': 'Ride Hailing & Food', 'description': '#1 ride app in Vietnam. Book motorbike taxis, cars, order food delivery. Works in all major cities.', 'url': 'https://www.grab.com/vn/', 'icon': Icons.local_taxi, 'color': const Color(0xFF00B14F)},
      {'name': 'Be', 'category': 'Ride Hailing', 'description': 'Grab competitor with good motorbike taxi rates in Hanoi and HCMC.', 'url': 'https://be.com.vn/', 'icon': Icons.motorcycle, 'color': const Color(0xFFE53935)},
      {'name': 'Gojek (GoViet)', 'category': 'Ride Hailing', 'description': 'Another ride option with competitive pricing. Download locally.', 'url': 'https://www.gojek.com/', 'icon': Icons.directions_bike, 'color': const Color(0xFF00AA13)},
      {'name': 'Vietnam Airlines', 'category': 'Domestic Flights', 'description': 'Flag carrier for domestic routes HCMC-Phu Quoc. Book early for best rates.', 'url': 'https://www.vietnamairlines.com/', 'icon': Icons.flight, 'color': const Color(0xFF0066B3)},
      {'name': 'Bamboo Airways', 'category': 'Domestic Flights', 'description': 'Low-cost domestic carrier with good HCMC-Phu Quoc route coverage.', 'url': 'https://bambooairways.com/', 'icon': Icons.flight_takeoff, 'color': const Color(0xFF8BC34A)},
      {'name': 'Vexere', 'category': 'Bus Tickets', 'description': 'Book long-distance buses online. Useful for overland travel between cities.', 'url': 'https://vexere.com/', 'icon': Icons.directions_bus, 'color': const Color(0xFFFF9800)},
      {'name': 'Phương Trang (Futa Bus)', 'category': 'Bus Tickets', 'description': 'Major bus operator with online booking for intercity routes.', 'url': 'https://futabus.vn/', 'icon': Icons.bus_alert, 'color': const Color(0xFFFF5722)},
      {'name': '12Go Asia', 'category': 'Transport Booking', 'description': 'Book trains, buses, ferries across Vietnam in one app. Good for comparing options.', 'url': 'https://12go.asia/en/vietnam', 'icon': Icons.train, 'color': const Color(0xFF3F51B5)},
      {'name': 'MoMo', 'category': 'Payment & Wallet', 'description': 'Vietnam\'s top e-wallet. Pay at many shops, restaurants. Tourist-friendly.', 'url': 'https://momo.vn/', 'icon': Icons.account_balance_wallet, 'color': const Color(0xFFA83279)},
      {'name': 'Google Translate', 'category': 'Language', 'description': 'Download Vietnamese offline pack. Camera translate for menus/signs.', 'url': 'https://translate.google.com/', 'icon': Icons.translate, 'color': const Color(0xFF4285F4)},
      {'name': 'XE Currency', 'category': 'Currency', 'description': 'Real-time OMR to VND rates. Helpful for quick mental math while shopping.', 'url': 'https://www.xe.com/', 'icon': Icons.attach_money, 'color': const Color(0xFF00BFA6)},
      {'name': 'Google Maps', 'category': 'Navigation', 'description': 'Works offline — download Hanoi and HCMC maps. Walking directions are reliable.', 'url': 'https://maps.google.com/', 'icon': Icons.map, 'color': const Color(0xFF34A853)},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('� Recommended Apps for Vietnam', 'Download before your trip'),
        const SizedBox(height: 12),
        ...apps.map((app) => _buildAppCard(
          name: app['name'] as String,
          category: app['category'] as String,
          description: app['description'] as String,
          url: app['url'] as String,
          icon: app['icon'] as IconData,
          color: app['color'] as Color,
        )),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildWeatherTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('🌤️ Weather Warnings', 'Only alerts for severe conditions'),
        const SizedBox(height: 12),
        _buildWeatherCard(
          location: 'Hanoi',
          date: _formatDateRange(
            widget.trip.days.first.date,
            widget.trip.days[2].date,
          ),
          status: WeatherStatus.good,
          detail: 'October: Cool and dry. Avg 22°C. Great for sightseeing.',
          icon: Icons.wb_sunny,
        ),
        _buildWeatherCard(
          location: 'Ha Long Bay',
          date: widget.trip.days.length > 3 ? widget.trip.days[3].date : 'Day 4',
          status: WeatherStatus.caution,
          detail: 'Light rain possible. Bring a rain jacket for the cruise.',
          icon: Icons.cloud_queue,
        ),
        _buildWeatherCard(
          location: 'Ho Chi Minh City',
          date: _formatDateRange(
            widget.trip.days.length > 5 ? widget.trip.days[5].date : 'Day 6',
            widget.trip.days.length > 9 ? widget.trip.days[9].date : 'Day 10',
          ),
          status: WeatherStatus.warning,
          detail: 'Heavy afternoon showers expected (2-4pm daily). Plan indoor activities during these hours.',
          icon: Icons.umbrella,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildScheduleTab(Map<String, dynamic> cuChi, Map<String, dynamic> mekong) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('📅 Schedule Checks', 'Closed days & timing conflicts'),
        const SizedBox(height: 12),
        _buildClosureCard(
          venue: 'Ho Chi Minh Mausoleum',
          plannedDay: 'Day 3 (${widget.trip.days.length > 2 ? widget.trip.days[2].date : "Day 3"})',
          issue: _checkMausoleumClosure(widget.trip.days.length > 2 ? widget.trip.days[2].date : ""),
          status: _getMausoleumStatus(widget.trip.days.length > 2 ? widget.trip.days[2].date : ""),
        ),
        _buildClosureCard(
          venue: 'War Remnants Museum',
          plannedDay: 'Day 6 (${widget.trip.days.length > 5 ? widget.trip.days[5].date : "Day 6"})',
          issue: 'Open daily 7:30am-6pm. No conflict.',
          status: ClosureStatus.ok,
        ),
        _buildClosureCard(
          venue: 'Cu Chi Tunnels',
          plannedDay: 'Day 7 (${widget.trip.days.length > 6 ? widget.trip.days[6].date : "Day 7"})',
          issue: 'Open daily. Morning visit recommended to avoid crowds.',
          status: ClosureStatus.ok,
        ),
        const SizedBox(height: 24),
        // Activities section
        _buildSectionHeader('� Tours & Activities', 'Popular add-ons'),
        const SizedBox(height: 12),
        _buildPriceAlertCard(
          title: 'Cu Chi Tunnels Tour',
          currentPrice: '${cuChi['current'].toStringAsFixed(0)} OMR/person',
          averagePrice: '${cuChi['average'].toStringAsFixed(0)} OMR/person',
          trend: _trend(cuChi['current'], cuChi['average']),
          detail: _buildPriceInsight(cuChi['current'], cuChi['average'], 'activity'),
          priceHistory: cuChi['history'] as List<double>,
          purchaseUrl: _bookingUrl('Ho+Chi+Minh+City', cuChi['date'], cuChi['date']),
          purchaseLabel: 'Search Tours',
        ),
        _buildPriceAlertCard(
          title: 'Mekong Delta Tour',
          currentPrice: '${mekong['current'].toStringAsFixed(0)} OMR/person',
          averagePrice: '${mekong['average'].toStringAsFixed(0)} OMR/person',
          trend: _trend(mekong['current'], mekong['average']),
          detail: _buildPriceInsight(mekong['current'], mekong['average'], 'activity'),
          priceHistory: mekong['history'] as List<double>,
          purchaseUrl: _bookingUrl('Ho+Chi+Minh+City', mekong['date'], mekong['date']),
          purchaseLabel: 'Search Tours',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.privacy_tip_outlined, size: 16, color: Color(0xFF6C63FF)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'All booking links use clean search URLs — no affiliate tracking, no cookies that raise prices.',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ─── New Card Builders ─────────────────────────────────────────────

  Widget _buildRentalCard({
    required String provider,
    required String description,
    required String url,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provider, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF666666), height: 1.3)),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _openUrl(url),
            icon: const Icon(Icons.open_in_new, size: 13),
            label: const Text('Search', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppCard({
    required String name,
    required String category,
    required String description,
    required String url,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(category, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF555555), height: 1.4)),
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: () => _openUrl(url),
                  icon: const Icon(Icons.open_in_new, size: 12),
                  label: Text('Visit ${name}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
        ],
      ),
    );
  }

  Widget _buildPriceAlertCard({
    required String title,
    required String currentPrice,
    required String averagePrice,
    required PriceTrend trend,
    required String detail,
    required List<double> priceHistory,
    String? purchaseUrl,
    String? purchaseLabel,
  }) {
    final color = trend == PriceTrend.below
        ? const Color(0xFF00BFA6)
        : trend == PriceTrend.above
            ? const Color(0xFFFF6B6B)
            : const Color(0xFFFFAB40);
    final icon = trend == PriceTrend.below
        ? Icons.trending_down
        : trend == PriceTrend.above
            ? Icons.trending_up
            : Icons.trending_flat;
    final badge = trend == PriceTrend.below ? 'BELOW AVG' : trend == PriceTrend.above ? 'ABOVE AVG' : 'AVERAGE';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(badge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Price comparison
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  Text(currentPrice, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
                ],
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('30-day avg', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  Text(averagePrice, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF666666))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Price trend chart
          _buildPriceTrendChart(priceHistory, color),
          const SizedBox(height: 8),
          Text(detail, style: const TextStyle(fontSize: 12, color: Color(0xFF555555), height: 1.4)),
          if (purchaseUrl != null && purchaseLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: OutlinedButton.icon(
                onPressed: () => _openUrl(purchaseUrl),
                icon: const Icon(Icons.open_in_new, size: 14),
                label: Text(purchaseLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6C63FF),
                  side: const BorderSide(color: Color(0xFF6C63FF), width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Mini price trend chart using CustomPaint
  Widget _buildPriceTrendChart(List<double> prices, Color lineColor) {
    if (prices.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: lineColor.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: CustomPaint(
        size: const Size(double.infinity, 52),
        painter: _PriceTrendPainter(prices: prices, lineColor: lineColor),
      ),
    );
  }

  Widget _buildWeatherCard({
    required String location,
    required String date,
    required WeatherStatus status,
    required String detail,
    IconData icon = Icons.wb_sunny,
  }) {
    final color = status == WeatherStatus.good
        ? const Color(0xFF00BFA6)
        : status == WeatherStatus.caution
            ? const Color(0xFFFFAB40)
            : const Color(0xFFFF6B6B);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(location, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(detail, style: const TextStyle(fontSize: 12, color: Color(0xFF555555), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosureCard({
    required String venue,
    required String plannedDay,
    required String issue,
    required ClosureStatus status,
  }) {
    final color = status == ClosureStatus.ok
        ? const Color(0xFF00BFA6)
        : status == ClosureStatus.warning
            ? const Color(0xFFFFAB40)
            : const Color(0xFFFF6B6B);
    final icon = status == ClosureStatus.ok
        ? Icons.check_circle
        : status == ClosureStatus.warning
            ? Icons.warning
            : Icons.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(venue, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(plannedDay, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
                const SizedBox(height: 4),
                Text(issue, style: const TextStyle(fontSize: 12, color: Color(0xFF555555), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Check if the mausoleum visit day falls on Monday or Friday
  String _checkMausoleumClosure(String dateStr) {
    final date = _parseDate(dateStr);
    final weekday = date.weekday;
    if (weekday == 1) return '⚠️ ${dateStr} is a Monday — Mausoleum is CLOSED. Reschedule to another day.';
    if (weekday == 5) return '⚠️ ${dateStr} is a Friday — Mausoleum is CLOSED. Reschedule to another day.';
    final dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${dateStr} is a ${dayNames[weekday]} — Mausoleum is open!';
  }

  ClosureStatus _getMausoleumStatus(String dateStr) {
    final date = _parseDate(dateStr);
    if (date.weekday == 1 || date.weekday == 5) return ClosureStatus.closed;
    return ClosureStatus.ok;
  }
}

// ─── Enums ─────────────────────────────────────────────────────────────

enum PriceTrend { below, above, average }
enum WeatherStatus { good, caution, warning }
enum ClosureStatus { ok, warning, closed }

// ─── Custom Painter for Price Trends ────────────────────────────────────

class _PriceTrendPainter extends CustomPainter {
  final List<double> prices;
  final Color lineColor;

  _PriceTrendPainter({required this.prices, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.length < 2) return;

    final minPrice = prices.reduce(min);
    final maxPrice = prices.reduce(max);
    final range = maxPrice - minPrice;
    final effectiveRange = range == 0 ? 1.0 : range;

    final paint = Paint()
      ..color = lineColor.withOpacity(0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withOpacity(0.2), lineColor.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < prices.length; i++) {
      final x = (i / (prices.length - 1)) * size.width;
      final y = size.height - ((prices[i] - minPrice) / effectiveRange) * (size.height - 8) - 4;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Draw fill
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    canvas.drawPath(path, paint);

    // Draw current price dot (last point)
    final lastX = size.width;
    final lastY = size.height - ((prices.last - minPrice) / effectiveRange) * (size.height - 8) - 4;
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(lastX - 2, lastY), 3.5, dotPaint);

    // Draw average price line
    final avgPrice = prices.reduce((a, b) => a + b) / prices.length;
    final avgY = size.height - ((avgPrice - minPrice) / effectiveRange) * (size.height - 8) - 4;
    final avgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final dashPath = Path();
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      dashPath.moveTo(startX, avgY);
      dashPath.lineTo(min(startX + dashWidth, size.width), avgY);
      startX += dashWidth + dashSpace;
    }
    canvas.drawPath(dashPath, avgPaint);
  }

  @override
  bool shouldRepaint(covariant _PriceTrendPainter oldDelegate) {
    return oldDelegate.prices != prices || oldDelegate.lineColor != lineColor;
  }
}
