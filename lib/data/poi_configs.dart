import 'package:flutter/material.dart';

/// Category for a Point of Interest
enum PoiCategory {
  museum,
  restaurant,
  cafe,
  shop,
  monument,
  tour,
  temple,
  beach,
  market,
  other,
}

String poiCategoryLabel(PoiCategory c) {
  switch (c) {
    case PoiCategory.museum: return 'Museum';
    case PoiCategory.restaurant: return 'Restaurant';
    case PoiCategory.cafe: return 'Cafe';
    case PoiCategory.shop: return 'Shop';
    case PoiCategory.monument: return 'Monument';
    case PoiCategory.tour: return 'Tour / Activity';
    case PoiCategory.temple: return 'Temple / Religious';
    case PoiCategory.beach: return 'Beach';
    case PoiCategory.market: return 'Market';
    case PoiCategory.other: return 'Other';
  }
}

String poiCategoryIcon(PoiCategory c) {
  switch (c) {
    case PoiCategory.museum: return 'museum';
    case PoiCategory.restaurant: return 'restaurant';
    case PoiCategory.cafe: return 'local_cafe';
    case PoiCategory.shop: return 'shopping_bag';
    case PoiCategory.monument: return 'account_balance';
    case PoiCategory.tour: return 'tour';
    case PoiCategory.temple: return 'temple_buddhist';
    case PoiCategory.beach: return 'beach_access';
    case PoiCategory.market: return 'storefront';
    case PoiCategory.other: return 'place';
  }
}

/// A known Point of Interest in a city
class Poi {
  final String id;
  final String name;
  final String city;
  final PoiCategory category;
  final double typicalPriceOmr;
  final String? bookingUrl;
  final String? notes;
  /// Days of week this place is closed (1=Monday ... 7=Sunday)
  final List<int> closedDays;
  /// Best time of day (e.g., "morning", "afternoon", "evening")
  final String? bestTime;

  const Poi({
    required this.id,
    required this.name,
    required this.city,
    required this.category,
    this.typicalPriceOmr = 0,
    this.bookingUrl,
    this.notes,
    this.closedDays = const [],
    this.bestTime,
  });
}

/// A POI entry on a specific trip day
class TripPoiEntry {
  final String id;
  final String poiId; // reference to known Poi, or 'custom' prefix
  final String name;
  final PoiCategory category;
  final double typicalPriceOmr;
  final int dayNumber;
  final String? notes;
  final String? bookingUrl;
  /// Whether tickets/booking are required
  final bool requiresBooking;
  bool isDone;

