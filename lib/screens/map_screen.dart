import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stay_safe_app/services/location_service.dart';
import 'package:share_plus/share_plus.dart';

class SafeHavensMapScreen extends StatefulWidget {
  const SafeHavensMapScreen({super.key});

  @override
  State<SafeHavensMapScreen> createState() => _SafeHavensMapScreenState();
}

class _SafeHavensMapScreenState extends State<SafeHavensMapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  
  LatLng _currentLatLng = const LatLng(0, 0);
  String _selectedCategory = 'All';
  List<Map<String, dynamic>> _allHavens = [];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  void _generateLocalHavens(Position pos) {
    _allHavens = [
      {
        'id': '1',
        'name': 'Regional Police Precinct',
        'type': 'Police',
        'point': LatLng(pos.latitude + 0.0035, pos.longitude + 0.0021),
        'phone': '911',
        'address': 'Emergency Response Hub',
      },
      {
        'id': '2',
        'name': 'Local Medical Center',
        'type': 'Hospital',
        'point': LatLng(pos.latitude - 0.0042, pos.longitude + 0.0015),
        'phone': '555-0123',
        'address': 'Community Health Plaza',
      },
      {
        'id': '3',
        'name': 'District 24/7 Pharmacy',
        'type': 'Pharmacy',
        'point': LatLng(pos.latitude + 0.0012, pos.longitude - 0.0038),
        'phone': '555-9876',
        'address': 'Corner Health Mart',
      },
    ];

    for (var haven in _allHavens) {
      double distanceInMeters = Geolocator.distanceBetween(
        pos.latitude, pos.longitude,
        haven['point'].latitude, haven['point'].longitude,
      );
      haven['distance'] = '${(distanceInMeters * 0.000621371).toStringAsFixed(1)} mi';
    }
  }

  void _getUserLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _currentLatLng = LatLng(position.latitude, position.longitude);
          _generateLocalHavens(position);
        });
        _mapController.move(_currentLatLng, 14.0);
      }
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  void _shareLocation() {
    final String locationUrl = "https://www.google.com/maps/search/?api=1&query=${_currentLatLng.latitude},${_currentLatLng.longitude}";
    Share.share("This is my current location: $locationUrl");
  }

  @override
  Widget build(BuildContext context) {
    final filteredHavens = _allHavens.where((h) => _selectedCategory == 'All' || h['type'] == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLatLng,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.stay_safe_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLatLng,
                    width: 60, height: 60,
                    child: const Icon(Icons.person_pin_circle, color: Color(0xFF02579C), size: 40),
                  ),
                  ...filteredHavens.map((haven) => Marker(
                    point: haven['point'],
                    width: 40, height: 40,
                    child: GestureDetector(
                      onTap: () => _showHavenDetails(haven),
                      child: Icon(
                        haven['type'] == 'Police' ? Icons.local_police : 
                        haven['type'] == 'Hospital' ? Icons.medical_services : Icons.medication,
                        color: haven['type'] == 'Police' ? const Color(0xFF02579C) : 
                               haven['type'] == 'Hospital' ? Colors.red : Colors.green,
                        size: 30,
                      ),
                    ),
                  )),
                ],
              ),
            ],
          ),

          // floating share button
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              heroTag: "share",
              backgroundColor: const Color(0xFF02579C),
              onPressed: _shareLocation,
              child: const Icon(Icons.share, color: Colors.white),
            ),
          ),

          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.white.withValues(alpha: 0.9), Colors.transparent],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildIconButton(Icons.arrow_back, () => Navigator.pop(context)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white, borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                          ),
                          child: const TextField(
                            decoration: InputDecoration(
                              hintText: "Search for safe havens...",
                              prefixIcon: Icon(Icons.search, color: Colors.grey),
                              border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterButton('All', Icons.apps),
                        _buildFilterButton('Police', Icons.local_police, color: const Color(0xFF02579C)),
                        _buildFilterButton('Hospital', Icons.medical_services, color: Colors.red),
                        _buildFilterButton('Pharmacy', Icons.medication, color: Colors.green),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          _buildBottomPanel(filteredHavens),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF02579C),
        unselectedItemColor: Colors.grey,
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/home');
          if (index == 2) Navigator.pushReplacementNamed(context, '/contacts');
          if (index == 3) Navigator.pushReplacementNamed(context, '/profile');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Safety Map'),
          BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Circle'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
        child: Icon(icon, color: const Color(0xFF02579C)),
      ),
    );
  }

  Widget _buildFilterButton(String label, IconData icon, {Color? color}) {
    bool isSelected = _selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF02579C) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 5)] : null,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : (color ?? Colors.grey)),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel(List<Map<String, dynamic>> havens) {
    return DraggableScrollableSheet(
      initialChildSize: 0.3, minChildSize: 0.1, maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 30)],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(3))),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: havens.length,
                  itemBuilder: (context, index) {
                    final haven = havens[index];
                    return ListTile(
                      leading: Icon(
                        haven['type'] == 'Police' ? Icons.local_police : 
                        haven['type'] == 'Hospital' ? Icons.medical_services : Icons.medication,
                        color: haven['type'] == 'Police' ? const Color(0xFF02579C) : 
                               haven['type'] == 'Hospital' ? Colors.red : Colors.green,
                      ),
                      title: Text(haven['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(haven['address']),
                      trailing: Text(haven['distance'], style: const TextStyle(color: Color(0xFF02579C), fontWeight: FontWeight.bold)),
                      onTap: () => _mapController.move(haven['point'], 16.0),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHavenDetails(Map<String, dynamic> haven) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(haven['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(haven['address'], style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.directions),
                    label: const Text("Directions"),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF02579C), foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.call, color: Colors.green),
                  style: IconButton.styleFrom(backgroundColor: Colors.green.withValues(alpha: 0.1)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}