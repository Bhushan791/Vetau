import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilterLocation {
  final double lat;
  final double lng;

  FilterLocation({required this.lat, required this.lng});
}

class FilterState {
  final String? type;
  final List<String> categories;
  final bool nearMe;
  final bool highReward;
  final FilterLocation? location;

  const FilterState({
    this.type,
    this.categories = const [],
    this.nearMe = false,
    this.highReward = false,
    this.location,
  });

  FilterState copyWith({
    String? type,
    List<String>? categories,
    bool? nearMe,
    bool? highReward,
    FilterLocation? location,
    bool clearType = false,
    bool clearLocation = false,
  }) {
    return FilterState(
      type: clearType ? null : (type ?? this.type),
      categories: categories ?? this.categories,
      nearMe: nearMe ?? this.nearMe,
      highReward: highReward ?? this.highReward,
      location: clearLocation ? null : (location ?? this.location),
    );
  }

  String get summaryText {
    List<String> parts = [];
    if (type != null) parts.add("Type: $type");
    if (categories.isNotEmpty) parts.add("Categories: ${categories.join(', ')}");
    if (nearMe) parts.add("Near Me");
    if (highReward) parts.add("High Reward");
    return parts.isEmpty ? "No filters selected" : parts.join(" • ");
  }
}

class FilterStore extends Notifier<FilterState> {
  @override
  FilterState build() => const FilterState();

  void toggleType(String type) {
    state = state.copyWith(
      type: state.type == type ? null : type,
      clearType: state.type == type,
    );
  }

  void toggleCategory(String category) {
    final cats = List<String>.from(state.categories);
    if (cats.contains(category)) {
      cats.remove(category);
    } else {
      cats.add(category);
    }
    state = state.copyWith(categories: cats);
  }

  void toggleNearMe(bool value, {double? lat, double? lng}) {
    if (value && lat != null && lng != null) {
      state = state.copyWith(
        nearMe: true,
        location: FilterLocation(lat: lat, lng: lng),
      );
    } else {
      state = state.copyWith(
        nearMe: false,
        location: null,
        clearLocation: true,
      );
    }
  }

  void toggleHighReward() {
    state = state.copyWith(highReward: !state.highReward);
  }

  void clearFilters() {
    state = const FilterState();
  }
}

final filterStoreProvider = NotifierProvider<FilterStore, FilterState>(() {
  return FilterStore();
});
