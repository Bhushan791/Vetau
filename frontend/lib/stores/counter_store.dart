// lib/stores/counter_store.dart
import 'package:flutter_riverpod/legacy.dart';

/// CounterStore: StateNotifier that holds an int state and actions.
class CounterStore extends StateNotifier<int> {
  CounterStore() : super(0); // initial state

  void increment() => state++;
  void decrement() => state--;
  void reset() => state = 0;
}

/// Provider that exposes the store's state (int) and notifier.
final counterProvider =
    StateNotifierProvider<CounterStore, int>((ref) => CounterStore());
