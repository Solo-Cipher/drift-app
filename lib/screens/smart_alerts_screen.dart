import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/trip_data.dart';
import '../data/city_configs.dart';
import '../services/closure_checker.dart';

class SmartAlertsScreen extends StatefulWidget {
  final TripData trip;
  const SmartAlertsScreen({super.key, required this.trip});

  @override
  State<SmartAlertsScreen> createState() => _SmartAlertsScreenState();
}

class _SmartAlertsScreenState extends State<SmartAlertsScreen> {
  CityConfig? _config;

  @override
  void initState() {
    super.initState();
    _config = _findConfig();
  }

  CityConfig? _findConfig() {
    if (widget.trip.days.isEmpty) return null;
    // Match by comparing normalized country names (handle 'sri_lanka' vs 'Sri Lanka')
    final tripCountry = widget.trip.days.first.country.toLowerCase().replaceAll('_', ' ').trim();
    for (final key in CityConfigs.availableCountries) {
      final c = CityConfigs.get(key);
      final configCountry = c.country.toLowerCase().replaceAll('_', ' ').trim();
      if (tripCountry == configCountry) {
        return c;
      }
    }
    // Fallback: match by country key directly
    for (final key in CityConfigs.availableCountries) {
      final c = CityConfigs.get(key);
      if (widget.trip.days.any((d) => d.country.toLowerCase().contains(key.replaceAll('_', ' ')))) {
        return c;
      }
    }
    return null;
  }
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
    final month = months[parts[0]] ?? widget.trip.baseStartDate.month;
    final day = int.tryParse(parts[1].replaceAll(',', '')) ?? widget.trip.baseStartDate.day;
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

  /// Flight pricing: generates flights to ALL cities in the itinerary
  /// so users can see various entry point options
  List<Map<String, dynamic>> _getFlightPricing() {
    final config = _config;
    final fromCode = config?.originAirport ?? 'MCT';
    final basePrice = config?.flightBasePrice ?? 200.0;
    final seed = widget.trip.baseStartDate.day + widget.trip.baseStartDate.month * 31;

    // Collect unique cities from the itinerary
    final uniqueCities = <String>{};
    for (final day in widget.trip.days) {
      uniqueCities.add(day.location);
    }

    // Map city names to IATA codes (use city name 3-letter code as fallback)
    final flights = <Map<String, dynamic>>[];
    int cityIdx = 0;
    for (final city in uniqueCities) {
      final cityIata = _cityToIata(city, config);
      final citySeed = seed + cityIdx * 100;
      final factor = _priceFactor(widget.trip.baseStartDate.day, widget.trip.baseStartDate.month, citySeed);
      // Add some price variation per city (±30%)
      final priceVariation = 0.7 + (cityIdx % 3) * 0.3;
      final current = basePrice * factor * priceVariation;
      final avg = basePrice * priceVariation;
      flights.add({
        'current': current,
        'average': avg,
        'history': _generatePriceHistory(current, citySeed),
        'departureDate': widget.trip.startDate,
        'from': fromCode,
        'to': cityIata,
        'toCity': city,
        'label': 'Flights: $fromCode → $cityIata ($city)',
        'fromLabel': fromCode,
        'toLabel': city,
        'currency': _displayCurrency,
      });
      cityIdx++;
    }
    return flights;
  }

  /// All prices in Smart Alerts display in OMR (or trip currency if preferred)
  String get _displayCurrency => 'OMR';

  /// Convert a city name to a reasonable IATA code
  String _cityToIata(String city, CityConfig? config) {
    // Check cities in config for a match
    if (config != null) {
      for (final entry in config.cities.entries) {
        if (entry.value.displayName.toLowerCase() == city.toLowerCase()) {
          // Use the key if it looks like an IATA code, else generate one
          return entry.key.length == 3 ? entry.key.toUpperCase() : entry.value.displayName.substring(0, 3).toUpperCase();
        }
      }
    }
    // Fallback: first 3 letters of city name
    return city.length >= 3 ? city.substring(0, 3).toUpperCase() : city.toUpperCase();
  }

