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

  Destination({
    required this.name,
    required this.state,
    required this.image,
    required this.rating,
    required this.bestTime,
    required this.avgCost,
    required this.duration,
    required this.about,
    required this.highlights,
    required this.category,
    this.bestMonths = const [],
    this.tags = const [],
    this.childFriendly = true,
    this.elderFriendly = true,
    this.physicalDemand = 'Low', // Low, Medium, High
    this.terrainType = 'Flat', // Flat, Mixed, Steep
    this.platformVariant = 'mobile',
    this.isCurated =
        false, // Default to false (generated), true for static data
  });

  final bool childFriendly;
  final bool elderFriendly;
  final String physicalDemand;
  final String terrainType;
  final bool? isCurated;
  final String? platformVariant;
}
