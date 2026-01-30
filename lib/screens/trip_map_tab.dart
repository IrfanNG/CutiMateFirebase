import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/trip_model.dart';

/// ===============================================================
/// TRIP MAP TAB
/// ---------------------------------------------------------------
/// Visualizes the trip itinerary on a map.
/// - Markers for each location
/// - Polylines connecting them
/// - Heuristic travel estimates in bottom sheet
/// - Real-time User Location button
/// ===============================================================
class TripMapTab extends StatefulWidget {
  final List<ItineraryItem> itinerary;

  const TripMapTab({super.key, required this.itinerary});

  @override
  State<TripMapTab> createState() => _TripMapTabState();
}

class _TripMapTabState extends State<TripMapTab> {
  final MapController _mapController = MapController();

  // Default to somewhere central in Malaysia if no points
  final LatLng _defaultCenter = const LatLng(3.140853, 101.693207); // KL
  List<LatLng> _points = [];
  List<Marker> _markers = [];
  LatLng? _userLocation;
  bool _isLoadingLocation = false;

  // Selected leg for bottom sheet
  int? _selectedLegIndex;

  @override
  void initState() {
    super.initState();
    _processItinerary();
    // Removed auto-location check to prevent navigation lag/freeze
  }

  @override
  void didUpdateWidget(covariant TripMapTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itinerary != widget.itinerary) {
      _processItinerary();
    }
  }

  void _processItinerary() {
    _points = [];
    _markers = [];

    for (int i = 0; i < widget.itinerary.length; i++) {
      final item = widget.itinerary[i];
      if (item.lat != null && item.lng != null) {
        final pos = LatLng(item.lat!, item.lng!);
        _points.add(pos);

        _markers.add(
          Marker(
            point: pos,
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                // If it's not the last point, show route to next
                if (i < _points.length - 1) {
                  setState(() => _selectedLegIndex = i);
                } else {
                  setState(
                    () => _selectedLegIndex = null,
                  ); // Selected end point
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    "${i + 1}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    // Fit bounds if we have points
    if (_points.isNotEmpty) {
      // Small delay to let map layout
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _mapController.move(_points.first, 12);
        }
      });
    }
  }

  Future<void> _goToMyLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Try requesting service
        serviceEnabled = await Geolocator.openLocationSettings();
        if (!serviceEnabled) {
          throw 'Location services are disabled.';
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied)
          throw 'Location permissions are denied';
      }

      if (permission == LocationPermission.deniedForever)
        throw 'Location permissions are permanently denied.';

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      final userPos = LatLng(position.latitude, position.longitude);

      _mapController.move(userPos, 15);
      setState(() => _userLocation = userPos);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Could not get location: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Combine standard markers with user marker if available
    List<Marker> allMarkers = List.from(_markers);
    if (_userLocation != null) {
      allMarkers.add(
        Marker(
          point: _userLocation!,
          width: 20,
          height: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        RepaintBoundary(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _points.isNotEmpty
                  ? _points.first
                  : (_userLocation ?? _defaultCenter),
              initialZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.cutimateapp',
              ),
              PolylineLayer(
                polylines: [
                  if (_points.isNotEmpty)
                    Polyline(
                      points: _points,
                      strokeWidth: 4.0,
                      color: Theme.of(context).primaryColor,
                    ),
                ],
              ),
              MarkerLayer(markers: allMarkers),
            ],
          ),
        ),

        // Bottom Sheet for Route Info
        if (_selectedLegIndex != null &&
            _selectedLegIndex! < _points.length - 1)
          _buildLegInfo(_selectedLegIndex!),

        // Top floating instructions (Only if we have points)
        if (_points.isNotEmpty)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    "Tap numbered markers to see route info",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

        // My Location Button
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: Colors.white,
            foregroundColor: Theme.of(context).primaryColor,
            onPressed: _goToMyLocation,
            child: _isLoadingLocation
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }

  Widget _buildLegInfo(int index) {
    final start = _points[index];
    final end = _points[index + 1];
    final startItem = widget.itinerary[index];
    final endItem = widget.itinerary[index + 1];

    // Heuristic Calc
    final Distance distance = const Distance();
    final double km = distance.as(LengthUnit.Meter, start, end) / 1000.0;

    String timeEstimate = "";

    if (km < 1.0) {
      timeEstimate = "${(km * 15).round()} mins"; // Walking pace roughly
    } else if (km < 5.0) {
      timeEstimate = "10-15 mins";
    } else if (km < 20.0) {
      timeEstimate = "20-45 mins";
    } else {
      timeEstimate = "45+ mins";
    }

    return Positioned(
      bottom: 80, // moved up to avoid FAB
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.directions_car,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Leg ${index + 1}: ${startItem.title} ➔ ${endItem.title}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "${km.toStringAsFixed(1)} km  •  $timeEstimate",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
