import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/room_provider.dart';
import '../../../providers/department_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../data/models/room_model.dart';
import '../../../data/models/department_model.dart';
import '../../widgets/loading_widget.dart';

class RoomAssignmentScreen extends StatefulWidget {
  const RoomAssignmentScreen({super.key});

  @override
  State<RoomAssignmentScreen> createState() => _RoomAssignmentScreenState();
}

class _RoomAssignmentScreenState extends State<RoomAssignmentScreen> {
  int? _selectedFloor;
  Department? _selectedDepartment;
  String _selectedType = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<int> _floors = List.generate(20, (i) => i + 1);
  final List<String> _roomTypes = ['All', 'Theory', 'Lab'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      Provider.of<RoomProvider>(context, listen: false).loadRooms(),
      Provider.of<DepartmentProvider>(context, listen: false).loadDepartments(),
    ]);
  }

  List<Room> _getFilteredRooms(RoomProvider roomProvider) {
    var rooms = roomProvider.rooms;

    if (_selectedFloor != null) {
      rooms = rooms.where((r) => r.floor == _selectedFloor).toList();
    }

    if (_selectedDepartment != null) {
      rooms = rooms.where((r) => r.departmentId == _selectedDepartment!.id).toList();
    }

    if (_selectedType != 'All') {
      rooms = rooms.where((r) => r.type == _selectedType).toList();
    }

    if (_searchQuery.isNotEmpty) {
      rooms = rooms.where((r) =>
          r.roomNo.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    rooms.sort((a, b) => a.roomNo.compareTo(b.roomNo));
    return rooms;
  }

  Map<String, dynamic> _getDepartmentStats(RoomProvider roomProvider, DepartmentProvider deptProvider) {
    Map<String, dynamic> stats = {};

    for (var dept in deptProvider.departments) {
      int total = roomProvider.rooms.where((r) => r.departmentId == dept.id).length;
      int theory = roomProvider.rooms.where((r) => r.departmentId == dept.id && r.type == 'Theory').length;
      int lab = roomProvider.rooms.where((r) => r.departmentId == dept.id && r.type == 'Lab').length;

      stats[dept.name] = {
        'total': total,
        'theory': theory,
        'lab': lab,
        'code': dept.code,
        'id': dept.id,
      };
    }

    return stats;
  }

  Map<String, int> _getOverallStats(RoomProvider roomProvider) {
    int total = roomProvider.totalRooms;
    int theory = roomProvider.getRoomCountByType('Theory');
    int lab = roomProvider.getRoomCountByType('Lab');
    int assigned = roomProvider.rooms.where((r) => r.departmentId != null).length;

    return {
      'total': total,
      'theory': theory,
      'lab': lab,
      'assigned': assigned,
    };
  }

  Future<void> _assignDepartment(Room room, Department? dept) async {
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

    bool success = await roomProvider.assignDepartment(room.id!, dept?.id);

    if (success && mounted) {
      await dashboardProvider.refreshDashboard();

      String message = dept == null
          ? 'Room ${room.roomNo} unassigned'
          : 'Room ${room.roomNo} assigned to ${dept.name}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showAssignDialog(Room room) {
    final deptProvider = Provider.of<DepartmentProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Assign Room ${room.roomNo}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.meeting_room, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            room.roomNo,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoChip(
                            'Floor ${room.floor}',
                            Icons.location_on,
                            Colors.orange,
                          ),
                          _buildInfoChip(
                            room.type,
                            room.type == 'Lab' ? Icons.science : Icons.menu_book,
                            room.type == 'Lab' ? Colors.orange : Colors.blue,
                          ),
                          _buildInfoChip(
                            'Cap: ${room.capacity}',
                            Icons.people,
                            Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<Department>(
                  value: room.departmentId != null
                      ? deptProvider.departments.firstWhere(
                        (d) => d.id == room.departmentId,
                    orElse: () => Department(id: 0, name: '', code: ''),
                  )
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Select Department',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  hint: const Text('Choose department'),
                  items: [
                    const DropdownMenuItem<Department>(
                      value: null,
                      child: Text('None (Unassign)'),
                    ),
                    ...deptProvider.departments.map((dept) {
                      return DropdownMenuItem<Department>(
                        value: dept,
                        child: Text('${dept.name} (${dept.code})'),
                      );
                    }),
                  ],
                  onChanged: (dept) async {
                    Navigator.pop(context);
                    await _assignDepartment(room, dept);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomCard(Room room, DepartmentProvider deptProvider) {
    final isAssigned = room.departmentId != null;
    final dept = isAssigned
        ? deptProvider.departments.firstWhere(
          (d) => d.id == room.departmentId,
      orElse: () => Department(id: 0, name: 'Unknown', code: ''),
    )
        : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAssigned ? Colors.green.shade200 : Colors.grey.shade300,
          width: isAssigned ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showAssignDialog(room),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Room Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: room.type == 'Lab' ? Colors.orange : Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      room.type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 16),
                    onSelected: (value) {
                      if (value == 'assign') {
                        _showAssignDialog(room);
                      } else if (value == 'unassign' && isAssigned) {
                        _assignDepartment(room, null);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'assign',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue, size: 16),
                            SizedBox(width: 4),
                            Text('Assign/Change', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      if (isAssigned)
                        const PopupMenuItem(
                          value: 'unassign',
                          child: Row(
                            children: [
                              Icon(Icons.close, color: Colors.red, size: 16),
                              SizedBox(width: 4),
                              Text('Unassign', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Room Number
              Row(
                children: [
                  Icon(
                    room.type == 'Lab' ? Icons.science : Icons.menu_book,
                    size: 14,
                    color: room.type == 'Lab' ? Colors.orange : Colors.blue,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    room.roomNo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 2),

              // Floor & Capacity
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'F${room.floor}',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Cap: ${room.capacity}',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Department
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: isAssigned ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.business,
                      size: 12,
                      color: isAssigned ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        isAssigned ? '${dept?.code}' : 'Not Assigned',
                        style: TextStyle(
                          fontSize: 9,
                          color: isAssigned ? Colors.green : Colors.grey,
                          fontWeight: isAssigned ? FontWeight.w500 : FontWeight.normal,
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

  @override
  Widget build(BuildContext context) {
    final roomProvider = Provider.of<RoomProvider>(context);
    final deptProvider = Provider.of<DepartmentProvider>(context);

    final filteredRooms = _getFilteredRooms(roomProvider);
    final overallStats = _getOverallStats(roomProvider);
    final departmentStats = _getDepartmentStats(roomProvider, deptProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Assignment'),
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
      ),
      body: roomProvider.isLoading
          ? const LoadingWidget()
          : Column(
        children: [
          // Statistics Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Total', '${overallStats['total']}', Icons.meeting_room),
                _buildStatItem('Theory', '${overallStats['theory']}', Icons.menu_book),
                _buildStatItem('Lab', '${overallStats['lab']}', Icons.science),
                _buildStatItem('Assigned', '${overallStats['assigned']}', Icons.check_circle),
              ],
            ),
          ),

          // Department Filter Dropdown
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<Department>(
              value: _selectedDepartment,
              decoration: InputDecoration(
                labelText: 'Filter by Department',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.business, color: Color(0xFF1976D2)),
                suffixIcon: _selectedDepartment != null
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    setState(() {
                      _selectedDepartment = null;
                    });
                  },
                )
                    : null,
              ),
              hint: const Text('All Departments'),
              items: [
                const DropdownMenuItem<Department>(
                  value: null,
                  child: Text('All Departments'),
                ),
                ...deptProvider.departments.map((dept) {
                  final stats = departmentStats[dept.name] ?? {'total': 0, 'theory': 0, 'lab': 0};
                  return DropdownMenuItem<Department>(
                    value: dept,
                    child: Text('${dept.name} (${dept.code}) - T:${stats['theory']} L:${stats['lab']}'),
                  );
                }),
              ],
              onChanged: (dept) {
                setState(() {
                  _selectedDepartment = dept;
                });
              },
            ),
          ),

          // Type Filter Chips
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _roomTypes.length,
              itemBuilder: (context, index) {
                final type = _roomTypes[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(type),
                    selected: _selectedType == type,
                    onSelected: (_) {
                      setState(() {
                        _selectedType = type;
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: type == 'Theory' ? Colors.blue : (type == 'Lab' ? Colors.orange : Colors.teal),
                    labelStyle: TextStyle(
                      color: _selectedType == type ? Colors.white : Colors.black87,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Floor Filter
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 21,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: FilterChip(
                      label: const Text('All Floors'),
                      selected: _selectedFloor == null,
                      onSelected: (_) {
                        setState(() {
                          _selectedFloor = null;
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: Colors.teal,
                    ),
                  );
                }
                int floor = index;
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: FilterChip(
                    label: Text('Floor $floor'),
                    selected: _selectedFloor == floor,
                    onSelected: (_) {
                      setState(() {
                        _selectedFloor = floor;
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.teal,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Department-wise Stats
          if (_selectedDepartment == null)
            Container(
              height: 70,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: deptProvider.departments.length,
                itemBuilder: (context, index) {
                  final dept = deptProvider.departments[index];
                  final stats = departmentStats[dept.name] ?? {'total': 0, 'theory': 0, 'lab': 0};

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDepartment = dept;
                      });
                    },
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dept.code,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.menu_book, size: 10, color: Colors.blue),
                              const SizedBox(width: 2),
                              Text(
                                '${stats['theory']}',
                                style: const TextStyle(fontSize: 10),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.science, size: 10, color: Colors.orange),
                              const SizedBox(width: 2),
                              Text(
                                '${stats['lab']}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // Department Filter Summary
          if (_selectedDepartment != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Showing ${_selectedType == 'All' ? 'all' : _selectedType} rooms for ${_selectedDepartment!.name}',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.blue),
                    onPressed: () {
                      setState(() {
                        _selectedDepartment = null;
                      });
                    },
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Room Grid
          Expanded(
            child: filteredRooms.isEmpty
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
                    ),
                  ),
                ],
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: filteredRooms.length,
              itemBuilder: (context, index) {
                final room = filteredRooms[index];
                return _buildRoomCard(room, deptProvider);
              },
            ),
          ),
        ],
      ),
    );
  }
}