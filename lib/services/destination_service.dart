import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/destination_model.dart';
import '../data/destination_data.dart';

class DestinationService {
  /// Google Places API Key (Provided by User)
  static const String _apiKey = 'AIzaSyBMR8dB2Ch_gv01CBc8LK_thf9_fqwAP9I';

  /// Google Places (New) Text Search Endpoint
  static const String _placesUrl =
      'https://places.googleapis.com/v1/places:searchText';

  /// Google Places Photo Base URL (for constructing image links)
  static const String _photoBaseUrl = 'https://places.googleapis.com/v1';

  /// Fetch destinations from Google Places API based on query
  static Future<List<Destination>> searchDestinations(String query) async {
    if (query.length < 2) return [];

    try {
      final response = await http.post(
        Uri.parse(_placesUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'places.id,places.displayName,places.formattedAddress,places.types,places.photos',
        },
        body: jsonEncode({
          'textQuery': query,
          'languageCode': 'en', // Optional: prioritize English results
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> places = data['places'] ?? [];

        List<Destination> results = [];

        for (var place in places) {
          // 1. Check if this place exists in our Curated Data (Hybrid Logic)
          // We match by name loosely to prefer our high-quality data
          final String name = place['displayName']['text'];

          try {
            final curatedMatch = allDestinations.firstWhere(
              (d) => d.name.toLowerCase() == name.toLowerCase(),
            );
            results.add(curatedMatch);
            continue; // Skip API processing for this item
          } catch (_) {
            // Not in curated list, proceed to map from API
          }

          // 2. Map Google Place to Destination
          results.add(_mapGooglePlaceToDestination(place));
        }

        return results;
      } else {
        print(
          'Google Places API Error: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print("API Error: $e");
      return [];
    }
  }

  /// Get Popular Destinations (Fetches from API)
  static Future<List<Destination>> getPopularDestinations() async {
    // Track unique IDs to prevent duplicates
    final Set<String> existingIds = {};
    final List<Destination> finalResults = [];

    // Helper to process and add places
    void processPlaces(List<dynamic> places) {
      for (var place in places) {
        // Skip if no photos (User wants original images)
        if (place['photos'] == null || (place['photos'] as List).isEmpty) {
          continue;
        }

        final d = _mapGooglePlaceToDestination(place);

        // Skip if duplicate ID or Name (for robustness)
        if (existingIds.contains(d.placeId)) continue;
        if (finalResults.any((e) => e.name == d.name)) continue;

        existingIds.add(d.placeId!);
        finalResults.add(d);
      }
    }

    try {
      // 1. First Batch: Top Tourist Attractions
      final response = await http.post(
        Uri.parse(_placesUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'places.id,places.displayName,places.formattedAddress,places.types,places.photos,places.editorialSummary',
        },
        body: jsonEncode({
          'textQuery': "Tourist attractions in Malaysia",
          'languageCode': 'en',
          'pageSize': 20,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        processPlaces(data['places'] ?? []);
      }

      // 2. Second Batch: Islands & Beaches (to ensure variety and count)
      if (finalResults.length < 25) {
        final response2 = await http.post(
          Uri.parse(_placesUrl),
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': _apiKey,
            'X-Goog-FieldMask':
                'places.id,places.displayName,places.formattedAddress,places.types,places.photos,places.editorialSummary',
          },
          body: jsonEncode({
            'textQuery': "Islands and beaches in Malaysia",
            'languageCode': 'en',
            'pageSize': 15, // Ask for slightly more
          }),
        );

        if (response2.statusCode == 200) {
          final data2 = json.decode(response2.body);
          processPlaces(data2['places'] ?? []);
        }
      }

      // 3. Third Batch (Optional Backup): Hidden Gems / Nature if still low
      if (finalResults.length < 20) {
        final response3 = await http.post(
          Uri.parse(_placesUrl),
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': _apiKey,
            'X-Goog-FieldMask':
                'places.id,places.displayName,places.formattedAddress,places.types,places.photos,places.editorialSummary',
          },
          body: jsonEncode({
            'textQuery': "Nature parks in Malaysia",
            'languageCode': 'en',
            'pageSize': 10,
          }),
        );
        if (response3.statusCode == 200) {
          final data3 = json.decode(response3.body);
          processPlaces(data3['places'] ?? []);
        }
      }

      return finalResults;
    } catch (e) {
      print("API Error: $e");
      return allDestinations; // Fallback only on critical error
    }
  }

  /// Get Similar Destinations based on a seed (e.g. derived from Trip Destination)
  /// Get Similar Destinations based on a seed (e.g. derived from Trip Destination)
  static Future<List<Destination>> getSimilarDestinations(
    String seedName,
  ) async {
    // 1. Try Local Match First
    try {
      final localMatch = allDestinations.firstWhere(
        (d) => d.name.toLowerCase() == seedName.toLowerCase(),
      );

      // Found locally! Return others of same category
      final similar = allDestinations
          .where((d) => d.category == localMatch.category && d.name != seedName)
          .toList();

      if (similar.isNotEmpty) {
        return [localMatch, ...similar].take(5).toList();
      }
    } catch (_) {
      // Not found locally
    }

    // 2. Keyword-Based API Search (More Specific)
    // normalize for checking
    final lowerSeed = seedName.toLowerCase();
    String searchQuery = "Tourist attractions in Malaysia"; // default

    if (lowerSeed.contains('pulau') || lowerSeed.contains('island')) {
      searchQuery = "Islands and beaches in Malaysia";
    } else if (lowerSeed.contains('mountain') ||
        lowerSeed.contains('gunung') ||
        lowerSeed.contains('bukit') ||
        lowerSeed.contains('hill') ||
        lowerSeed.contains('peak')) {
      searchQuery = "Mountains and hiking trails in Malaysia";
    } else if (lowerSeed.contains('mall') ||
        lowerSeed.contains('plaza') ||
        lowerSeed.contains('complex') ||
        lowerSeed.contains('shopping')) {
      searchQuery = "Shopping malls in Malaysia";
    } else if (lowerSeed.contains('waterfall') ||
        lowerSeed.contains('air terjun')) {
      searchQuery = "Waterfalls in Malaysia";
    } else if (lowerSeed.contains('theme park') ||
        lowerSeed.contains('resort') ||
        lowerSeed.contains('amusement') ||
        lowerSeed.contains('subway') || // legoland, sunway, etc
        lowerSeed.contains('lagoon')) {
      searchQuery = "Theme parks and resorts in Malaysia";
    } else if (lowerSeed.contains('museum') || lowerSeed.contains('muzium')) {
      searchQuery = "Museums and galleries in Malaysia";
    } else if (lowerSeed.contains('temple') ||
        lowerSeed.contains('mosque') ||
        lowerSeed.contains('church')) {
      searchQuery = "Religious sites in Malaysia";
    } else {
      // 3. Fallback: API Category Match (General)
      try {
        final seedResults = await searchDestinations(seedName);
        if (seedResults.isNotEmpty) {
          final seed = seedResults.first;
          // Use category to broaden search
          if (seed.category == 'Beach')
            searchQuery = "Islands and beaches Malaysia";
          else if (seed.category == 'Nature')
            searchQuery = "Nature parks Malaysia";
          else if (seed.category == 'Adventure')
            searchQuery = "Adventure activities Malaysia";
          else if (seed.category == 'City')
            searchQuery = "Cities in Malaysia";
          else if (seed.category == 'Culture')
            searchQuery = "Cultural sites Malaysia";
        }
      } catch (e) {
        // failed to get details, stick to default
      }
    }

    try {
      final similarResults = await searchDestinations(searchQuery);

      // Filter out exact name match if any (case insensitive)
      final filtered = similarResults
          .where(
            (d) =>
                !d.name.toLowerCase().contains(
                  lowerSeed,
                ) && // Avoid "Pulau X" matching "Pulau X Resort" if similar
                d.name.toLowerCase() != lowerSeed,
          )
          .toList();

      // Return results (try to include seed if we can fetch it, but searchDestinations returns a list)
      // Actually we don't have the 'seed' object ready-made unless we search for it.
      // But for "Similar Destinations", user likely sees the seed as the current plan.
      // We should return just the suggestions.
      // BUT `DestinationVoteScreen` expects options. If we want the current plan to be an option, we must fetch it.

      // Let's ensure we have the "Current Plan" (Seed) as the first option.
      Destination? seedObj;
      try {
        final seedFetch = await searchDestinations(seedName);
        if (seedFetch.isNotEmpty) seedObj = seedFetch.first;
      } catch (_) {}

      final List<Destination> finalReturn = [];
      if (seedObj != null) finalReturn.add(seedObj);

      finalReturn.addAll(filtered);

      return finalReturn.take(5).toList();
    } catch (e) {
      print("Error finding similar: $e");
      return getPopularDestinations();
    }
  }

  /// Construct the Photo URL from the photo resource name
  static String _buildPhotoUrl(String photoName) {
    // maxSizeBytes helps limit data usage. 400px wide is good for thumbnails/cards.
    return '$_photoBaseUrl/$photoName/media?key=$_apiKey&maxHeightPx=400&maxWidthPx=400';
  }

  /// Map Google Place JSON to Destination Model
  static Destination _mapGooglePlaceToDestination(Map<String, dynamic> place) {
    // 1. Basic Info
    final String name = place['displayName']['text'] ?? 'Unknown Place';
    final String address = place['formattedAddress'] ?? 'Malaysia';
    final String id = place['id'];

    // Extract State from address (Simple heuristic: look for last comma part or known states)
    // E.g. "123 Jalan, Subang Jaya, Selangor, Malaysia" -> "Selangor"
    // For now, we'll just use the full address or a truncated version
    String state = address;
    final parts = address.split(',');
    if (parts.length > 2) {
      state = parts[parts.length - 2].trim(); // heuristics
    }

    // 2. Types & Heuristics
    final List<dynamic> types = place['types'] ?? [];

    // Default values
    String category = 'City';
    bool childFriendly = true;
    bool elderFriendly = true;
    String physicalDemand = 'Low';
    String terrainType = 'Flat';
    List<String> tags = ['New Discovery'];

    // Generated Info Lists
    List<String> attractions = ['Main Area', 'Local Shops', 'Photo Spots'];
    List<String> activities = ['Sightseeing', 'Relaxing', 'Photography'];
    List<String> tips = [
      'Check opening hours',
      'Bring a camera',
      'Stay hydrated',
    ];

    // Heuristic Rules based on Google Place Types
    if (types.contains('beach') || types.contains('island')) {
      category = 'Beach';
      terrainType = 'Sandy';
      elderFriendly = false; // Sandy terrain usually hard for elderly
      tags.add('Beach');
      attractions = ['Sandy Shore', 'Sunset Viewpoint', 'Local Stalls'];
      activities = ['Swimming', 'Sunbathing', 'Picnic', 'Sandcastle Building'];
      tips = [
        'Bring sunscreen',
        'Visiting at sunset is recommended',
        'Watch for tide changes',
      ];
    } else if (types.contains('national_park') ||
        types.contains('park') ||
        types.contains('campground') ||
        types.contains('natural_feature')) {
      category = 'Nature';
      terrainType = 'Mixed';
      attractions = ['Walking Trails', 'Nature Center', 'Scenic Overlooks'];
      activities = ['Walking', 'Bird Watching', 'Picnicking'];
      tips = [
        'Bring insect repellent',
        'Wear comfortable shoes',
        'Keep the park clean',
      ];

      if (types.contains('mountain') || types.contains('hiking_area')) {
        category = 'Adventure';
        physicalDemand = 'High';
        childFriendly = false;
        elderFriendly = false;
        terrainType = 'Steep';
        tags.add('Hiking');
        attractions = ['Summit View', 'Waterfall', 'Forest Trails'];
        activities = ['Hiking', 'Trekking', 'Photography', 'Camping'];
        tips = [
          'Start early to avoid heat',
          'Bring plenty of water',
          'Wear hiking boots',
        ];
      }
    } else if (types.contains('museum') ||
        types.contains('place_of_worship') ||
        types.contains('hindu_temple') ||
        types.contains('mosque') ||
        types.contains('church')) {
      category = 'Culture';
      physicalDemand = 'Low';
      tags.add('Heritage');
      attractions = ['Main Hall', 'Exhibits', 'Architecture'];
      activities = ['Guided Tour', 'Cultural Learning', 'Quiet Reflection'];
      tips = [
        'Dress modestly',
        'Respect the silence',
        'Check if photography is allowed',
      ];
    } else if (types.contains('amusement_park') ||
        types.contains('theme_park')) {
      category = 'Adventure';
      physicalDemand = 'Medium';
      tags.add('Theme Park');
      attractions = ['Roller Coasters', 'Kids Zone', 'Live Shows'];
      activities = ['Rides', 'Games', 'Dining', 'Shopping'];
      tips = [
        'Buy tickets online to skip queues',
        'Arrive early',
        'Wear comfortable clothes',
      ];
    } else if (types.contains('restaurant') || types.contains('food')) {
      category = 'Food';
      tags.add('Foodie');
      attractions = ['Dining Area', 'Open Kitchen', 'Bar'];
      activities = ['Fine Dining', 'Tasting', 'Socializing'];
      tips = [
        'Make a reservation',
        'Try the signature dish',
        'Check dress code',
      ];
    } else if (types.contains('shopping_mall')) {
      category = 'City';
      tags.add('Shopping');
      attractions = ['Cinema', 'Food Court', 'Retail Stores'];
      activities = ['Shopping', 'Dining', 'Movie Watching'];
      tips = [
        'Great for rainy days',
        'Sales usually happen on weekends',
        'Parking can be full',
      ];
    }

    // 3. Image Handling
    String image = _getFallbackImage(category);
    String? photoRef;

    final List<dynamic>? photos = place['photos'];
    if (photos != null && photos.isNotEmpty) {
      final firstPhoto = photos.first;
      final String photoName =
          firstPhoto['name']; // usage: places/PLACE_ID/photos/PHOTO_ID
      photoRef = photoName;
      image = _buildPhotoUrl(photoName);
    }

    // 4. Detailed Description (Editorial Summary)
    String about = 'Discovered via Google Places. $address';
    if (place['editorialSummary'] != null) {
      about = place['editorialSummary']['text'] ?? about;
    }

    return Destination(
      name: name,
      state: state,
      category: category,
      image: image,
      rating: 4.5, // Default for new places
      bestTime: 'Year-round',
      avgCost: 'RM 50 - RM 200', // Estimate
      duration: '2-4 hours', // Estimate
      about: about,
      highlights: tags,
      bestMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      tags: tags,
      childFriendly: childFriendly,
      elderFriendly: elderFriendly,
      physicalDemand: physicalDemand,
      terrainType: terrainType,
      platformVariant: 'mobile',
      isCurated: false,
      placeId: id,
      photoReference: photoRef,
      attractions: attractions,
      activities: activities,
      tips: tips,
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
