import 'package:flutter/material.dart';

enum TransportMode { flight, bus, boat, train, walk, taxi }

/// A resolved location attached to an activity
class ActivityLocation {
  final String name;
  final double lat;
  final double lng;

  const ActivityLocation({required this.name, required this.lat, required this.lng});

  ActivityLocation copyWith({String? name, double? lat, double? lng}) {
    return ActivityLocation(
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}

class TripDay {
  final int day;
  final String date;
  final String location;
  final String country;
  final String title;
  final String description;
  final List<String> activities;
  final List<ActivityLocation?> activityLocations;
  final TransportMode? arrivalTransport;
  final TransportMode? departureTransport;
  final String? transportDuration;
  final String? transportCost;
  final String? accommodationCost;
  final String? foodCost;
  final IconData icon;
  final Color color;
  final bool isTravelDay;
  final double? lat;
  final double? lng;

  TripDay({
    required this.day,
    required this.date,
    required this.location,
    required this.country,
    required this.title,
    required this.description,
    required this.activities,
    List<ActivityLocation?>? activityLocations,
    this.arrivalTransport,
    this.departureTransport,
    this.transportDuration,
    this.transportCost,
    this.accommodationCost,
    this.foodCost,
    required this.icon,
    required this.color,
    this.isTravelDay = false,
    this.lat,
    this.lng,
  }) : activityLocations = activityLocations ?? List.filled(activities.length, null);

  double get totalCost {
    double total = 0;
    if (transportCost != null) total += double.tryParse(transportCost!.replaceAll(RegExp(r'[^\\d.]'), '')) ?? 0;
    if (accommodationCost != null) total += double.tryParse(accommodationCost!.replaceAll(RegExp(r'[^\\d.]'), '')) ?? 0;
    if (foodCost != null) total += double.tryParse(foodCost!.replaceAll(RegExp(r'[^\\d.]'), '')) ?? 0;
    return total;
  }

  /// Get all pinned locations: day location + all resolved activity locations
  List<ActivityLocation> get allPins {
    final pins = <ActivityLocation>[];
    if (lat != null && lng != null) {
      pins.add(ActivityLocation(name: location, lat: lat!, lng: lng!));
    }
    for (int i = 0; i < activityLocations.length; i++) {
      final al = activityLocations[i];
      if (al != null && al.lat != 0 && al.lng != 0) {
        // Avoid duplicates of the day location
        if (lat != null && lng != null && (al.lat - lat!).abs() < 0.001 && (al.lng - lng!).abs() < 0.001) {
          continue;
        }
        pins.add(al);
      }
    }
    return pins;
  }

  TripDay copyWith({
    int? day, String? date, String? location, String? country,
    String? title, String? description, List<String>? activities,
    List<ActivityLocation?>? activityLocations,
    TransportMode? arrivalTransport, TransportMode? departureTransport,
    String? transportDuration, String? transportCost,
    String? accommodationCost, String? foodCost,
    IconData? icon, Color? color, bool? isTravelDay,
    double? lat, double? lng,
  }) {
    // If activities changed but activityLocations didn't, pad/truncate to match
    final newActivities = activities ?? this.activities;
    final currentLocs = activityLocations ?? this.activityLocations;
    final newLocs = List<ActivityLocation?>.filled(newActivities.length, null);
    for (int i = 0; i < newActivities.length && i < currentLocs.length; i++) {
      newLocs[i] = currentLocs[i];
    }

    return TripDay(
      day: day ?? this.day,
      date: date ?? this.date,
      location: location ?? this.location,
      country: country ?? this.country,
      title: title ?? this.title,
      description: description ?? this.description,
      activities: newActivities,
      activityLocations: newLocs,
      arrivalTransport: arrivalTransport ?? this.arrivalTransport,
      departureTransport: departureTransport ?? this.departureTransport,
      transportDuration: transportDuration ?? this.transportDuration,
      transportCost: transportCost ?? this.transportCost,
      accommodationCost: accommodationCost ?? this.accommodationCost,
      foodCost: foodCost ?? this.foodCost,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isTravelDay: isTravelDay ?? this.isTravelDay,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  /// Create a new TripDay with date shifted
  TripDay withShiftedDate(DateTime baseDate) {
    final newDate = baseDate.add(Duration(days: day - 1));
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final shiftedDate = '${months[newDate.month - 1]} ${newDate.day}';
    return copyWith(date: shiftedDate);
  }
}

class TripData {
  final String title;
  final String subtitle;
  final String startDate;
  final String endDate;
  final int totalDays;
  final String totalBudget;
  final String currency;
  final List<TripDay> days;
  final DateTime baseStartDate;

  TripData({
    required this.title,
    required this.subtitle,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.totalBudget,
    required this.currency,
    required this.days,
    required this.baseStartDate,
  });

  double get totalEstimatedCost {
    return days.fold(0, (sum, day) => sum + day.totalCost);
  }

  TripData copyWith({
    String? title, String? subtitle, String? startDate, String? endDate,
    int? totalDays, String? totalBudget, String? currency, List<TripDay>? days,
    DateTime? baseStartDate,
  }) {
    return TripData(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalDays: totalDays ?? this.totalDays,
      totalBudget: totalBudget ?? this.totalBudget,
      currency: currency ?? this.currency,
      days: days ?? this.days,
      baseStartDate: baseStartDate ?? this.baseStartDate,
    );
  }

  TripData withNewStartDate(DateTime newStart) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final newStartStr = '${months[newStart.month - 1]} ${newStart.day}, ${newStart.year}';
    final newEnd = newStart.add(Duration(days: totalDays - 1));
    final newEndStr = '${months[newEnd.month - 1]} ${newEnd.day}, ${newEnd.year}';
    final shiftedDays = days.map((d) => d.withShiftedDate(newStart)).toList();
    return copyWith(
      startDate: newStartStr,
      endDate: newEndStr,
      days: shiftedDays,
      baseStartDate: newStart,
    );
  }
}

IconData getTransportIcon(TransportMode mode) {
  switch (mode) {
    case TransportMode.flight: return Icons.flight;
    case TransportMode.bus: return Icons.directions_bus;
    case TransportMode.boat: return Icons.directions_boat;
    case TransportMode.train: return Icons.train;
    case TransportMode.walk: return Icons.directions_walk;
    case TransportMode.taxi: return Icons.local_taxi;
  }
}

Color getTransportColor(TransportMode mode) {
  switch (mode) {
    case TransportMode.flight: return const Color(0xFF6C63FF);
    case TransportMode.bus: return const Color(0xFF00BFA6);
    case TransportMode.boat: return const Color(0xFF00B4D8);
    case TransportMode.train: return const Color(0xFFFF6B6B);
    case TransportMode.walk: return const Color(0xFFFFAB40);
    case TransportMode.taxi: return const Color(0xFF4CAF50);
  }
}

String getTransportLabel(TransportMode mode) {
  switch (mode) {
    case TransportMode.flight: return 'Flight';
    case TransportMode.bus: return 'Bus';
    case TransportMode.boat: return 'Boat';
    case TransportMode.train: return 'Train';
    case TransportMode.walk: return 'Walk';
    case TransportMode.taxi: return 'Taxi';
  }
}
