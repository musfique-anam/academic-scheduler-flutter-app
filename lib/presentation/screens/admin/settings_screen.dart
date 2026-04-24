// lib/presentation/screens/admin/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';

  // Merge Rules variables
  bool _autoMergeByCode = true;
  bool _crossDepartmentMerge = false;
  int _maxBatchesPerMerge = 3;

  final List<String> _languages = ['English', 'বাংলা'];
  final List<String> _timeSlots = [
    'Slot 1: 9:30 - 11:00',
    'Slot 2: 11:10 - 12:40',
    'Slot 3: 14:00 - 15:30',
    'Slot 4: 15:40 - 17:10',
  ];

  final List<String> _workingDays = ['Friday', 'Saturday', 'Sunday', 'Monday', 'Tuesday'];
  List<String> _selectedDays = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    setState(() {
      _isDarkMode = themeProvider.isDarkMode;
      _notificationsEnabled = settingsProvider.notificationsEnabled;
      _selectedLanguage = settingsProvider.language;
      _selectedDays = settingsProvider.workingDays;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _resetToDefault,
            tooltip: 'Reset to default',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // General Settings Section
          const Text(
            'General Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Dark Mode Switch
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return SwitchListTile(
                      title: const Text('Dark Mode'),
                      subtitle: const Text('Enable dark theme'),
                      value: themeProvider.isDarkMode,
                      activeColor: const Color(0xFF1976D2),
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                        setState(() {
                          _isDarkMode = value;
                        });
                      },
                    );
                  },
                ),
                const Divider(height: 0),

                // Notifications Switch
                Consumer<SettingsProvider>(
                  builder: (context, settingsProvider, child) {
                    return SwitchListTile(
                      title: const Text('Notifications'),
                      subtitle: const Text('Receive push notifications'),
                      value: settingsProvider.notificationsEnabled,
                      activeColor: const Color(0xFF1976D2),
                      onChanged: (value) {
                        settingsProvider.toggleNotifications(value);
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        _showSnackBar(context,
                            value ? 'Notifications enabled' : 'Notifications disabled'
                        );
                      },
                    );
                  },
                ),
                const Divider(height: 0),

                // Language Selection
                ListTile(
                  leading: const Icon(Icons.language, color: Color(0xFF1976D2)),
                  title: const Text('Language'),
                  subtitle: Text(_selectedLanguage),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showLanguageDialog(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Academic Settings Section
          const Text(
            'Academic Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Time Slots
                ListTile(
                  leading: const Icon(Icons.access_time, color: Color(0xFF1976D2)),
                  title: const Text('Time Slots'),
                  subtitle: const Text('Configure class timings'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showTimeSlotsDialog(context),
                ),
                const Divider(height: 0),

                // Working Days
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: Color(0xFF1976D2)),
                  title: const Text('Working Days'),
                  subtitle: Text('${_selectedDays.length} days selected'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showWorkingDaysDialog(context),
                ),
                const Divider(height: 0),

                // Merge Rules - Updated with Checkboxes
                ListTile(
                  leading: const Icon(Icons.merge_type, color: Color(0xFF1976D2)),
                  title: const Text('Merge Rules'),
                  subtitle: const Text('Tap to configure'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showMergeRulesDialog(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // System Settings Section
          const Text(
            'System Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Backup Data
                ListTile(
                  leading: const Icon(Icons.backup, color: Color(0xFF1976D2)),
                  title: const Text('Backup Data'),
                  subtitle: const Text('Backup database to cloud'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showBackupDialog(context),
                ),
                const Divider(height: 0),

                // Restore Data
                ListTile(
                  leading: const Icon(Icons.restore, color: Color(0xFF1976D2)),
                  title: const Text('Restore Data'),
                  subtitle: const Text('Restore from backup'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showRestoreDialog(context),
                ),
                const Divider(height: 0),

                // About
                ListTile(
                  leading: const Icon(Icons.info, color: Color(0xFF1976D2)),
                  title: const Text('About'),
                  subtitle: const Text('App version 1.0.0'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Smart Academic Scheduler',
                      applicationVersion: '1.0.0',
                      applicationIcon: const FlutterLogo(size: 50),
                      applicationLegalese: 'Developed by Anonto & Arif\n'
                          'For Pundra University of Science & Technology',
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          '© 2024 All rights reserved',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Logout Button
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.currentUser != null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(context, authProvider),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  // Language Selection Dialog
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _languages.map((language) {
              return ListTile(
                title: Text(language),
                leading: Radio<String>(
                  value: language,
                  groupValue: _selectedLanguage,
                  activeColor: const Color(0xFF1976D2),
                  onChanged: (value) {
                    setState(() {
                      _selectedLanguage = value!;
                    });
                    Provider.of<SettingsProvider>(context, listen: false)
                        .setLanguage(value!);
                    Navigator.pop(context);
                    _showSnackBar(context, 'Language changed to $value');
                  },
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Time Slots Dialog
  void _showTimeSlotsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Time Slots'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _timeSlots.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_timeSlots[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showEditTimeSlotDialog(context, index),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showAddTimeSlotDialog(context);
              },
              child: const Text('Add New'),
            ),
          ],
        );
      },
    );
  }

  // Edit Time Slot Dialog
  void _showEditTimeSlotDialog(BuildContext context, int index) {
    final slotParts = _timeSlots[index].split(': ');
    final slotName = slotParts[0];
    final timeRange = slotParts[1].split(' - ');

    TextEditingController startController = TextEditingController(text: timeRange[0]);
    TextEditingController endController = TextEditingController(text: timeRange[1]);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $slotName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: startController,
                decoration: const InputDecoration(
                  labelText: 'Start Time',
                  hintText: '9:30',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: endController,
                decoration: const InputDecoration(
                  labelText: 'End Time',
                  hintText: '11:00',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Save time slot
                Navigator.pop(context);
                _showSnackBar(context, 'Time slot updated');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Add Time Slot Dialog
  void _showAddTimeSlotDialog(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    TextEditingController startController = TextEditingController();
    TextEditingController endController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Time Slot'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Slot Name',
                  hintText: 'Slot 5',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: startController,
                decoration: const InputDecoration(
                  labelText: 'Start Time',
                  hintText: '9:30',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: endController,
                decoration: const InputDecoration(
                  labelText: 'End Time',
                  hintText: '11:00',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showSnackBar(context, 'New time slot added');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Working Days Dialog
  void _showWorkingDaysDialog(BuildContext context) {
    List<String> tempSelected = List.from(_selectedDays);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Working Days'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _workingDays.map((day) {
                    return CheckboxListTile(
                      title: Text(day),
                      value: tempSelected.contains(day),
                      activeColor: const Color(0xFF1976D2),
                      onChanged: (checked) {
                        setState(() {
                          if (checked!) {
                            tempSelected.add(day);
                          } else {
                            tempSelected.remove(day);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedDays = tempSelected;
                    });
                    Provider.of<SettingsProvider>(context, listen: false)
                        .setWorkingDays(tempSelected);
                    Navigator.pop(context);
                    _showSnackBar(context, 'Working days updated');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Merge Rules Dialog - Updated with multiple select
  void _showMergeRulesDialog(BuildContext context) {
    bool tempAutoMerge = _autoMergeByCode;
    bool tempCrossMerge = _crossDepartmentMerge;
    int tempMaxBatches = _maxBatchesPerMerge;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Merge Rules'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Auto-merge by course code
                  CheckboxListTile(
                    title: const Text('Auto-merge by course code'),
                    subtitle: const Text('Merge batches with same course'),
                    value: tempAutoMerge,
                    activeColor: const Color(0xFF1976D2),
                    onChanged: (value) {
                      setState(() {
                        tempAutoMerge = value!;
                      });
                    },
                  ),

                  // Cross-department merge
                  CheckboxListTile(
                    title: const Text('Cross-department merge'),
                    subtitle: const Text('Allow merging across departments'),
                    value: tempCrossMerge,
                    activeColor: const Color(0xFF1976D2),
                    onChanged: (value) {
                      setState(() {
                        tempCrossMerge = value!;
                      });
                    },
                  ),

                  const Divider(height: 24),

                  // Max batches per merge
                  ListTile(
                    title: const Text('Max batches per merge'),
                    subtitle: Text('Currently: $tempMaxBatches'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            if (tempMaxBatches > 2) {
                              setState(() {
                                tempMaxBatches--;
                              });
                            }
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '$tempMaxBatches',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            if (tempMaxBatches < 5) {
                              setState(() {
                                tempMaxBatches++;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _autoMergeByCode = tempAutoMerge;
                      _crossDepartmentMerge = tempCrossMerge;
                      _maxBatchesPerMerge = tempMaxBatches;
                    });
                    Navigator.pop(context);
                    _showSnackBar(context, 'Merge rules updated');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Backup Dialog
  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Backup Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_upload, size: 48, color: Color(0xFF1976D2)),
              const SizedBox(height: 16),
              const Text('Create a backup of all data?'),
              const SizedBox(height: 8),
              Text(
                'Last backup: Never',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showBackupProgress(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
              ),
              child: const Text('Backup Now'),
            ),
          ],
        );
      },
    );
  }

  // Backup Progress Dialog
  void _showBackupProgress(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
              ),
              const SizedBox(height: 16),
              const Text('Creating backup...'),
              const SizedBox(height: 8),
              Text(
                'Please wait',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        );
      },
    );

    // Simulate backup process
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close progress dialog
      _showSnackBar(context, 'Backup completed successfully!', isSuccess: true);
    });
  }

  // Restore Dialog
  void _showRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restore Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_download, size: 48, color: Color(0xFF1976D2)),
              const SizedBox(height: 16),
              const Text('Select a backup to restore:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Backup 1'),
                      subtitle: const Text('2024-02-27 10:30 AM'),
                      leading: Radio(
                        value: 1,
                        groupValue: 1,
                        activeColor: const Color(0xFF1976D2),
                        onChanged: (value) {},
                      ),
                    ),
                    ListTile(
                      title: const Text('Backup 2'),
                      subtitle: const Text('2024-02-26 05:15 PM'),
                      leading: Radio(
                        value: 2,
                        groupValue: 1,
                        activeColor: const Color(0xFF1976D2),
                        onChanged: (value) {},
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showRestoreConfirmDialog(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
              ),
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );
  }

  // Restore Confirm Dialog
  void _showRestoreConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Restore'),
          content: const Text(
            'This will overwrite all current data. Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close confirm dialog
                _showRestoreProgress(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );
  }

  // Restore Progress Dialog
  void _showRestoreProgress(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
              ),
              const SizedBox(height: 16),
              const Text('Restoring data...'),
              const SizedBox(height: 8),
              Text(
                'Please wait',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        );
      },
    );

    // Simulate restore process
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close progress dialog
      _showSnackBar(context, 'Data restored successfully!', isSuccess: true);
    });
  }

  // Reset to Default
  void _resetToDefault() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Settings'),
          content: const Text('Reset all settings to default?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isDarkMode = false;
                  _notificationsEnabled = true;
                  _selectedLanguage = 'English';
                  _selectedDays = ['Friday', 'Saturday', 'Sunday', 'Monday', 'Tuesday'];
                  _autoMergeByCode = true;
                  _crossDepartmentMerge = false;
                  _maxBatchesPerMerge = 3;
                });

                final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
                final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

                if (themeProvider.isDarkMode) {
                  themeProvider.toggleTheme();
                }

                settingsProvider.resetToDefault();

                Navigator.pop(context);
                _showSnackBar(context, 'Settings reset to default');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  // Logout Dialog
  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                authProvider.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // Show SnackBar
  void _showSnackBar(BuildContext context, String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}