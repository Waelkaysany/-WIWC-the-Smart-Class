import 'dart:io';
import 'package:excel/excel.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';

class ExcelService {
  // ────────────────────────────────────────────────────────────────────────────
  // Export attendance for a date using the full history log (timestamps).
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> exportAttendanceByDate(String date) async {
    final snapshot =
        await FirebaseDatabase.instance.ref('attendance').child(date).get();

    final Map<String, dynamic> rows = {};
    if (snapshot.exists && snapshot.value is Map) {
      rows.addAll(Map<String, dynamic>.from(snapshot.value as Map));
    }

    final excel = Excel.createExcel();
    final Sheet sheet = excel['Attendance $date'];
    excel.setDefaultSheet('Attendance $date');

    sheet.appendRow([
      TextCellValue('Name'),
      TextCellValue('UID / Card ID'),
      TextCellValue('Role'),
      TextCellValue('Check-In'),
      TextCellValue('Check-Out'),
      TextCellValue('Status'),
    ]);

    rows.forEach((uid, value) {
      if (value is! Map) return;
      final name   = value['name']?.toString()   ?? 'Unknown';
      final role   = value['role']?.toString()   ?? 'student';
      final status = value['status']?.toString() ?? 'outside';

      final int inTs  = (value['checkInTime']  as int?) ?? 0;
      final int outTs = (value['checkOutTime'] as int?) ?? 0;
      final checkIn  = inTs  > 0
          ? DateFormat('HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(inTs  * 1000))
          : '-';
      final checkOut = outTs > 0
          ? DateFormat('HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(outTs * 1000))
          : '-';

      sheet.appendRow([
        TextCellValue(name),
        TextCellValue(uid),
        TextCellValue(role),
        TextCellValue(checkIn),
        TextCellValue(checkOut),
        TextCellValue(status),
      ]);
    });

    await _share(excel, 'Attendance_$date.xlsx', 'Attendance Report for $date');
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Export a snapshot of who is currently inside (Live Attendance button).
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> exportLiveUsers(String date, List<UserModel> users) async {
    final now   = DateFormat('HH:mm:ss').format(DateTime.now());
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Live Attendance $date'];
    excel.setDefaultSheet('Live Attendance $date');

    sheet.appendRow([
      TextCellValue('Name'),
      TextCellValue('UID / Card ID'),
      TextCellValue('Role'),
      TextCellValue('Status'),
      TextCellValue('Export Time'),
    ]);

    for (final u in users) {
      sheet.appendRow([
        TextCellValue(u.name),
        TextCellValue(u.uid),
        TextCellValue(u.role),
        TextCellValue('Inside'),
        TextCellValue(now),
      ]);
    }

    await _share(excel, 'LiveAttendance_$date.xlsx', 'Live Attendance $date');
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Legacy: kept so HistoryScreen still compiles without changes.
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> exportAttendance(
      String date, Map<dynamic, dynamic> attendanceData) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Attendance - $date'];
    excel.setDefaultSheet('Attendance - $date');

    sheet.appendRow([
      TextCellValue('Name'),
      TextCellValue('UID'),
      TextCellValue('Check-In Time'),
      TextCellValue('Check-Out Time'),
      TextCellValue('Status'),
    ]);

    attendanceData.forEach((key, value) {
      if (value is! Map) return;
      final name   = value['name']?.toString()   ?? 'Unknown';
      final uid    = value['uid']?.toString()    ?? 'N/A';
      final status = value['status']?.toString() ?? 'unknown';
      final int inTs  = (value['checkInTime']  as int?) ?? 0;
      final int outTs = (value['checkOutTime'] as int?) ?? 0;
      final inStr  = inTs  > 0 ? DateFormat('HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(inTs  * 1000)) : '-';
      final outStr = outTs > 0 ? DateFormat('HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(outTs * 1000)) : '-';
      sheet.appendRow([
        TextCellValue(name), TextCellValue(uid),
        TextCellValue(inStr), TextCellValue(outStr), TextCellValue(status),
      ]);
    });

    await _share(excel, 'Attendance_$date.xlsx', 'Attendance Report for $date');
  }

  // ── Private helper ────────────────────────────────────────────────────────
  Future<void> _share(Excel excel, String filename, String subject) async {
    final bytes = excel.save();
    if (bytes == null) return;
    final dir  = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$filename';
    await File(path).writeAsBytes(bytes);
    await Share.shareXFiles([XFile(path)], text: subject);
  }
}
