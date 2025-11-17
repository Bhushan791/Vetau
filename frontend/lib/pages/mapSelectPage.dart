import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapSelectPage extends StatefulWidget {
  const MapSelectPage({super.key});

  @override
  State<MapSelectPage> createState() => _MapSelectPageState();
}

class _MapSelectPageState extends State<MapSelectPage> {
  final Completer<GoogleMapController> _controller = Completer();

  LatLng? _pickedLocation;
  String? _placeName;
  String? _mapTheme;

  @override
  void initState() {
    super.initState();
    _loadMapTheme();
    _initLocation();
  }

  /// Load custom map theme
  Future<void> _loadMapTheme() async {
    _mapTheme = await rootBundle.loadString("assets/raw/maptheme.json");
  }

  /// Ask for permission + move camera to current location
  Future<void> _initLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position pos = await Geolocator.getCurrentPosition();

    _moveCamera(LatLng(pos.latitude, pos.longitude));
  }

  Future<void> _moveCamera(LatLng target) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 15),
      ),
    );
  }

  /// Reverse geocode (lat -> place name)
  Future<void> _getPlaceName(LatLng pos) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);

      if (placemarks.isNotEmpty) {
        Placemark p = placemarks.first;
        _placeName =
            "${p.name}, ${p.locality}, ${p.administrativeArea}, ${p.country}";
      } else {
        _placeName = "${pos.latitude}, ${pos.longitude}";
      }
    } catch (e) {
      print("Error getting place name: $e");
      _placeName = "${pos.latitude}, ${pos.longitude}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Location"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(27.6850, 85.3169), // fallback Kathmandu
              zoom: 14,
            ),
            onMapCreated: (GoogleMapController controller) {
              if (_mapTheme != null) {
                controller.setMapStyle(_mapTheme);
              }
              _controller.complete(controller);
            },

            myLocationEnabled: true,
            myLocationButtonEnabled: true,

            markers: _pickedLocation == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId("selected"),
                      position: _pickedLocation!,
                    )
                  },

            onTap: (LatLng pos) async {
              setState(() {
                _pickedLocation = pos;
                _placeName = null; // reset while loading
              });

              await _getPlaceName(pos);

              setState(() {});
            },
          ),

          // Bottom confirmation button when location selected
          if (_pickedLocation != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_placeName != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                          )
                        ],
                      ),
                      child: Text(
                        _placeName!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context, {
                        "lat": _pickedLocation!.latitude,
                        "lng": _pickedLocation!.longitude,
                        "placeName": _placeName ?? "Unknown Place",
                      });
                    },
                    child: const Text(
                      "Confirm Location",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
