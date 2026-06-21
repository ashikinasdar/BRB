import '../models/user_profile.dart';
import '../services/profile_service.dart';

/// Mediates between the UI/provider layer and [ProfileService].
/// Keeps business rules (validation, error translation) out of the UI.
class ProfileRepository {
  final ProfileService _service;

  ProfileRepository({ProfileService? service})
      : _service = service ?? ProfileService();

  Stream<UserProfile?> watchProfile() => _service.profileStream();

  Future<UserProfile> getOrCreateProfile() => _service.fetchOrCreateProfile();

  /// Validates then persists editable fields.
  /// Throws a user-readable [Exception] on validation failure.
  Future<void> saveProfile({
    required String fullName,
    required String phoneNumber,
    String? profileImageBase64,
  }) async {
    _validateFullName(fullName);
    _validatePhoneNumber(phoneNumber);

    await _service.updateProfile(
      fullName: fullName,
      phoneNumber: phoneNumber,
      profileImageBase64: profileImageBase64,
    );
  }

  Future<void> saveProfileImage(List<int> imageBytes) =>
      _service.uploadProfileImage(imageBytes);

 

  void _validateFullName(String value) {
    if (value.trim().isEmpty) throw Exception('Full name is required.');
    if (value.trim().length < 3) throw Exception('Full name must be at least 3 characters.');
  }

  void _validatePhoneNumber(String value) {
    if (value.trim().isEmpty) throw Exception('Phone number is required.');
    // Malaysian format: +601X-XXXXXXX  or  01X-XXXXXXX  (9–11 digits after prefix)
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
    final regex = RegExp(r'^(\+?60|0)1[0-9]{7,9}$');
    if (!regex.hasMatch(cleaned)) {
      throw Exception('Enter a valid Malaysian phone number (e.g. 0123456789).');
    }
  }
}
