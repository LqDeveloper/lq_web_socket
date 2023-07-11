import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/io.dart';

import 'heart_beat_config.dart';
import 'socket_connect_mixin.dart';
import 'socket_data_mixin.dart';

class SocketManager with SocketConnectMixin, SocketDataMixin {
  ///websocket连接地址
  String _wsUrl = '';

  ///失败重连此次
  int _retryCount = 3;

  ///Socket Header
  Map<String, dynamic>? _headers;

  ///控制发送 ping 信号的时间间隔
  Duration? _pingInterval;

  ///[connectTimeout] 确定在抛出 [TimeoutException] 之前等待 [WebSocket.connect] 的时间
  Duration? _connectTimeout;

  /// 心跳配置
  HeartBeatConfig? _heartConfig;

  ///Channel
  IOWebSocketChannel? _channel;

  /// 心跳定时器
  Timer? _heartTimer;

  /// 当前已重试的次数
  int _currentRetryCount = 0;

  StreamSubscription? _subscription;

  ///是否已连接
  bool _connected = false;

  bool get connected => _connected;

  ///设置Socket连接信息
  void setupConfig({
    required String wsUrl,
    int retryCount = 3,
    HeartBeatConfig? heartConfig,
    Map<String, dynamic>? headers,
    Duration? pingInterval,
    Duration? connectTimeout,
  }) {
    _wsUrl = wsUrl;
    _retryCount = retryCount;
    _heartConfig = heartConfig;
    _headers = headers;
    _pingInterval = pingInterval;
    _connectTimeout = connectTimeout;
  }

  ///连接socket
  Future<void> connect() async {
    try {
      await _connect();
      logMessage("socket：$_wsUrl 建立连接");
      notifyConnected();
    } catch (e) {
      logMessage('-----------WebSocket:$_wsUrl 连接失败------------');
    }
  }

  ///调用了disconnect后，重新连接
  Future<void> reconnect() async {
    try {
      await _connect();
      logMessage("socket：$_wsUrl 重新连接");
      notifyReconnected();
    } catch (e) {
      logMessage('-----------WebSocket:$_wsUrl 重新连接失败------------');
    }
  }

  Future<void> _connect() async {
    if (_channel != null) {
      disconnect();
    }
    _channel = IOWebSocketChannel.connect(_wsUrl,
        headers: _headers,
        pingInterval: _pingInterval,
        connectTimeout: _connectTimeout);

    ///等待连接成功
    await _channel?.ready;
    _startHeartBeat();

    _subscription =
        _channel?.stream.listen(_onData, onDone: _onDone, onError: _onError);
    _connected = true;
  }

  /// 向socket 发送数据
  void sendMessage(dynamic data) {
    final jsonData = jsonEncode(data);
    logMessage("发送数据: $jsonData");
    _channel?.sink.add(jsonData);
  }

  /// 关闭socket 通道
  void close() {
    disconnect();
    logMessage("socket：$_wsUrl 关闭连接，并清空观察者");
  }

  ///断开连接
  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _stopHeartBeat();
    _connected = false;
    notifyDisconnected();
    logMessage("socket：$_wsUrl 断开连接");
  }

  ///将字符串解析为Map
  Map<String, dynamic> _parseAndDecode(String response) {
    Map<String, dynamic> map = {};
    try {
      map = jsonDecode(response) as Map<String, dynamic>;
    } catch (_) {}
    return map;
  }

  ///开辟子线程
  // Future<Map<String, dynamic>> parseJson(String text) {
  //   return compute(_parseAndDecode, text);
  // }

  void _onData(dynamic data) {
    ///成功接收数据后，重置_currentRetryCount
    if (_currentRetryCount > 0) {
      _currentRetryCount = 0;
    }
    if (data is String) {
      final jsonData = _parseAndDecode(data);
      notifyReceiveData(jsonData);
    } else {
      notifyReceiveData(data);
    }
  }

  void _onDone() {
    logMessage('断开连接 - 已完成');
    _connectRetry();
  }

  ///当发生错误重新连接
  void _onError(Object? error) {
    logMessage('断开连接 - ${error.toString()}');
    notifyReceiveError(error);
    _connectRetry();
  }

  void _connectRetry() {
    if (_currentRetryCount < _retryCount) {
      _currentRetryCount++;
      disconnect();
      Future.delayed(const Duration(seconds: 5), () {
        reconnect();
      });
    } else {
      disconnect();
    }
  }

  /// 开启心跳
  void _startHeartBeat() {
    if (_heartConfig == null) return;
    if (_heartTimer != null) {
      _heartTimer?.cancel();
    }
    final period = _heartConfig?.period ?? const Duration(seconds: 1);
    _heartTimer = Timer.periodic(period, (timer) {
      sendMessage(_heartConfig?.content ?? "");
    });
  }

  /// 停止心跳
  void _stopHeartBeat() {
    if (_heartTimer != null) {
      _heartTimer?.cancel();
      _heartTimer = null;
    }
  }

  void logMessage(String message) {}
}
