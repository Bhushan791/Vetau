import 'package:flutter_riverpod/legacy.dart';

/// This provider exposes the list of selected filters.
/// It uses a StateNotifier to manage adding/removing filters.
final filterStoreProvider =
    StateNotifierProvider<FilterStore, List<String>>((ref) {
  return FilterStore();
});

/// FilterStore manages the selected filters list.
/// It has a toggle method that selects or unselects a filter.
class FilterStore extends StateNotifier<List<String>> {
  FilterStore() : super([]);

  /// Toggles a filter on/off
  void toggleFilter(String filter) {
    if (state.contains(filter)) {
      state = [...state]..remove(filter);
    } else {
      state = [...state, filter];
    }
  }

  /// Optionally: clear all filters
  void clearFilters() {
    state = [];
  }
}
