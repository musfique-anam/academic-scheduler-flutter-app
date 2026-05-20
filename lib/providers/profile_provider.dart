// lib/providers/profile_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';

class ProfileProvider extends ChangeNotifier {
  // Profile image
  File? _profileImage;
  File? _coverImage;

  // Basic info
  String? _phoneNumber;
  String? _joinDate;
  String? _department;
  String? _address;

  // Missing fields - add these
  String? _bio;
  String? _gender;
  DateTime? _birthDate;

  // Stats
  int _totalActivities = 0;
  int _totalClasses = 0;
  int _totalReviews = 0;

  // Recent activities
  List<Map<String, dynamic>> _recentActivities = [];

  // ========== Getters ==========
  File? get profileImage => _profileImage;
  File? get coverImage => _coverImage;
  String? get phoneNumber => _phoneNumber;
  String? get joinDate => _joinDate;
  String? get department => _department;
  String? get address => _address;

  // New getters
  String? get bio => _bio;
  String? get gender => _gender;
  DateTime? get birthDate => _birthDate;

  int get totalActivities => _totalActivities;
  int get totalClasses => _totalClasses;
  int get totalReviews => _totalReviews;
  List<Map<String, dynamic>> get recentActivities => _recentActivities;

  // ========== Methods ==========
  Future<void> loadProfileData() async {
    // Load data from database or shared preferences
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate loading

    // Sample data
    _phoneNumber = '+880 1712345678';
    _joinDate = 'January 15, 2024';
    _department = 'Computer Science & Engineering';
    _address = 'PUST, Pabna-6600';

    // New fields with sample data
    _bio = 'Administrator at Pundra University of Science & Technology. Passionate about education technology.';
    _gender = 'Male';
    _birthDate = DateTime(1990, 1, 1);

    _totalActivities = 156;
    _totalClasses = 45;
    _totalReviews = 28;

    _recentActivities = [
      {
        'icon': Icons.edit,
        'title': 'Updated profile information',
        'time': '2 hours ago',
        'color': Colors.blue,
      },
      {
        'icon': Icons.lock,
        'title': 'Changed password',
        'time': 'Yesterday',
        'color': Colors.green,
      },
      {
        'icon': Icons.schedule,
        'title': 'Generated new routine',
        'time': '2 days ago',
        'color': Colors.orange,
      },
    ];

    notifyListeners();
  }

  // Profile image methods
  Future<void> updateProfileImage(File image) async {
    _profileImage = image;
    notifyListeners();
    // TODO: Save to database/storage
  }

  Future<void> updateCoverImage(File image) async {
    _coverImage = image;
    notifyListeners();
    // TODO: Save to database/storage
  }

  // Update profile fields
  Future<void> updateProfileField(String field, String value) async {
    switch (field) {
      case 'name':
      // Update name in AuthProvider
        break;
      case 'email':
      // Update email in AuthProvider
        break;
      case 'phone':
        _phoneNumber = value;
        break;
      case 'department':
        _department = value;
        break;
      case 'address':
        _address = value;
        break;
    // New cases
      case 'bio':
        _bio = value;
        break;
      case 'gender':
        _gender = value;
        break;
      case 'birthDate':
        if (value.isNotEmpty) {
          _birthDate = DateTime.parse(value);
        }
        break;
    }
    notifyListeners();

    // Add to recent activities
    _addActivity('Updated $field', Icons.edit, Colors.blue);

    // TODO: Save to database
  }

  // Add activity
  void _addActivity(String title, IconData icon, Color color) {
    _recentActivities.insert(0, {
      'icon': icon,
      'title': title,
      'time': 'Just now',
      'color': color,
    });

    // Keep only last 10 activities
    if (_recentActivities.length > 10) {
      _recentActivities = _recentActivities.sublist(0, 10);
    }

    notifyListeners();
  }

  // Clear all data
  void clear() {
    _profileImage = null;
    _coverImage = null;
    _phoneNumber = null;
    _joinDate = null;
    _department = null;
    _address = null;
    _bio = null;
    _gender = null;
    _birthDate = null;
    _totalActivities = 0;
    _totalClasses = 0;
    _totalReviews = 0;
    _recentActivities = [];
    notifyListeners();
  }
}