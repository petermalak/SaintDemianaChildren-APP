import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../core/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  final ApiService _apiService = ApiService.instance;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      _currentUser = UserModel.fromJson(response['user']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      // Even if logout fails on server, clear local state
    } finally {
      _currentUser = null;
      _errorMessage = null;
      notifyListeners();
    }
  }

  // Update user profile
  Future<UserModel?> updateUserProfile(Map<String, dynamic> updateData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response =
          await _apiService.updateUser(_currentUser!.id, updateData);
      final updatedUser = UserModel.fromJson(response);

      // Update current user if it's the same user
      if (_currentUser!.id == updatedUser.id) {
        _currentUser = updatedUser;
      }

      _isLoading = false;
      notifyListeners();
      return updatedUser;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get all users (for khadem role)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _apiService.getUsers();
      return response.map((user) => UserModel.fromJson(user)).toList();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String id) async {
    try {
      final response = await _apiService.getUserById(id);
      return UserModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Add new user (for khadem role)
  Future<UserModel?> addUser(UserModel user) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.createUser(user.toJson());
      final createdUser = UserModel.fromJson(response);
      _isLoading = false;
      notifyListeners();
      return createdUser;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Add new user with raw data (for forms)
  Future<UserModel?> addUserWithData(Map<String, dynamic> userData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.createUser(userData);
      final createdUser = UserModel.fromJson(response);
      _isLoading = false;
      notifyListeners();
      return createdUser;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Update user (for khadem role)
  Future<bool> updateUser(UserModel updatedUser) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.updateUser(updatedUser.id, updatedUser.toJson());
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete user (for khadem role)
  Future<bool> deleteUser(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.deleteUser(userId);

      // Clear error message on success
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Set more user-friendly error messages
      if (e.toString().contains('Foreign key constraint')) {
        _errorMessage =
            'Cannot delete user. User has related data (classes, attendance records) that must be handled first.';
      } else if (e.toString().contains('404')) {
        _errorMessage = 'User not found.';
      } else if (e.toString().contains('403')) {
        _errorMessage = 'You do not have permission to delete this user.';
      } else {
        _errorMessage = 'Failed to delete user: ${e.toString()}';
      }

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update current user profile
  Future<bool> updateMyProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.updateMyProfile(data);
      _currentUser = UserModel.fromJson(response);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Refresh current user data from server
  Future<bool> refreshCurrentUser() async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getMyProfile();
      _currentUser = UserModel.fromJson(response);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update profile image
  Future<bool> updateProfileImage(String imagePath) async {
    _isLoading = true;
    notifyListeners();

    try {
      final imageUrl = await _apiService.uploadProfileImage(imagePath);
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(profileImage: imageUrl);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
