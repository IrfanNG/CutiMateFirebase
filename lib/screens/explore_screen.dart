import 'package:flutter/material.dart';
import 'destination_detail_screen.dart';
import '../models/destination_model.dart';
import '../services/recommendation_service.dart';
import '../data/destination_data.dart';
import '../services/destination_service.dart';

/// ===============================================================
/// EXPLORE SCREEN
/// ---------------------------------------------------------------
/// This screen displays a list of travel destinations (API Powered).
/// UI Redesigned to match "Explore World" mockup (Masonry Layout).
/// ===============================================================
class ExploreScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const ExploreScreen({super.key, this.onBack});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  /// Currently selected category filter
  String selectedCategory = 'All';

  /// Current search text (for filtering the list below)
  String _searchKeyword = '';

  /// Available destination categories
  final List<String> categories = [
    'All Destinations', // Renamed to match mockup slightly better or keep 'All'
    'Beach',
    'Mountains', // Added/Renamed from City/Nature? Mockup says "Mountains"
    'Adventure',
    'Culture',
    'City',
    'Nature',
  ];

  late Future<List<LongWeekend>> _longWeekendsFuture;
  late Future<List<Destination>> _destinationsFuture;

  // Local cache of all destinations (API + hardcoded fallback) for local filtering
  final List<Destination> _allKnownDestinations = [...allDestinations];

  @override
  void initState() {
    super.initState();
    _longWeekendsFuture = RecommendationService.getUpcomingLongWeekends();

    // Fetch initial data from API
    _destinationsFuture = DestinationService.getPopularDestinations();
  }

  /// ===============================================================
  /// MAIN UI BUILD
  /// ===============================================================
  @override
  Widget build(BuildContext context) {
    // Mockup background is slightly off-white/warm
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header & Search are fixed at top
            _header(),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _searchBar(),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categories
                    const SizedBox(height: 12),
                    _categories(),
                    const SizedBox(height: 24),

                    // Smart Recommendation: Long Weekend (Preserved Logic)
                    _buildSmartRecommendation(),

                    const SizedBox(height: 24),

                    // Masonry Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: FutureBuilder<List<Destination>>(
                        future: _destinationsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _loading();
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error loading destinations',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return _empty();
                          }

                          // Filter data
                          final allDestinations = snapshot.data!;
                          final filtered = allDestinations.where((d) {
                            // Map category names if needed
                            String checkCat = selectedCategory;
                            if (checkCat == 'All Destinations') {
                              checkCat = 'All';
                            }

                            final matchCategory =
                                checkCat == 'All' || d.category == checkCat;

                            // Loose category matching for demo (Mountains -> Nature)
                            final matchLoose =
                                (selectedCategory == 'Mountains' &&
                                d.category == 'Nature');

                            final matchSearch =
                                _searchKeyword.isEmpty ||
                                d.name.toLowerCase().contains(
                                  _searchKeyword.toLowerCase(),
                                ) ||
                                d.state.toLowerCase().contains(
                                  _searchKeyword.toLowerCase(),
                                );

                            return (matchCategory || matchLoose) && matchSearch;
                          }).toList();

                          if (filtered.isEmpty) return _empty();

                          return _masonryGrid(filtered);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button (Circle)
          GestureDetector(
            onTap: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.pop(context);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
                color: Colors.white,
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: Colors.black87,
              ),
            ),
          ),

          // Title
          const Text(
            "Explore World",
            style: TextStyle(
              fontFamily: 'Serif', // Mockup style
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),

          // Heart Button (Circle)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
              color: Colors.white,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              size: 20,
              color: Color(0xFFFF7043), // Orange/Coral from mockup
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    // Cleaner search bar from mockup
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Autocomplete<Destination>(
        optionsBuilder: (TextEditingValue textEditingValue) async {
          final query = textEditingValue.text;
          if (query.isEmpty) return const Iterable<Destination>.empty();

          // 1. Local Search (Instant)
          final localMatches = _allKnownDestinations.where((option) {
            return option.name.toLowerCase().contains(query.toLowerCase()) ||
                option.state.toLowerCase().contains(query.toLowerCase());
          }).toList();

          // 2. API Search (Network) - Only if length > 2
          if (query.length > 2) {
            try {
              final apiMatches = await DestinationService.searchDestinations(
                query,
              );

              // Merge without duplicates (prefer local matches)
              for (var apiDest in apiMatches) {
                if (!localMatches.any((l) => l.name == apiDest.name)) {
                  localMatches.add(apiDest);
                }
              }
            } catch (e) {
              debugPrint("Search Error: $e");
            }
          }

          return localMatches;
        },
        displayStringForOption: (Destination option) => option.name,
        onSelected: (Destination selection) {
          // Instead of navigating, we update the grid to show this selection
          // Or we could navigate. But user said "show the destination on the list".
          // Typically "search bar... show on the list" means filtering.
          // Let's set the main list to just this item or similar items.
          setState(() {
            _destinationsFuture = Future.value([selection]);
          });
        },
        fieldViewBuilder: (context, controller, focusNode, onComplete) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            onSubmitted: (value) {
              // Trigger full search on submit
              if (value.isNotEmpty) {
                setState(() {
                  _destinationsFuture = DestinationService.searchDestinations(
                    value,
                  );
                });
              }
            },
            onChanged: (value) {
              // Optional: Live search?
              // We might not want to spam API.
              // Let's stick to Autocomplete suggestions updating, and "Submit" or "Select" updating the grid.
              // But for local filtering, we can still use _searchKeyword.
              setState(() {
                _searchKeyword = value;
              });
            },
            decoration: InputDecoration(
              hintText: "Search destinations, activities...",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
              suffixIcon: IconButton(
                icon: const Icon(Icons.tune),
                color: const Color(0xFFFFC107),
                onPressed: () {
                  // Filter logic if needed
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: MediaQuery.of(context).size.width - 40, // Adjust width
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Destination option = options.elementAt(index);
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: option.image.startsWith('http')
                            ? Image.network(
                                option.image,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 40,
                                  height: 40,
                                  color: Colors.grey.shade200,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 20,
                                  ),
                                ),
                              )
                            : Image.asset(
                                option.image,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                      ),
                      title: Text(
                        option.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        option.state,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= CATEGORIES =================
  Widget _categories() {
    return SizedBox(
      height: 48, // Taller for pills
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category == selectedCategory;

          return GestureDetector(
            onTap: () => setState(() => selectedCategory = category),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFFFC107)
                    : const Color(0xFFFFF9E5), // Yellow vs Light Beige
                borderRadius: BorderRadius.circular(30),
                // No border for cleaner look, or light border
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: selected ? Colors.black87 : const Color(0xFF5D4037),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Serif',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= MASONRY GRID =================
  Widget _masonryGrid(List<Destination> list) {
    if (list.isEmpty) return _empty();

    final List<Destination> leftColumn = [];
    final List<Destination> rightColumn = [];

    for (int i = 0; i < list.length; i++) {
      if (i % 2 == 0) {
        leftColumn.add(list[i]);
      } else {
        rightColumn.add(list[i]);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: leftColumn
                .map((d) => _destinationCard(d, isLeft: true))
                .toList(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: rightColumn
                .map((d) => _destinationCard(d, isLeft: false))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _destinationCard(Destination d, {bool isLeft = true}) {
    // Random-ish height factor based on name length to create masonry effect
    // Or just let aspect ratio handle it.
    // For mockup look: some are tall, some short.
    // We'll mimic this by alternating or using data properties.

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DestinationDetailScreen(destination: d),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                    bottom: Radius.circular(24),
                  ), // Fully rounded card often has image fill header, but mockup shows distinct image area or full card? Mockup shows image takes top part, but rounded edges.
                  // Actually mockup shows full blead image at top.
                  child: d.image.startsWith('http')
                      ? Image.network(
                          d.image,
                          // Variable height: Left column items might be taller?
                          // Let's just use fitWidth.
                          fit: BoxFit.cover,
                          height: isLeft ? 260 : 200, // Staggered heights
                          width: double.infinity,
                          errorBuilder: (_, _, _) => Container(
                            height: 200,
                            color: Colors.grey.shade200,
                          ),
                        )
                      : Image.asset(
                          d.image,
                          fit: BoxFit.cover,
                          height: isLeft ? 260 : 200,
                          width: double.infinity,
                        ),
                ),
                // Featured Tag (Mockup style)
                if (d.rating > 4.7)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "FEATURED",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),

                // Heart Icon (Bottom Right of Image) - Mockup has it for some
                if (!isLeft) // Just vary it
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.redAccent,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),

            // Text Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.name,
                    style: const TextStyle(
                      fontFamily: 'Serif',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Tags/Subtitle
                  if (d.tags.isNotEmpty)
                    Text(
                      d.tags.first, // "Whitewashed houses..."
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    // Fallback description
                    Text(
                      "${d.state}, Malaysia",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Rating & Location
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: Color(0xFFFFC107),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        d.rating.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          d.state,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Chips for "Culture", "Autumn" etc.
                  if (d.tags.length > 1) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: d.tags
                          .skip(1)
                          .take(2)
                          .map(
                            (t) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                t,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= SMART RECOMMENDATION (Preserved) =================
  Widget _buildSmartRecommendation() {
    return FutureBuilder<List<LongWeekend>>(
      future: _longWeekendsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final weekend = snapshot.data!.first;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1), // Light yellow/gold
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFECB3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.wb_sunny_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Upcoming: ${weekend.holidayName}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      weekend.dateRangeText,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= HELPERS =================
  Widget _loading() {
    return const Padding(
      padding: EdgeInsets.all(40.0),
      child: Center(child: CircularProgressIndicator(color: Color(0xFFFFC107))),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.travel_explore, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No destinations found",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
