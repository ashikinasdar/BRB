import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../repositories/profile_repository.dart';

enum ProfileStatus { idle, loading, saving, imageUploading, success, error }

/// State management for the profile feature using Provider (ChangeNotifier),
/// consistent with the existing [AuthProvider] pattern in the project.
class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repo;

  ProfileProvider({ProfileRepository? repository})
      : _repo = repository ?? ProfileRepository();

  // ── State ──────────────────────────────────────────────────────────────────

  ProfileStatus _status = ProfileStatus.idle;
  UserProfile? _profile;
  String? _errorMessage;
  String? _successMessage;

  ProfileStatus get status => _status;
  UserProfile? get profile => _profile;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  bool get isLoading => _status == ProfileStatus.loading;
  bool get isSaving => _status == ProfileStatus.saving;
  bool get isImageUploading => _status == ProfileStatus.imageUploading;
  bool get isBusy =>
      _status == ProfileStatus.loading ||
      _status == ProfileStatus.saving ||
      _status == ProfileStatus.imageUploading;

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Called when the profile screen initialises.
  Future<void> loadProfile() async {
    _setStatus(ProfileStatus.loading);
    try {
      _profile = await _repo.getOrCreateProfile();
      _setStatus(ProfileStatus.idle);
    } catch (e) {
      _setError('Failed to load profile: ${e.toString()}');
    }
  }

  /// Saves the edited profile fields.
  Future<bool> saveProfile({
    required String fullName,
    required String phoneNumber,
    String? newProfileImageBase64,
  }) async {
    _setStatus(ProfileStatus.saving);
    try {
      await _repo.saveProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        profileImageBase64: newProfileImageBase64,
      );
      // Optimistically update local state
      if (_profile != null) {
        _profile = _profile!.copyWith(
          fullName: fullName,
          phoneNumber: phoneNumber,
          profileImageBase64: newProfileImageBase64,
        );
      }
      _setSuccess('Profile updated successfully!');
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  /// Uploads a new profile image.
  Future<bool> uploadProfileImage(List<int> imageBytes) async {
    _setStatus(ProfileStatus.imageUploading);
    try {
      await _repo.saveProfileImage(imageBytes);
      // Refresh profile to get updated base64
      _profile = await _repo.getOrCreateProfile();
      _setSuccess('Profile picture updated!');
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void _setStatus(ProfileStatus s) {
    _status = s;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _status = ProfileStatus.error;
    _errorMessage = msg;
    _successMessage = null;
    notifyListeners();
  }

  void _setSuccess(String msg) {
    _status = ProfileStatus.success;
    _successMessage = msg;
    _errorMessage = null;
    notifyListeners();
  }
}
