import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../models/class_model.dart';
import '../models/class_membership_model.dart';
import '../features/authentication/model/user_model.dart';

class ClassProvider with ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<ClassModel> _classes = [];
  final List<ClassMembershipModel> _memberships = [];
  List<UserModel> _myMembers = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ClassModel> get classes => _classes;
  List<ClassMembershipModel> get memberships => _memberships;
  List<UserModel> get myMembers => _myMembers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Load all classes
  Future<void> loadClasses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getClasses();

      _classes = response.map((json) {
        return ClassModel.fromJson(json);
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load my classes
  Future<void> loadMyClasses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getMyClasses();
      _classes = response.map((json) => ClassModel.fromJson(json)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load my members (for khadem)
  Future<void> loadMyMembers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getMyMembers();
      _myMembers = response.map((json) => UserModel.fromJson(json)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get class by ID
  Future<ClassModel?> getClassById(String classId) async {
    try {
      final response = await _apiService.getClassById(classId);
      return ClassModel.fromJson(response);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Create class
  Future<bool> createClass(ClassModel classModel) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.createClass(classModel.toJson());
      final newClass = ClassModel.fromJson(response);
      _classes.add(newClass);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update class
  Future<bool> updateClass(ClassModel classModel) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await _apiService.updateClass(classModel.id, classModel.toJson());
      final updatedClass = ClassModel.fromJson(response);

      final index = _classes.indexWhere((c) => c.id == classModel.id);
      if (index != -1) {
        _classes[index] = updatedClass;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete class
  Future<bool> deleteClass(String classId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteClass(classId);
      _classes.removeWhere((c) => c.id == classId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get class members
  Future<Map<String, List<UserModel>>?> getClassMembers(String classId) async {
    try {
      final response = await _apiService.getClassMembers(classId);

      final khadem = (response['khadem'] as List)
          .map((json) => UserModel.fromJson(json))
          .toList();

      final makhdoum = (response['makhdoum'] as List)
          .map((json) => UserModel.fromJson(json))
          .toList();

      return {
        'khadem': khadem,
        'makhdoum': makhdoum,
      };
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Add class member
  Future<bool> addClassMember(String classId, String userId, UserRole role,
      {String? notes}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final memberData = {
        'userId': userId,
        'role': role.name,
        'notes': notes,
      };

      print(
          'ClassProvider: Adding member to class $classId with data: $memberData');
      await _apiService.addClassMember(classId, memberData);
      print('ClassProvider: Successfully added member to class');

      // Refresh the class data
      await loadClasses();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('ClassProvider: Error adding member to class: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Remove class member
  Future<bool> removeClassMember(String classId, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.removeClassMember(classId, userId);

      // Refresh the class data
      await loadClasses();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Set more user-friendly error messages
      if (e.toString().contains('404')) {
        _error = 'User not found in this class or class does not exist.';
      } else if (e.toString().contains('403')) {
        _error =
            'You do not have permission to remove this member from the class.';
      } else if (e.toString().contains('500')) {
        _error =
            'Server error occurred while removing member. Please try again.';
      } else {
        _error = 'Failed to remove member from class: ${e.toString()}';
      }

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get class members with detailed information (raw API response)
  Future<Map<String, dynamic>> getClassMembersRaw(String classId) async {
    try {
      return await _apiService.getClassMembers(classId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Bulk assign users to class
  Future<void> bulkAssignUsers(
      String classId, List<String> userIds, UserRole role) async {
    try {
      for (final userId in userIds) {
        await _apiService.addClassMember(classId, {
          'userId': userId,
          'role': role.name,
        });
      }
      await loadClasses(); // Refresh classes list
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Transfer users between classes
  Future<void> transferUsers(
      String fromClassId, String toClassId, List<String> userIds) async {
    try {
      for (final userId in userIds) {
        // Remove from old class
        await _apiService.removeClassMember(fromClassId, userId);

        // Get user's role in old class to maintain it
        final memberships = await getClassMembersRaw(fromClassId);
        final userMembership = memberships['memberships']?.firstWhere(
          (m) => m['userId'] == userId,
          orElse: () => null,
        );

        if (userMembership != null) {
          // Add to new class with same role
          await _apiService.addClassMember(toClassId, {
            'userId': userId,
            'role': userMembership['role'],
          });
        }
      }
      await loadClasses(); // Refresh classes list
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Get classes for a specific user
  List<ClassModel> getClassesForUser(String userId) {
    // This would need to be implemented based on your specific requirements
    // For now, return all classes
    return _classes;
  }

  // Get members for a specific class
  List<UserModel> getMembersForClass(String classId) {
    // This would need to be implemented based on your specific requirements
    // For now, return my members
    return _myMembers;
  }

  // Check if user is in class
  bool isUserInClass(String userId, String classId) {
    // This would need to be implemented based on your specific requirements
    return false;
  }

  // Get active classes only
  List<ClassModel> get activeClasses {
    return _classes.where((c) => c.isActive).toList();
  }

  // Get classes by capacity
  List<ClassModel> getClassesByCapacity({bool? hasSpace}) {
    if (hasSpace == null) return _classes;

    return _classes
        .where((c) => hasSpace ? c.canAddMember : c.isAtCapacity)
        .toList();
  }

  // Search classes
  List<ClassModel> searchClasses(String query) {
    if (query.isEmpty) return _classes;

    final lowercaseQuery = query.toLowerCase();
    return _classes
        .where((c) =>
            c.name.toLowerCase().contains(lowercaseQuery) ||
            (c.description?.toLowerCase().contains(lowercaseQuery) ?? false) ||
            (c.location?.toLowerCase().contains(lowercaseQuery) ?? false))
        .toList();
  }
}
