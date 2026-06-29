import 'package:flutter/material.dart';

/// Geographic coordinates for a city
class Coordinates {
  final double lat;
  final double lng;
  const Coordinates(this.lat, this.lng);
}

/// City information including display name and coordinates
class CityInfo {
  final String displayName;
  final Coordinates coordinates;
  const CityInfo(this.displayName, this.coordinates);
}

/// A recommended app for the country
class RecommendedApp {
  final String name;
  final String category;
  final String description;
  final String url;
  final String iconName;
  final int colorValue;
  const RecommendedApp({required this.name, required this.category, required this.description, required this.url, required this.iconName, required this.colorValue});
}

/// Weather profile per destination
class WeatherProfile {
  final String location;
  final String detail;
  final String iconName;
  final String severity;
  const WeatherProfile({required this.location, required this.detail, required this.iconName, required this.severity});
}

/// Configuration for a destination country
class CityConfig {
  final String country;
  final String primaryCity;
  final String flagEmoji;
  final String currency;
  final String currencySymbol;
  final String language;
  final String timezone;
  final String primaryTaxiApp;
  final String emergencyNumber;
  final String voltage;
  final String plugType;
  final double defaultHotelBase;
  final Map<String, CityInfo> cities;
  final String iataCode;
  final String countryCode;
  final List<RecommendedApp> recommendedApps;
  final List<WeatherProfile> weatherProfiles;
  final double flightBasePrice;
  final String originAirport;

  const CityConfig({
    required this.country,
    required this.primaryCity,
    required this.flagEmoji,
    required this.currency,
    required this.currencySymbol,
    required this.language,
    required this.timezone,
    required this.primaryTaxiApp,
    required this.emergencyNumber,
    required this.voltage,
    required this.plugType,
    required this.defaultHotelBase,
    required this.cities,
    this.iataCode = '',
    this.countryCode = '',
    this.recommendedApps = const [],
    this.weatherProfiles = const [],
    this.flightBasePrice = 200.0,
    this.originAirport = 'MCT',
  });
}