  TripPoiEntry({
    required this.id,
    required this.poiId,
    required this.name,
    required this.category,
    required this.dayNumber,
    this.typicalPriceOmr = 0,
    this.notes,
    this.bookingUrl,
    this.requiresBooking = false,
    this.isDone = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'poiId': poiId,
    'name': name,
    'category': category.name,
    'dayNumber': dayNumber,
    'typicalPriceOmr': typicalPriceOmr,
    'notes': notes,
    'bookingUrl': bookingUrl,
    'requiresBooking': requiresBooking,
    'isDone': isDone,
  };

  factory TripPoiEntry.fromMap(Map<String, dynamic> m) => TripPoiEntry(
    id: m['id'],
    poiId: m['poiId'],
    name: m['name'],
    category: PoiCategory.values.firstWhere((c) => c.name == m['category'], orElse: () => PoiCategory.other),
    dayNumber: m['dayNumber'],
    typicalPriceOmr: (m['typicalPriceOmr'] as num?)?.toDouble() ?? 0,
    notes: m['notes'],
    bookingUrl: m['bookingUrl'],
    requiresBooking: m['requiresBooking'] ?? false,
    isDone: m['isDone'] ?? false,
  );

  TripPoiEntry copyWith({
    String? name, int? dayNumber, double? typicalPriceOmr,
    String? notes, String? bookingUrl, bool? requiresBooking, bool? isDone,
  }) => TripPoiEntry(
    id: id, poiId: poiId, name: name ?? this.name, category: category,
    dayNumber: dayNumber ?? this.dayNumber, typicalPriceOmr: typicalPriceOmr ?? this.typicalPriceOmr,
    notes: notes ?? this.notes, bookingUrl: bookingUrl ?? this.bookingUrl,
    requiresBooking: requiresBooking ?? this.requiresBooking, isDone: isDone ?? this.isDone,
  );
}

/// Registry of known Points of Interest per city
class PoiConfigs {
  static final Map<String, List<Poi>> _pois = {
    // ── VIETNAM ──────────────────────────────────────
    'hanoi': [
      const Poi(id:'hanoi_hm_museum', name:'Ho Chi Minh Mausoleum', city:'Hanoi', category:PoiCategory.monument, typicalPriceOmr:0, closedDays:[1,5], notes:'Closed Mondays and Fridays. Arrive early (7-9am) to avoid crowds.'),
      const Poi(id:'hanoi_temple_lit', name:'Temple of Literature', city:'Hanoi', category:PoiCategory.temple, typicalPriceOmr:1, notes:'1036 year old university. Open 8am-5pm.'),
      const Poi(id:'hanoi_hoan_kiem', name:'Hoan Kiem Lake', city:'Hanoi', category:PoiCategory.monument, typicalPriceOmr:0, notes:'Free public space. Best at sunrise or after dark.'),
      const Poi(id:'hanoi_egg_coffee', name:'Cafe Giang (Egg Coffee)', city:'Hanoi', category:PoiCategory.cafe, typicalPriceOmr:1, notes:'Since 1946. Signature coffee 35K VND.'),
      const Poi(id:'hanoi_water_puppet', name:'Thang Long Water Puppets', city:'Hanoi', category:PoiCategory.tour, typicalPriceOmr:4, notes:'Shows at 3:30pm, 5pm, 6:30pm, 8pm.'),
      const Poi(id:'hanoi_train_street', name:'Train Street', city:'Hanoi', category:PoiCategory.other, typicalPriceOmr:0, notes:'Trains pass twice daily. Cafe owners move chairs.'),
      const Poi(id:'hanoi_museum_ethno', name:'Vietnam Museum of Ethnology', city:'Hanoi', category:PoiCategory.museum, typicalPriceOmr:2, notes:'Excellent exhibits. Closed Mondays.'),
      const Poi(id:'hanoi_pho_thin', name:'Pho Thin (Lo Duc)', city:'Hanoi', category:PoiCategory.restaurant, typicalPriceOmr:1, notes:'Famous since 1972. Stir-fried beef pho.'),
    ],
    'ha_long': [
      const Poi(id:'halong_cruise_2d1n', name:'Ha Long Bay Cruise (2D1N)', city:'Ha Long', category:PoiCategory.tour, typicalPriceOmr:50, notes:'Kayaking, swimming, cave visit. Book in advance.'),
      const Poi(id:'halong_sung_sot', name:'Sung Sot Cave', city:'Ha Long', category:PoiCategory.monument, typicalPriceOmr:0, notes:'Largest cave in Ha Long. Included in cruise price.'),
    ],
    'hcmc': [
      const Poi(id:'hcmc_war_museum', name:'War Remnants Museum', city:'Ho Chi Minh City', category:PoiCategory.museum, typicalPriceOmr:1, notes:'Open daily 7:30am-6pm. Powerful exhibits.'),
      const Poi(id:'hcmc_ben_thanh', name:'Ben Thanh Market', city:'Ho Chi Minh City', category:PoiCategory.market, typicalPriceOmr:0, notes:'Open 6am-6pm. Negotiate prices.'),
      const Poi(id:'hcmc_cu_chi', name:'Cu Chi Tunnels', city:'Ho Chi Minh City', category:PoiCategory.tour, typicalPriceOmr:5, notes:'1.5h drive. Book morning slot. Open daily.'),
      const Poi(id:'hcmc_jade_emperor', name:'Jade Emperor Pagoda', city:'Ho Chi Minh City', category:PoiCategory.temple, typicalPriceOmr:0, notes:'Free entry. Taoist temple. Open 7am-6pm.'),
      const Poi(id:'hcmc_rooftop_bars', name:'Chill Skybar / Saigon Saigon', city:'Ho Chi Minh City', category:PoiCategory.cafe, typicalPriceOmr:3, notes:'Rooftop city views. Happy hour 5-7pm.'),
    ],
    'phu_quoc': [
      const Poi(id:'pq_long_beach', name:'Long Beach', city:'Phu Quoc', category:PoiCategory.beach, typicalPriceOmr:0, notes:'Main public beach. Free entry.'),
      const Poi(id:'pq_safari', name:'Phu Quoc Safari Park', city:'Phu Quoc', category:PoiCategory.tour, typicalPriceOmr:12, notes:'Vietnam\'s largest wildlife park. Open 9am-5pm.'),
      const Poi(id:'pq_pearl_farm', name:'Phu Quoc Pearl Farm', city:'Phu Quoc', category:PoiCategory.shop, typicalPriceOmr:0, notes:'Free visit. See pearl cultivation process.'),
      const Poi(id:'pq_night_market', name:'Duong Dong Night Market', city:'Phu Quoc', category:PoiCategory.market, typicalPriceOmr:0, notes:'Open evenings 5-10pm. Seafood and souvenirs.'),
    ],

    // ── SRI LANKA ────────────────────────────────────
    'colombo': [
      const Poi(id:'colombo_gangaramaya', name:'Gangaramaya Temple', city:'Colombo', category:PoiCategory.temple, typicalPriceOmr:1, notes:'Mixed Buddhist/Hindu. Open daily 6am-10pm.'),
      const Poi(id:'colombo_galle_face', name:'Galle Face Green', city:'Colombo', category:PoiCategory.beach, typicalPriceOmr:0, notes:'Promenade. Best at sunset for street food.'),
      const Poi(id:'colombo_ministry_crab', name:'Ministry of Crab', city:'Colombo', category:PoiCategory.restaurant, typicalPriceOmr:20, notes:'Reservations required. WHO\'s famed crab.'),
      const Poi(id:'colombo_pettah', name:'Pettah Floating Market', city:'Colombo', category:PoiCategory.market, typicalPriceOmr:0, notes:'Open daily. Spices, textiles, jewelry.'),
      const Poi(id:'colombo_independence', name:'Independence Memorial Hall', city:'Colombo', category:PoiCategory.monument, typicalPriceOmr:0, notes:'Free. Open daily 8am-6pm.'),
      const Poi(id:'colombo_hospital', name:'Dutch Hospital Shopping Precinct', city:'Colombo', category:PoiCategory.shop, typicalPriceOmr:0, notes:'Heritage building. Boutiques and cafes inside.'),
    ],
    'kandy': [
      const Poi(id:'kandy_tooth_temple', name:'Temple of the Tooth Relic', city:'Kandy', category:PoiCategory.temple, typicalPriceOmr:5, notes:'Sri Lanka\'s most sacred site. Open 5:30am-8pm.'),
      const Poi(id:'kandy_lake', name:'Kandy Lake', city:'Kandy', category:PoiCategory.monument, typicalPriceOmr:0, notes:'Free. Walk the 3.2km loop. Best at sunset.'),
      const Poi(id:'kandy_botanical', name:'Peradeniya Botanical Garden', city:'Kandy', category:PoiCategory.tour, typicalPriceOmr:5, notes:'Open 7:30am-5pm. 147 acres. Orchid house.'),
      const Poi(id:'kandy_tea_factory', name:'Pedler\'s Pride Tea Factory', city:'Kandy', category:PoiCategory.shop, typicalPriceOmr:0, notes:'Free tea tasting. Buy Ceylon tea.'),
      const Poi(id:'kandy_dance_show', name:'Kandy Cultural Dance Show', city:'Kandy', category:PoiCategory.tour, typicalPriceOmr:3, notes:'Shows at 5:30pm daily. Kandyan dance & fire walking.'),
    ],
    'galle': [
      const Poi(id:'galle_fort', name:'Galle Fort (UNESCO)', city:'Galle', category:PoiCategory.monument, typicalPriceOmr:0, notes:'Dutch colonial fort. Free to walk. Best at sunset.'),
      const Poi(id:'galle_lighthouse', name:'Galle Lighthouse', city:'Galle', category:PoiCategory.monument, typicalPriceOmr:0, notes:'Iconic 18m lighthouse. Built 1939.'),
      const Poi(id:'galle_flag_rock', name:'Flag Rock Bastion', city:'Galle', category:PoiCategory.monument, typicalPriceOmr:0, notes:'Best sunset spot in the fort. Street food nearby.'),
    ],
    'ella': [
      const Poi(id:'ella_nine_arch', name:'Nine Arch Bridge', city:'Ella', category:PoiCategory.monument, typicalPriceOmr:0, notes:'Train passes 9:30am, 11am, 3:30pm. Stand on the bridge.'),
      const Poi(id:'ella_rock', name:'Ella Rock', city:'Ella', category:PoiCategory.monument, typicalPriceOmr:0, notes:'2-3h hike. Start early. Start from town center or train station.'),
      const Poi(id:'ella_adams_peak', name:'Little Adam\'s Peak', city:'Ella', category:PoiCategory.monument, typicalPriceOmr:0, notes:'45min hike. Sunrise best. Easy climb.'),
      const Poi(id:'ella_ravana_falls', name:'Ravana Falls', city:'Ella', category:PoiCategory.monument, typicalPriceOmr:0, notes:'Monsoon season most impressive. Swim at the base.'),
    ],

    // ── INDONESIA ────────────────────────────────────
    'jakarta': [
      const Poi(id:'jakarta_monas', name:'Monas (National Monument)', city:'Jakarta', category:PoiCategory.monument, typicalPriceOmr:1, notes:'132m obelisk. Jakarta symbol. Open 8am-4pm. Closed Mondays.'),
      const Poi(id:'jakarta_istiqlal', name:'Istiqlal Mosque', city:'Jakarta', category:PoiCategory.temple, typicalPriceOmr:0, notes:'Southeast Asia\'s largest mosque. Free entry. Closed Fridays 10am-12pm.'),
      const Poi(id:'jakarta_kota_tua', name:'Kota Tua (Old Town)', city:'Jakarta', category:PoiCategory.monument, typicalPriceOmr:0, notes:'Dutch colonial buildings. Street art. Photography.'),
      const Poi(id:'jakarta_national_museum', name:'National Museum', city:'Jakarta', category:PoiCategory.museum, typicalPriceOmr:2, notes:'Open Tue-Sun. Closed Mondays. Excellent Hindu-Buddhist collection.'),
    ],
    'bali': [
      const Poi(id:'bali_tanah_lot', name:'Tanah Lot Temple', city:'Bali', category:PoiCategory.temple, typicalPriceOmr:3, notes:'Sea temple on rock. Best at sunset. Open 7am-7pm.'),
      const Poi(id:'bali_uluwatu', name:'Uluwatu Temple + Kecak Dance', city:'Bali', category:PoiCategory.temple, typicalPriceOmr:5, notes:'Clifftop temple. Kecak dance at 6pm daily. Beware monkeys!'),
      const Poi(id:'bali_tegallalang', name:'Tegallalang Rice Terraces', city:'Bali', category:PoiCategory.monument, typicalPriceOmr:1, notes:'Iconic terraces. Go early. Coconut photo spots.'),
      const Poi(id:'bali_monkey_forest', name:'Ubud Monkey Forest', city:'Bali', category:PoiCategory.tour, typicalPriceOmr:3, notes:'Sacred monkey sanctuary. Remove glasses/jewelry! Open 8:30am-6pm.'),
      const Poi(id:'bali_ubud_art', name:'Ubud Art Market', city:'Bali', category:PoiCategory.market, typicalPriceOmr:0, notes:'Open daily 6am-5pm. Negotiate. Bargain hard.'),
      const Poi(id:'bali_tirta_gangga', name:'Tirta Gangga Water Palace', city:'Bali', category:PoiCategory.temple, typicalPriceOmr:2, notes:'Former royal palace. Fish ponds. Open 8am-6pm.'),
      const Poi(id:'bali_jimbaran', name:'Jimbaran Seafood Dinner', city:'Bali', category:PoiCategory.restaurant, typicalPriceOmr:6, notes:'Beachside grilled fish. Sunset dining. Book ahead.'),
    ],
    'yogyakarta': [
      const Poi(id:'yogya_borobudur', name:'Borobudur Temple', city:'Yogyakarta', category:PoiCategory.temple, typicalPriceOmr:12, notes:'World\'s largest Buddhist temple. Sunrise tickets available 4:30am.'),
      const Poi(id:'yogya_prambanan', name:'Prambanan Temple', city:'Yogyakarta', category:PoiCategory.temple, typicalPriceOmr:12, notes:'Hindu temple complex. Open 6am-5pm. Ramayana ballet May-Oct.'),
      const Poi(id:'yogya_kraton', name:'Sultan\'s Kraton', city:'Yogyakarta', category:PoiCategory.monument, typicalPriceOmr:1, notes:'Royal palace. Open 8:30am-2pm. Closed Fridays.'),
      const Poi(id:'yogya_malioboro', name:'Malioboro Street', city:'Yogyakarta', category:PoiCategory.market, typicalPriceOmr:0, notes:'Main shopping street. Satay at night. Batik shops.'),
    ],
  };

