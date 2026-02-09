class Destination {
  final String name;
  final String state;
  final String image;
  final double rating;
  final String bestTime;
  final String avgCost;
  final String duration;
  final String about;
  final List<String> highlights;
  final String category;
  final List<int> bestMonths; // 1 = Jan, 12 = Dec
  final List<String> tags; // e.g. "Best during dry season"

  final bool childFriendly;
  final bool elderFriendly;
  final String physicalDemand;
  final String terrainType;
  final bool? isCurated;
  final String? platformVariant;

  // Google Places Integration
  final String? placeId;
  final String? photoReference;

  // Detailed fields (New)
  final List<String> attractions;
  final List<String> activities;
  final List<String> tips;

  Destination({
    required this.name,
    required this.state,
    required this.category,
    required this.image,
    required this.rating,
    required this.bestTime,
    required this.avgCost,
    required this.duration,
    required this.about,
    required this.highlights,
    this.childFriendly = true,
    this.elderFriendly = true,
    this.physicalDemand = 'Low',
    this.terrainType = 'Flat',
    this.bestMonths = const [],
    this.platformVariant = 'mobile',
    this.tags = const [],
    this.isCurated = true,
    this.placeId,
    this.photoReference,
    this.attractions = const [],
    this.activities = const [],
    this.tips = const [],
  });
}
