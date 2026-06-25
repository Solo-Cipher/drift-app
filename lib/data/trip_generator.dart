import 'package:flutter/material.dart';
import '../models/trip_data.dart';
import '../data/city_configs.dart';

/// Generates a complete trip with destination-specific day content
/// (activities, transport, accommodation, food costs) for each supported country.
class TripGenerator {
  /// Generate a trip for the given country key with the specified date range
  static TripData generate({
    required String countryKey,
    required DateTime startDate,
    required DateTime endDate,
    String? title,
  }) {
    final config = CityConfigs.get(countryKey);
    final totalDays = endDate.difference(startDate).inDays + 1;
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    final startStr = '${months[startDate.month - 1]} ${startDate.day}, ${startDate.year}';
    final endStr = '${months[endDate.month - 1]} ${endDate.day}, ${endDate.year}';

    // Get country-specific day templates
    final days = _generateDays(countryKey, startDate, totalDays);

    return TripData(
      title: title ?? '${config.country} Trip',
      subtitle: 'Muscat → ${config.primaryCity}',
      startDate: startStr,
      endDate: endStr,
      totalDays: totalDays,
      totalBudget: _calculateBudget(days, config.currency),
      currency: 'OMR',
      days: days,
      baseStartDate: startDate,
    );
  }

  static String _calculateBudget(List<TripDay> days, String currency) {
    double total = 0;
    for (final day in days) {
      total += day.totalCost;
    }
    return total.toStringAsFixed(0);
  }

  static List<TripDay> _generateDays(String countryKey, DateTime startDate, int totalDays) {
    switch (countryKey) {
      case 'vietnam':
        return _vietnamDays(startDate, totalDays);
      case 'sri_lanka':
        return _sriLankaDays(startDate, totalDays);
      case 'indonesia':
        return _indonesiaDays(startDate, totalDays);
      case 'scotland':
        return _scotlandDays(startDate, totalDays);
      case 'mauritius':
        return _mauritiusDays(startDate, totalDays);
      case 'thailand':
        return _thailandDays(startDate, totalDays);
      case 'japan':
        return _japanDays(startDate, totalDays);
      case 'turkey':
        return _turkeyDays(startDate, totalDays);
      case 'morocco':
        return _moroccoDays(startDate, totalDays);
      default:
        return _genericDays(startDate, totalDays, countryKey);
    }
  }

