import '../models/trip_data.dart';

/// A notification about a venue — closure, ticket requirement, or timing warning
class ClosureNotification {
  final String venue;
  final String dayDate;
  final int dayNumber;
  final String message;
  final NotificationType type;
  final ClosureRisk risk;

  ClosureNotification({
    required this.venue,
    required this.dayDate,
    required this.dayNumber,
    required this.message,
    required this.type,
    required this.risk,
  });
}

enum NotificationType { closure, ticket, timing, info }
enum ClosureRisk { ok, warning, closed }

/// Check all days for venue issues: closures, ticket requirements, timing
List<ClosureNotification> checkClosures(TripData trip) {
  final notifications = <ClosureNotification>[];

  // Determine the trip country from the first day
  final country = trip.days.isNotEmpty ? trip.days.first.country.toLowerCase() : 'vietnam';

  for (final day in trip.days) {
    final date = _parseDate(day.date, trip.baseStartDate.year);
    final weekday = date.weekday; // 1=Mon ... 7=Sun

    for (final activity in day.activities) {
      final lower = activity.toLowerCase();

      // ── VIETNAM-SPECIFIC CLOSURES ──
      if (country == 'vietnam') {
        // Ho Chi Minh Mausoleum — closed Mon & Fri
        if (_matchesAny(lower, ['ho chi minh mausoleum', 'mausoleum'])) {
          if (weekday == 1 || weekday == 5) {
            final dayName = weekday == 1 ? 'Monday' : 'Friday';
            notifications.add(ClosureNotification(
              venue: 'Ho Chi Minh Mausoleum',
              dayDate: day.date,
              dayNumber: day.day,
              message: '${day.date} is a $dayName — Mausoleum is CLOSED. Reschedule to another day.',
              type: NotificationType.closure,
              risk: ClosureRisk.closed,
            ));
          }
        }

        // Vietnam Museum of Ethnology — closed Mondays
        if (_matchesAny(lower, ['museum of ethnology', 'ethnology museum'])) {
          if (weekday == 1) {
            notifications.add(ClosureNotification(
              venue: 'Vietnam Museum of Ethnology',
              dayDate: day.date,
              dayNumber: day.day,
              message: '${day.date} is a Monday — Museum of Ethnology is CLOSED.',
              type: NotificationType.closure,
              risk: ClosureRisk.closed,
            ));
          }
        }

        // Cu Chi Tunnels — rainy season warning
        if (_matchesAny(lower, ['cu chi', 'cu chi tunnels'])) {
          notifications.add(ClosureNotification(
            venue: 'Cu Chi Tunnels',
            dayDate: day.date,
            dayNumber: day.day,
            message: 'October is rainy season — tunnels may partially flood. Bring rain gear and wear proper shoes.',
            type: NotificationType.info,
            risk: ClosureRisk.warning,
          ));
        }
      }

      // ── SRI LANKA ──
      if (country == 'sri_lanka') {
        // Temple of the Tooth — restricted on Poya days
        if (_matchesAny(lower, ['temple of the tooth', 'sri dalada maligawa', 'kandy temple'])) {
          notifications.add(ClosureNotification(
            venue: 'Temple of the Tooth',
            dayDate: day.date,
            dayNumber: day.day,
            message: 'Check Poya day schedule — temple may have restricted access on full moon days.',
            type: NotificationType.timing,
            risk: ClosureRisk.warning,
          ));
        }
        // Sigiriya Lion Rock — closed during heavy rain
        if (_matchesAny(lower, ['sigiriya', 'lion rock'])) {
          notifications.add(ClosureNotification(
            venue: 'Sigiriya Lion Rock',
            dayDate: day.date,
            dayNumber: day.day,
            message: 'Climb can be slippery after rain. Wear proper shoes and start early to avoid afternoon heat.',
            type: NotificationType.timing,
            risk: ClosureRisk.warning,
          ));
        }
        // Whale watching — seasonal
        if (_matchesAny(lower, ['whale watching', 'whale'])) {
          notifications.add(ClosureNotification(
            venue: 'Whale Watching (Mirissa)',
            dayDate: day.date,
            dayNumber: day.day,
            message: 'Feb–Mar is peak season. Book early morning tour for best sightings. Sea can be rough — take motion sickness pills.',
            type: NotificationType.timing,
            risk: ClosureRisk.ok,
          ));
        }
        // Dambulla Cave Temple
        if (_matchesAny(lower, ['dambulla', 'golden cave', 'cave temple'])) {
          notifications.add(ClosureNotification(
            venue: 'Dambulla Golden Cave Temple',
            dayDate: day.date,
            dayNumber: day.day,
            message: 'Open daily. Remove shoes before entering. Go early to avoid crowds and heat.',
            type: NotificationType.timing,
            risk: ClosureRisk.ok,
          ));
        }
      }

      // ── SCOTLAND ──
      if (country == 'scotland') {
        if (_matchesAny(lower, ['edinburgh castle'])) {
          notifications.add(ClosureNotification(
            venue: 'Edinburgh Castle',
            dayDate: day.date,
            dayNumber: day.day,
            message: 'Check opening hours — castle may close early during winter months (Nov-Feb).',
            type: NotificationType.timing,
            risk: ClosureRisk.warning,
          ));
        }
      }

      // ── INDONESIA ──
      if (country == 'indonesia') {
        if (_matchesAny(lower, ['bali temple', 'pura', 'temple ceremony'])) {
          notifications.add(ClosureNotification(
            venue: 'Bali Temple',
            dayDate: day.date,
            dayNumber: day.day,
            message: 'Some temples close during ceremonies. Check local schedule.',
            type: NotificationType.timing,
            risk: ClosureRisk.warning,
          ));
        }
        if (_matchesAny(lower, ['mount bromo', 'bromo'])) {
          notifications.add(ClosureNotification(
            venue: 'Mount Bromo',
            dayDate: day.date,
            dayNumber: day.day,
            message: 'Volcanic activity may close trails. Check BMKG alerts before visiting.',
            type: NotificationType.info,
            risk: ClosureRisk.warning,
          ));
        }
      }

      // ── THAILAND ──
      if (country == 'thailand') {
        if (_matchesAny(lower, ['grand palace', 'wat phra kaew'])) {
          if (weekday == 6 || weekday == 7) {
            notifications.add(ClosureNotification(
              venue: 'Grand Palace',
              dayDate: day.date,
              dayNumber: day.day,
              message: 'Grand Palace can be extremely crowded on weekends. Go early morning (opens 8:30am).',
              type: NotificationType.timing,
              risk: ClosureRisk.warning,
            ));
          }
        }
        if (_matchesAny(lower, ['elephant', 'sanctuary'])) {
          notifications.add(ClosureNotification(
            venue: 'Elephant Sanctuary',
            dayDate: day.date,
            dayNumber: day.day,
            message: 'Book sanctuary visit at least 1 week ahead. Avoid riding camps — choose ethical sanctuaries only.',
            type: NotificationType.ticket,
            risk: ClosureRisk.ok,
          ));
        }
      }

      // ── JAPAN ──
      if (country == 'japan') {
        if (_matchesAny(lower, ['museum', 'tokyo national', 'teamLab'])) {
          if (weekday == 1) {
            notifications.add(ClosureNotification(
              venue: 'Museum / Gallery',
              dayDate: day.date,
              dayNumber: day.day,
              message: '${day.date} is a Monday — many museums in Japan are closed on Mondays.',
              type: NotificationType.closure,
              risk: ClosureRisk.closed,
            ));
          }
        }
        if (_matchesAny(lower, ['onsen', 'hot spring', 'sentō'])) {
          notifications.add(ClosureNotification(
            venue: 'Onsen / Hot Spring',
            dayDate: day.date,
            dayNumber: day.day,
            message: 'Tattoo policies vary at onsen. Some facilities restrict entry for visible tattoos.',
            type: NotificationType.info,
            risk: ClosureRisk.ok,
          ));
        }
      }

      // ── TURKEY ──
      if (country == 'turkey') {
        if (_matchesAny(lower, ['mosque', 'blue mosque', 'hagia sophia'])) {
          if (weekday == 5) {
            notifications.add(ClosureNotification(
              venue: 'Mosque Visit',
              dayDate: day.date,
              dayNumber: day.day,
              message: '${day.date} is Friday — mosques close during Friday prayer (around 1pm). Plan visit outside prayer times.',
              type: NotificationType.timing,
              risk: ClosureRisk.warning,
            ));
          }
        }
        if (_matchesAny(lower, ['hammam', 'turkish bath'])) {
          notifications.add(ClosureNotification(
            venue: 'Turkish Hammam',
            dayDate: day.date,
            dayNumber: day.day,
            message: 'Book hammam in advance. Some facilities have separate hours for men and women.',
            type: NotificationType.timing,
            risk: ClosureRisk.ok,
          ));
        }
      }

      // ── MOROCCO ──
      if (country == 'morocco') {
        if (_matchesAny(lower, ['medina', 'souk', 'bazaar', 'fez medina'])) {
          notifications.add(ClosureNotification(
            venue: 'Medina / Souk',
            dayDate: day.date,
            dayNumber: day.day,
            message: 'Souks can be overwhelming. Keep valuables secure and be prepared to bargain.',
            type: NotificationType.info,
            risk: ClosureRisk.ok,
          ));
        }
        if (_matchesAny(lower, ['ramadan', 'mosque', ' Hassan ii'])) {
          notifications.add(ClosureNotification(
            venue: 'Hassan II Mosque',
            dayDate: day.date,
            dayNumber: day.day,
            message: 'Non-Muslims can only visit outside prayer times. Check tour schedule in advance.',
            type: NotificationType.timing,
            risk: ClosureRisk.ok,
          ));
        }
      }

      // ── MAURITIUS ──
      if (country == 'mauritius') {
        if (_matchesAny(lower, ['beach', 'ocean', 'snorkel', 'diving'])) {
          notifications.add(ClosureNotification(
            venue: 'Beach / Water Sports',
            dayDate: day.date,
            dayNumber: day.day,
            message: 'Check weather conditions before water activities. Avoid swimming in unpatrolled areas.',
            type: NotificationType.info,
            risk: ClosureRisk.ok,
          ));
        }
      }

      // ── UNIVERSAL CHECKS (any country) ──

      // ── TICKET REQUIRED ──
      if (_matchesAny(lower, ['cruise', 'overnight cruise', 'ha long bay cruise'])) {
        notifications.add(ClosureNotification(
          venue: 'Cruise',
          dayDate: day.date,
          dayNumber: day.day,
          message: 'Cruise requires advance booking. Book at least 1-2 weeks ahead.',
          type: NotificationType.ticket,
          risk: ClosureRisk.warning,
        ));
      }

      if (_matchesAny(lower, ['cu chi', 'cu chi tunnels'])) {
        notifications.add(ClosureNotification(
          venue: 'Cu Chi Tunnels',
          dayDate: day.date,
          dayNumber: day.day,
          message: 'Entrance ticket required. Book a guided tour in advance for the best experience.',
          type: NotificationType.ticket,
          risk: ClosureRisk.ok,
        ));
      }

      if (_matchesAny(lower, ['water puppet', 'thang long'])) {
        notifications.add(ClosureNotification(
          venue: 'Water Puppet Theatre',
          dayDate: day.date,
          dayNumber: day.day,
          message: 'Show tickets required — book in advance, especially for weekend shows.',
          type: NotificationType.ticket,
          risk: ClosureRisk.ok,
        ));
      }

      if (_matchesAny(lower, ['mekong delta', 'mekong'])) {
        notifications.add(ClosureNotification(
          venue: 'Mekong Delta Tour',
          dayDate: day.date,
          dayNumber: day.day,
          message: 'Day tour requires booking ahead.',
          type: NotificationType.ticket,
          risk: ClosureRisk.ok,
        ));
      }

      if (_matchesAny(lower, ['cooking class', 'cooking course'])) {
        notifications.add(ClosureNotification(
          venue: 'Cooking Class',
          dayDate: day.date,
          dayNumber: day.day,
          message: 'Cooking class requires advance reservation. Book 2-3 days ahead.',
          type: NotificationType.ticket,
          risk: ClosureRisk.ok,
        ));
      }

      if (_matchesAny(lower, ['snorkeling', 'snorkelling', 'snorkel', 'diving'])) {
        notifications.add(ClosureNotification(
          venue: 'Snorkeling / Diving',
          dayDate: day.date,
          dayNumber: day.day,
          message: 'Requires booking. Check weather conditions before committing.',
          type: NotificationType.ticket,
          risk: ClosureRisk.warning,
        ));
      }

      // ── TIMING WARNINGS ──
      if (_matchesAny(lower, ['temple', 'pagoda', 'shrine', 'mosque'])) {
        if (weekday == 6 || weekday == 7) {
          notifications.add(ClosureNotification(
            venue: 'Religious Site',
            dayDate: day.date,
            dayNumber: day.day,
            message: '${day.date} is a weekend — expect crowds at religious sites. Go early morning.',
            type: NotificationType.timing,
            risk: ClosureRisk.warning,
          ));
        }
      }

      if (_matchesAny(lower, ['market', 'bazaar', 'souq'])) {
        if (weekday == 6 || weekday == 7) {
          notifications.add(ClosureNotification(
            venue: 'Market / Bazaar',
            dayDate: day.date,
            dayNumber: day.day,
            message: '${day.date} is a weekend — markets are extremely crowded. Bargain hard, watch belongings.',
            type: NotificationType.timing,
            risk: ClosureRisk.warning,
          ));
        }
      }
    }
  }

  return notifications;
}

bool _matchesAny(String text, List<String> keywords) {
  return keywords.any((k) => text.contains(k));
}

DateTime _parseDate(String dateStr, int year) {
  final months = {
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
    'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
  };
  final parts = dateStr.split(' ');
  final month = months[parts[0]] ?? 10;
  final day = int.tryParse(parts[1].replaceAll(',', '')) ?? 1;
  return DateTime(year, month, day);
}