  /// Dynamic hotel pricing per unique location in trip
  List<Map<String, dynamic>> _getHotelPricings() {
    final config = _config;
    if (config == null) return [];
    
    // Group days by unique location
    final locationGroups = <String, List<int>>{};
    for (int i = 0; i < widget.trip.days.length; i++) {
      final loc = widget.trip.days[i].location;
      locationGroups.putIfAbsent(loc, () => []).add(i);
    }
    
    final pricings = <Map<String, dynamic>>[];
    final baseHotel = config.defaultHotelBase;
    
    for (final entry in locationGroups.entries) {
      final loc = entry.key;
      final indices = entry.value;
      final firstIdx = indices.first;
      final lastIdx = indices.last;
      final start = widget.trip.days[firstIdx].date;
      final end = widget.trip.days[lastIdx].date;
      final seed = loc.hashCode % 10000;
      final factor = _priceFactor(firstIdx + 1, widget.trip.baseStartDate.month, seed);
      final current = baseHotel * factor;
      final avg = baseHotel * 1.0;
      
      pricings.add({
        'current': current,
        'average': avg,
        'history': _generatePriceHistory(current, seed + 100),
        'checkIn': start,
        'checkOut': end,
        'city': loc.replaceAll(' ', '+'),
        'label': 'Hotels: $loc',
        'currency': _displayCurrency,
      });
    }
    return pricings;
  }

