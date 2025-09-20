import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../models/class_model.dart';
import '../models/class_membership_model.dart';
import '../models/user_model.dart';

class ClassProvider with ChangeNotifier {
  final ApiService _apiService = ApiService.instance;
  
  List<ClassModel> _classes = [];
  List<ClassMembershipModel> _memberships = [];
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
      _classes = response.map((json) => ClassModel.fromJson(json)).toList();
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
      final response = await _apiService.updateClass(classModel.id, classModel.toJson());
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
  Future<bool> addClassMember(String classId, String userId, UserRole role, {String? notes}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final memberData = {
        'userId': userId,
        'role': role.name,
        'notes': notes,
      };
      
      await _apiService.addClassMember(classId, memberData);
      
      // Refresh the class data
      await loadClasses();
      
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
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
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
    
    return _classes.where((c) => hasSpace ? c.canAddMember : c.isAtCapacity).toList();
  }

  // Search classes
  List<ClassModel> searchClasses(String query) {
    if (query.isEmpty) return _classes;
    
    final lowercaseQuery = query.toLowerCase();
    return _classes.where((c) => 
      c.name.toLowerCase().contains(lowercaseQuery) ||
      (c.description?.toLowerCase().contains(lowercaseQuery) ?? false) ||
      (c.location?.toLowerCase().contains(lowercaseQuery) ?? false)
    ).toList();
  }
}
