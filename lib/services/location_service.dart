import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

/// A resolved location from Nominatim geocoding
class ResolvedLocation {
  final String name;
  final String displayName;
  final double lat;
  final double lng;
  final String? category;

  ResolvedLocation({
    required this.name,
    required this.displayName,
    required this.lat,
    required this.lng,
    this.category,
  });

  factory ResolvedLocation.fromNominatim(Map<String, dynamic> json) {
    final displayName = json['display_name'] as String? ?? '';
    final parts = displayName.split(',').map((s) => s.trim()).toList();
    final shortName = parts.length >= 2 ? '${parts[0]}, ${parts[1]}' : parts.firstOrNull ?? displayName;

    return ResolvedLocation(
      name: json['name'] as String? ?? shortName,
      displayName: displayName,
      lat: double.tryParse(json['lat']?.toString() ?? '0') ?? 0,
      lng: double.tryParse(json['lon']?.toString() ?? '0') ?? 0,
      category: json['type'] as String?,
    );
  }
}

/// Search for locations using Nominatim (OpenStreetMap) — free, no API key needed
Future<List<ResolvedLocation>> searchLocations(String query, {int limit = 5}) async {
  if (query.length < 2) return [];

  try {
    final encoded = Uri.encodeComponent(query);
    final url = 'https://nominatim.openstreetmap.org/search?format=json&q=$encoded&limit=$limit&addressdetails=1';

    final xhr = html.HttpRequest();
    final completer = Completer<List<ResolvedLocation>>();

    xhr.open('GET', url);
    xhr.setRequestHeader('Accept', 'application/json');
    xhr.onLoad.listen((_) {
      if (xhr.status == 200) {
        try {
          final List<dynamic> results = jsonDecode(xhr.responseText!);
          final locations = results
              .map((r) => ResolvedLocation.fromNominatim(r as Map<String, dynamic>))
              .where((l) => l.lat != 0 && l.lng != 0)
              .toList();
          completer.complete(locations);
        } catch (e) {
          completer.complete([]);
        }
      } else {
        completer.complete([]);
      }
    });
    xhr.onError.listen((_) => completer.complete([]));
    xhr.send();

    return completer.future.timeout(const Duration(seconds: 8), onTimeout: () => []);
  } catch (e) {
    return [];
  }
}