  /// Get all POIs for a city (case-insensitive)
  static List<Poi> getForCity(String city) {
    final key = city.toLowerCase().replaceAll(' ', '_');
    return _pois[key] ?? [];
  }

  /// Search POIs by city and category
  static List<Poi> getForCityAndCategory(String city, PoiCategory? category) {
    final pois = getForCity(city);
    if (category == null) return pois;
    return pois.where((p) => p.category == category).toList();
  }

  /// Search POIs across all cities by name
  static List<Poi> search(String query) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    final results = <Poi>[];
    for (final entry in _pois.entries) {
      for (final poi in entry.value) {
        if (poi.name.toLowerCase().contains(q) || poi.city.toLowerCase().contains(q)) {
          results.add(poi);
        }
      }
    }
    return results;
  }

  /// Get POI by ID
  static Poi? getById(String id) {
    for (final poiList in _pois.values) {
      for (final poi in poiList) {
        if (poi.id == id) return poi;
      }
    }
    return null;
  }

  /// Get all unique city names that have POIs
  static List<String> get cities {
    final citySet = <String>{};
    for (final poiList in _pois.values) {
      for (final poi in poiList) {
        citySet.add(poi.city);
      }
    }
    return citySet.toList()..sort();
  }
}

/// Notification generated from a POI entry
class PoiNotification {
  final String poiName;
  final int dayNumber;
  final String dayDate;
  final String type; // 'closure', 'booking_required', 'weather', 'best_time'
  final String message;
  final Color color;
  final IconData icon;

