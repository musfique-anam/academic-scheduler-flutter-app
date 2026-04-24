import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/room_provider.dart';
import '../../../providers/department_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../data/models/room_model.dart';
import '../../../data/models/department_model.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _roomNoController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _equipmentController = TextEditingController();
  final TextEditingController _pcTotalController = TextEditingController();
  final TextEditingController _pcActiveController = TextEditingController();

  String _selectedType = 'Theory';
  int _selectedFloor = 1;
  int _selectedRoomIndex = 1;
  Department? _selectedDepartment;
  Room? _selectedRoom;
  bool _isEditMode = false;

  final List<String> _roomTypes = ['Theory', 'Lab'];
  List<int> _floors = List.generate(20, (i) => i + 1);
  List<int> _roomIndices = List.generate(8, (i) => i + 1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });

    _searchController.addListener(() {
      final provider = Provider.of<RoomProvider>(context, listen: false);
      provider.searchRooms(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _roomNoController.dispose();
    _capacityController.dispose();
    _equipmentController.dispose();
    _pcTotalController.dispose();
    _pcActiveController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    final deptProvider = Provider.of<DepartmentProvider>(context, listen: false);

    await Future.wait([
      roomProvider.loadRooms(),
      deptProvider.loadDepartments(),
      roomProvider.loadDepartments(),
    ]);
  }

  void _updateRoomNo() {
    String roomNo = Room.generateRoomNo(_selectedFloor, _selectedRoomIndex);
    _roomNoController.text = roomNo;
    setState(() {});
  }

  void _showAddEditDialog({Room? room}) {
    _isEditMode = room != null;
    _selectedRoom = room;

    if (_isEditMode) {
      _roomNoController.text = room!.roomNo;
      _capacityController.text = room.capacity.toString();
      _selectedType = room.type;
      _selectedFloor = room.floor;
      _selectedRoomIndex = int.parse(room.roomNo.replaceAll('NB', '')) % 100;
      _equipmentController.text = room.equipment ?? '';

      if (room.type == 'Lab') {
        _pcTotalController.text = room.pcTotal?.toString() ?? '';
        _pcActiveController.text = room.pcActive?.toString() ?? '';
      }

      if (room.departmentId != null) {
        final deptProvider = Provider.of<DepartmentProvider>(context, listen: false);
        try {
          _selectedDepartment = deptProvider.departments.firstWhere(
                (d) => d.id == room.departmentId,
          );
        } catch (e) {
          _selectedDepartment = null;
        }
      } else {
        _selectedDepartment = null;
      }
    } else {
      _roomNoController.clear();
      _capacityController.clear();
      _equipmentController.clear();
      _pcTotalController.clear();
      _pcActiveController.clear();
      _selectedType = 'Theory';
      _selectedFloor = 1;
      _selectedRoomIndex = 1;
      _selectedDepartment = null;
      _updateRoomNo();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  children: [
                    // Dialog Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1976D2),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isEditMode ? Icons.edit : Icons.add,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isEditMode ? 'Edit Room' : 'Add New Room',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Dialog Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Room Type Selection
                            const Text(
                              'Room Type',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTypeSelectionChip(
                                    label: 'Theory',
                                    icon: Icons.menu_book,
                                    isSelected: _selectedType == 'Theory',
                                    onTap: () {
                                      setState(() {
                                        _selectedType = 'Theory';
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildTypeSelectionChip(
                                    label: 'Lab',
                                    icon: Icons.science,
                                    isSelected: _selectedType == 'Lab',
                                    onTap: () {
                                      setState(() {
                                        _selectedType = 'Lab';
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Location Selection
                            const Text(
                              'Location',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      value: _selectedFloor,
                                      decoration: const InputDecoration(
                                        labelText: 'Floor',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      items: _floors.map((floor) {
                                        return DropdownMenuItem(
                                          value: floor,
                                          child: Text('Floor $floor'),
                                        );
                                      }).toList(),
                                      onChanged: _isEditMode ? null : (floor) {
                                        setState(() {
                                          _selectedFloor = floor!;
                                          _updateRoomNo();
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      value: _selectedRoomIndex,
                                      decoration: const InputDecoration(
                                        labelText: 'Room',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      items: _roomIndices.map((index) {
                                        return DropdownMenuItem(
                                          value: index,
                                          child: Text('${_selectedFloor * 100 + index}'),
                                        );
                                      }).toList(),
                                      onChanged: _isEditMode ? null : (index) {
                                        setState(() {
                                          _selectedRoomIndex = index!;
                                          _updateRoomNo();
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Room Details
                            const Text(
                              'Room Details',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                children: [
                                  // Room Number (Read Only)
                                  TextFormField(
                                    controller: _roomNoController,
                                    decoration: InputDecoration(
                                      labelText: 'Room Number',
                                      border: const OutlineInputBorder(),
                                      prefixIcon: const Icon(Icons.meeting_room),
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                    ),
                                    enabled: false,
                                  ),
                                  const SizedBox(height: 12),

                                  // Capacity
                                  TextFormField(
                                    controller: _capacityController,
                                    decoration: const InputDecoration(
                                      labelText: 'Capacity',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.people),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                  const SizedBox(height: 12),

                                  // Equipment
                                  TextFormField(
                                    controller: _equipmentController,
                                    decoration: const InputDecoration(
                                      labelText: 'Equipment',
                                      hintText: 'e.g., Projector, Whiteboard',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.settings),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (_selectedType == 'Lab') ...[
                              const SizedBox(height: 20),

                              // Lab Information
                              const Text(
                                'Lab Information',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange.shade300),
                                ),
                                child: Column(
                                  children: [
                                    // Total PCs
                                    TextFormField(
                                      controller: _pcTotalController,
                                      decoration: const InputDecoration(
                                        labelText: 'Total PCs',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.computer),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(height: 12),

                                    // Active PCs
                                    TextFormField(
                                      controller: _pcActiveController,
                                      decoration: const InputDecoration(
                                        labelText: 'Active PCs',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.computer),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),

                            // Department Assignment
                            const Text(
                              'Department Assignment',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Consumer<DepartmentProvider>(
                              builder: (context, deptProvider, child) {
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.green.shade300),
                                  ),
                                  child: DropdownButtonFormField<Department>(
                                    value: _selectedDepartment,
                                    decoration: const InputDecoration(
                                      labelText: 'Assign Department',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.business),
                                    ),
                                    hint: const Text('Select Department (Optional)'),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('None'),
                                      ),
                                      ...deptProvider.departments.map((dept) {
                                        return DropdownMenuItem(
                                          value: dept,
                                          child: Text('${dept.name} (${dept.code})'),
                                        );
                                      }),
                                    ],
                                    onChanged: (dept) {
                                      setState(() {
                                        _selectedDepartment = dept;
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Dialog Actions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _saveRoom(dialogContext),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(_isEditMode ? 'Update' : 'Add'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      _loadData();
    });
  }

  Widget _buildTypeSelectionChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (label == 'Theory' ? Colors.blue : Colors.orange)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (label == 'Theory' ? Colors.blue : Colors.orange)
                : Colors.grey[400]!,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRoom(BuildContext dialogContext) async {
    if (_capacityController.text.isEmpty) {
      _showError('Please enter capacity');
      return;
    }

    int? capacity = int.tryParse(_capacityController.text);
    if (capacity == null || capacity <= 0) {
      _showError('Please enter valid capacity');
      return;
    }

    int? pcTotal;
    int? pcActive;

    if (_selectedType == 'Lab') {
      pcTotal = int.tryParse(_pcTotalController.text);
      pcActive = int.tryParse(_pcActiveController.text);

      if (pcTotal == null || pcTotal <= 0) {
        _showError('Please enter valid total PCs');
        return;
      }

      if (pcActive == null || pcActive < 0 || pcActive > pcTotal) {
        _showError('Active PCs must be between 0 and total PCs');
        return;
      }
    }

    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

    Room room = Room(
      id: _isEditMode ? _selectedRoom!.id : null,
      roomNo: _roomNoController.text,
      type: _selectedType,
      capacity: capacity,
      floor: _selectedFloor,
      equipment: _equipmentController.text.isNotEmpty ? _equipmentController.text : null,
      pcTotal: pcTotal,
      pcActive: pcActive,
      departmentId: _selectedDepartment?.id,
    );

    bool success;
    if (_isEditMode) {
      print('✏️ Updating room ID: ${_selectedRoom!.id}');
      success = await roomProvider.updateRoom(room);
    } else {
      print('➕ Adding new room');
      success = await roomProvider.addRoom(room);
    }

    if (success) {
      Navigator.pop(dialogContext);
      await dashboardProvider.refreshDashboard();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Room updated' : 'Room added'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _deleteRoom(Room room) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Room'),
        content: Text('Are you sure you want to delete ${room.roomNo}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<RoomProvider>(context, listen: false);
              bool success = await provider.deleteRoom(room.id!);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Room deleted'), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _assignDepartment(Room room) async {
    final deptProvider = Provider.of<DepartmentProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Assign Department'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.meeting_room, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room.roomNo,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              room.type,
                              style: TextStyle(
                                color: room.type == 'Lab' ? Colors.orange : Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Department>(
                  decoration: const InputDecoration(
                    labelText: 'Select Department',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  hint: const Text('Choose department'),
                  value: room.departmentId != null
                      ? deptProvider.departments.firstWhere(
                        (d) => d.id == room.departmentId,
                    orElse: () => Department(id: 0, name: '', code: ''),
                  )
                      : null,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('None'),
                    ),
                    ...deptProvider.departments.map((dept) {
                      return DropdownMenuItem(
                        value: dept,
                        child: Text('${dept.name} (${dept.code})'),
                      );
                    }),
                  ],
                  onChanged: (dept) async {
                    Navigator.pop(context);
                    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
                    bool success = await roomProvider.assignDepartment(room.id!, dept?.id);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(dept == null
                              ? 'Department unassigned'
                              : 'Department assigned to ${dept.name}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Management'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by room number...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    _searchController.clear();
                    final provider = Provider.of<RoomProvider>(context, listen: false);
                    provider.searchRooms('');
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.add),
      ),
      body: Consumer<RoomProvider>(
        builder: (context, roomProvider, child) {
          if (roomProvider.isLoading && roomProvider.rooms.isEmpty) {
            return const LoadingWidget();
          }

          if (roomProvider.error != null && roomProvider.rooms.isEmpty) {
            return ErrorWidgetWithRetry(
              error: roomProvider.error!,
              onRetry: _loadData,
            );
          }

          final rooms = roomProvider.rooms;

          return Column(
            children: [
              // Stats Card
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.meeting_room,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Rooms',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${roomProvider.totalRooms}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'T:${roomProvider.getRoomCountByType('Theory')} L:${roomProvider.getRoomCountByType('Lab')}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Chips
              Container(
                height: 45,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip(
                      label: 'All Floors',
                      isSelected: roomProvider.selectedFloor == null,
                      onTap: () => roomProvider.filterByFloor(null),
                    ),
                    ...List.generate(20, (index) {
                      int floor = index + 1;
                      return Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: _buildFilterChip(
                          label: 'F$floor',
                          isSelected: roomProvider.selectedFloor == floor,
                          onTap: () => roomProvider.filterByFloor(floor),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Type Filter Chips
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTypeChip(
                        label: 'All',
                        isSelected: roomProvider.selectedType == null,
                        onTap: () => roomProvider.filterByType(null),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildTypeChip(
                        label: 'Theory',
                        icon: Icons.menu_book,
                        color: Colors.blue,
                        isSelected: roomProvider.selectedType == 'Theory',
                        onTap: () => roomProvider.filterByType('Theory'),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildTypeChip(
                        label: 'Lab',
                        icon: Icons.science,
                        color: Colors.orange,
                        isSelected: roomProvider.selectedType == 'Lab',
                        onTap: () => roomProvider.filterByType('Lab'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // Room Grid
              Expanded(
                child: rooms.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.meeting_room,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No rooms found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click + to add a new room',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
                    : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return _buildRoomCard(room);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.teal,
      ),
    );
  }

  Widget _buildTypeChip({
    required String label,
    IconData? icon,
    Color? color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: isSelected ? Colors.white : color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey[200],
      selectedColor: color ?? Colors.teal,
    );
  }

  Widget _buildRoomCard(Room room) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: room.type == 'Lab' ? Colors.orange.shade200 : Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showRoomDetails(room),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: room.type == 'Lab' ? Colors.orange : Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      room.type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 16),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showAddEditDialog(room: room);
                      } else if (value == 'assign') {
                        _assignDepartment(room);
                      } else if (value == 'delete') {
                        _deleteRoom(room);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'assign',
                        child: Row(
                          children: [
                            Icon(Icons.business, color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Text('Assign Dept'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Room Number
              Row(
                children: [
                  Icon(
                    room.type == 'Lab' ? Icons.science : Icons.menu_book,
                    size: 16,
                    color: room.type == 'Lab' ? Colors.orange : Colors.blue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    room.roomNo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Capacity
              Row(
                children: [
                  const Icon(Icons.people, size: 12, color: Colors.grey),
                  const SizedBox(width: 2),
                  Text(
                    'Capacity: ${room.capacity}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),

              if (room.type == 'Lab') ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.computer, size: 12, color: Colors.grey),
                    const SizedBox(width: 2),
                    Text(
                      'PCs: ${room.pcActive ?? 0}/${room.pcTotal ?? 0}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],

              const Spacer(),

              // Department
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: room.departmentId != null
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.business,
                      size: 10,
                      color: room.departmentId != null ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        room.departmentName ?? 'Unassigned',
                        style: TextStyle(
                          fontSize: 9,
                          color: room.departmentId != null ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRoomDetails(Room room) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: room.type == 'Lab' ? Colors.orange : Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      room.type == 'Lab' ? Icons.science : Icons.menu_book,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.roomNo,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          room.type,
                          style: TextStyle(
                            color: room.type == 'Lab' ? Colors.orange : Colors.blue,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildDetailRow(Icons.location_on, 'Floor', '${room.floor}'),
              _buildDetailRow(Icons.people, 'Capacity', '${room.capacity} students'),
              if (room.equipment != null && room.equipment!.isNotEmpty)
                _buildDetailRow(Icons.settings, 'Equipment', room.equipment!),
              if (room.type == 'Lab') ...[
                _buildDetailRow(Icons.computer, 'Total PCs', '${room.pcTotal}'),
                _buildDetailRow(Icons.computer, 'Active PCs', '${room.pcActive}'),
              ],
              _buildDetailRow(
                Icons.business,
                'Department',
                room.departmentName ?? 'Not Assigned',
                color: room.departmentId != null ? Colors.green : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _assignDepartment(room);
                      },
                      icon: const Icon(Icons.business, size: 16),
                      label: const Text('Assign Dept'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddEditDialog(room: room);
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}