/// Static registry of all supported destination countries and their cities
class CityConfigs {
  static final Map<String, CityConfig> _configs = {
    'vietnam': CityConfig(
      country: 'Vietnam',
      primaryCity: 'Hanoi',
      flagEmoji: '🇻🇳',
      currency: 'VND',
      currencySymbol: '₫',
      language: 'Vietnamese',
      timezone: 'ICT (UTC+7)',
      primaryTaxiApp: 'Grab',
      emergencyNumber: '113',
      voltage: '220V',
      plugType: 'A/C/D',
      defaultHotelBase: 45,
      iataCode: 'HAN',
      countryCode: 'vn',
      flightBasePrice: 220.0,
      originAirport: 'MCT',
      cities: {
        'hanoi': CityInfo('Hanoi', const Coordinates(21.0285, 105.8542)),
        'hcmc': CityInfo('Ho Chi Minh City', const Coordinates(10.8231, 106.6297)),
        'ha_long': CityInfo('Ha Long', const Coordinates(20.9101, 107.1839)),
        'da_nang': CityInfo('Da Nang', const Coordinates(16.0544, 108.2022)),
        'hue': CityInfo('Hue', const Coordinates(16.4637, 107.5905)),
        'nha_trang': CityInfo('Nha Trang', const Coordinates(12.2388, 109.1967)),
        'phu_quoc': CityInfo('Phu Quoc', const Coordinates(10.2850, 103.9833)),
      },
      recommendedApps: [
        const RecommendedApp(name: 'Grab', category: 'Ride Hailing & Food', description: '#1 ride app in Vietnam. Book motorbike taxis, cars, order food delivery.', url: 'https://www.grab.com/vn/', iconName: 'local_taxi', colorValue: 0xFF00B14F),
        const RecommendedApp(name: 'Be', category: 'Ride Hailing', description: 'Grab competitor with good motorbike taxi rates in Hanoi and HCMC.', url: 'https://be.com.vn/', iconName: 'motorcycle', colorValue: 0xFFE53935),
        const RecommendedApp(name: 'Vietnam Airlines', category: 'Domestic Flights', description: 'Flag carrier for domestic routes. Book early for best rates.', url: 'https://www.vietnamairlines.com/', iconName: 'flight', colorValue: 0xFF0066B3),
        const RecommendedApp(name: 'Vexere', category: 'Bus Tickets', description: 'Book long-distance buses online for intercity travel.', url: 'https://vexere.com/', iconName: 'directions_bus', colorValue: 0xFFFF9800),
        const RecommendedApp(name: 'MoMo', category: 'Payment', description: 'Vietnam\'s top e-wallet. Pay at shops and restaurants.', url: 'https://momo.vn/', iconName: 'account_balance_wallet', colorValue: 0xFFA83279),
        const RecommendedApp(name: 'Google Translate', category: 'Language', description: 'Download Vietnamese offline pack. Camera translate for menus.', url: 'https://translate.google.com/', iconName: 'translate', colorValue: 0xFF4285F4),
      ],
      weatherProfiles: [
        const WeatherProfile(location: 'Hanoi', detail: 'Oct-Nov: Cool and dry. Avg 22°C. Great for sightseeing.', iconName: 'sunny', severity: 'good'),
        const WeatherProfile(location: 'Ha Long Bay', detail: 'Light rain possible. Bring a rain jacket for the cruise.', iconName: 'cloud', severity: 'caution'),
        const WeatherProfile(location: 'Ho Chi Minh City', detail: 'Heavy afternoon showers expected. Plan indoor activities 2-4pm.', iconName: 'umbrella', severity: 'warning'),
      ],
    ),
    'sri_lanka': CityConfig(
      country: 'Sri Lanka',
      primaryCity: 'Colombo',
      flagEmoji: '�🇰',
      currency: 'LKR',
      currencySymbol: 'Rs',
      language: 'Sinhala / Tamil',
      timezone: 'SLST (UTC+5:30)',
      primaryTaxiApp: 'PickMe',
      emergencyNumber: '119',
      voltage: '230V',
      plugType: 'D/M',
      defaultHotelBase: 35,
      iataCode: 'CMB',
      countryCode: 'lk',
      flightBasePrice: 180.0,
      originAirport: 'MCT',
      cities: {
        'colombo': CityInfo('Colombo', const Coordinates(6.9271, 79.8612)),
        'kandy': CityInfo('Kandy', const Coordinates(7.2906, 80.6337)),
        'galle': CityInfo('Galle', const Coordinates(6.0535, 80.2210)),
        'ella': CityInfo('Ella', const Coordinates(6.8667, 81.0467)),
        'sigiriya': CityInfo('Sigiriya', const Coordinates(7.9570, 80.7603)),
        'mirissa': CityInfo('Mirissa', const Coordinates(5.9483, 80.4586)),
      },
      recommendedApps: [
        const RecommendedApp(name: 'PickMe', category: 'Ride Hailing', description: 'Sri Lanka\'s #1 ride app. Tuk-tuks and cars available.', url: 'https://pickme.lk/', iconName: 'local_taxi', colorValue: 0xFF00B14F),
        const RecommendedApp(name: 'Uber', category: 'Ride Hailing', description: 'Available in Colombo. Good for airport transfers.', url: 'https://www.uber.com/', iconName: 'local_taxi', colorValue: 0xFF000000),
        const RecommendedApp(name: 'Google Translate', category: 'Language', description: 'Download Sinhala and Tamil offline packs.', url: 'https://translate.google.com/', iconName: 'translate', colorValue: 0xFF4285F4),
        const RecommendedApp(name: 'XE Currency', category: 'Currency', description: 'Real-time OMR to LKR rates.', url: 'https://www.xe.com/', iconName: 'attach_money', colorValue: 0xFF00BFA6),
      ],
      weatherProfiles: [
        const WeatherProfile(location: 'Colombo', detail: 'Dec-Mar: Dry season. Hot and humid. Avg 27°C.', iconName: 'sunny', severity: 'good'),
        const WeatherProfile(location: 'Kandy', detail: 'Cooler highlands. Evening temps drop to 18°C. Bring a light jacket.', iconName: 'cloud', severity: 'caution'),
        const WeatherProfile(location: 'Ella', detail: 'Hill country mist common. Mornings may be foggy.', iconName: 'cloud', severity: 'caution'),
      ],
    ),
    'indonesia': CityConfig(
      country: 'Indonesia',
      primaryCity: 'Jakarta',
      flagEmoji: '',
      currency: 'IDR',
      currencySymbol: 'Rp',
      language: 'Indonesian',
      timezone: 'WIB (UTC+7)',
      primaryTaxiApp: 'Gojek',
      emergencyNumber: '112',
      voltage: '220V',
      plugType: 'C/F',
      defaultHotelBase: 40,
      iataCode: 'CGK',
      countryCode: 'id',
      flightBasePrice: 200.0,
      originAirport: 'MCT',
      cities: {
        'jakarta': CityInfo('Jakarta', const Coordinates(-6.2088, 106.8456)),
        'bali': CityInfo('Bali', const Coordinates(-8.3405, 115.0920)),
        'yogyakarta': CityInfo('Yogyakarta', const Coordinates(-7.7956, 110.3695)),
        'lombok': CityInfo('Lombok', const Coordinates(-8.6509, 116.1014)),
      },
      recommendedApps: [
        const RecommendedApp(name: 'Gojek', category: 'Ride Hailing & Food', description: '#1 super app in Indonesia. Rides, food, payments.', url: 'https://www.gojek.com/', iconName: 'local_taxi', colorValue: 0xFF00AA13),
        const RecommendedApp(name: 'Grab', category: 'Ride Hailing', description: 'Gojek competitor. Often has promos in Bali.', url: 'https://www/', iconName: 'local_taxi', colorValue: 0xFF00B14F),
        const RecommendedApp(name: 'Traveloka', category: 'Booking', description: 'Book flights, hotels, attractions and tours.', url: 'https://www.traveloka.com/', iconName: 'flight', colorValue: 0xFF0066B3),
        const RecommendedApp(name: 'Google Translate', category: 'Language', description: 'Download Bahasa Indonesia offline pack.', url: 'https://translate.google.com/', iconName: 'translate', colorValue: 0xFF4285F4),
      ],
      weatherProfiles: [
        const WeatherProfile(location: 'Jakarta', detail: 'Apr-Oct: Dry season. Hot and humid. Avg 28°C.', iconName: 'sunny', severity: 'good'),
        const WeatherProfile(location: 'Bali', detail: 'Dry season Apr-Oct. Avg 27°C. Low humidity.', iconName: 'sunny', severity: 'good'),
        const WeatherProfile(location: 'Yogyakarta', detail: 'Afternoon thunderstorms common Nov-Mar. Plan mornings outdoors.', iconName: 'umbrella', severity: 'warning'),
      ],
    ),
    'scotland': CityConfig(
      country: 'Scotland',
      primaryCity: 'Edinburgh',
      flagEmoji: '🏴󠁧󠁢󠁳󠁣󠁴󠁿',
      currency: 'GBP',
      currencySymbol: '£',
      language: 'English / Scots',
      timezone: 'GMT (UTC+0)',
      primaryTaxiApp: 'Free Now',
      emergencyNumber: '999',
      voltage: '230V',
      plugType: 'G',
      defaultHotelBase: 55,
      iataCode: 'EDI',
      countryCode: 'gb',
      flightBasePrice: 280.0,
      originAirport: 'MCT',
      cities: {
        'edinburgh': CityInfo('Edinburgh', const Coordinates(55.9533, -3.1883)),
        'glasgow': CityInfo('Glasgow', const Coordinates(55.8642, -4.2518)),
        'highlands': CityInfo('Highlands', const Coordinates(57.4778, -5.0500)),
        'skye': CityInfo('Isle of Skye', const Coordinates(57.2730, -6.2150)),
      },
      recommendedApps: [
        const RecommendedApp(name: 'Free Now', category: 'Taxis', description: 'Book licensed black cabs and private hires across Scotland.', url: 'https://free-now.com/', iconName: 'local_taxi', colorValue: 0xFFFFD700),
        const RecommendedApp(name: 'Trainline', category: 'Trains', description: 'Book ScotRail and cross-border trains. Get e-tickets.', url: 'https://www.trainline.com/', iconName: 'train', colorValue: 0xFF3F51B5),
        const RecommendedApp(name: 'VisitScotland', category: 'Tourism', description: 'Official guide with maps, attractions, events.', url: 'https://www.visitscotland.com/', iconName: 'map', colorValue: 0xFF34A853),
        const RecommendedApp(name: 'Met Office', category: 'Weather', description: 'Accurate UK weather forecasts. Scotland can change fast.', url: 'https://www.metoffice.gov.uk/', iconName: 'cloud', colorValue: 0xFF4285F4),
      ],
      weatherProfiles: [
        const WeatherProfile(location: 'Edinburgh', detail: 'May-Sep: Mild, 15-20°C. Rain possible any day. Pack layers!', iconName: 'cloud', severity: 'caution'),
        const WeatherProfile(location: 'Highlands', detail: 'Cooler than Edinburgh. Midges (biting flies) May-Sep. Bring repellent.', iconName: 'cloud', severity: 'warning'),
        const WeatherProfile(location: 'Isle of Skye', detail: 'Very windy. Waterproof jacket essential year-round.', iconName: 'umbrella', severity: 'warning'),
      ],
    ),
    'mauritius': CityConfig(
      country: 'Mauritius',
      primaryCity: 'Port Louis',
      flagEmoji: '🇲🇺',
      currency: 'MUR',
      currencySymbol: '₨',
      language: 'English / French / Creole',
      timezone: 'MUT (UTC+4)',
      primaryTaxiApp: 'Uber',
      emergencyNumber: '112',
      voltage: '230V',
      plugType: 'C/M',
      defaultHotelBase: 45,
      iataCode: 'MRU',
      countryCode: 'mu',
      flightBasePrice: 240.0,
      originAirport: 'MCT',
      cities: {
        'port_louis': CityInfo('Port Louis', const Coordinates(-20.1609, 57.5012)),
        'grand_baie': CityInfo('Grand Baie', const Coordinates(-20.0133, 57.5800)),
        'flic_en_flac': CityInfo('Flic en Flac', const Coordinates(-20.4519, 57.3650)),
        'belle_mare': CityInfo('Belle Mare', const Coordinates(-20.1889, 57.7056)),
      },
      recommendedApps: [
        const RecommendedApp(name: 'Uber', category: 'Taxis', description: 'Available in Mauritius. Good for airport transfers.', url: 'https://www.uber.com/mu/', iconName: 'local_taxi', colorValue: 0xFF000000),
        const RecommendedApp(name: 'Air Mauritius', category: 'Flights', description: 'National carrier for domestic updates and lounge access.', url: 'https://www.airmauritius.com/', iconName: 'flight', colorValue: 0xFF0066B3),
        const RecommendedApp(name: 'Google Translate', category: 'Language', description: 'Mauritian Creole, French widely spoken. English in tourist areas.', url: 'https://translate.google.com/', iconName: 'translate', colorValue: 0xFF4285F4),
        const RecommendedApp(name: 'XE Currency', category: 'Currency', description: 'Real-time OMR to MUR rates.', url: 'https://www.xe.com/', iconName: 'attach_money', colorValue: 0xFF00BFA6),
      ],
      weatherProfiles: [
        const WeatherProfile(location: 'Port Louis', detail: 'May-Nov: Dry and sunny. 22-28°C. Peak beach season.', iconName: 'sunny', severity: 'good'),
        const WeatherProfile(location: 'Grand Baie', detail: 'Cyclone season Dec-Mar. Monitor weather if traveling then.', iconName: 'umbrella', severity: 'warning'),
        const WeatherProfile(location: 'Belle Mare', detail: 'East coast trade winds. Best conditions May-Sep.', iconName: 'sunny', severity: 'good'),
      ],
    ),
    'thailand': CityConfig(
      country: 'Thailand',
      primaryCity: 'Bangkok',
      flagEmoji: '�🇭',
      currency: 'THB',
      currencySymbol: '฿',
      language: 'Thai',
      timezone: 'ICT (UTC+7)',
      primaryTaxiApp: 'Grab',
      emergencyNumber: '191',
      voltage: '220V',
      plugType: 'A/B/C/O',
      defaultHotelBase: 35,
      iataCode: 'BKK',
      countryCode: 'th',
      flightBasePrice: 180.0,
      originAirport: 'MCT',
      cities: {
        'bangkok': CityInfo('Bangkok', const Coordinates(13.7563, 100.5018)),
        'phuket': CityInfo('Phuket', const Coordinates(7.8804, 98.3923)),
        'krabi': CityInfo('Krabi', const Coordinates(8.0863, 98.9063)),
        'chiang_mai': CityInfo('Chiang Mai', const Coordinates(18.7883, 98.9853)),
      },
      recommendedApps: [
        const RecommendedApp(name: 'Grab', category: 'Ride Hailing', description: '#1 ride app in Thailand. Food delivery and payments too.', url: 'https://www.grab.com/th/', iconName: 'local_taxi', colorValue: 0xFF00B14F),
        const RecommendedApp(name: 'Bolt', category: 'Ride Hailing', description: 'Often cheaper than Grab for short trips.', url: 'https://bolt.eu/', iconName: 'local_taxi', colorValue: 0xFF25C07A),
        const RecommendedApp(name: 'Agoda', category: 'Hotels', description: 'Asia-focused booking. Great hotel deals in Thailand.', url: 'https://www.agoda.com/', iconName: 'hotel', colorValue: 0xFF6C63FF),
        const RecommendedApp(name: '12Go Asia', category: 'Transport', description: 'Book trains, buses, ferries across Thailand.', url: 'https://12go.asia/en/thailand', iconName: 'train', colorValue: 0xFF3F51B5),
      ],
      weatherProfiles: [
        const WeatherProfile(location: 'Bangkok', detail: 'Nov-Feb: Coolest and driest. Avg 26-30°C. Peak tourist season.', iconName: 'sunny', severity: 'good'),
        const WeatherProfile(location: 'Phuket', detail: 'May-Oct: Monsoon season. Heavy rain, rough seas. Nov-Apr best.', iconName: 'umbrella', severity: 'warning'),
        const WeatherProfile(location: 'Chiang Mai', detail: 'Nov-Feb: Cool and clear. Dec-Jan can be chilly at night.', iconName: 'sunny', severity: 'good'),
      ],
    ),
    'japan': CityConfig(
      country: 'Japan',
      primaryCity: 'Tokyo',
      flagEmoji: '🇯🇵',
      currency: 'JPY',
      currencySymbol: '¥',
      language: 'Japanese',
      timezone: 'JST (UTC+9)',
      primaryTaxiApp: 'GO',
      emergencyNumber: '110',
      voltage: '100V',
      plugType: 'A',
      defaultHotelBase: 60,
      iataCode: 'NRT',
      countryCode: 'jp',
      flightBasePrice: 300.0,
      originAirport: 'MCT',
      cities: {
        'tokyo': CityInfo('Tokyo', const Coordinates(35.6762, 139.6503)),
        'osaka': CityInfo('Osaka', const Coordinates(34.6937, 135.5023)),
        'kyoto': CityInfo('Kyoto', const Coordinates(35.0116, 135.7681)),
        'okinawa': CityInfo('Okinawa', const Coordinates(26.3344, 127.8056)),
        'hokkaido': CityInfo('Hokkaido', const Coordinates(43.0618, 141.3545)),
      },
      recommendedApps: [
        const RecommendedApp(name: 'GO', category: 'Taxis', description: '#1 taxi app in Japan. No hailing cabs on street.', url: 'https://go-taxibus.azurewebsites.net/', iconName: 'local_taxi', colorValue: 0xFF00B14F),
        const RecommendedApp(name: 'Japan Travel by Navitime', category: 'Navigation', description: 'Better than Google Maps in Japan. JR pass route finder.', url: 'https://japantravel.navitime.com/', iconName: 'map', colorValue: 0xFF34A853),
        const RecommendedApp(name: 'Google Translate', category: 'Language', description: 'Camera translate essential for Japanese menus and signs.', url: 'https://translate.google.com/', iconName: 'translate', colorValue: 0xFF4285F4),
        const RecommendedApp(name: 'Suica (Apple Wallet)', category: 'Payment', description: 'Add Suica to Apple Wallet for trains, convenience stores.', url: 'https://www.jreast.co.jp/e/pass/suica.html', iconName: 'credit_card', colorValue: 0xFF00BFA6),
      ],
      weatherProfiles: [
        const WeatherProfile(location: 'Tokyo', detail: 'Mar-May: Cherry blossom season. Mild 15-22°C. Book ahead!', iconName: 'sunny', severity: 'good'),
        const WeatherProfile(location: 'Osaka', detail: 'Similar to Tokyo. Autumn leaves Nov are spectacular.', iconName: 'sunny', severity: 'good'),
        const WeatherProfile(location: 'Hokkaido', detail: 'Sep-Oct: Autumn colors. Winter Nov-Mar for skiing and snow.', iconName: 'cloud', severity: 'caution'),
      ],
    ),
    'turkey': CityConfig(
      country: 'Turkey',
      primaryCity: 'Istanbul',
      flagEmoji: '🇹🇷',
      currency: 'TRY',
      currencySymbol: '₺',
      language: 'Turkish',
      timezone: 'TRT (UTC+3)',
      primaryTaxiApp: 'Taksi',
      emergencyNumber: '112',
      voltage: '220V',
      plugType: 'C/F',
      defaultHotelBase: 40,
      iataCode: 'IST',
      countryCode: 'tr',
      flightBasePrice: 160.0,
      originAirport: 'MCT',
      cities: {
        'istanbul': CityInfo('Istanbul', const Coordinates(41.0082, 28.9784)),
        'izmir': CityInfo('Izmir', const Coordinates(38.4237, 27.1428)),
        'antalya': CityInfo('Antalya', const Coordinates(36.8969, 30.7133)),
        'cappadocia': CityInfo('Cappadocia', const Coordinates(38.6431, 34.8289)),
      },
      recommendedApps: [
        const RecommendedApp(name: 'BiTaksi', category: 'Taxis', description: 'Metered taxis in Istanbul. Avoids negotiation.', url: 'https://bitaksi.com/', iconName: 'local_taxi', colorValue: 0xFF00B14F),
        const RecommendedApp(name: 'Obilet', category: 'Transport', description: 'Book flights, buses, ferries across Turkey.', url: 'https://www.obilet.com/', iconName: 'directions_bus', colorValue: 0xFF3F51B5),
        const RecommendedApp(name: 'TripAdvisor', category: 'Tourism', description: 'Reviews for restaurants, tours, attractions.', url: 'https://www.tripadvisor.com/', iconName: 'map', colorValue: 0xFF34A853),
        const RecommendedApp(name: 'XE Currency', category: 'Currency', description: 'Real-time OMR to TRY rates. Lira fluctuates — check often.', url: 'https://www.xe.com/', iconName: 'attach_money', colorValue: 0xFF00BFA6),
      ],
      weatherProfiles: [
        const WeatherProfile(location: 'Istanbul', detail: 'May-Oct: Warm and pleasant. Jul-Aug hot up to 30°C.', iconName: 'sunny', severity: 'good'),
        const WeatherProfile(location: 'Cappadocia', detail: 'Spring and fall best. Hot air balloons fly in calm conditions.', iconName: 'cloud', severity: 'caution'),
        const WeatherProfile(location: 'Antalya', detail: 'Coastal Mediterranean. Hot summers 35°C. Beach ideal Jun-Sep.', iconName: 'sunny', severity: 'good'),
      ],
    ),
    'morocco': CityConfig(
      country: 'Morocco',
      primaryCity: 'Casablanca',
      flagEmoji: '🇲�',
      currency: 'MAD',
      currencySymbol: 'MAD',
      language: 'Arabic / French',
      timezone: 'WET (UTC+1)',
      primaryTaxiApp: 'Careem',
      emergencyNumber: '15',
      voltage: '220V',
      plugType: 'C/E',
      defaultHotelBase: 35,
      iataCode: 'CMN',
      countryCode: 'ma',
      flightBasePrice: 220.0,
      originAirport: 'MCT',
      cities: {
        'casablanca': CityInfo('Casablanca', const Coordinates(33.5731, -7.5898)),
        'marrakech': CityInfo('Marrakech', const Coordinates(31.6295, -7.9811)),
        'fez': CityInfo('Fez', const Coordinates(34.0181, -5.0078)),
        'chefchaouen': CityInfo('Chefchaouen', const Coordinates(35.1714, -5.2696)),
      },
      recommendedApps: [
        const RecommendedApp(name: 'Careem', category: 'Taxis', description: 'Popular in Casablanca and Marrakech. Uber alternative.', url: 'https://www.careem.com/', iconName: 'local_taxi', colorValue: 0xFF00B14F),
        const RecommendedApp(name: 'ONCF', category: 'Trains', description: 'Official rail app for Casablanca-Marrakech and more.', url: 'https://www-oncf-ma.translate.goog/', iconName: 'train', colorValue: 0xFF3F51B5),
        const RecommendedApp(name: 'Google Translate', category: 'Language', description: 'Download Arabic and French offline. Camera translate for signs.', url: 'https://translate.google.com/', iconName: 'translate', colorValue: 0xFF4285F4),
        const RecommendedApp(name: 'HappyCow', category: 'Food', description: 'Find vegetarian/vegan options in tourist cities.', url: 'https://www.happycow.net/', iconName: 'restaurant', colorValue: 0xFF00BFA6),
      ],
      weatherProfiles: [
        const WeatherProfile(location: 'Casablanca', detail: 'May-Sep: Warm and dry. Atlantic breeze keeps it pleasant.', iconName: 'sunny', severity: 'good'),
        const WeatherProfile(location: 'Marrakech', detail: 'Inland heat. Summer 40°C+. Best Mar-May or Sep-Nov.', iconName: 'umbrella', severity: 'warning'),
        const WeatherProfile(location: 'Chefchaouen', detail: 'Mountain town. Cooler than coast. Spring for blue city photos.', iconName: 'sunny', severity: 'good'),
      ],
    ),
  };

