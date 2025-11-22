import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:frontend/config/socket_config.dart';

class SocketService {
  late io.Socket socket;

  bool isConnected = false;

  void initSocket() {
    socket = io.io(
      SocketConfig.socketBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableForceNew()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(500)
          .build(),
    );

    _registerCoreListeners();
  }

  void _registerCoreListeners() {
    socket.on("connect", (_) {
      isConnected = true;
      print("🔌 SOCKET CONNECTED");
    });

    socket.on("disconnect", (_) {
      isConnected = false;
      print("🔌 SOCKET DISCONNECTED");
    });

    socket.on("connect_error", (data) {
      print("❌ SOCKET CONNECTION ERROR: $data");
    });
  }

  // Join a chat room
  void joinRoom(String roomId) {
    socket.emit("joinRoom", roomId);
    print("📡 Joined room: $roomId");
  }

  // Send message to backend
  void sendMessage(Map<String, dynamic> message) {
    socket.emit("sendMessage", message);
  }

  // Listen for incoming messages
  void onMessage(void Function(dynamic) callback) {
    socket.on("message", callback);
  }

  void dispose() {
    socket.dispose();
  }
}
