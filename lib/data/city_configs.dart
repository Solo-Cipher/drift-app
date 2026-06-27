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
      cities: {
        'hanoi': CityInfo('Hanoi', const Coordinates(21.0285, 105.8542)),
        'hcmc': CityInfo('Ho Chi Minh City', const Coordinates(10.8231, 106.6297)),
        'ha_long': CityInfo('Ha Long', const Coordinates(20.9101, 107.1839)),
        'da_nang': CityInfo('Da Nang', const Coordinates(16.0544, 108.2022)),
        'hue': CityInfo('Hue', const Coordinates(16.4637, 107.5905)),
        'nha_trang': CityInfo('Nha Trang', const Coordinates(12.2388, 109.1967)),
        'phu_quoc': CityInfo('Phu Quoc', const Coordinates(10.2850, 103.9833)),
      },
    ),
    'sri_lanka': CityConfig(
      country: 'Sri Lanka',
      primaryCity: 'Colombo',
      flagEmoji: '🇱🇰',
      currency: 'LKR',
      currencySymbol: 'Rs',
      language: 'Sinhala / Tamil',
      timezone: 'SLST (UTC+5:30)',
      primaryTaxiApp: 'PickMe',
      emergencyNumber: '119',
      voltage: '230V',
      plugType: 'D/M',
      defaultHotelBase: 35,
      cities: {
        'colombo': CityInfo('Colombo', const Coordinates(6.9271, 79.8612)),
        'kandy': CityInfo('Kandy', const Coordinates(7.2906, 80.6337)),
        'galle': CityInfo('Galle', const Coordinates(6.0535, 80.2210)),
        'ella': CityInfo('Ella', const Coordinates(6.8667, 81.0467)),
        'sigiriya': CityInfo('Sigiriya', const Coordinates(7.9570, 80.7603)),
        'mirissa': CityInfo('Mirissa', const Coordinates(5.9483, 80.4586)),
      },
    ),
    'indonesia': CityConfig(
      country: 'Indonesia',
      primaryCity: 'Jakarta',
      flagEmoji: '🇮🇩',
      currency: 'IDR',
      currencySymbol: 'Rp',
      language: 'Indonesian',
      timezone: 'WIB (UTC+7)',
      primaryTaxiApp: 'Gojek',
      emergencyNumber: '112',
      voltage: '220V',
      plugType: 'C/F',
      defaultHotelBase: 40,
      cities: {
        'jakarta': CityInfo('Jakarta', const Coordinates(-6.2088, 106.8456)),
        'bali': CityInfo('Bali', const Coordinates(-8.3405, 115.0920)),
        'yogyakarta': CityInfo('Yogyakarta', const Coordinates(-7.7956, 110.3695)),
        'lombok': CityInfo('Lombok', const Coordinates(-8.6509, 116.1014)),
      },
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
      cities: {
        'edinburgh': CityInfo('Edinburgh', const Coordinates(55.9533, -3.1883)),
        'glasgow': CityInfo('Glasgow', const Coordinates(55.8642, -4.2518)),
        'highlands': CityInfo('Highlands', const Coordinates(57.4778, -5.0500)),
        'skye': CityInfo('Isle of Skye', const Coordinates(57.2730, -6.2150)),
      },
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
      cities: {
        'port_louis': CityInfo('Port Louis', const Coordinates(-20.1609, 57.5012)),
        'grand_baie': CityInfo('Grand Baie', const Coordinates(-20.0133, 57.5800)),
        'flic_en_flac': CityInfo('Flic en Flac', const Coordinates(-20.4519, 57.3650)),
        'belle_mare': CityInfo('Belle Mare', const Coordinates(-20.1889, 57.7056)),
      },
    ),
    'thailand': CityConfig(
      country: 'Thailand',
      primaryCity: 'Bangkok',
      flagEmoji: '🇹🇭',
      currency: 'THB',
      currencySymbol: '฿',
      language: 'Thai',
      timezone: 'ICT (UTC+7)',
      primaryTaxiApp: 'Grab',
      emergencyNumber: '191',
      voltage: '220V',
      plugType: 'A/B/C/O',
      defaultHotelBase: 35,
      cities: {
        'bangkok': CityInfo('Bangkok', const Coordinates(13.7563, 100.5018)),
        'phuket': CityInfo('Phuket', const Coordinates(7.8804, 98.3923)),
        'krabi': CityInfo('Krabi', const Coordinates(8.0863, 98.9063)),
        'chiang_mai': CityInfo('Chiang Mai', const Coordinates(18.7883, 98.9853)),
      },
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
      cities: {
        'tokyo': CityInfo('Tokyo', const Coordinates(35.6762, 139.6503)),
        'osaka': CityInfo('Osaka', const Coordinates(34.6937, 135.5023)),
        'kyoto': CityInfo('Kyoto', const Coordinates(35.0116, 135.7681)),
        'okinawa': CityInfo('Okinawa', const Coordinates(26.3344, 127.8056)),
        'hokkaido': CityInfo('Hokkaido', const Coordinates(43.0618, 141.3545)),
      },
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
      cities: {
        'istanbul': CityInfo('Istanbul', const Coordinates(41.0082, 28.9784)),
        'izmir': CityInfo('Izmir', const Coordinates(38.4237, 27.1428)),
        'antalya': CityInfo('Antalya', const Coordinates(36.8969, 30.7133)),
        'cappadocia': CityInfo('Cappadocia', const Coordinates(38.6431, 34.8289)),
      },
    ),
    'morocco': CityConfig(
      country: 'Morocco',
      primaryCity: 'Casablanca',
      flagEmoji: '🇲🇦',
      currency: 'MAD',
      currencySymbol: 'MAD',
      language: 'Arabic / French',
      timezone: 'WET (UTC+1)',
      primaryTaxiApp: 'Careem',
      emergencyNumber: '15',
      voltage: '220V',
      plugType: 'C/E',
      defaultHotelBase: 35,
      cities: {
        'casablanca': CityInfo('Casablanca', const Coordinates(33.5731, -7.5898)),
        'marrakech': CityInfo('Marrakech', const Coordinates(31.6295, -7.9811)),
        'fez': CityInfo('Fez', const Coordinates(34.0181, -5.0078)),
        'chefchaouen': CityInfo('Chefchaouen', const Coordinates(35.1714, -5.2696)),
      },
    ),
  };

  static CityConfig get(String countryKey) {
    final config = _configs[countryKey];
    if (config == null) {
      throw ArgumentError('Unknown country: $countryKey');
    }
    return config;
  }

  static List<String> get availableCountries => _configs.keys.toList();
}