  static CityConfig get(String countryKey) {
    final config = _configs[countryKey];
    if (config == null) {
      throw ArgumentError('Unknown country: $countryKey');
    }
    return config;
  }

  static CityConfig? tryGet(String countryKey) {
    return _configs[countryKey];
  }

  static List<String> get availableCountries => _configs.keys.toList();
}

// ─── Helper to map iconName to IconData ──────────────────────────────
IconData parseIcon(String iconName) {
  switch (iconName) {
    case 'local_taxi': return Icons.local_taxi;
    case 'motorcycle': return Icons.motorcycle;
    case 'flight': return Icons.flight;
    case 'flight_takeoff': return Icons.flight_takeoff;
    case 'directions_bus': return Icons.directions_bus;
    case 'train': return Icons.train;
    case 'directions_car': return Icons.directions_car;
    case 'directions_walk': return Icons.directions_walk;
    case 'translate': return Icons.translate;
    case 'map': return Icons.map;
    case 'attach_money': return Icons.attach_money;
    case 'account_balance_wallet': return Icons.account_balance_wallet;
    case 'credit_card': return Icons.credit_card;
    case 'restaurant': return Icons.restaurant;
    case 'hotel': return Icons.hotel;
    case 'cloud': return Icons.cloud;
    case 'wb_sunny': return Icons.wb_sunny;
    case 'beach_access': return Icons.beach_access;
    case 'business': return Icons.business;
    case 'directions_bike': return Icons.directions_bike;
    case 'electric_rickshaw': return Icons.electric_rickshaw;
    case 'bus_alert': return Icons.bus_alert;
    case 'spa': return Icons.spa;
    default: return Icons.apps;
  }
}
