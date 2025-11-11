import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:frontend/stores/filter_store.dart';

class FilterComponent extends ConsumerWidget {
  FilterComponent({super.key});

  final List<String> filters = [
    "Lost",
    "Found",
    "High Reward",
    "Pets",
    "Electronics",
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(filterStoreProvider);

    return Wrap(
      spacing: 8,
      children: filters.map((filter) {
        final isSelected = selected.contains(filter);

        return ChoiceChip(
          label: Text(filter),
          selected: isSelected,
          onSelected: (_) {
            ref
                .read(filterStoreProvider.notifier)
                .toggleFilter(filter);
          },
        );
      }).toList(),
    );
  }
}
