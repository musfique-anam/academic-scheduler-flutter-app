// lib/providers/settings_provider.dart
import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  bool _notificationsEnabled = true;
  String _language = 'English';
  List<String> _workingDays = ['Friday', 'Saturday', 'Sunday', 'Monday', 'Tuesday'];

  bool get notificationsEnabled => _notificationsEnabled;
  String get language => _language;
  List<String> get workingDays => _workingDays;

  void toggleNotifications(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  void setLanguage(String language) {
    _language = language;
    notifyListeners();
  }

  void setWorkingDays(List<String> days) {
    _workingDays = days;
    notifyListeners();
  }

  void resetToDefault() {
    _notificationsEnabled = true;
    _language = 'English';
    _workingDays = ['Friday', 'Saturday', 'Sunday', 'Monday', 'Tuesday'];
    notifyListeners();
  }
}