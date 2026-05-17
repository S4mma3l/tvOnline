import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/xtream_api.dart';
import '../../../core/storage/app_storage.dart';
import '../models/server_config.dart';

// The active API client, rebuilt when server config changes
final xtreamApiProvider = Provider<XtreamApi?>((ref) {
  final config = ref.watch(serverConfigProvider);
  return config.whenOrNull(
    data: (cfg) => cfg != null
        ? XtreamApi(
            baseUrl: cfg.serverUrl,
            username: cfg.username,
            password: cfg.password,
          )
        : null,
  );
});

final serverConfigProvider =
    AsyncNotifierProvider<ServerConfigNotifier, ServerConfig?>(
  ServerConfigNotifier.new,
);

class ServerConfigNotifier extends AsyncNotifier<ServerConfig?> {
  @override
  Future<ServerConfig?> build() async {
    if (!AppStorage.isConfigured) return null;
    return _loadFromStorage();
  }

  ServerConfig? _loadFromStorage() {
    if (!AppStorage.isConfigured) return null;
    return ServerConfig(
      serverUrl: AppStorage.serverUrl!,
      username: AppStorage.username!,
      password: AppStorage.password!,
      userInfo: AppStorage.userInfo,
    );
  }

  Future<void> connect({
    required String url,
    required String username,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api = XtreamApi(
        baseUrl: url.trimRight().replaceAll(RegExp(r'/$'), ''),
        username: username.trim(),
        password: password.trim(),
      );

      final userInfo = await api.authenticate();

      final userInfoMap = userInfo['user_info'] as Map<String, dynamic>?;
      if (userInfoMap?['status']?.toString() != 'Active') {
        throw Exception('Cuenta inactiva o credenciales inválidas');
      }

      await AppStorage.saveServerConfig(
        url: url.trimRight().replaceAll(RegExp(r'/$'), ''),
        user: username.trim(),
        pass: password.trim(),
      );
      await AppStorage.saveUserInfo(userInfo);

      return ServerConfig(
        serverUrl: AppStorage.serverUrl!,
        username: AppStorage.username!,
        password: AppStorage.password!,
        userInfo: userInfo,
      );
    });
  }

  Future<void> disconnect() async {
    await AppStorage.clearConfig();
    state = const AsyncData(null);
  }
}