  static String _dateStr(DateTime d) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }

  // ── VIETNAM ──────────────────────────────────────────────────────────
  static List<TripDay> _vietnamDays(DateTime startDate, int totalDays) {
    final cities = CityConfigs.get('vietnam').cities;
    final hanoi = cities['hanoi']!;
    final hcmc = cities['hcmc']!;
    final haLong = cities['ha_long']!;
    final daNang = cities['da_nang']!;
    final hue = cities['hue']!;
    final nhaTrang = cities['nha_trang']!;
    final phuQuoc = cities['phu_quoc']!;

    final List<Map<String, dynamic>> templates = [
      {'location': hanoi.displayName, 'country': 'vietnam', 'title': 'Arrival in Hanoi', 'description': 'Fly from Muscat to Hanoi. Settle into the Old Quarter and explore the vibrant street life.', 'activities': ['Hoan Kiem Lake evening walk', 'Old Quarter exploration', 'Pho dinner at local spot'], 'arrivalTransport': TransportMode.flight, 'transportDuration': '14h total', 'transportCost': '200', 'accommodationCost': '25', 'foodCost': '8', 'icon': Icons.flight_land, 'color': const Color(0xFF6C63FF), 'isTravelDay': true, 'lat': hanoi.coordinates.lat, 'lng': hanoi.coordinates.lng},
      {'location': hanoi.displayName, 'country': 'vietnam', 'title': 'Hanoi Old Quarter', 'description': 'Dive into Hanoi\'s chaotic charm — ancient temples, street food, and endless motorbikes.', 'activities': ['Hoan Kiem Lake morning walk', 'Old Quarter walking tour', 'Pho at Pho Thin', 'Temple of Literature', 'Egg coffee at Café Giang', 'Street food tour evening'], 'accommodationCost': '25', 'foodCost': '12', 'icon': Icons.temple_buddhist, 'color': const Color(0xFFFF6B6B), 'lat': hanoi.coordinates.lat, 'lng': hanoi.coordinates.lng},
      {'location': hanoi.displayName, 'country': 'vietnam', 'title': 'Culture & History', 'description': 'Vietnam\'s rich history comes alive at museums and monuments.', 'activities': ['Ho Chi Minh Mausoleum (closed Mon/Fri)', 'One Pillar Pagoda', 'Vietnam Museum of Ethnology', 'Water Puppet Show at Thang Long', 'West Lake sunset walk'], 'accommodationCost': '25', 'foodCost': '12', 'icon': Icons.museum, 'color': const Color(0xFF00BFA6), 'lat': hanoi.coordinates.lat, 'lng': hanoi.coordinates.lng},
      {'location': haLong.displayName, 'country': 'vietnam', 'title': 'Ha Long Bay Cruise', 'description': 'Board an overnight cruise through legendary limestone karsts.', 'activities': ['Kayaking through caves', 'Swim in emerald waters', 'Sunset dinner on deck', 'Tai Chi at sunrise'], 'arrivalTransport': TransportMode.bus, 'transportDuration': '2.5h', 'transportCost': '8', 'accommodationCost': '50', 'foodCost': '0', 'icon': Icons.directions_boat, 'color': const Color(0xFF00B4D8), 'lat': haLong.coordinates.lat, 'lng': haLong.coordinates.lng},
      {'location': haLong.displayName, 'country': 'vietnam', 'title': 'Cruise & Fly South', 'description': 'Morning cruise, return to Hanoi, evening flight to Ho Chi Minh City.', 'activities': ['Tai Chi on deck', 'Sung Sot Cave visit', 'Brunch on board'], 'arrivalTransport': TransportMode.boat, 'departureTransport': TransportMode.flight, 'transportDuration': '2.5h + 2h', 'transportCost': '30', 'accommodationCost': '25', 'foodCost': '5', 'icon': Icons.flight_takeoff, 'color': const Color(0xFF6C63FF), 'isTravelDay': true, 'lat': haLong.coordinates.lat, 'lng': haLong.coordinates.lng},
      {'location': hcmc.displayName, 'country': 'vietnam', 'title': 'Welcome to Saigon', 'description': 'Arrive in Vietnam\'s bustling southern metropolis. The energy is electric.', 'activities': ['War Remnants Museum', 'Ben Thanh Market', 'Rooftop bar sunset', 'Bui Vien Street nightlife'], 'accommodationCost': '25', 'foodCost': '12', 'icon': Icons.location_city, 'color': const Color(0xFFE91E63), 'lat': hcmc.coordinates.lat, 'lng': hcmc.coordinates.lng},
      {'location': 'Cu Chi', 'country': 'vietnam', 'title': 'Cu Chi Tunnels Day Trip', 'description': 'Explore the incredible underground tunnel network from the Vietnam War.', 'activities': ['Crawl through restored tunnels', 'Learn about wartime traps', 'Rooftop dinner with city views'], 'arrivalTransport': TransportMode.bus, 'transportDuration': '1.5h each way', 'transportCost': '10', 'accommodationCost': '25', 'foodCost': '12', 'icon': Icons.terrain, 'color': const Color(0xFF795548), 'lat': 11.0667, 'lng': 106.5167},
      {'location': hcmc.displayName, 'country': 'vietnam', 'title': 'Food & Markets', 'description': 'A full day dedicated to Saigon\'s incredible food scene.', 'activities': ['Bun cha breakfast', 'Jade Emperor Pagoda', 'Street food tour by motorbike', 'Cooking class afternoon', 'Dinner at The Deck Saigon'], 'accommodationCost': '25', 'foodCost': '20', 'icon': Icons.restaurant, 'color': const Color(0xFFFF9800), 'lat': hcmc.coordinates.lat, 'lng': hcmc.coordinates.lng},
      {'location': 'Mekong Delta', 'country': 'vietnam', 'title': 'Mekong Delta Adventure', 'description': 'Full day tour of Vietnam\'s lush river delta and floating markets.', 'activities': ['Boat through Mekong channels', 'Coconut candy farm', 'Elephant ear fish tasting', 'Village cycling'], 'arrivalTransport': TransportMode.bus, 'transportDuration': '2h each way', 'transportCost': '15', 'accommodationCost': '25', 'foodCost': '12', 'icon': Icons.water, 'color': const Color(0xFF4CAF50), 'lat': 10.3167, 'lng': 106.3500},
      {'location': hcmc.displayName, 'country': 'vietnam', 'title': 'Relax & Explore', 'description': 'A relaxed day to explore whatever you missed or soak in Saigon\'s vibe.', 'activities': ['Rooftop cafe breakfast', 'Saigon Central Post Office', 'Pink Church photography', 'Couple\'s spa afternoon', 'Dinner at Propaganda Bistro'], 'accommodationCost': '25', 'foodCost': '15', 'icon': Icons.spa, 'color': const Color(0xFF9C27B0), 'lat': hcmc.coordinates.lat, 'lng': hcmc.coordinates.lng},
      {'location': phuQuoc.displayName, 'country': 'vietnam', 'title': 'Phu Quoc Beach Day', 'description': 'Fly to Vietnam\'s paradise island for a beach day before heading home.', 'activities': ['Long Beach afternoon', 'Snorkeling session', 'Sunset dinner on beach'], 'arrivalTransport': TransportMode.flight, 'transportDuration': '1h', 'transportCost': '25', 'accommodationCost': '40', 'foodCost': '15', 'icon': Icons.beach_access, 'color': const Color(0xFF00BCD4), 'lat': phuQuoc.coordinates.lat, 'lng': phuQuoc.coordinates.lng},
      {'location': phuQuoc.displayName, 'country': 'vietnam', 'title': 'Departure Day', 'description': 'Last beach morning, then fly home to Muscat.', 'activities': ['Beach morning swim', 'Souvenir shopping'], 'departureTransport': TransportMode.flight, 'transportDuration': '12h total', 'transportCost': '0', 'accommodationCost': '0', 'foodCost': '5', 'icon': Icons.flight_takeoff, 'color': const Color(0xFF6C63FF), 'isTravelDay': true, 'lat': phuQuoc.coordinates.lat, 'lng': phuQuoc.coordinates.lng},
    ];
    return _buildDaysFromTemplates(templates, startDate, totalDays);
  }

  // ── SRI LANKA ────────────────────────────────────────────────────────
  static List<TripDay> _sriLankaDays(DateTime startDate, int totalDays) {
    final cities = CityConfigs.get('sri_lanka').cities;
    final colombo = cities['colombo']!;
    final sigiriya = cities['sigiriya']!;
    final kandy = cities['kandy']!;
    final ella = cities['ella']!;
    final galle = cities['galle']!;
    final mirissa = cities['mirissa']!;

    final List<Map<String, dynamic>> templates = [
      {'location': colombo.displayName, 'country': 'sri_lanka', 'title': 'Arrival in Colombo', 'description': 'Fly from Muscat to Colombo. Settle in, explore the waterfront and street food.', 'activities': ['Galle Face Green sunset', 'Street food at Galle Road', 'Pettah Market area'], 'arrivalTransport': TransportMode.flight, 'transportDuration': '6h total', 'transportCost': '180', 'accommodationCost': '22', 'foodCost': '8', 'icon': Icons.flight_land, 'color': const Color(0xFF6C63FF), 'isTravelDay': true, 'lat': colombo.coordinates.lat, 'lng': colombo.coordinates.lng},
      {'location': colombo.displayName, 'country': 'sri_lanka', 'title': 'Explore Colombo', 'description': 'Temples, colonial architecture, and the best kottu in town.', 'activities': ['Gangaramaya Temple', 'Independence Memorial Hall', 'Ministry of Crab lunch', 'Viharamahadevi Park', 'Dutch Hospital dinner'], 'accommodationCost': '22', 'foodCost': '15', 'icon': Icons.temple_buddhist, 'color': const Color(0xFFFF6B6B), 'lat': colombo.coordinates.lat, 'lng': colombo.coordinates.lng},
      {'location': sigiriya.displayName, 'country': 'sri_lanka', 'title': 'Journey to Sigiriya', 'description': 'Early transfer to the cultural triangle. Climb the iconic Lion Rock.', 'activities': ['Scenic hill country drive', 'Sigiriya Lion Rock climb', 'Sunset from summit', 'Traditional dinner'], 'arrivalTransport': TransportMode.car, 'transportDuration': '4h', 'transportCost': '30', 'accommodationCost': '24', 'foodCost': '10', 'icon': Icons.terrain, 'color': const Color(0xFF795548), 'lat': sigiriya.coordinates.lat, 'lng': sigiriya.coordinates.lng},
      {'location': sigiriya.displayName, 'country': 'sri_lanka', 'title': 'Dambulla & Village Life', 'description': 'Ancient cave temples and rural Sri Lankan life.', 'activities': ['Dambulla Cave Temple', 'Bullock cart ride', 'Cooking class', 'Catamaran lake ride', 'Spice garden'], 'accommodationCost': '24', 'foodCost': '12', 'icon': Icons.temple_buddhist, 'color': const Color(0xFF00BFA6), 'lat': sigiriya.coordinates.lat, 'lng': sigiriya.coordinates.lng},
      {'location': kandy.displayName, 'country': 'sri_lanka', 'title': 'Transfer to Kandy', 'description': 'Drive to the hill capital. Visit the Temple of the Tooth.', 'activities': ['Temple of the Tooth', 'Kandy Lake walk', 'Kandy Market', 'Cultural dance show', 'Helga\'s Folly dinner'], 'arrivalTransport': TransportMode.car, 'transportDuration': '2.5h', 'transportCost': '20', 'accommodationCost': '18', 'foodCost': '12', 'icon': Icons.temple_buddhist, 'color': const Color(0xFFE91E63), 'lat': kandy.coordinates.lat, 'lng': kandy.coordinates.lng},
      {'location': kandy.displayName, 'country': 'sri_lanka', 'title': 'Kandy Highlands', 'description': 'Tea plantations, botanical gardens, mountain views.', 'activities': ['Botanical Garden', 'Tea factory tour', 'Udawattakele Forest', 'Kandy viewpoint sunset', 'Local kottu dinner'], 'accommodationCost': '18', 'foodCost': '10', 'icon': Icons.park, 'color': const Color(0xFF4CAF50), 'lat': kandy.coordinates.lat, 'lng': kandy.coordinates.lng},
      {'location': ella.displayName, 'country': 'sri_lanka', 'title': 'Scenic Train to Ella', 'description': 'One of the world\'s most beautiful train rides.', 'activities': ['Kandy to Ella train (1st class)', 'Nine Arches Bridge', 'Little Adam\'s Peak', 'Ella Gap sunset', 'Chill Cafe dinner'], 'arrivalTransport': TransportMode.train, 'transportDuration': '7h (scenic)', 'transportCost': '8', 'accommodationCost': '16', 'foodCost': '10', 'icon': Icons.train, 'color': const Color(0xFF00B4D8), 'lat': ella.coordinates.lat, 'lng': ella.coordinates.lng},
      {'location': ella.displayName, 'country': 'sri_lanka', 'title': 'Ella Adventure Day', 'description': 'Hike Ella Rock, explore waterfalls, relax in mountain air.', 'activities': ['Ella Rock sunrise hike', 'Ravana Falls', 'Tea plantation walk', 'Zip-lining', 'BBQ dinner'], 'accommodationCost': '16', 'foodCost': '12', 'icon': Icons.terrain, 'color': const Color(0xFF6C63FF), 'lat': ella.coordinates.lat, 'lng': ella.coordinates.lng},
      {'location': galle.displayName, 'country': 'sri_lanka', 'title': 'Down South to Galle', 'description': 'Transfer to the south coast. Explore UNESCO Galle Fort.', 'activities': ['Scenic coastal drive', 'Galle Fort walking tour', 'Lighthouse sunset', 'Flag Rock Bastion', 'Seafood dinner'], 'arrivalTransport': TransportMode.car, 'transportDuration': '5h', 'transportCost': '35', 'accommodationCost': '25', 'foodCost': '15', 'icon': Icons.castle, 'color': const Color(0xFFFF9800), 'lat': galle.coordinates.lat, 'lng': galle.coordinates.lng},
      {'location': mirissa.displayName, 'country': 'sri_lanka', 'title': 'Beach Day at Mirissa', 'description': 'Whale watching, beach time, coastal vibes.', 'activities': ['Whale watching tour', 'Coconut Tree Hill sunset', 'Secret Beach swim', 'Fresh seafood lunch', 'Beach bar evening'], 'arrivalTransport': TransportMode.tuktuk, 'transportDuration': '45min', 'transportCost': '5', 'accommodationCost': '22', 'foodCost': '15', 'icon': Icons.beach_access, 'color': const Color(0xFF00BCD4), 'lat': mirissa.coordinates.lat, 'lng': mirissa.coordinates.lng},
      {'location': colombo.displayName, 'country': 'sri_lanka', 'title': 'Return to Colombo', 'description': 'Coastal train back. Last-minute shopping and farewell dinner.', 'activities': ['Galle to Colombo train', 'ODEL shopping', 'Pettah souvenirs', 'Nuga Gama farewell dinner', 'Sky Lounge rooftop'], 'arrivalTransport': TransportMode.train, 'transportDuration': '2.5h', 'transportCost': '3', 'accommodationCost': '22', 'foodCost': '18', 'icon': Icons.shopping_bag, 'color': const Color(0xFF9C27B0), 'lat': colombo.coordinates.lat, 'lng': colombo.coordinates.lng},
      {'location': colombo.displayName, 'country': 'sri_lanka', 'title': 'Departure Day', 'description': 'Last morning in Sri Lanka. Fly home to Muscat.', 'activities': ['Galle Face Green walk', 'Last curry lunch', 'Airport transfer'], 'departureTransport': TransportMode.flight, 'transportDuration': '6h total', 'transportCost': '0', 'accommodationCost': '0', 'foodCost': '8', 'icon': Icons.flight_takeoff, 'color': const Color(0xFF6C63FF), 'isTravelDay': true, 'lat': colombo.coordinates.lat, 'lng': colombo.coordinates.lng},
    ];
    return _buildDaysFromTemplates(templates, startDate, totalDays);
  }

  // ── INDONESIA ────────────────────────────────────────────────────────
  static List<TripDay> _indonesiaDays(DateTime startDate, int totalDays) {
    final cities = CityConfigs.get('indonesia').cities;
    final jakarta = cities['jakarta']!;
    final bali = cities['bali']!;
    final lombok = cities['lombok']!;
    final yogyakarta = cities['yogyakarta']!;

    final List<Map<String, dynamic>> templates = [
      {'location': jakarta.displayName, 'country': 'indonesia', 'title': 'Arrival in Jakarta', 'description': 'Fly from Muscat to Jakarta. Settle in and explore the capital.', 'activities': ['Monas (National Monument)', 'Kota Tua Old Town', 'Street food in Glodok'], 'arrivalTransport': TransportMode.flight, 'transportDuration': '12h total', 'transportCost': '200', 'accommodationCost': '24', 'foodCost': '8', 'icon': Icons.flight_land, 'color': const Color(0xFF6C63FF), 'isTravelDay': true, 'lat': jakarta.coordinates.lat, 'lng': jakarta.coordinates.lng},
      {'location': jakarta.displayName, 'country': 'indonesia', 'title': 'Jakarta Exploration', 'description': 'Dive into Indonesia\'s capital — markets, temples, and food.', 'activities': ['Istiqlal Mosque', 'National Museum', 'Mangga Dua shopping', 'Padang lunch'], 'accommodationCost': '24', 'foodCost': '10', 'icon': Icons.temple_buddhist, 'color': const Color(0xFFFF6B6B), 'lat': jakarta.coordinates.lat, 'lng': jakarta.coordinates.lng},
      {'location': yogyakarta.displayName, 'country': 'indonesia', 'title': 'Fly to Yogyakarta', 'description': 'Fly to Java\'s cultural heart. Visit Borobudur at sunrise.', 'activities': ['Borobudur sunrise tour', 'Prambanan Temple', 'Malioboro Street', 'Gudeg dinner'], 'arrivalTransport': TransportMode.flight, 'transportDuration': '1.5h', 'transportCost': '25', 'accommodationCost': '15', 'foodCost': '10', 'icon': Icons.temple_buddhist, 'color': const Color(0xFF00BFA6), 'lat': yogyakarta.coordinates.lat, 'lng': yogyakarta.coordinates.lng},
      {'location': yogyakarta.displayName, 'country': 'indonesia', 'title': 'Java Culture', 'description': 'Explore Javanese culture, batik, and ancient temples.', 'activities': ['Sultan\'s Kraton', 'Batik workshop', 'Timang Beach', 'Jomblang Cave'], 'accommodationCost': '15', 'foodCost': '10', 'icon': Icons.palette, 'color': const Color(0xFF795548), 'lat': yogyakarta.coordinates.lat, 'lng': yogyakarta.coordinates.lng},
      {'location': bali.displayName, 'country': 'indonesia', 'title': 'Fly to Bali', 'description': 'Fly to the Island of Gods. Time for beaches and temples.', 'activities': ['Tanah Lot temple sunset', 'Seminyak beach club', 'Uluwatu Kecak dance'], 'arrivalTransport': TransportMode.flight, 'transportDuration': '2.5h', 'transportCost': '30', 'accommodationCost': '25', 'foodCost': '12', 'icon': Icons.beach_access, 'color': const Color(0xFF00B4D8), 'lat': bali.coordinates.lat, 'lng': bali.coordinates.lng},
      {'location': bali.displayName, 'country': 'indonesia', 'title': 'Ubud Rice Terraces', 'description': 'Explore Ubud\'s stunning rice terraces and art scene.', 'activities': ['Tegallalang Rice Terraces', 'Ubud Monkey Forest', 'Art market shopping', 'Balinese cooking class'], 'accommodationCost': '25', 'foodCost': '12', 'icon': Icons.terrain, 'color': const Color(0xFF4CAF50), 'lat': bali.coordinates.lat, 'lng': bali.coordinates.lng},
      {'location': bali.displayName, 'country': 'indonesia', 'title': 'Bali Beaches', 'description': 'Beach day — swim, surf, or just relax.', 'activities': ['Kuta Beach morning', 'Waterbom Bali', 'Jimbaran seafood dinner', 'Beach club sunset'], 'accommodationCost': '25', 'foodCost': '15', 'icon': Icons.beach_access, 'color': const Color(0xFFFF9800), 'lat': bali.coordinates.lat, 'lng': bali.coordinates.lng},
      {'location': lombok.displayName, 'country': 'indonesia', 'title': 'Lombok Escape', 'description': 'Fast boat to Lombok for waterfalls and pristine beaches.', 'activities': ['Tiu Kelep Waterfall', 'Senggigi Beach', 'Gili Islands snorkeling', 'Sunset at Malimbu'], 'arrivalTransport': TransportMode.boat, 'transportDuration': '2h', 'transportCost': '15', 'accommodationCost': '18', 'foodCost': '12', 'icon': Icons.directions_boat, 'color': const Color(0xFF00BCD4), 'lat': lombok.coordinates.lat, 'lng': lombok.coordinates.lng},
      {'location': lombok.displayName, 'country': 'indonesia', 'title': 'Gili Islands', 'description': 'Snorkel, bike around the island, watch the sunset.', 'activities': ['Snorkeling with turtles', 'Bike around Gili T', 'Underwater statues', 'Beachside BBQ'], 'accommodationCost': '18', 'foodCost': '12', 'icon': Icons.directions_bike, 'color': const Color(0xFF9C27B0), 'lat': lombok.coordinates.lat, 'lng': lombok.coordinates.lng},
      {'location': bali.displayName, 'country': 'indonesia', 'title': 'Return to Bali', 'description': 'Back to Bali for last-minute shopping and relaxation.', 'activities': ['Sukawati Art Market', 'Spa treatment', 'Nasi goreng dinner', 'Beach walk'], 'arrivalTransport': TransportMode.boat, 'transportDuration': '2h', 'transportCost': '15', 'accommodationCost': '25', 'foodCost': '12', 'icon': Icons.shopping_bag, 'color': const Color(0xFFFF6B6B), 'lat': bali.coordinates.lat, 'lng': bali.coordinates.lng},
      {'location': bali.displayName, 'country': 'indonesia', 'title': 'Departure Day', 'description': 'Last morning in Bali. Fly home to Muscat.', 'activities': ['Beach morning swim', 'Souvenir hunt', 'Airport transfer'], 'departureTransport': TransportMode.flight, 'transportDuration': '12h total', 'transportCost': '0', 'accommodationCost': '0', 'foodCost': '8', 'icon': Icons.flight_takeoff, 'color': const Color(0xFF6C63FF), 'isTravelDay': true, 'lat': bali.coordinates.lat, 'lng': bali.coordinates.lng},
    ];
    return _buildDaysFromTemplates(templates, startDate, totalDays);
  }

  // ── SCOTLAND ─────────────────────────────────────────────────────────
  static List<TripDay> _scotlandDays(DateTime startDate, int totalDays) {
    final cities = CityConfigs.get('scotland').cities;
    final edinburgh = cities['edinburgh']!;
    final glasgow = cities['glasgow']!;
    final highlands = cities['highlands']!;
    final skye = cities['skye']!;

    final List<Map<String, dynamic>> templates = [
      {'location': edinburgh.displayName, 'country': 'scotland', 'title': 'Arrival in Edinburgh', 'description': 'Fly from Muscat to Edinburgh. Explore the Old Town and castle.', 'activities': ['Royal Mile walk', 'Edinburgh Castle', 'Arthur\'s Seat hike', 'Pub dinner on Grassmarket'], 'arrivalTransport': TransportMode.flight, 'transportDuration': '12h total', 'transportCost': '280', 'accommodationCost': '48', 'foodCost': '12', 'icon': Icons.flight_land, 'color': const Color(0xFF6C63FF), 'isTravelDay': true, 'lat': edinburgh.coordinates.lat, 'lng': edinburgh.coordinates.lng},
      {'location': edinburgh.displayName, 'country': 'scotland', 'title': 'Edinburgh Old Town', 'description': 'Dive into Scotland\'s history — castles, closes, and whisky.', 'activities': ['St Giles\' Cathedral', 'Real Mary King\'s Close', 'Whisky tasting', 'National Museum of Scotland'], 'accommodationCost': '48', 'foodCost': '15', 'icon': Icons.castle, 'color': const Color(0xFFFF6B6B), 'lat': edinburgh.coordinates.lat, 'lng': edinburgh.coordinates.lng},
      {'location': edinburgh.displayName, 'country': 'scotland', 'title': 'Harry Potter Trail', 'description': 'Follow in the footsteps of Hogwarts.', 'activities': ['Victoria Street (Diagon Alley)', 'Greyfriars Kirkyard', 'Elephant House cafe', 'Botanic Garden walk'], 'accommodationCost': '48', 'foodCost': '12', 'icon': Icons.auto_stories, 'color': const Color(0xFF00BFA6), 'lat': edinburgh.coordinates.lat, 'lng': edinburgh.coordinates.lng},
      {'location': highlands.displayName, 'country': 'scotland', 'title': 'Highlands Road Trip', 'description': 'Drive into the Scottish Highlands. Mountains, lochs, and glens.', 'activities': ['Glencoe valley stop', 'Glenfinnan Viaduct', 'Loch Ness search', 'Fort William lunch'], 'arrivalTransport': TransportMode.car, 'transportDuration': '3h', 'transportCost': '25', 'accommodationCost': '42', 'foodCost': '12', 'icon': Icons.landscape, 'color': const Color(0xFF4CAF50), 'lat': highlands.coordinates.lat, 'lng': highlands.coordinates.lng},
      {'location': highlands.displayName, 'country': 'scotland', 'title': 'Loch Ness & Castles', 'description': 'Search for Nessie and explore ancient castles.', 'activities': ['Urquhart Castle', 'Loch Ness boat cruise', 'Culloden Battlefield', 'Dinner in Inverness'], 'accommodationCost': '42', 'foodCost': '15', 'icon': Icons.directions_boat, 'color': const Color(0xFF00B4D8), 'lat': highlands.coordinates.lat, 'lng': highlands.coordinates.lng},
      {'location': skye.displayName, 'country': 'scotland', 'title': 'Isle of Skye', 'description': 'Drive to Skye for dramatic landscapes and fairy pools.', 'activities': ['Old Man of Storr hike', 'Fairy Pools', 'Portree lunch', 'Quiraing viewpoint'], 'arrivalTransport': TransportMode.car, 'transportDuration': '2h', 'transportCost': '15', 'accommodationCost': '50', 'foodCost': '12', 'icon': Icons.terrain, 'color': const Color(0xFF795548), 'lat': skye.coordinates.lat, 'lng': skye.coordinates.lng},
      {'location': skye.displayName, 'country': 'scotland', 'title': 'Skye Coastal Day', 'description': 'Explore Skye\'s coastline and waterfalls.', 'activities': ['Kilt Rock waterfall', 'Neist Point lighthouse', 'Fairy Glen', 'Seafood dinner in Portree'], 'accommodationCost': '50', 'foodCost': '15', 'icon': Icons.water, 'color': const Color(0xFFFF9800), 'lat': skye.coordinates.lat, 'lng': skye.coordinates.lng},
      {'location': glasgow.displayName, 'country': 'scotland', 'title': 'Glasgow City', 'description': 'Drive to Glasgow for art, music, and food.', 'activities': ['Kelvingrove Museum', 'Glasgow Cathedral', 'Buchanan Street shopping', 'Live music at King Tut\'s'], 'arrivalTransport': TransportMode.car, 'transportDuration': '2h', 'transportCost': '15', 'accommodationCost': '38', 'foodCost': '15', 'icon': Icons.location_city, 'color': const Color(0xFFE91E63), 'lat': glasgow.coordinates.lat, 'lng': glasgow.coordinates.lng},
      {'location': glasgow.displayName, 'country': 'scotland', 'title': 'Glasgow Food Scene', 'description': 'Explore Glasgow\'s legendary food and drink scene.', 'activities': ['West End brunch', 'Barras Market', 'Craft beer tour', 'Dinner at Ubiquitous Chip'], 'accommodationCost': '38', 'foodCost': '18', 'icon': Icons.restaurant, 'color': const Color(0xFF9C27B0), 'lat': glasgow.coordinates.lat, 'lng': glasgow.coordinates.lng},
      {'location': edinburgh.displayName, 'country': 'scotland', 'title': 'Return to Edinburgh', 'description': 'Train back to Edinburgh. Last night out.', 'activities': ['ScotRail to Edinburgh', 'Grassmarket pubs', 'Whisky tasting', 'Farewell dinner'], 'arrivalTransport': TransportMode.train, 'transportDuration': '1h', 'transportCost': '10', 'accommodationCost': '48', 'foodCost': '18', 'icon': Icons.train, 'color': const Color(0xFF00BFA6), 'lat': edinburgh.coordinates.lat, 'lng': edinburgh.coordinates.lng},
      {'location': edinburgh.displayName, 'country': 'scotland', 'title': 'Departure Day', 'description': 'Last morning in Scotland. Fly home to Muscat.', 'activities': ['Morning walk at Holyrood', 'Last haggis lunch', 'Airport transfer'], 'departureTransport': TransportMode.flight, 'transportDuration': '12h total', 'transportCost': '0', 'accommodationCost': '0', 'foodCost': '10', 'icon': Icons.flight_takeoff, 'color': const Color(0xFF6C63FF), 'isTravelDay': true, 'lat': edinburgh.coordinates.lat, 'lng': edinburgh.coordinates.lng},
    ];
    return _buildDaysFromTemplates(templates, startDate, totalDays);
  }

  // ── MAURITIUS ────────────────────────────────────────────────────────
  static List<TripDay> _mauritiusDays(DateTime startDate, int totalDays) {
    final cities = CityConfigs.get('mauritius').cities;
    final portLouis = cities['port_louis']!;
    final flicEnFlac = cities['flic_en_flac']!;
    final grandBaie = cities['grand_baie']!;
    final belleMare = cities['belle_mare']!;

    final List<Map<String, dynamic>> templates = [
      {'location': portLouis.displayName, 'country': 'mauritius', 'title': 'Arrival in Mauritius', 'description': 'Fly from Muscat to Mauritius. Settle into your beach resort.', 'activities': ['Beach walk', 'Sunset cocktails', 'Welcome dinner at resort'], 'arrivalTransport': TransportMode.flight, 'transportDuration': '8h total', 'transportCost': '250', 'accommodationCost': '35', 'foodCost': '10', 'icon': Icons.flight_land, 'color': const Color(0xFF6C63FF), 'isTravelDay': true, 'lat': portLouis.coordinates.lat, 'lng': portLouis.coordinates.lng},
      {'location': portLouis.displayName, 'country': 'mauritius', 'title': 'Explore Port Louis', 'description': 'Explore the capital — markets, colonial architecture, and local food.', 'activities': ['Central Market', 'Caudan Waterfront', 'Champ de Mars racecourse', 'Dholl Puri lunch'], 'accommodationCost': '35', 'foodCost': '12', 'icon': Icons.location_city, 'color': const Color(0xFFFF6B6B), 'lat': portLouis.coordinates.lat, 'lng': portLouis.coordinates.lng},
      {'location': flicEnFlac.displayName, 'country': 'mauritius', 'title': 'West Coast Beaches', 'description': 'Beach day on the west coast — calm water and sunsets.', 'activities': ['Flic en Flac beach', 'Snorkeling at Coral Reef', 'Sunset catamaran', 'Beachside BBQ'], 'arrivalTransport': TransportMode.car, 'transportDuration': '1h', 'transportCost': '10', 'accommodationCost': '38', 'foodCost': '12', 'icon': Icons.beach_access, 'color': const Color(0xFF00B4D8), 'lat': flicEnFlac.coordinates.lat, 'lng': flicEnFlac.coordinates.lng},
      {'location': flicEnFlac.displayName, 'country': 'mauritius', 'title': 'Casela Nature Park', 'description': 'Adventure park — zip lines, lion walks, and quad biking.', 'activities': ['Zip line adventure', 'Lion walking experience', 'Quad biking', 'Lunch at the park'], 'accommodationCost': '38', 'foodCost': '15', 'icon': Icons.terrain, 'color': const Color(0xFF4CAF50), 'lat': flicEnFlac.coordinates.lat, 'lng': flicEnFlac.coordinates.lng},
      {'location': grandBaie.displayName, 'country': 'mauritius', 'title': 'Grand Baie & North', 'description': 'Head north for beaches, shopping, and nightlife.', 'activities': ['Grand Baie beach', 'Pamplemousses Botanical Garden', 'Shopping at Grand Baie bazaar', 'Seafood dinner'], 'arrivalTransport': TransportMode.car, 'transportDuration': '45min', 'transportCost': '8', 'accommodationCost': '40', 'foodCost': '15', 'icon': Icons.beach_access, 'color': const Color(0xFFFF9800), 'lat': grandBaie.coordinates.lat, 'lng': grandBaie.coordinates.lng},
      {'location': grandBaie.displayName, 'country': 'mauritius', 'title': 'Île aux Cerfs Day Trip', 'description': 'Boat to the island for golf, beaches, and lunch.', 'activities': ['Boat to Île aux Cerfs', 'Beach relaxation', 'Golf course views', 'BBQ lunch on island'], 'accommodationCost': '40', 'foodCost': '15', 'icon': Icons.directions_boat, 'color': const Color(0xFF00BCD4), 'lat': grandBaie.coordinates.lat, 'lng': grandBaie.coordinates.lng},
      {'location': belleMare.displayName, 'country': 'mauritius', 'title': 'East Coast Relaxation', 'description': 'Move to the east coast for luxury resorts and lagoons.', 'activities': ['Belle Mare beach', 'Water sports', 'Spa treatment', 'Sunset dinner'], 'arrivalTransport': TransportMode.car, 'transportDuration': '1h', 'transportCost': '10', 'accommodationCost': '42', 'foodCost': '15', 'icon': Icons.spa, 'color': const Color(0xFF9C27B0), 'lat': belleMare.coordinates.lat, 'lng': belleMare.coordinates.lng},
      {'location': belleMare.displayName, 'country': 'mauritius', 'title': 'Blue Bay Marine Park', 'description': 'Snorkel in the marine park — crystal clear water and colorful fish.', 'activities': ['Snorkeling at Blue Bay', 'Glass bottom boat', 'Ile aux Aigrettes nature reserve', 'Lunch at marine park'], 'accommodationCost': '42', 'foodCost': '12', 'icon': Icons.water, 'color': const Color(0xFF00BFA6), 'lat': belleMare.coordinates.lat, 'lng': belleMare.coordinates.lng},
      {'location': portLouis.displayName, 'country': 'mauritius', 'title': 'Return to Port Louis', 'description': 'Last day shopping and cultural exploration.', 'activities': ['Blue Penny Museum', 'Aapravasi Ghat UNESCO', 'Shopping at Caudan', 'Farewell dinner'], 'arrivalTransport': TransportMode.car, 'transportDuration': '1h', 'transportCost': '10', 'accommodationCost': '35', 'foodCost': '15', 'icon': Icons.shopping_bag, 'color': const Color(0xFFFF6B6B), 'lat': portLouis.coordinates.lat, 'lng': portLouis.coordinates.lng},
      {'location': portLouis.displayName, 'country': 'mauritius', 'title': 'Departure Day', 'description': 'Last morning in Mauritius. Fly home to Muscat.', 'activities': ['Beach morning walk', 'Last-minute souvenirs', 'Airport transfer'], 'departureTransport': TransportMode.flight, 'transportDuration': '8h total', 'transportCost': '0', 'accommodationCost': '0', 'foodCost': '8', 'icon': Icons.flight_takeoff, 'color': const Color(0xFF6C63FF), 'isTravelDay': true, 'lat': portLouis.coordinates.lat, 'lng': portLouis.coordinates.lng},
    ];
    return _buildDaysFromTemplates(templates, startDate, totalDays);
  }

  // ── THAILAND ─────────────────────────────────────────────────────────
  static List<TripDay> _thailandDays(DateTime startDate, int totalDays) {
    final cities = CityConfigs.get('thailand').cities;
    final bangkok = cities['bangkok']!;
    final chiangMai = cities['chiang_mai']!;
    final phuket = cities['phuket']!;
    final krabi = cities['krabi']!;

    final List<Map<String, dynamic>> templates = [
      {'location': bangkok.displayName, 'country': 'thailand', 'title': 'Arrival in Bangkok', 'description': 'Fly from Muscat to Bangkok. Settle in and explore the city.', 'activities': ['Chao Phraya river walk', 'Wat Pho Temple', 'Street food in Yaowarat'], 'arrivalTransport': TransportMode.flight, 'transportDuration': '10h total', 'transportCost': '190', 'accommodationCost': '22', 'foodCost': '8', 'icon': Icons.flight_land, 'color': const Color(0xFF6C63FF), 'isTravelDay': true, 'lat': bangkok.coordinates.lat, 'lng': bangkok.coordinates.lng},
      {'location': bangkok.displayName, 'country': 'thailand', 'title': 'Bangkok Temples & Markets', 'description': 'Explore Bangkok\'s temples, markets, and street food.', 'activities': ['Grand Palace & Wat Phra Kaew', 'Chatuchak Weekend Market', 'Boat tour of canals', 'Rooftop dinner'], 'accommodationCost': '22', 'foodCost': '12', 'icon': Icons.temple_buddhist, 'color': const Color(0xFFFF6B6B), 'lat': bangkok.coordinates.lat, 'lng': bangkok.coordinates.lng},
      {'location': bangkok.displayName, 'country': 'thailand', 'title': 'Bangkok Food Tour', 'description': 'A full day dedicated to Bangkok\'s legendary street food.', 'activities': ['Yaowarat Chinatown food tour', 'Thipsamai Pad Thai', 'Mango sticky rice', 'Khao San Road evening'], 'accommodationCost': '22', 'foodCost': '15', 'icon': Icons.restaurant, 'color': const Color(0xFFFF9800), 'lat': bangkok.coordinates.lat, 'lng': bangkok.coordinates.lng},
      {'location': chiangMai.displayName, 'country': 'thailand', 'title': 'Fly to Chiang Mai', 'description': 'Fly north to the cultural capital of Thailand.', 'activities': ['Old City temple walk', 'Sunday Night Market', 'Thai cooking class', 'Doi Suthep temple'], 'arrivalTransport': TransportMode.flight, 'transportDuration': '1.5h', 'transportCost': '25', 'accommodationCost': '16', 'foodCost': '10', 'icon': Icons.temple_buddhist, 'color': const Color(0xFF00BFA6), 'lat': chiangMai.coordinates.lat, 'lng': chiangMai.coordinates.lng},
      {'location': chiangMai.displayName, 'country': 'thailand', 'title': 'Elephant Sanctuary', 'description': 'Visit an ethical elephant sanctuary in the hills.', 'activities': ['Elephant feeding & bathing', 'Bamboo rafting', 'Lunch at hill tribe village', 'Night Bazaar evening'], 'accommodationCost': '16', 'foodCost': '12', 'icon': Icons.pets, 'color': const Color(0xFF4CAF50), 'lat': chiangMai.coordinates.lat, 'lng': chiangMai.coordinates.lng},
      {'location': phuket.displayName, 'country': 'thailand', 'title': 'Fly to Phuket', 'description': 'Fly south to Thailand\'s island paradise.', 'activities': ['Patong Beach afternoon', 'Big Buddha viewpoint', 'Phuket Old Town walk', 'Seafood dinner'], 'arrivalTransport': TransportMode.flight, 'transportDuration': '2h', 'transportCost': '30', 'accommodationCost': '28', 'foodCost': '12', 'icon': Icons.beach_access, 'color': const Color(0xFF00B4D8), 'lat': phuket.coordinates.lat, 'lng': phuket.coordinates.lng},
      {'location': phuket.displayName, 'country': 'thailand', 'title': 'Phi Phi Island Day Trip', 'description': 'Boat tour to the iconic Phi Phi Islands.', 'activities': ['Maya Bay snorkeling', 'Loh Samah Bay', 'Bamboo Island', 'Sunset cruise back'], 'accommodationCost': '28', 'foodCost': '12', 'icon': Icons.directions_boat, 'color': const Color(0xFF00BCD4), 'lat': phuket.coordinates.lat, 'lng': phuket.coordinates.lng},
      {'location': krabi.displayName, 'country': 'thailand', 'title': 'Krabi & Railay Beach', 'description': 'Move to Krabi for dramatic limestone cliffs and beaches.', 'activities': ['Railay Beach rock climbing', 'Four Islands tour', 'Tiger Cave Temple', 'Sunset at Ao Nang'], 'arrivalTransport': TransportMode.bus, 'transportDuration': '2h', 'transportCost': '8', 'accommodationCost': '24', 'foodCost': '12', 'icon': Icons.terrain, 'color': const Color(0xFF795548), 'lat': krabi.coordinates.lat, 'lng': krabi.coordinates.lng},
      {'location': krabi.displayName, 'country': 'thailand', 'title': 'Kayaking & Lagoon', 'description': 'Kayak through mangroves and visit the Emerald Pool.', 'activities': ['Mangrove kayaking', 'Emerald Pool & hot springs', 'Krabi Town night market', 'Thai massage'], 'accommodationCost': '24', 'foodCost': '12', 'icon': Icons.water, 'color': const Color(0xFF4CAF50), 'lat': krabi.coordinates.lat, 'lng': krabi.coordinates.lng},
      {'location': bangkok.displayName, 'country': 'thailand', 'title': 'Return to Bangkok', 'description': 'Fly back to Bangkok for last-minute shopping.', 'activities': ['MBK Center shopping', 'Lumphini Park', 'Rooftop bar sunset', 'Farewell dinner'], 'arrivalTransport': TransportMode.flight, 'transportDuration': '2h', 'transportCost': '30', 'accommodationCost': '22', 'foodCost': '15', 'icon': Icons.shopping_bag, 'color': const Color(0xFF9C27B0), 'lat': bangkok.coordinates.lat, 'lng': bangkok.coordinates.lng},
      {'location': bangkok.displayName, 'country': 'thailand', 'title': 'Departure Day', 'description': 'Last morning in Thailand. Fly home to Muscat.', 'activities': ['Morning market walk', 'Last pad thai', 'Airport transfer'], 'departureTransport': TransportMode.flight, 'transportDuration': '10h total', 'transportCost': '0', 'accommodationCost': '0', 'foodCost': '8', 'icon': Icons.flight_takeoff, 'color': const Color(0xFF6C63FF), 'isTravelDay': true, 'lat': bangkok.coordinates.lat, 'lng': bangkok.coordinates.lng},
    ];
    return _buildDaysFromTemplates(templates, startDate, totalDays);
  }

  // ── JAPAN ────────────────────────────────────────────────────────────
  static List<TripDay> _japanDays(DateTime startDate, int totalDays) {
    final cities = CityConfigs.get('japan').cities;
    final tokyo = cities['tokyo']!;
    final kyoto = cities['kyoto']!;
    final osaka = cities['osaka']!;
    final hokkaido = cities['hokkaido']!;
    final okinawa = cities['okinawa']!;

    final List<Map<String, dynamic>> templates = [
      {'location': tokyo.displayName, 'country': 'japan', 'title': 'Arrival in Tokyo', 'description': 'Fly from Muscat to Tokyo. Settle in and explore the city lights.', 'activities': ['Shibuya Crossing', 'Harajuku Takeshita Street', 'Shinjuku evening walk'], 'arrivalTransport': TransportMode.flight, 'transportDuration': '14h total', 'transportCost': '320', 'accommodationCost': '45', 'foodCost': '12', 'icon': Icons.flight_land, 'color': const Color(0xFF6C63FF), 'isTravelDay': true, 'lat': tokyo.coordinates.lat, 'lng': tokyo.coordinates.lng},
      {'location': tokyo.displayName, 'country': 'japan', 'title': 'Tokyo Modern Culture', 'description': 'Explore Tokyo\'s modern culture — anime, tech, and food.', 'activities': ['Akihabara electronics', 'TeamLab Borderless', 'Tsukiji Outer Market', 'Ramen dinner'], 'accommodationCost': '45', 'foodCost': '15', 'icon': Icons.location_city, 'color': const Color(0xFFFF6B6B), 'lat': tokyo.coordinates.lat, 'lng': tokyo.coordinates.lng},
      {'location': tokyo.displayName, 'country': 'japan', 'title': 'Traditional Tokyo', 'description': 'Temples, gardens, and traditional culture.', 'activities': ['Senso-ji Temple', 'Meiji Shrine', 'Imperial Palace East Gardens', 'Sushi dinner at Ginza'], 'accommodationCost': '45', 'foodCost': '18', 'icon': Icons.temple_buddhist, 'color': const Color(0xFF00BFA6), 'lat': tokyo.coordinates.lat, 'lng': tokyo.coordinates.lng},
      {'location': kyoto.displayName, 'country': 'japan', 'title': 'Shinkansen to Kyoto', 'description': 'Bullet train to Japan\'s cultural capital.', 'activities': ['Fushimi Inari Shrine', 'Kinkaku-ji Golden Pavilion', 'Gion geisha district', 'Kaiseki dinner'], 'arrivalTransport': TransportMode.train, 'transportDuration': '2.5h', 'transportCost': '40', 'accommodationCost': '38', 'foodCost': '15', 'icon': Icons.train, 'color': const Color(0xFF00B4D8), 'lat': kyoto.coordinates.lat, 'lng': kyoto.coordinates.lng},
      {'location': kyoto.displayName, 'country': 'japan', 'title': 'Kyoto Temples & Gardens', 'description': 'Explore Kyoto\'s stunning temples and bamboo groves.', 'activities': ['Arashiyama Bamboo Grove', 'Kiyomizu-dera Temple', 'Nishiki Market', 'Tea ceremony experience'], 'accommodationCost': '38', 'foodCost': '15', 'icon': Icons.temple_buddhist, 'color': const Color(0xFF4CAF50), 'lat': kyoto.coordinates.lat, 'lng': kyoto.coordinates.lng},
      {'location': osaka.displayName, 'country': 'japan', 'title': 'Day Trip to Osaka', 'description': 'Train to Osaka for food and nightlife.', 'activities': ['Osaka Castle', 'Dotonbori street food', 'Kuromon Market', 'Umeda Sky Building'], 'arrivalTransport': TransportMode.train, 'transportDuration': '30min', 'transportCost': '5', 'accommodationCost': '32', 'foodCost': '18', 'icon': Icons.restaurant, 'color': const Color(0xFFFF9800), 'lat': osaka.coordinates.lat, 'lng': osaka.coordinates.lng},
      {'location': kyoto.displayName, 'country': 'japan', 'title': 'Nara Day Trip', 'description': 'Visit Nara for the giant Buddha and friendly deer.', 'activities': ['Todai-ji Temple', 'Nara Park deer', 'Kasuga Taisha', 'Lunch in Naramachi'], 'arrivalTransport': TransportMode.train, 'transportDuration': '45min', 'transportCost': '8', 'accommodationCost': '38', 'foodCost': '12', 'icon': Icons.pets, 'color': const Color(0xFF795548), 'lat': kyoto.coordinates.lat, 'lng': kyoto.coordinates.lng},
      {'location': tokyo.displayName, 'country': 'japan', 'title': 'Return to Tokyo', 'description': 'Back to Tokyo for last-minute shopping and experiences.', 'activities': ['Odaiba waterfront', 'Tokyo Skytree', 'Last sushi dinner', 'Don Quijote shopping'], 'arrivalTransport': TransportMode.train, 'transportDuration': '2.5h', 'transportCost': '40', 'accommodationCost': '45', 'foodCost': '18', 'icon': Icons.shopping_bag, 'color': const Color(0xFF9C27B0), 'lat': tokyo.coordinates.lat, 'lng': tokyo.coordinates.lng},
      {'location': tokyo.displayName, 'country': 'japan', 'title': 'Departure Day', 'description': 'Last morning in Japan. Fly home to Muscat.', 'activities': ['Tsukiji breakfast', 'Last-minute souvenirs', 'Airport transfer'], 'departureTransport': TransportMode.flight, 'transportDuration': '14h total', 'transportCost': '0', 'accommodationCost': '0', 'foodCost': '10', 'icon': Icons.flight_takeoff, 'color': const Color(0xFF6C63FF), 'isTravelDay': true, 'lat': tokyo.coordinates.lat, 'lng': tokyo.coordinates.lng},
    ];
    return _buildDaysFromTemplates(templates, startDate, totalDays);
  }

  // ── TURKEY ──────────────────────────────────────────────────────────
  static List<TripDay> _turkeyDays(DateTime startDate, int totalDays) {
    final cities = CityConfigs.get('turkey').cities;
    final istanbul = cities['istanbul']!;
    final cappadocia = cities['cappadocia']!;
    final antalya = cities['antalya']!;
    final izmir = cities['izmir']!;

    final List<Map<String, dynamic>> templates = [
      {'location': istanbul.displayName, 'country': 'turkey', 'title': 'Arrival in Istanbul', 'description': 'Fly from Muscat to Istanbul. Explore the historic peninsula.', 'activities': ['Hagia Sophia', 'Blue Mosque', 'Grand Bazaar', 'Turkish dinner in Sultanahmet'], 'arrivalTransport': TransportMode.flight, 'transportDuration': '8h total', 'transportCost': '150', 'accommodationCost': '20', 'foodCost': '8', 'icon': Icons.flight_land, 'color': const Color(0xFF6C63FF), 'isTravelDay': true, 'lat': istanbul.coordinates.lat, 'lng': istanbul.coordinates.lng},
      {'location': istanbul.displayName, 'country': 'turkey', 'title': 'Istanbul Bosphorus', 'description': 'Bosphorus cruise, spice market, and Turkish delight.', 'activities': ['Bosphorus ferry cruise', 'Spice Bazaar (Egyptian)', 'Galata Tower', 'Beyoğlu street food'], 'accommodationCost': '20', 'foodCost': '12', 'icon': Icons.directions_boat, 'color': const Color(0xFF00B4D8), 'lat': istanbul.coordinates.lat, 'lng': istanbul.coordinates.lng},
      {'location': istanbul.displayName, 'country': 'turkey', 'title': 'Topkapi & Hammam', 'description': 'Palace visit followed by a traditional Turkish bath.', 'activities': ['Topkapi Palace', 'Turkish hammam experience', 'Çiya Sofrası lunch', 'Istanbul Archaeology Museum'], 'accommodationCost': '20', 'foodCost': '12', 'icon': Icons.castle, 'color': const Color(0xFFFF6B6B), 'lat': istanbul.coordinates.lat, 'lng': istanbul.coordinates.lng},
      {'location': cappadocia.displayName, 'country': 'turkey', 'title': 'Fly to Cappadocia', 'description': 'Fly to the land of fairy chimneys and hot air balloons.', 'activities': ['Hot air balloon sunrise', 'Göreme Open Air Museum', 'Pasabag (Monks Valley)', 'Pottery workshop'], 'arrivalTransport': TransportMode.flight, 'transportDuration': '1.5h', 'transportCost': '25', 'accommodationCost': '22', 'foodCost': '10', 'icon': Icons.terrain, 'color': const Color(0xFF795548), 'lat': cappadocia.coordinates.lat, 'lng': cappadocia.coordinates.lng},
      {'location': cappadocia.displayName, 'country': 'turkey', 'title': 'Cappadocia Valleys', 'description': 'Hike through the valleys and explore underground cities.', 'activities': ['Rose Valley hike', 'Derinkuyu Underground City', 'Uchisar Castle sunset', 'Turkish night show'], 'accommodationCost': '22', 'foodCost': '12', 'icon': Icons.landscape, 'color': const Color(0xFF4CAF50), 'lat': cappadocia.coordinates.lat, 'lng': cappadocia.coordinates.lng},
      {'location': cappadocia.displayName, 'country': 'turkey', 'title': 'Green Tour', 'description': 'Full day Green Tour of southern Cappadocia.', 'activities': ['Ihlara Valley hike', 'Selime Monastery', 'Pigeon Valley', 'Onyx workshop'], 'arrivalTransport': TransportMode.bus, 'transportDuration': 'full day', 'transportCost': '15', 'accommodationCost': '22', 'foodCost': '12', 'icon': Icons.directions_bus, 'color': const Color(0xFF00BFA6), 'lat': cappadocia.coordinates.lat, 'lng': cappadocia.coordinates.lng},
      {'location': antalya.displayName, 'country': 'turkey', 'title': 'Drive to Antalya', 'description': 'Drive to the Turkish Riviera for beaches and history.', 'activities': ['Düden Waterfall', 'Kaleiçi Old Town', 'Lara Beach', 'Rafting at Köprülü Canyon'], 'arrivalTransport': TransportMode.bus, 'transportDuration': '4h', 'transportCost': '15', 'accommodationCost': '16', 'foodCost': '12', 'icon': Icons.beach_access, 'color': const Color(0xFF00BCD4), 'lat': antalya.coordinates.lat, 'lng': antalya.coordinates.lng},
      {'location': antalya.displayName, 'country': 'turkey', 'title': 'Antalya Beaches', 'description': 'Beach day on the Mediterranean coast.', 'activities': ['Konyaaltı Beach', 'Aqualand water park', 'Lycian Way hike', 'Seafood dinner'], 'accommodationCost': '16', 'foodCost': '15', 'icon': Icons.beach_access, 'color': const Color(0xFFFF9800), 'lat': antalya.coordinates.lat, 'lng': antalya.coordinates.lng},
      {'location': istanbul.displayName, 'country': 'turkey', 'title': 'Return to Istanbul', 'description': 'Fly back to Istanbul for last days.', 'activities': ['Kadıköy market', 'Princes\' Islands day trip', 'Turkish coffee tasting', 'Farewell dinner'], 'arrivalTransport': TransportMode.flight, 'transportDuration': '1.5h', 'transportCost': '25', 'accommodationCost': '20', 'foodCost': '15', 'icon': Icons.flight, 'color': const Color(0xFF9C27B0), 'lat': istanbul.coordinates.lat, 'lng': istanbul.coordinates.lng},
      {'location': istanbul.displayName, 'country': 'turkey', 'title': 'Departure Day', 'description': 'Last morning in Turkey. Fly home to Muscat.', 'activities': ['Last Turkish breakfast', 'Souvenir shopping', 'Airport transfer'], 'departureTransport': TransportMode.flight, 'transportDuration': '8h total', 'transportCost': '0', 'accommodationCost': '0', 'foodCost': '8', 'icon': Icons.flight_takeoff, 'color': const Color(0xFF6C63FF), 'isTravelDay': true, 'lat': istanbul.coordinates.lat, 'lng': istanbul.coordinates.lng},
    ];
    return _buildDaysFromTemplates(templates, startDate, totalDays);
  }

  // ── MOROCCO ──────────────────────────────────────────────────────────
  static List<TripDay> _moroccoDays(DateTime startDate, int totalDays) {
    final cities = CityConfigs.get('morocco').cities;
    final marrakech = cities['marrakech']!;
    final casablanca = cities['casablanca']!;
    final fez = cities['fez']!;
    final chefchaouen = cities['chefchaouen']!;

    final List<Map<String, dynamic>> templates = [
      {'location': casablanca.displayName, 'country': 'morocco', 'title': 'Arrival in Casablanca', 'description': 'Fly from Muscat to Casablanca. Visit the Hassan II Mosque.', 'activities': ['Hassan II Mosque', 'Corniche waterfront', 'Moroccan tea ceremony'], 'arrivalTransport': TransportMode.flight, 'transportDuration': '8h total', 'transportCost': '200', 'accommodationCost': '22', 'foodCost': '8', 'icon': Icons.flight_land, 'color': const Color(0xFF6C63FF), 'isTravelDay': true, 'lat': casablanca.coordinates.lat, 'lng': casablanca.coordinates.lng},
      {'location': casablanca.displayName, 'country': 'morocco', 'title': 'Casablanca to Marrakech', 'description': 'Train to Marrakech. Explore the medina and Jemaa el-Fna.', 'activities': ['Train to Marrakech', 'Jemaa el-Fna square', 'Koutoubia Mosque', 'Food stalls dinner'], 'arrivalTransport': TransportMode.train, 'transportDuration': '2.5h', 'transportCost': '8', 'accommodationCost': '24', 'foodCost': '10', 'icon': Icons.train, 'color': const Color(0xFF00B4D8), 'lat': marrakech.coordinates.lat, 'lng': marrakech.coordinates.lng},
      {'location': marrakech.displayName, 'country': 'morocco', 'title': 'Marrakech Medina', 'description': 'Explore the souks, palaces, and gardens of Marrakech.', 'activities': ['Bahia Palace', 'Majorelle Garden', 'Souk shopping', 'Jemaa el-Fna at night'], 'accommodationCost': '24', 'foodCost': '12', 'icon': Icons.temple_buddhist, 'color': const Color(0xFFFF6B6B), 'lat': marrakech.coordinates.lat, 'lng': marrakech.coordinates.lng},
      {'location': marrakech.displayName, 'country': 'morocco', 'title': 'Atlas Mountains Day Trip', 'description': 'Day trip to the Atlas Mountains and Berber villages.', 'activities': ['Ourika Valley hike', 'Berber village visit', 'Lunch with local family', 'Waterfall stop'], 'arrivalTransport': TransportMode.car, 'transportDuration': '2h', 'transportCost': '15', 'accommodationCost': '24', 'foodCost': '12', 'icon': Icons.terrain, 'color': const Color(0xFF4CAF50), 'lat': marrakech.coordinates.lat, 'lng': marrakech.coordinates.lng},
      {'location': fez.displayName, 'country': 'morocco', 'title': 'Train to Fez', 'description': 'Train to Fez — the cultural and spiritual heart of Morocco.', 'activities': ['Fes el-Bali medina', 'Al-Attarine Madrasa', 'Chouara Tannery', 'Royal Palace visit'], 'arrivalTransport': TransportMode.train, 'transportDuration': '1h', 'transportCost': '5', 'accommodationCost': '18', 'foodCost': '10', 'icon': Icons.temple_buddhist, 'color': const Color(0xFF00BFA6), 'lat': fez.coordinates.lat, 'lng': fez.coordinates.lng},
      {'location': fez.displayName, 'country': 'morocco', 'title': 'Fez Culture Day', 'description': 'Deep dive into Fez\'s artisan traditions and cuisine.', 'activities': ['Pottery workshop', 'Couscous cooking class', 'Medersa Bou Inania', 'Spice market'], 'accommodationCost': '18', 'foodCost': '12', 'icon': Icons.palette, 'color': const Color(0xFF795548), 'lat': fez.coordinates.lat, 'lng': fez.coordinates.lng},
      {'location': chefchaouen.displayName, 'country': 'morocco', 'title': 'Chefchaouen Blue City', 'description': 'Travel to the famous blue-painted city in the Rif Mountains.', 'activities': ['Blue medina walk', 'Rifian photography', 'Cascades waterfall', 'Spanish Mosque sunset'], 'arrivalTransport': TransportMode.bus, 'transportDuration': '4h', 'transportCost': '12', 'accommodationCost': '16', 'foodCost': '10', 'icon': Icons.camera_alt, 'color': const Color(0xFF00BCD4), 'lat': chefchaouen.coordinates.lat, 'lng': chefchaouen.coordinates.lng},
      {'location': chefchaouen.displayName, 'country': 'morocco', 'title': 'Chefchaouen Relax', 'description': 'A relaxed day in the blue city — photography and local food.', 'activities': ['Rooftop breakfast', 'Local hammam', 'Hike to Akchour Waterfall', 'Dinner at a riad'], 'accommodationCost': '16', 'foodCost': '12', 'icon': Icons.spa, 'color': const Color(0xFF9C27B0), 'lat': chefchaouen.coordinates.lat, 'lng': chefchaouen.coordinates.lng},
      {'location': marrakech.displayName, 'country': 'morocco', 'title': 'Return to Marrakech', 'description': 'Back to Marrakech for last shopping and relaxation.', 'activities': ['Last souk shopping', 'Hammam & spa', 'Rooftop dinner', 'Jemaa el-Fna farewell'], 'arrivalTransport': TransportMode.bus, 'transportDuration': '4h', 'transportCost': '12', 'accommodationCost': '24', 'foodCost': '15', 'icon': Icons.shopping_bag, 'color': const Color(0xFFFF9800), 'lat': marrakech.coordinates.lat, 'lng': marrakech.coordinates.lng},
      {'location': casablanca.displayName, 'country': 'morocco', 'title': 'Departure Day', 'description': 'Last morning in Morocco. Fly home to Muscat.', 'activities': ['Last mint tea', 'Souvenir shopping', 'Airport transfer'], 'departureTransport': TransportMode.flight, 'transportDuration': '8h total', 'transportCost': '0', 'accommodationCost': '0', 'foodCost': '8', 'icon': Icons.flight_takeoff, 'color': const Color(0xFF6C63FF), 'isTravelDay': true, 'lat': casablanca.coordinates.lat, 'lng': casablanca.coordinates.lng},
    ];
    return _buildDaysFromTemplates(templates, startDate, totalDays);
  }

  // ── GENERIC FALLBACK ─────────────────────────────────────────────────
  static List<TripDay> _genericDays(DateTime startDate, int totalDays, String countryKey) {
    final config = CityConfigs.get(countryKey);
    final city = config.cities.values.first;
    final List<Map<String, dynamic>> templates = [];
    for (int i = 0; i < 8; i++) {
      templates.add({
        'location': city.displayName,
        'country': countryKey,
        'title': 'Day ${i + 1} in ${config.country}',
        'description': 'Explore ${config.country} — a beautiful destination with rich culture and stunning landscapes.',
        'activities': ['Local sightseeing', 'Traditional food experience', 'Market exploration', 'Cultural visit'],
        'accommodationCost': config.defaultHotelBase.toStringAsFixed(0),
        'foodCost': '10',
        'icon': Icons.explore,
        'color': const Color(0xFF6C63FF),
        'lat': city.coordinates.lat,
        'lng': city.coordinates.lng,
      });
    }
    return _buildDaysFromTemplates(templates, startDate, totalDays);
  }

  // ── BUILD DAYS FROM TEMPLATES ────────────────────────────────────────
  static List<TripDay> _buildDaysFromTemplates(
    List<Map<String, dynamic>> templates,
    DateTime startDate,
    int totalDays,
  ) {
    final days = <TripDay>[];
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    for (int i = 0; i < totalDays; i++) {
      final dayDate = startDate.add(Duration(days: i));
      final dateStr = '${months[dayDate.month - 1]} ${dayDate.day}';

      // Use template if available, otherwise use last template as fallback
      final templateIndex = i < templates.length ? i : templates.length - 1;
      final t = templates[templateIndex];

      days.add(TripDay(
        day: i + 1,
        date: dateStr,
        location: t['location'] as String,
        country: t['country'] as String,
        title: t['title'] as String,
        description: t['description'] as String,
        activities: List<String>.from(t['activities'] as List),
        arrivalTransport: t['arrivalTransport'] as TransportMode?,
        departureTransport: t['departureTransport'] as TransportMode?,
        transportDuration: t['transportDuration'] as String?,
        transportCost: t['transportCost'] as String?,
        accommodationCost: t['accommodationCost'] as String?,
        foodCost: t['foodCost'] as String?,
        icon: t['icon'] as IconData,
        color: t['color'] as Color,
        isTravelDay: t['isTravelDay'] as bool? ?? false,
        lat: t['lat'] as double?,
        lng: t['lng'] as double?,
      ));
    }
    return days;
  }
}
