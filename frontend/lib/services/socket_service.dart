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
  
  // Getter for connection status
  bool get connectionStatus => isConnected && socket.connected;

  /// Initialize and connect socket
  Future<void> initSocket() async {
  final tokenService = TokenService();
  final token = await tokenService.getAccessToken();

  print('🔧 Initializing socket with token: ${token?.substring(0, 20)}...');

  socket = io.io(
    SocketConfig.socketBaseUrl,
    io.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .setReconnectionAttempts(5)
        .setReconnectionDelay(1000)
        .setAuth({
          'token': 'Bearer $token',
        })
        .build(),
  );

  _registerCoreListeners();
  
  print('🔧 Socket object created, waiting for connection...');
}


  void _registerCoreListeners() {
    socket.on('connect', (_) {
      isConnected = true;
      print('🔌 SOCKET CONNECTED: ${socket.id}');
    });

    socket.on('disconnect', (_) {
      isConnected = false;
      print('🔌 SOCKET DISCONNECTED');
    });

    socket.on('connect_error', (data) {
      isConnected = false;
      final errorMsg = data.toString();
      print('❌ SOCKET CONNECTION ERROR: $errorMsg');
      
      // If authentication error, try to refresh token and reconnect
      if (errorMsg.contains('Authentication')) {
        _handleAuthError();
      }
    });

    socket.on('error', (data) {
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
    print('📤 Attempting to send message. Connected: $isConnected, Socket connected: ${socket.connected}');
    if (!isConnected && !socket.connected) {
      print('⚠️ Cannot send message, socket not connected');
      return;
    }
    socket.emit('send_message', {
      'chatId': chatId,
      'content': content,
    });
    print('📤 Message emitted via socket');
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

  /// Listen for typing indicators
  void onUserTyping(void Function(dynamic) callback) {
    socket.on('user_typing', callback);
  }

  void onUserStopTyping(void Function(dynamic) callback) {
    socket.on('user_stop_typing', callback);
  }

  /// Send typing indicator
  void sendTyping(String chatId) {
    if (!isConnected) return;
    socket.emit('typing', {'chatId': chatId});
  }

  void sendStopTyping(String chatId) {
    if (!isConnected) return;
    socket.emit('stop_typing', {'chatId': chatId});
  }

  /// Clear all listeners to prevent duplicates (but keep core connection listeners)
  void clearListeners() {
    socket.off('new_message');
    socket.off('message_sent');
    socket.off('joined_chat');
    socket.off('user_typing');
    socket.off('user_stop_typing');
    // Don't clear 'connect', 'disconnect', 'connect_error', 'error' - these are core listeners
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
