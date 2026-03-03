import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

const _keyNickname = 'profile_nickname';
const _keyImagePath = 'profile_image_path';
const _keyIsLoggedIn = 'auth_is_logged_in';

/// Persists and loads the current user's profile (nickname + face photo).
class ProfileRepository {
  ProfileRepository._();
  static final ProfileRepository instance = ProfileRepository._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<String?> getNickname() async {
    final prefs = await _preferences;
    return prefs.getString(_keyNickname);
  }

  Future<void> setNickname(String? value) async {
    final prefs = await _preferences;
    if (value == null || value.trim().isEmpty) {
      await prefs.remove(_keyNickname);
    } else {
      await prefs.setString(_keyNickname, value.trim());
    }
  }

  Future<String?> getProfileImagePath() async {
    final prefs = await _preferences;
    final p = prefs.getString(_keyImagePath);
    if (p != null && File(p).existsSync()) return p;
    return null;
  }

  Future<void> setProfileImagePath(String? value) async {
    final prefs = await _preferences;
    if (value == null || value.isEmpty) {
      await prefs.remove(_keyImagePath);
    } else {
      await prefs.setString(_keyImagePath, value);
    }
  }

  /// Save a new profile image from a source path (e.g. from image_picker).
  /// Copies the file to app storage and saves the new path.
  Future<String?> saveProfileImageFromPath(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final name = 'profile_face_${DateTime.now().millisecondsSinceEpoch}${path.extension(sourcePath)}';
    final dest = File(path.join(dir.path, 'opah_profile', name));
    await dest.parent.create(recursive: true);
    await File(sourcePath).copy(dest.path);
    await setProfileImagePath(dest.path);
    return dest.path;
  }

  Future<void> clearProfileImage() async {
    await setProfileImagePath(null);
  }

  /// True if user has set at least a nickname or a profile image.
  Future<bool> isProfileComplete() async {
    final nickname = await getNickname();
    final imagePath = await getProfileImagePath();
    return (nickname != null && nickname.trim().isNotEmpty) || imagePath != null;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await _preferences;
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<void> setLoggedIn(bool value) async {
    final prefs = await _preferences;
    await prefs.setBool(_keyIsLoggedIn, value);
  }

  Future<void> logout() async {
    await setLoggedIn(false);
  }
}
