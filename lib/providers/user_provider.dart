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

  // Filter users by specific field
  List<UserModel> filterUsersByField(String field, dynamic value) {
    return _users.where((user) {
      switch (field) {
        case 'name':
          return user.name.toLowerCase().contains(value.toString().toLowerCase());
        case 'email':
          return user.email.toLowerCase().contains(value.toString().toLowerCase());
        case 'phoneNumber':
          return user.phoneNumber.contains(value.toString());
        case 'role':
          return user.role.toString().contains(value.toString());
        case 'fathersPhoneNumber':
          return user.fathersPhoneNumber?.contains(value.toString()) ?? false;
        case 'mothersPhoneNumber':
          return user.mothersPhoneNumber?.contains(value.toString()) ?? false;
        case 'address':
          return user.address?.toLowerCase().contains(value.toString().toLowerCase()) ?? false;
        case 'fatherOfConfession':
          return user.fatherOfConfession?.toLowerCase().contains(value.toString().toLowerCase()) ?? false;
        default:
          return false;
      }
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
        final updatedUser = UserModel.fromJson(response);
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

  // Update user profile (for khadem to update makhdoum profiles - excludes email and password)
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> profileData, BuildContext? context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.updateUserProfile(userId, profileData);
      
      // Update local user data with response from server
      final userIndex = _users.indexWhere((user) => user.id == userId);
      if (userIndex != -1) {
        final updatedUser = UserModel.fromJson(response);
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
        final currentUser = _users[userIndex];
        final filteredData = <String, dynamic>{};
        
        // Only add data that doesn't already exist or is null/empty
        newData.forEach((key, value) {
          bool shouldAdd = false;
          switch (key) {
            case 'fathersPhoneNumber':
              shouldAdd = currentUser.fathersPhoneNumber == null || currentUser.fathersPhoneNumber!.isEmpty;
              break;
            case 'mothersPhoneNumber':
              shouldAdd = currentUser.mothersPhoneNumber == null || currentUser.mothersPhoneNumber!.isEmpty;
              break;
            case 'birthdate':
              shouldAdd = currentUser.birthdate == null;
              break;
            case 'address':
              shouldAdd = currentUser.address == null || currentUser.address!.isEmpty;
              break;
            case 'addressLocationLink':
              shouldAdd = currentUser.addressLocationLink == null || currentUser.addressLocationLink!.isEmpty;
              break;
            case 'fatherOfConfession':
              shouldAdd = currentUser.fatherOfConfession == null || currentUser.fatherOfConfession!.isEmpty;
              break;
          }
          
          if (shouldAdd) {
            filteredData[key] = value;
          }
        });

        if (filteredData.isNotEmpty) {
          final response = await _apiService.updateMyProfile(filteredData);
          
          // Update local user data with response from server
          final updatedUser = UserModel.fromJson(response);
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