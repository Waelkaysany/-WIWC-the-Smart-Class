import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

const _profilePicPrefKey = 'wiwc_profile_pic_path';

/// Provider that persists the profile picture path to disk.
final profilePicProvider =
    StateNotifierProvider<ProfilePicNotifier, String?>((ref) {
  return ProfilePicNotifier();
});

class ProfilePicNotifier extends StateNotifier<String?> {
  ProfilePicNotifier() : super(null) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_profilePicPrefKey);
    if (saved != null && File(saved).existsSync()) {
      state = saved;
    }
  }

  /// Copy the picked image to a permanent location and save the path.
  Future<void> saveProfilePic(File pickedFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final savedPath = '${appDir.path}/profile_pic.jpg';
    await pickedFile.copy(savedPath);
    state = savedPath;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profilePicPrefKey, savedPath);
  }
}
