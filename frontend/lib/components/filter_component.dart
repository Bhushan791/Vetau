import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/stores/filter_store.dart';

class FilterComponent extends ConsumerWidget {
  FilterComponent({super.key});

  final List<String> filters = [
    "All",
    "Near You",
    "Lost",
    "Found",
    "Pets",
    "High Reward",
    "Electronics",
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(filterStoreProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: const Color(0xFFF1F6FD), // light background like your screenshot
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: filters.map((filter) {
          final isSelected = selected.contains(filter);

          // Custom colors for specific filters
          Color backgroundColor;
          Color textColor;
          FontWeight weight = FontWeight.w500;

          if (filter == "High Reward") {
            backgroundColor = isSelected
                ? const Color(0xFFFF8C1A) // orange
                : Colors.white;
            textColor = isSelected ? Colors.white : const Color(0xFFFF8C1A);
          } else if (filter == "All") {
            backgroundColor =
                isSelected ? const Color(0xFF2196F3) : Colors.white; // blue
            textColor = isSelected ? Colors.white : Colors.black87;
          } else {
            backgroundColor = isSelected ? const Color(0xFF2196F3) : Colors.white; // blue
            textColor = isSelected ? Colors.white : Colors.black87;
          }

          return GestureDetector(
            onTap: () => ref.read(filterStoreProvider.notifier).toggleFilter(filter),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? (filter == "High Reward"
                          ? const Color(0xFFFF8C1A)
                          : const Color(0xFF2196F3))
                      : Colors.grey.shade300,
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
                  color: textColor,
                  fontWeight: weight,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
