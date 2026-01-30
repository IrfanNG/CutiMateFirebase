import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/destination_model.dart';
import '../data/destination_data.dart';

class DestinationService {
  /// Nominatim OpenStreetMap API endpoint
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  /// Fetch destinations from API based on query
  static Future<List<Destination>> searchDestinations(
    String query, {
    int limit = 20,
  }) async {
    if (query.length < 2) return [];

    try {
      final url = Uri.parse(
        '$_baseUrl?q=$query&countrycodes=my&format=json&addressdetails=1&extratags=1&limit=$limit',
      );

      // User-Agent is required by Nominatim policy
      final response = await http.get(
        url,
        headers: {'User-Agent': 'CutiMateApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Process results in parallel to speed up Wiki fetches
        final futures = data.map((jsonItem) async {
          Destination apiDest = _mapJsonToDestination(jsonItem);

          // Hybrid Logic: Check for Curated Match FIRST
          try {
            final curatedMatch = allDestinations.firstWhere(
              (d) =>
                  d.name.toLowerCase() == apiDest.name.toLowerCase() ||
                  d.name.toLowerCase().contains(apiDest.name.toLowerCase()) ||
                  apiDest.name.toLowerCase().contains(d.name.toLowerCase()),
            );
            return curatedMatch;
          } catch (_) {
            // Not curated. Fetch Wiki image!
            final wikiImage = await _fetchWikiImage(apiDest.name);
            // Remap with the new image
            return _mapJsonToDestination(jsonItem, imageUrl: wikiImage);
          }
        });

        final results = await Future.wait(futures);

        // Dedup
        final uniqueMap = {for (var d in results) d.name: d};
        return uniqueMap.values.toList();
      } else {
        return [];
      }
    } catch (e) {
      print("API Error: $e");
      return [];
    }
  }

  /// Fetch initial list for Explore Screen
  /// Queries multiple diverse categories to build a rich "feed" of destinations
  /// Fetch initial list for Explore Screen
  /// Returns trusted curated destinations
  static Future<List<Destination>> getPopularDestinations() async {
    // Return curated list (simulating async)
    await Future.delayed(const Duration(milliseconds: 300));
    return allDestinations;
  }

  static Future<String?> _fetchWikiImage(String query) async {
    try {
      final url = Uri.parse(
        'https://en.wikipedia.org/w/api.php?action=query&prop=pageimages&format=json&piprop=thumbnail&pithumbsize=600&titles=$query',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']['pages'];
        if (pages != null) {
          final firstPageId = pages.keys.first;
          if (firstPageId != "-1") {
            final thumbnail = pages[firstPageId]['thumbnail'];
            if (thumbnail != null) {
              return thumbnail['source'];
            }
          }
        }
      }
    } catch (e) {
      print("Wiki Image Error: $e");
    }
    return null;
  }

  /// Convert Nominatim JSON to our App's Destination Model
  /// + "AI" Enrichment (Heuristic Logic)
  static Destination _mapJsonToDestination(
    Map<String, dynamic> json, {
    String? imageUrl,
  }) {
    // 1. Extract Basic Info
    String name = json['display_name'].split(',')[0]; // Simple name
    String fullState = json['address']['state'] ?? 'Malaysia';

    // 2. Identify Type for Heuristics
    String type =
        json['type'] ?? 'unknown'; // e.g., 'city', 'island', 'attraction'
    String category = json['class'] ?? 'place'; // e.g., 'natural', 'amenity'

    // 3. Smart Profile Enrichment (The "AI" Part)
    // Default values
    bool childFriendly = true;
    bool elderFriendly = true;
    String physicalDemand = 'Low';
    String terrainType = 'Flat';
    String appCategory = 'City';

    // Heuristic Rules
    if (category == 'natural') {
      appCategory = 'Nature';
      if (type == 'peak' || type == 'volcano' || type == 'mountain_range') {
        appCategory = 'Adventure';
        physicalDemand = 'High';
        terrainType = 'Steep';
        childFriendly = false;
        elderFriendly = false;
      } else if (type == 'beach' || type == 'coastline') {
        appCategory = 'Beach';
        terrainType = 'Sandy';
        // Beaches are generally mixed for accessibility
        elderFriendly = false;
      } else if (type == 'water' || type == 'bay') {
        appCategory = 'Nature';
      }
    } else if (category == 'historic') {
      appCategory = 'Culture';
      physicalDemand = 'Low';
      terrainType = 'Flat'; // Museums/ruins usually flat-ish
    } else if (type == 'island') {
      appCategory = 'Beach';
      childFriendly = true;
      elderFriendly = false; // Boat access usually required
      terrainType = 'Mixed';
    } else if (type == 'theme_park' || type == 'attraction') {
      appCategory = 'Adventure';
      childFriendly = true;
      elderFriendly = true;
      physicalDemand = 'Medium'; // Lots of walking
    }

    // fallback image (since API doesn't give nice photos)
    // IF imageUrl is provided (from Wikipedia), use that. Else fallback.
    String finalImage = imageUrl ?? _getFallbackImage(appCategory);

    return Destination(
      name: name,
      state: fullState,
      category: appCategory,
      image: finalImage, // Placeholder or mapping
      rating: 4.5, // Default rating for new discoveries
      bestTime: 'Year-round',
      avgCost: 'RM 300 - RM 1,000',
      duration: '2-3 days',
      about:
          'Discovered via OpenStreetMap. A great place for $appCategory lovers.',
      highlights: [appCategory, type, 'Exploring'],
      bestMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      tags: [appCategory, type.toUpperCase(), 'New Discovery'],

      // Enriched Data
      childFriendly: childFriendly,
      elderFriendly: elderFriendly,
      physicalDemand: physicalDemand,
      terrainType: terrainType,
      platformVariant: 'mobile',
      isCurated: false,
    );
  }

  static String _getFallbackImage(String category) {
    switch (category) {
      case 'Beach':
        return 'assets/langkawi.jpg';
      case 'Nature':
        return 'assets/cameron.jpg';
      case 'City':
        return 'assets/kuala_lumpur.jpg';
      case 'Culture':
        return 'assets/melaka.jpg';
      case 'Adventure':
        return 'assets/kinabalu.jpg';
      default:
        return 'assets/penang.jpg';
    }
  }
}
