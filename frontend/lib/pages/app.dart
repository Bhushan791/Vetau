// lib/pages/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../stores/counter_store.dart';

class AppPage extends ConsumerWidget {
  const AppPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);                 // read state
    final counter = ref.read(counterProvider.notifier);      // access actions

    return Scaffold(
      appBar: AppBar(title: const Text('Riverpod Counter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Count', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('$count', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: counter.increment,
                  child: const Text('Increment'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: counter.decrement,
                  child: const Text('Decrement'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: counter.reset,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
