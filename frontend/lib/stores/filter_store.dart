import 'package:flutter_riverpod/legacy.dart';

final filterStoreProvider =
    StateNotifierProvider<FilterStore, List<String>>((ref) {
  return FilterStore();
});

class FilterStore extends StateNotifier<List<String>> {
  FilterStore() : super(['All']); // Default: All selected

  void toggleFilter(String filter) {
    if (filter == 'All') {
      // Selecting All clears others
      state = ['All'];
      return;
    }

    // Remove "All" when another filter is selected
    final current = [...state]..remove('All');

    if (current.contains(filter)) {
      current.remove(filter);
    } else {
      current.add(filter);
    }

    // If nothing selected, revert back to All
    if (current.isEmpty) current.add('All');

    state = current;
  }

  void clearFilters() => state = ['All'];
}
