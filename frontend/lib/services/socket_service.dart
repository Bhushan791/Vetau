import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:frontend/config/socket_config.dart';
import 'package:frontend/services/token_service.dart';

class SocketService {
  // Singleton instance
  static final SocketService _instance = SocketService._internal();
  static SocketService get instance => _instance;

  late io.Socket socket;
  bool isConnected = false;

  SocketService._internal();

  /// Initialize and connect socket
  Future<void> initSocket() async {
  final tokenService = TokenService();
  final token = await tokenService.getAccessToken(); // async

  socket = io.io(
    SocketConfig.socketBaseUrl,
    io.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .enableForceNew()
        .setAuth({
          'token': 'Bearer $token',
        })
        .setReconnectionAttempts(5)
        .setReconnectionDelay(500)
        .build(),
  );

  _registerCoreListeners();
}


  void _registerCoreListeners() {
    socket.onConnect((_) {
      isConnected = true;
      print('🔌 SOCKET CONNECTED: ${socket.id}');
    });

    socket.onDisconnect((_) {
      isConnected = false;
      print('🔌 SOCKET DISCONNECTED');
    });

    socket.onConnectError((data) {
      isConnected = false;
      final errorMsg = data.toString();
      print('❌ SOCKET CONNECTION ERROR: $errorMsg');
      
      // If authentication error, try to refresh token and reconnect
      if (errorMsg.contains('Authentication')) {
        _handleAuthError();
      }
    });

    socket.onError((data) {
      final errorMsg = data.toString();
      print('❌ SOCKET ERROR: $errorMsg');
    });
  }

  Future<void> _handleAuthError() async {
    try {
      print('🔄 Attempting token refresh for socket...');
      final tokenService = TokenService();
      
      // Check if token needs refresh
      if (await tokenService.isAccessTokenExpired()) {
        // Token refresh is handled by ApiClient, just get new token
        final newToken = await tokenService.getAccessToken();
        if (newToken != null) {
          // Reconnect with new token
          socket.dispose();
          await initSocket();
        }
      }
    } catch (e) {
      print('❌ Failed to refresh token for socket: $e');
    }
  }

  /// Join a specific chat room
  void joinRoom(String chatId) {
    if (!isConnected) {
      print('⚠️ Cannot join room, socket not connected yet');
      return;
    }
    socket.emit('join_chat', {'chatId': chatId});
    print('📡 Joined room: $chatId');
  }

  /// Send message to backend
  void sendMessage(String chatId, String content) {
    if (!isConnected) {
      print('⚠️ Cannot send message, socket not connected');
      return;
    }
    socket.emit('send_message', {
      'chatId': chatId,
      'content': content,
    });
  }

  /// Listen for incoming messages
  void onNewMessage(void Function(dynamic) callback) {
    socket.on('new_message', callback);
  }

  /// Listen for message sent confirmation
  void onMessageSent(void Function(dynamic) callback) {
    socket.on('message_sent', callback);
  }

  /// Listen for joined chat confirmation
  void onJoinedChat(void Function(dynamic) callback) {
    socket.on('joined_chat', callback);
  }

  /// Listen for errors
  void onError(void Function(dynamic) callback) {
    socket.on('error', (data) {
      final error = {
        'message': data['message'] ?? data.toString(),
        'type': 'socket_error'
      };
      callback(error);
    });
  }

  /// Reconnect socket manually
  Future<void> reconnect() async {
    if (socket.connected) {
      socket.disconnect();
    }
    await initSocket();
  }

  /// Disconnect socket
  void dispose() {
    if (socket.connected) {
      socket.disconnect();
    }
    socket.dispose();
    isConnected = false;
  }
}
