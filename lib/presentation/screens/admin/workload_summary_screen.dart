import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/routine_provider.dart';
import '../../../data/models/conflict_model.dart';

class WorkloadSummaryScreen extends StatelessWidget {
  const WorkloadSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final routineProvider = Provider.of<RoutineProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Workload'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: routineProvider.workloads.isEmpty
          ? const Center(
        child: Text('No workload data available'),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: routineProvider.workloads.length,
        itemBuilder: (context, index) {
          final workload = routineProvider.workloads[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: workload.isOverloaded
                    ? Colors.red
                    : (workload.utilization > 80 ? Colors.orange : Colors.green),
                child: Text(
                  workload.teacherName[0],
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(workload.teacherName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Assigned: ${workload.assignedCredits} credits'),
                  Text('Max Load: ${workload.maxLoad} credits'),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: workload.isOverloaded
                      ? Colors.red[100]
                      : (workload.utilization > 80 ? Colors.orange[100] : Colors.green[100]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${workload.utilization.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: workload.isOverloaded
                        ? Colors.red[700]
                        : (workload.utilization > 80 ? Colors.orange[700] : Colors.green[700]),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assigned Classes:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...workload.assignedClasses.map((routine) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${routine.courseCode} - ${routine.courseTitle}',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      '${routine.day} Slot ${routine.slot}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '1 cr',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}