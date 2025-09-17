import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../core/services/api_service.dart';
import 'auth_provider.dart';

class UserProvider extends ChangeNotifier {
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;
  final ApiService _apiService = ApiService.instance;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get users by role
  List<UserModel> getUsersByRole(UserRole role) {
    return _users.where((user) => user.role == role).toList();
  }

  // Get makhdoum users (congregants)
  List<UserModel> get makhdoumUsers => getUsersByRole(UserRole.makhdoum);

  // Get khadem users (servants/admins)
  List<UserModel> get khademUsers => getUsersByRole(UserRole.khadem);

  // Search users by name or email
  List<UserModel> searchUsers(String query) {
    if (query.isEmpty) return _users;
    
    return _users.where((user) {
      return user.name.toLowerCase().contains(query.toLowerCase()) ||
             user.email.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Filter users by additional data
  List<UserModel> filterUsersByData(String key, dynamic value) {
    return _users.where((user) {
      return user.additionalData[key] == value;
    }).toList();
  }

  // Update user data
  Future<bool> updateUserData(String userId, Map<String, dynamic> newData, BuildContext? context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.updateMyProfile(newData);
      
      // Update local user data with response from server
      final userIndex = _users.indexWhere((user) => user.id == userId);
      if (userIndex != -1) {
        final currentData = _users[userIndex].additionalData;
        final mergedData = {...currentData, ...newData};
        
        final updatedUser = _users[userIndex].copyWith(
          additionalData: response['additionalData'] ?? mergedData,
        );
        _users[userIndex] = updatedUser;
      }
      
      // Also update the current user in auth provider if available
      if (context != null) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.currentUser?.id == userId) {
          await authProvider.refreshCurrentUser();
        }
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

  // Add user data (for makhdoum role - can only add missing data)
  Future<bool> addUserData(String userId, Map<String, dynamic> newData, BuildContext? context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userIndex = _users.indexWhere((user) => user.id == userId);
      if (userIndex != -1) {
        final currentData = _users[userIndex].additionalData;
        final filteredData = <String, dynamic>{};
        
        // Only add data that doesn't already exist
        newData.forEach((key, value) {
          if (!currentData.containsKey(key) || currentData[key] == null) {
            filteredData[key] = value;
          }
        });

        if (filteredData.isNotEmpty) {
          // Merge with existing data and send to API
          final mergedData = {...currentData, ...filteredData};
          final response = await _apiService.updateMyProfile({'additionalData': mergedData});
          
          // Update local user data with response from server
          final updatedUser = _users[userIndex].copyWith(
            additionalData: response['additionalData'] ?? mergedData,
          );
          _users[userIndex] = updatedUser;
        }
        
        // Also update the current user in auth provider if available
        if (context != null) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.currentUser?.id == userId) {
            await authProvider.refreshCurrentUser();
          }
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update profile image
  Future<bool> updateProfileImage(String userId, String imagePath, BuildContext? context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final imageUrl = await _apiService.uploadProfileImage(imagePath);
      
      final userIndex = _users.indexWhere((user) => user.id == userId);
      if (userIndex != -1) {
        final updatedUser = _users[userIndex].copyWith(profileImage: imageUrl);
        _users[userIndex] = updatedUser;
      }
      
      // Also update the current user in auth provider if available
      if (context != null) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.currentUser?.id == userId) {
          await authProvider.updateProfileImage(imagePath);
        }
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

  // Load users from API
  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getUsers();
      _users = response.map((user) => UserModel.fromJson(user)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load users from auth provider
  void setUsers(List<UserModel> users) {
    _users = users;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  UserModel? getUserById(String id) {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }
}