import 'package:flutter/foundation.dart';

@immutable
abstract class SocketResult<State> {
  const factory SocketResult.data(State state) = SocketResultData;

  const factory SocketResult.error(Object? error) = SocketResultError;

  bool get hasState;

  State? get stateOrNull;

  Object? get errorOrNull;

  R map<R>({
    required R Function(SocketResultData<State> data) data,
    required R Function(SocketResultError<State>) error,
  });

  R when<R>({
    required R Function(State data) data,
    required R Function(Object? error) error,
  });
}

class SocketResultData<State> implements SocketResult<State> {
  const SocketResultData(this.state);

  final State state;

  @override
  bool get hasState => true;

  @override
  State? get stateOrNull => state;

  @override
  Object? get errorOrNull => null;

  @override
  R map<R>({
    required R Function(SocketResultData<State> data) data,
    required R Function(SocketResultError<State>) error,
  }) {
    return data(this);
  }

  @override
  R when<R>({
    required R Function(State data) data,
    required R Function(Object? error) error,
  }) {
    return data(state);
  }
}

class SocketResultError<State> implements SocketResult<State> {
  const SocketResultError(this.error);

  final Object? error;

  @override
  bool get hasState => false;

  @override
  State? get stateOrNull => null;

  @override
  Object? get errorOrNull => error;

  @override
  R map<R>({
    required R Function(SocketResultData<State> data) data,
    required R Function(SocketResultError<State>) error,
  }) {
    return error(this);
  }

  @override
  R when<R>({
    required R Function(State data) data,
    required R Function(Object? error) error,
  }) {
    return error(error);
  }
}
