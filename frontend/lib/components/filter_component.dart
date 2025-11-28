import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/stores/filter_store.dart';
import 'package:frontend/stores/posts_provider.dart';
import 'package:geolocator/geolocator.dart';

class FilterComponent extends ConsumerWidget {
  FilterComponent({super.key});

  final List<String> filters = [
    "All",
    "Near Me",
    "Lost",
    "Found",
    "High Reward",
    "Pets",
    "Electronics",
    "Child",
    "Vehicle",
    "Documents",
  ];

  Future<Position?> _requestLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.watch(filterStoreProvider);

    bool isSelected(String f) {
      if (f == "Near Me") return fs.nearMe;
      if (f == "High Reward") return fs.highReward;
      if (f == "Lost") return fs.type == "lost";
      if (f == "Found") return fs.type == "found";
      if (f == "All") {
        return fs.categories.isEmpty &&
            fs.type == null &&
            !fs.nearMe &&
            !fs.highReward;
      }
      return fs.categories.contains(f.toLowerCase());
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = isSelected(filter);

          return GestureDetector(
            onTap: () async {
              final store = ref.read(filterStoreProvider.notifier);
              final postsNotifier = ref.read(postsProvider.notifier);

              if (filter == "All") {
                store.clearFilters();
              } else if (filter == "Near Me") {
                if (selected) {
                  store.toggleNearMe(false);
                } else {
                  final pos = await _requestLocation();
                  if (pos != null) {
                    store.toggleNearMe(true, lat: pos.latitude, lng: pos.longitude);
                  } else {
                    return;
                  }
                }
              } else if (filter == "Lost") {
                store.toggleType("lost");
              } else if (filter == "Found") {
                store.toggleType("found");
              } else if (filter == "High Reward") {
                store.toggleHighReward();
              } else {
                store.toggleCategory(filter.toLowerCase());
              }

              await postsNotifier.fetchPosts();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF2196F3) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? const Color(0xFF2196F3) : Colors.grey.shade300,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  )
                ],
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
