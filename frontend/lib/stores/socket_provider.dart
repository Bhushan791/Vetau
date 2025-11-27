import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/services/socket_service.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService.instance;
});

final resetAppStateProvider = FutureProvider<void>((ref) async {
  SocketService.instance.reset();
});
