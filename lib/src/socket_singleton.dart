import 'heart_beat_config.dart';
import 'socket_manager.dart';

class SocketSingleton {
  static final SocketSingleton _instance = SocketSingleton._();

  factory SocketSingleton() => _instance;

  final SocketManager _manager = SocketManager();

  SocketSingleton._();

  static bool get connected => _instance._manager.connected;

  ///连接web socket
  static Future<void> connect({
    String wsUrl = '',
    int retryCount = 3,
    HeartBeatConfig? heartConfig,
    Map<String, dynamic>? headers,
    Duration? pingInterval,
    Duration? connectTimeout,
  }) async {
    if (_instance._manager.connected) {
      _instance._manager.disconnect();
    }
    _instance._manager.setupConfig(
        wsUrl: wsUrl,
        retryCount: retryCount,
        heartConfig: heartConfig,
        headers: headers,
        pingInterval: pingInterval,
        connectTimeout: connectTimeout);
    await _instance._manager.connect();
  }

  ///通过web socket发送数据
  static void sendMessage(dynamic data) {
    _instance._manager.sendMessage(data);
  }

  ///调用了disconnect后，重新连接
  static Future<void> reconnect() async {
    await _instance._manager.reconnect();
  }

  ///只是清理Channel的监听，但是并不会清除观察者
  static void disconnect() {
    _instance._manager.disconnect();
  }

  ///彻底关闭web socket,并清理观察者
  static void close() {
    _instance._manager.close();
  }
}
