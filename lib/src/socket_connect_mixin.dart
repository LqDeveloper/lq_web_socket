import 'dart:async';

import 'socket_connect_type.dart';

mixin SocketConnectMixin {
  ///Socket连接状态
  SocketConnectType _connectType = SocketConnectType.disconnected;

  SocketConnectType get connectType => _connectType;

  final StreamController<SocketConnectType> _connectController =
      StreamController.broadcast();

  Stream<SocketConnectType> get connectStream => _connectController.stream;

  void _setupType(SocketConnectType type) {
    _connectType = type;
    _connectController.add(type);
  }

  void notifyConnected() {
    _setupType(SocketConnectType.connected);
  }

  void notifyReconnected() {
    _setupType(SocketConnectType.reconnected);
  }

  void notifyDisconnected() {
    _setupType(SocketConnectType.disconnected);
  }
}
