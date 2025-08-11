// File: providers/profile_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:event_management/models/user.dart';
import 'package:event_management/repository/user_repository.dart';

class ProfileProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _userRepository = UserRepository();

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _error;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isEditing => _isEditing;
  bool get isSaving => _isSaving;
  String? get error => _error;

  // Load current user data
  Future<void> loadUserData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user != null) {
        _currentUser = await _userRepository.getUserById(user.uid);
        if (_currentUser == null) {
          _error = 'User data not found';
        }
      } else {
        _error = 'No user logged in';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load user data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle edit mode
  void toggleEditMode() {
    _isEditing = !_isEditing;
    _error = null;
    notifyListeners();
  }

  // Cancel editing
  void cancelEditing() {
    _isEditing = false;
    _error = null;
    notifyListeners();
  }

  // Update user data
  Future<bool> updateUserData({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
  }) async {
    try {
      _isSaving = true;
      _error = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Create updated user model
      final updatedUser = _currentUser?.copyWith(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
      );

      if (updatedUser == null) {
        throw Exception('Current user data not available');
      }

      // Update using repository
      final success = await _userRepository.updateUser(updatedUser);

      if (!success) {
        throw Exception('Failed to update user in database');
      }

      // Update Firebase Auth email if changed (using new method)
      if (email != user.email) {
        try {
          await user.verifyBeforeUpdateEmail(email);
          // Note: User will need to verify the new email before it takes effect
          _error =
              'Profile updated. Please check your email to verify the new email address.';
        } catch (e) {
          // If email update fails, we still want to save other profile changes
          _error = 'Profile updated, but email verification failed: $e';
        }
      }

      // Update local user model
      _currentUser = updatedUser;

      _isEditing = false;
      _isSaving = false;
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Failed to update profile: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      _isEditing = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to logout: $e';
      notifyListeners();
    }
  }

  // Clear data
  void clearData() {
    _currentUser = null;
    _isLoading = false;
    _isEditing = false;
    _isSaving = false;
    _error = null;
    notifyListeners();
  }
}

// Add copyWith method to UserModel
extension UserModelCopyWith on UserModel {
  UserModel copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? group,
    List<String>? subGroups,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      group: group ?? this.group,
      subGroups: subGroups ?? this.subGroups,
    );
  }
}
