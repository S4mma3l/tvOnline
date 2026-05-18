import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/supabase/supabase_service.dart';

// Current logged-in user profile from Supabase
final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, Map<String, dynamic>?>(
  UserProfileNotifier.new,
);

class UserProfileNotifier extends AsyncNotifier<Map<String, dynamic>?> {
  @override
  Future<Map<String, dynamic>?> build() async {
    final email = AppStorage.userInfo?['user_info']?['email']?.toString();
    if (email == null || email.isEmpty) return null;
    return SupabaseService.getUserByEmail(email);
  }

  Future<Map<String, dynamic>> ensureRegistered({
    required String email,
    required String fullName,
    String? phone,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final xtreamUser = AppStorage.username;
      return SupabaseService.registerUser(
        email: email,
        fullName: fullName,
        phone: phone,
        xtreamUser: xtreamUser,
      );
    });
    return state.value!;
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final user = state.value;
    if (user == null) return;
    await SupabaseService.updateUser(user['id'] as String, data);
    ref.invalidateSelf();
  }

  void refresh() => ref.invalidateSelf();
}

// Active subscription for current user
final activeSubscriptionProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  if (profile == null) return null;
  return SupabaseService.getActiveSubscription(profile['id'] as String);
});

// Payment history for current user
final paymentHistoryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  if (profile == null) return [];
  return SupabaseService.getUserPayments(profile['id'] as String);
});
