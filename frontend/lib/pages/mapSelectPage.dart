import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapSelectPage extends StatefulWidget {
  const MapSelectPage({super.key});

  @override
  State<MapSelectPage> createState() => _MapSelectPageState();
}

class _MapSelectPageState extends State<MapSelectPage> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _pickedLocation;
  String? _mapTheme;

  @override
  void initState() {
    super.initState();
    _loadMapTheme();
    _initLocation();
  }

  /// Load map theme JSON from assets (same as you were doing)
  Future<void> _loadMapTheme() async {
    _mapTheme = await rootBundle.loadString("raw/maptheme.json");
  }

  /// Ask for permission + get GPS location
  Future<void> _initLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check service
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    // Ask permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // Get current GPS location
    Position pos = await Geolocator.getCurrentPosition();
    _moveCamera(LatLng(pos.latitude, pos.longitude));
  }

  /// Move the camera to given LatLng
  Future<void> _moveCamera(LatLng target) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 16),
      ),
    );
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
          // MAP
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(27.6850, 85.3169), // fallback before GPS loads
              zoom: 14,
            ),
            onMapCreated: (GoogleMapController controller) {
              controller.setMapStyle(_mapTheme);
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

            onTap: (LatLng position) {
              setState(() {
                _pickedLocation = position;
              });
            },
          ),

          // Confirm button (only when a location is chosen)
          if (_pickedLocation != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                ),
                onPressed: () {
                  Navigator.pop(context, _pickedLocation);
                },
                child: const Text(
                  "Confirm Location",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
