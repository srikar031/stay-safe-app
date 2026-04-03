import 'package:geolocator/geolocator.dart';

class LocationService {
  final GeolocatorPlatform _geolocator = GeolocatorPlatform.instance;

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await _geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    try {
      // 1. Try to get the last known position first (fastest)
      Position? lastPosition = await _geolocator.getLastKnownPosition();
      
      // 2. Try to get the current position with a timeout
      // This ensures if GPS is slow, we don't hang the app forever
      Position currentPosition = await _geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5), // Wait max 5 seconds for high accuracy
        ),
      );
      
      return currentPosition;
    } catch (e) {
      // If high accuracy fails or times out, return the last known position
      return await _geolocator.getLastKnownPosition();
    }
  }
}
