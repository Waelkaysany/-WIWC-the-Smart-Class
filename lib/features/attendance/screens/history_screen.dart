import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/firebase_service.dart';
import '../../../../services/excel_service.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final ExcelService _excelService = ExcelService();
  
  DateTime _selectedDate = DateTime.now();
  Map<dynamic, dynamic>? _attendanceData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseServiceProvider);
    final data = await db.getAttendanceByDate(_dateStr);
    setState(() {
      _attendanceData = data;
      _isLoading = false;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              if (_attendanceData != null && _attendanceData!.isNotEmpty) {
                _excelService.exportAttendance(_dateStr, _attendanceData!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No data to export')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          ListTile(
            title: Text('Date: $_dateStr'),
            trailing: const Icon(Icons.calendar_today),
            onTap: _selectDate,
          ),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _attendanceData == null || _attendanceData!.isEmpty
                    ? const Center(child: Text('No attendance records found for this date.'))
                    : ListView.builder(
                        itemCount: _attendanceData!.length,
                        itemBuilder: (context, index) {
                          final key = _attendanceData!.keys.elementAt(index);
                          final value = _attendanceData![key];
                          if (value is Map) {
                            final name = value['name'] ?? 'Unknown';
                            final uid = value['uid'] ?? 'N/A';
                            final status = value['status'] ?? 'unknown';
                            
                            int checkInTime = value['checkInTime'] ?? 0;
                            String checkInStr = checkInTime > 0 
                                ? DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(checkInTime * 1000)) 
                                : '-';
                            
                            int checkOutTime = value['checkOutTime'] ?? 0;
                            String checkOutStr = checkOutTime > 0 
                                ? DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(checkOutTime * 1000)) 
                                : '-';

                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(name.toString()),
                              subtitle: Text('In: $checkInStr  Out: $checkOutStr'),
                              trailing: Text(status.toString()),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