  /// Dynamic activity pricing — picks up to 2 notable activities from the trip
  List<Map<String, dynamic>> _getActivityPricings() {
    final pricings = <Map<String, dynamic>>[];
    final seen = <String>{};
    
    for (final day in widget.trip.days) {
      for (final activity in day.activities) {
        final key = activity.toLowerCase();
        // Pick activities that sound like tours/major attractions
        if (key.contains('tour') || key.contains('temple') || key.contains('cruise') || 
            key.contains('island') || key.contains('hike') || key.contains('trek') ||
            key.contains('diving') || key.contains('snorkel') || key.contains(' safari') ||
            key.contains('sunrise') || key.contains('sunset')) {
          if (seen.contains(key)) continue;
          seen.add(key);
          final seed = activity.hashCode % 10000;
          final basePrice = 15.0 + (seed % 20); // 15-35 range
          final factor = _priceFactor(day.day, widget.trip.baseStartDate.month, seed);
          pricings.add({
            'current': basePrice * factor,
            'average': basePrice * 1.0,
            'history': _generatePriceHistory(basePrice * factor, seed),
            'date': day.date,
            'label': activity,
            'currency': _displayCurrency,
          });
          if (pricings.length >= 2) break; // Max 2 activity cards
        }
      }
      if (pricings.length >= 2) break;
    }
    return pricings;
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final daysUntil = _daysUntilDeparture();

    // Compute all pricing dynamically
    final flights = _getFlightPricing();
    final hotels = _getHotelPricings();
    final activities = _getActivityPricings();

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
              Tab(text: '🏨 Hotels & Stays'),
              Tab(text: '📱 Apps'),
              Tab(text: '🌤️ Weather'),
              Tab(text: '📅 Schedule'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFlightsAndCarsTab(flights, daysUntil),
            _buildHotelsTab(hotels),
            _buildRecommendedAppsTab(),
            _buildWeatherTab(),
            _buildScheduleTab(activities),
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

  Widget _buildFlightsAndCarsTab(List<Map<String, dynamic>> flights, int daysUntil) {
    final config = _config;
    final primaryCity = config?.primaryCity ?? (widget.trip.days.isNotEmpty ? widget.trip.days.first.location : 'City');
    final travelDays = widget.trip.days.where((d) => d.isTravelDay).toList();
    final pickupDate = travelDays.isNotEmpty ? travelDays.first.date : widget.trip.startDate;
    final returnDate = travelDays.isNotEmpty ? travelDays.last.date : widget.trip.endDate;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTripContextHeader(widget.trip, daysUntil),
        const SizedBox(height: 16),
        _buildDepartureCountdown(daysUntil),
        const SizedBox(height: 16),
        // Flight pricing — show all destination cities
        _buildSectionHeader('�️ Flights', 'All destinations in your itinerary'),
        const SizedBox(height: 8),
        ...flights.map((flight) => _buildPriceAlertCard(
          title: flight['label'] as String,
          currentPrice: '${(flight['current'] as double).toStringAsFixed(0)} ${flight['currency']}',
          averagePrice: '${(flight['average'] as double).toStringAsFixed(0)} ${flight['currency']}',
          trend: _trend(flight['current'] as double, flight['average'] as double),
          detail: _buildPriceInsight(flight['current'] as double, flight['average'] as double, 'flight'),
          priceHistory: flight['history'] as List<double>,
          purchaseUrl: _skyscannerUrl(flight['from'] as String, flight['to'] as String, flight['departureDate'] as String),
          purchaseLabel: 'Search on Skyscanner',
        )),
        const SizedBox(height: 16),
        // Car rental
        _buildSectionHeader('� Rental Cars', 'Compare providers in $primaryCity'),
        const SizedBox(height: 8),
        _buildRentalCard(
          provider: 'Sixt',
          description: 'Wide range of vehicles including sedans and SUVs',
          url: _sixtUrl(primaryCity.toLowerCase().replaceAll(' ', '-'), pickupDate, returnDate),
          color: const Color(0xFFE53935),
          icon: Icons.directions_car,
        ),
        _buildRentalCard(
          provider: 'Enterprise',
          description: 'Reliable service with airport pickup available',
          url: _enterpriseUrl(primaryCity.toLowerCase().replaceAll(' ', '-'), pickupDate, returnDate),
          color: const Color(0xFF43A047),
          icon: Icons.business,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildHotelsTab(List<Map<String, dynamic>> hotels) {
    final config = _config;
    final currency = widget.trip.currency;

    // Build a flat list of price alert cards from each hotel entry.
    // Each hotel generates: Booking.com card, Agoda card (5% cheaper), Airbnb card (15% cheaper).
    final hotelCards = <Widget>[];
    String? lastCity;

    for (final hotel in hotels) {
      final current = (hotel['current'] as double);
      final average = (hotel['average'] as double);
      final history = hotel['history'] as List<double>;
      final city = hotel['city'] as String;
      final checkIn = hotel['checkIn'] as String;
      final checkOut = hotel['checkOut'] as String;
      final label = hotel['label'] as String;
      final hotelCurrency = hotel['currency'] as String? ?? currency;
      final cityDisplay = city.replaceAll('+', ' ');

      // Add a section header when the city changes
      if (cityDisplay != lastCity) {
        hotelCards.add(_buildSectionHeader('🏨 $cityDisplay', 'Compare across Booking, Agoda & Airbnb'));
        hotelCards.add(const SizedBox(height: 12));
        lastCity = cityDisplay;
      }

      // Booking.com card
      hotelCards.add(_buildPriceAlertCard(
        title: label,
        currentPrice: '${current.toStringAsFixed(0)} $hotelCurrency/night',
        averagePrice: '${average.toStringAsFixed(0)} $hotelCurrency/night',
        trend: _trend(current, average),
        detail: _buildPriceInsight(current, average, 'hotel'),
        priceHistory: history,
        purchaseUrl: _bookingUrl(city, checkIn, checkOut),
        purchaseLabel: 'Search on Booking.com',
      ));

      // Agoda card (typically ~5% cheaper)
      hotelCards.add(_buildPriceAlertCard(
        title: '$cityDisplay (Agoda)',
        currentPrice: '${(current * 0.95).toStringAsFixed(0)} $hotelCurrency/night',
        averagePrice: '${average.toStringAsFixed(0)} $hotelCurrency/night',
        trend: PriceTrend.below,
        detail: 'Agoda often has better deals for Southeast Asia. Compare before booking.',
        priceHistory: history,
        purchaseUrl: _agodaUrl(city, checkIn, checkOut),
        purchaseLabel: 'Search on Agoda',
      ));

      // Airbnb card (typically ~15% cheaper)
      hotelCards.add(_buildPriceAlertCard(
        title: 'Airbnb: $cityDisplay',
        currentPrice: '${(current * 0.85).toStringAsFixed(0)} $hotelCurrency/night',
        averagePrice: '${(average * 0.9).toStringAsFixed(0)} $hotelCurrency/night',
        trend: PriceTrend.below,
        detail: 'Great for longer stays. Often includes kitchen to save on food costs.',
        priceHistory: history,
        purchaseUrl: _airbnbUrl(cityDisplay, checkIn, checkOut),
        purchaseLabel: 'Search on Airbnb',
      ));

      hotelCards.add(const SizedBox(height: 8));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (hotels.isEmpty)
          _buildSectionHeader('🏨 Hotels & Airbnb', 'No hotel data available for this trip.')
        else
          ...hotelCards,
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildRecommendedAppsTab() {
    final config = _config;
    final countryName = config?.country ?? 'Your Destination';
    final apps = config?.recommendedApps ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('� Recommended Apps for $countryName', 'Download before your trip'),
        const SizedBox(height: 12),
        ...apps.map((app) => _buildAppCard(
          name: app.name,
          category: app.category,
          description: app.description,
          url: app.url,
          icon: parseIcon(app.iconName),
          color: Color(app.colorValue),
        )),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildWeatherTab() {
    final config = _config;
    final profiles = config?.weatherProfiles ?? [];
    final countryName = config?.country ?? 'Your Destination';

    // Map severity string to WeatherStatus
    WeatherStatus _statusFromSeverity(String s) {
      switch (s.toLowerCase()) {
        case 'warning': return WeatherStatus.warning;
        case 'caution': return WeatherStatus.caution;
        default: return WeatherStatus.good;
      }
    }

    // Map severity string to icon
    IconData _iconFromSeverity(String s) {
      switch (s.toLowerCase()) {
        case 'warning': return Icons.umbrella;
        case 'caution': return Icons.cloud;
        default: return Icons.wb_sunny;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('🌤️ Weather for $countryName', 'Alerts for severe conditions'),
        const SizedBox(height: 12),
        ...profiles.map((p) {
          // Find approximate date for this location from the itinerary
          final dayMatch = widget.trip.days.firstWhere(
            (d) => d.location.toLowerCase().contains(p.location.toLowerCase().split(' ')[0]),
            orElse: () => widget.trip.days.first,
          );
          return _buildWeatherCard(
            location: p.location,
            date: dayMatch.date,
            status: _statusFromSeverity(p.severity),
            detail: p.detail,
            icon: _iconFromSeverity(p.severity),
          );
        }),
        if (profiles.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No weather alerts for this destination.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildScheduleTab(List<Map<String, dynamic>> activities) {
    final config = _config;
    final countryName = config?.country ?? widget.trip.days.first.country;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('📅 Schedule Checks', 'Timing reminders for your itinerary'),
        const SizedBox(height: 12),
        // Generate a notice for each day that has activities
        ...widget.trip.days.map((day) {
          final dayActivities = day.activities.join(', ');
          if (dayActivities.isEmpty) return const SizedBox.shrink();
          return _buildClosureCard(
            venue: day.title,
            plannedDay: 'Day ${day.day} (${day.date})',
            issue: dayActivities.length > 60
                ? '${dayActivities.substring(0, 57)}...'
                : dayActivities,
            status: ClosureStatus.info,
          );
        }),
        const SizedBox(height: 24),
        // Activities pricing section (if activities found)
        if (activities.isNotEmpty) ...[
          _buildSectionHeader('🎟 Tours & Activities', 'Pricing based on your destinations'),
          const SizedBox(height: 12),
          ...activities.map((a) => _buildPriceAlertCard(
            title: a['label'] ?? 'Activity',
            currentPrice: '${(a['current'] as double).toStringAsFixed(0)} ${a['currency']}/person',
            averagePrice: '${(a['average'] as double).toStringAsFixed(0)} ${a['currency']}/person',
            trend: _trend(a['current'] as double, a['average'] as double),
            detail: _buildPriceInsight(a['current'] as double, a['average'] as double, 'activity'),
            priceHistory: a['history'] as List<double>,
            purchaseUrl: _bookingUrl(countryName.replaceAll(' ', '+'), a['date'] as String, a['date'] as String),
            purchaseLabel: 'Search',
          )),
        ],
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
                  style: TextStyle(fontSize: 11, color: Color(0xFF666666)),
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
        : status == ClosureStatus.info
            ? const Color(0xFF6C63FF)
            : status == ClosureStatus.warning
                ? const Color(0xFFFFAB40)
                : const Color(0xFFFF6B6B);
    final icon = status == ClosureStatus.ok
        ? Icons.check_circle
        : status == ClosureStatus.info
            ? Icons.info_outline
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

}

// ─── Enums ─────────────────────────────────────────────────────────────

enum PriceTrend { below, above, average }
enum WeatherStatus { good, caution, warning }
enum ClosureStatus { ok, info, warning, closed }

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
