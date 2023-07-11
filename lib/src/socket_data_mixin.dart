import 'dart:async';

import 'socket_result.dart';

mixin SocketDataMixin {
  final StreamController<SocketResult<dynamic>> _dataController =
      StreamController.broadcast();

  Stream<SocketResult<dynamic>> get dataStream => _dataController.stream;

  void notifyReceiveData(dynamic data) {
    _dataController.add(SocketResultData(data));
  }

  void notifyReceiveError(Object? error) {
    _dataController.add(SocketResultError(error));
  }
}
