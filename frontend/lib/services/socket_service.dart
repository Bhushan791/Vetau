import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:frontend/config/socket_config.dart';
import 'package:frontend/services/token_service.dart';

class SocketService {
  static SocketService? _instance;
  static SocketService get instance {
    _instance ??= SocketService._internal();
    return _instance!;
  }

  io.Socket? socket;
  bool isConnected = false;


  SocketService._internal();


  
  bool get connectionStatus => isConnected && (socket?.connected ?? false);

  Future<void> initSocket() async {
    final tokenService = TokenService();
    final token = await tokenService.getAccessToken();
    
    if (token == null) {
      print('❌ No token available for socket initialization');
      return;
    }

    if (socket != null) {
      socket!.dispose();
      socket = null;
    }

    print('🔧 Initializing socket with token: ${token.substring(0, 20)}...');

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
    socket!.on('connect', (_) {
      isConnected = true;
      print('🔌 SOCKET CONNECTED: ${socket!.id}');
    });

    socket!.on('disconnect', (_) {
      isConnected = false;
      print('🔌 SOCKET DISCONNECTED');
    });

    socket!.on('connect_error', (data) {
      isConnected = false;
      final errorMsg = data.toString();
      print('❌ SOCKET CONNECTION ERROR: $errorMsg');
      
      if (errorMsg.contains('Authentication')) {
        _handleAuthError();
      }
    });

    socket!.on('error', (data) {
      final errorMsg = data.toString();
      print('❌ SOCKET ERROR: $errorMsg');
    });
  }

  Future<void> _handleAuthError() async {
    try {
      print('🔄 Attempting token refresh for socket...');
      final tokenService = TokenService();
      
      if (await tokenService.isAccessTokenExpired()) {
        final newToken = await tokenService.getAccessToken();
        if (newToken != null) {
          socket?.dispose();
          socket = null;
          await initSocket();
        }
      }
    } catch (e) {
      print('❌ Failed to refresh token for socket: $e');
    }
  }

  void joinRoom(String chatId) {
    if (!isConnected || socket == null) {
      print('⚠️ Cannot join room, socket not connected yet');
      return;
    }
    socket!.emit('join_chat', {'chatId': chatId});
    print('📡 Joined room: $chatId');
  }

  void sendMessage(String chatId, String content) {
    print('📤 Attempting to send message. Connected: $isConnected, Socket connected: ${socket?.connected}');
    if (!isConnected || socket == null || !socket!.connected) {
      print('⚠️ Cannot send message, socket not connected');
      return;
    }
    socket!.emit('send_message', {
      'chatId': chatId,
      'content': content,
    });
    print('📤 Message emitted via socket');
  }

  void onNewMessage(void Function(dynamic) callback) {
    socket?.on('new_message', callback);
  }

  void onMessageSent(void Function(dynamic) callback) {
    socket?.on('message_sent', callback);
  }

  void onJoinedChat(void Function(dynamic) callback) {
    socket?.on('joined_chat', callback);
  }

  void onError(void Function(dynamic) callback) {
    socket?.on('error', (data) {
      final error = {
        'message': data['message'] ?? data.toString(),
        'type': 'socket_error'
      };
      callback(error);
    });
  }

  void onUserTyping(void Function(dynamic) callback) {
    socket?.on('user_typing', callback);
  }

  void onUserStopTyping(void Function(dynamic) callback) {
    socket?.on('user_stop_typing', callback);
  }

  void sendTyping(String chatId) {
    if (!isConnected || socket == null) return;
    socket!.emit('typing', {'chatId': chatId});
  }

  void sendStopTyping(String chatId) {
    if (!isConnected || socket == null) return;
    socket!.emit('stop_typing', {'chatId': chatId});
  }

  void clearListeners() {
    socket?.off('new_message');
    socket?.off('message_sent');
    socket?.off('joined_chat');
    socket?.off('user_typing');
    socket?.off('user_stop_typing');
  }

  void cleanup() {
    print('🧹 Cleaning up socket service...');
    
    if (socket == null) {
      print('🧹 Socket already null, nothing to cleanup');
      return;
    }
    
    socket!.offAny();
    socket!.off('new_message');
    socket!.off('message_sent');
    socket!.off('joined_chat');
    socket!.off('user_typing');
    socket!.off('user_stop_typing');
    socket!.off('connect');
    socket!.off('disconnect');
    socket!.off('connect_error');
    socket!.off('error');
    
    if (socket!.connected) {
      socket!.disconnect();
    }
    socket!.dispose();
    socket = null;
    
    isConnected = false;
    _currentUserId = null;
    print('🧹 Socket cleanup complete - socket set to null');
  }

  void reset() {
    cleanup();
    _currentUserId = null;
    _instance = null;
    print('🔄 Socket instance reset for new user');
  }

  Future<void> reconnect() async {
    if (socket?.connected ?? false) {
      socket!.disconnect();
    }
    await initSocket();
    await waitForConnection();
  }

  Future<void> waitForConnection() async {
    int retries = 0;
    while (!isConnected && retries < 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      retries++;
    }
    if (!isConnected) {
      print('❌ Socket connection timeout after retries');
    }
  }

  void dispose() {
    if (socket?.connected ?? false) {
      socket!.disconnect();
    }
    socket?.dispose();
    socket = null;
    isConnected = false;
  }
}