  PoiNotification({
    required this.poiName,
    required this.dayNumber,
    required this.dayDate,
    required this.type,
    required this.message,
    required this.color,
    required this.icon,
  });
}

/// Check a POI entry against its planned day and generate notifications
PoiNotification? checkPoiClosure(TripPoiEntry entry, Poi? knownPoi, DateTime tripBaseDate) {
  if (knownPoi == null) return null;

  // Calculate the actual date for this day
  final dayDate = tripBaseDate.add(Duration(days: entry.dayNumber - 1));
  final weekday = dayDate.weekday; // 1=Monday

  // Check if the place is closed on this day
  if (knownPoi.closedDays.contains(weekday)) {
    final dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return PoiNotification(
      poiName: entry.name,
      dayNumber: entry.dayNumber,
      dayDate: '${dayNames[weekday]}',
      type: 'closure',
      message: '${entry.name} is CLOSED on ${dayNames[weekday]}s. Consider rescheduling.',
      color: const Color(0xFFFF6B6B),
      icon: Icons.cancel,
    );
  }

  // Best time warning
  if (knownPoi.bestTime != null) {
    return PoiNotification(
      poiName: entry.name,
      dayNumber: entry.dayNumber,
      dayDate: '',
      type: 'best_time',
      message: '${entry.name}: Best visited in the ${knownPoi.bestTime}.',
      color: const Color(0xFF6C63FF),
      icon: Icons.schedule,
    );
  }

  return null;
}
