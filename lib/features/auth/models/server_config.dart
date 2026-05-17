class ServerConfig {
  final String serverUrl;
  final String username;
  final String password;
  final Map<String, dynamic>? userInfo;

  const ServerConfig({
    required this.serverUrl,
    required this.username,
    required this.password,
    this.userInfo,
  });

  String get displayName {
    final info = userInfo?['user_info'] as Map<String, dynamic>?;
    return info?['username']?.toString() ?? username;
  }

  String? get expirationDate {
    final info = userInfo?['user_info'] as Map<String, dynamic>?;
    final exp = info?['exp_date']?.toString();
    if (exp == null || exp == 'Unlimited') return 'Sin vencimiento';
    final ts = int.tryParse(exp);
    if (ts == null) return exp;
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  int? get maxConnections {
    final info = userInfo?['user_info'] as Map<String, dynamic>?;
    return int.tryParse(info?['max_connections']?.toString() ?? '');
  }

  bool get isActive {
    final info = userInfo?['user_info'] as Map<String, dynamic>?;
    return info?['status']?.toString() == 'Active';
  }
}
