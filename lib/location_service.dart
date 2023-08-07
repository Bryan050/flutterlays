import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as goa;
import 'package:mapsforge_flutter/core.dart';

class LocationProvider with ChangeNotifier {
  Location? _location;
  Location get location => _location!;
  LatLong? _locationPosition;
  LatLong get locationPosition => _locationPosition!;
  bool locationServiceActive = true;
  LocationProvider() {
    _location = Location();
    _locationPosition = LatLong(-0.94694, -78.61905);
  }
  initalization() async {
    await getUserLocation();
  }

  getUserLocation() async {
    bool _serviceEnable;
    PermissionStatus _permissionGranted;

    _serviceEnable = await location.serviceEnabled();
    if (!_serviceEnable) {
      _serviceEnable = await location.requestService();
      if (!_serviceEnable) {
        return;
      }
      _permissionGranted = await location.hasPermission();
      if (_permissionGranted == PermissionStatus.denied) {
        _permissionGranted = await location.requestPermission();
      }
    }
    location.onLocationChanged.listen((LocationData currentLocation) {
      _locationPosition =
          LatLong(currentLocation.latitude!, currentLocation.longitude!);
      print(_locationPosition);
      notifyListeners();
    });
  }
}
