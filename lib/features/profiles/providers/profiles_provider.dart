import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/app_storage.dart';
import '../../../shared/models/profile_model.dart';

// Increment to force profile-dependent widgets to rebuild
final profilesRefreshProvider = StateProvider<int>((ref) => 0);

// Full list of profiles
final profilesListProvider = Provider<List<ProfileModel>>((ref) {
  ref.watch(profilesRefreshProvider);
  return AppStorage.profiles;
});

// Currently active profile
final activeProfileProvider = Provider<ProfileModel?>((ref) {
  ref.watch(profilesRefreshProvider);
  final list = ref.watch(profilesListProvider);
  if (list.isEmpty) return null;
  return list.firstWhere(
    (p) => p.id == AppStorage.activeProfileId,
    orElse: () => list.first,
  );
});

// True once a profile has been chosen in this session
final profileSelectedProvider = StateProvider<bool>((ref) => false);
