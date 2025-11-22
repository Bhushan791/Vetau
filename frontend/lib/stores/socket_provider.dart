import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/services/socket_service.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  service.initSocket();
  return service;
});
