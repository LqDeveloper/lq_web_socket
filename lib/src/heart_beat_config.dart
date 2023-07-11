class HeartBeatConfig {
  /// 心跳周期
  final Duration period;

  /// 心跳包要发送的内容
  final Map<String, dynamic> content;

  const HeartBeatConfig({required this.period, required this.content});
}
