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

  for (final day in trip.days) {
    final date = _parseDate(day.date, trip.baseStartDate.year);
    final weekday = date.weekday; // 1=Mon ... 7=Sun

    for (final activity in day.activities) {
      final lower = activity.toLowerCase();

      // ── CLOSURES ──

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

      // ── TICKET REQUIRED ──

      // Ha Long Bay Cruise — requires booking
      if (_matchesAny(lower, ['ha long bay cruise', 'ha long cruise', 'overnight cruise'])) {
        notifications.add(ClosureNotification(
          venue: 'Ha Long Bay Cruise',
          dayDate: day.date,
          dayNumber: day.day,
          message: 'Cruise requires advance booking. Book at least 1-2 weeks ahead for October.',
          type: NotificationType.ticket,
          risk: ClosureRisk.warning,
        ));
      }

      // Cu Chi Tunnels — requires tickets
      if (_matchesAny(lower, ['cu chi', 'cu chi tunnels'])) {
        notifications.add(ClosureNotification(
          venue: 'Cu Chi Tunnels',
          dayDate: day.date,
          dayNumber: day.day,
          message: 'Entrance ticket required (~180,000 VND). Book a guided tour in advance for the best experience.',
          type: NotificationType.ticket,
          risk: ClosureRisk.ok,
        ));
      }

      // Water Puppet Show — requires tickets
      if (_matchesAny(lower, ['water puppet', 'thang long'])) {
        notifications.add(ClosureNotification(
          venue: 'Thang Long Water Puppet Theatre',
          dayDate: day.date,
          dayNumber: day.day,
          message: 'Show tickets required — book in advance, especially for weekend shows. Popular with tourists.',
          type: NotificationType.ticket,
          risk: ClosureRisk.ok,
        ));
        if (weekday == 1) {
          notifications.add(ClosureNotification(
            venue: 'Thang Long Water Puppet Theatre',
            dayDate: day.date,
            dayNumber: day.day,
            message: '${day.date} is a Monday — some shows may have limited schedule. Check availability.',
            type: NotificationType.timing,
            risk: ClosureRisk.warning,
          ));
        }
      }

      // Mekong Delta tour — requires booking
      if (_matchesAny(lower, ['mekong delta', 'mekong'])) {
        notifications.add(ClosureNotification(
          venue: 'Mekong Delta Tour',
          dayDate: day.date,
          dayNumber: day.day,
          message: 'Day tour requires booking. October is floating season — unique experience but book ahead.',
          type: NotificationType.ticket,
          risk: ClosureRisk.ok,
        ));
      }

      // Cooking class — requires booking
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

      // Phu Quoc snorkeling — requires booking
      if (_matchesAny(lower, ['snorkeling', 'snorkelling', 'snorkel'])) {
        notifications.add(ClosureNotification(
          venue: 'Snorkeling Tour',
          dayDate: day.date,
          dayNumber: day.day,
          message: 'Snorkeling session requires booking. Check weather conditions — October can be rough.',
          type: NotificationType.ticket,
          risk: ClosureRisk.warning,
        ));
      }

      // ── TIMING WARNINGS ──

      // Temple of Literature — crowded weekends
      if (_matchesAny(lower, ['temple of literature'])) {
        if (weekday == 6 || weekday == 7) {
          notifications.add(ClosureNotification(
            venue: 'Temple of Literature',
            dayDate: day.date,
            dayNumber: day.day,
            message: '${day.date} is a weekend — expect heavy crowds. Go early morning (opens 8am).',
            type: NotificationType.timing,
            risk: ClosureRisk.warning,
          ));
        }
      }

      // Ben Thanh Market — very crowded weekends
      if (_matchesAny(lower, ['ben thanh market', 'ben thanh'])) {
        if (weekday == 6 || weekday == 7) {
          notifications.add(ClosureNotification(
            venue: 'Ben Thanh Market',
            dayDate: day.date,
            dayNumber: day.day,
            message: '${day.date} is a weekend — market will be extremely crowded. Bargain hard, watch belongings.',
            type: NotificationType.timing,
            risk: ClosureRisk.warning,
          ));
        }
      }

      // War Remnants Museum — reduced hours some days
      if (_matchesAny(lower, ['war remnants museum', 'war museum'])) {
        if (weekday == 1) {
          notifications.add(ClosureNotification(
            venue: 'War Remnants Museum',
            dayDate: day.date,
            dayNumber: day.day,
            message: '${day.date} is a Monday — museum may have reduced hours. Check before going.',
            type: NotificationType.timing,
            risk: ClosureRisk.warning,
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
