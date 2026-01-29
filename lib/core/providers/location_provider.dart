import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

// Current user location provider
class LocationNotifier extends AsyncNotifier<Position?> {
  @override
  Future<Position?> build() async {
    return await LocationService.getCurrentLocation();
  }

  Future<void> refreshLocation() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await LocationService.getCurrentLocation();
    });
  }
}

final currentLocationProvider = AsyncNotifierProvider<LocationNotifier, Position?>(() {
  return LocationNotifier();
});

// Selected location for search (can be different from current location)
final selectedLocationProvider = Provider<Position?>((ref) => null);

// Search radius in kilometers  
class SearchRadiusNotifier extends Notifier<double> {
  @override
  double build() => 10.0;
  
  void setRadius(double radius) {
    state = radius;
  }
}

final searchRadiusProvider = NotifierProvider<SearchRadiusNotifier, double>(() {
  return SearchRadiusNotifier();
});
