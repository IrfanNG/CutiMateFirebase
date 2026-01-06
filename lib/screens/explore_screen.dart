import 'package:flutter/material.dart';
import 'destination_detail_screen.dart';
import '../models/destination_model.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String selectedCategory = 'All';
  final TextEditingController searchController = TextEditingController();

  // Branding Colors
  final Color primaryBlue = const Color(0xFF1BA0E2);
  final Color darkNavy = const Color(0xFF1B4E6B);

  final List<String> categories = [
    'All',
    'Beach',
    'City',
    'Nature',
    'Food',
    'Adventure',
  ];

  // (Destinations list remains unchanged as per your logic)
  final List<Destination> destinations = [
    Destination(
      name: 'Langkawi Island',
      state: 'Kedah, Malaysia',
      category: 'Beach',
      image: 'assets/langkawi.jpg',
      rating: 4.8,
      bestTime: 'November to April',
      avgCost: 'RM 500 - RM 1,500',
      duration: '3-5 days',
      about: 'Langkawi is a duty-free island and archipelago of 99 islands located off the coast of Kedah.',
      highlights: ['Pristine beaches', 'Duty-free shopping', 'Cable car views', 'Island hopping'],
    ),
    Destination(
      name: 'Penang',
      state: 'Penang, Malaysia',
      category: 'Food',
      image: 'assets/penang.jpg',
      rating: 4.7,
      bestTime: 'December to March',
      avgCost: 'RM 400 - RM 1,200',
      duration: '2-4 days',
      about: 'Penang is famous for its heritage streets, culture, and some of the best street food in Asia.',
      highlights: ['Street food paradise', 'George Town heritage', 'Cafés & murals'],
    ),
    Destination(
      name: 'Kuala Lumpur',
      state: 'Federal Territory, Malaysia',
      category: 'City',
      image: 'assets/kuala_lumpur.jpg',
      rating: 4.6,
      bestTime: 'May to July',
      avgCost: 'RM 600 - RM 1,800',
      duration: '2-3 days',
      about: 'Malaysia’s capital city known for shopping malls, skyscrapers, and diverse culture.',
      highlights: ['Petronas Twin Towers', 'Shopping & nightlife', 'Cultural diversity'],
    ),
    Destination(
      name: 'Cameron Highlands',
      state: 'Pahang, Malaysia',
      category: 'Nature',
      image: 'assets/cameron.jpg',
      rating: 4.5,
      bestTime: 'March to September',
      avgCost: 'RM 300 - RM 900',
      duration: '2-3 days',
      about: 'A cool hill station famous for tea plantations, strawberry farms, and scenic views.',
      highlights: ['Tea plantations', 'Cool weather', 'Nature walks'],
    ),
    Destination(
      name: 'Mount Kinabalu',
      state: 'Sabah, Malaysia',
      category: 'Adventure',
      image: 'assets/kinabalu.jpg',
      rating: 4.9,
      bestTime: 'February to September',
      avgCost: 'RM 1,000 - RM 3,000',
      duration: '3-4 days',
      about: 'The tallest mountain in Southeast Asia and a bucket-list destination for hikers.',
      highlights: ['Mountain climbing', 'Sunrise view', 'Challenging adventure'],
    ),
    Destination(
      name: 'Melaka',
      state: 'Melaka, Malaysia',
      category: 'Food',
      image: 'assets/melaka.jpg',
      rating: 4.6,
      bestTime: 'April to October',
      avgCost: 'RM 300 - RM 800',
      duration: '2-3 days',
      about: 'A historic city rich with colonial heritage, museums, and unique local cuisine.',
      highlights: ['Historical sites', 'Jonker Street', 'Local delicacies'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final keyword = searchController.text.toLowerCase();
    final filteredDestinations = destinations.where((d) {
      final matchCategory = selectedCategory == 'All' || d.category == selectedCategory;
      final matchSearch = d.name.toLowerCase().contains(keyword) || d.state.toLowerCase().contains(keyword);
      return matchCategory && matchSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 8),
            _categories(),
            const SizedBox(height: 16),
            Expanded(
              child: filteredDestinations.isEmpty
                  ? _empty()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredDestinations.length,
                      itemBuilder: (context, index) {
                        return _destinationCard(filteredDestinations[index]);
                      },
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore Malaysia',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: darkNavy),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4)),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search destinations, states...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                icon: Icon(Icons.search_rounded, color: primaryBlue),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= CATEGORIES =================
  Widget _categories() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category == selectedCategory;

          return GestureDetector(
            onTap: () => setState(() => selectedCategory = category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: selected
                    ? [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    : null,
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: selected ? Colors.white : darkNavy.withOpacity(0.6),
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= DESTINATION CARD =================
  Widget _destinationCard(Destination d) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DestinationDetailScreen(destination: d)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: d.name,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Image.asset(
                      d.image,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 18, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          d.rating.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        d.name,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkNavy),
                      ),
                      Text(
                        d.category,
                        style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        d.state,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= EMPTY =================
  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No destinations found',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }
}