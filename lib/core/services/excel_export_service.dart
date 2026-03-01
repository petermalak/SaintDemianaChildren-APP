import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../features/authentication/model/user_model.dart';
import 'web_download_stub.dart' if (dart.library.html) 'web_download_web.dart'
    as web_download;
import '../../features/super_admin_&_khadem_layout/attendance/model/attendance_model.dart';
import '../../features/super_admin_&_khadem_layout/aftekad/model/aftekad_model.dart';
import '../../features/scoring/model/scoring_models.dart';

class ExcelExportService {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

  /// Export members list to Excel (supports multiple classes)
  static Future<String?> exportMembers(
    List<UserModel> members,
    String? className, {
    Map<String, String>? classNamesMap,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['الأعضاء'];

      // Header row: base columns + Pope Athanasius extra data columns
      const popeAthanasiusHeaders = [
        'تاريخ التسجيل',
        'الكنيسه المواظب عليها',
        'خدمات سابقه',
        'الخدمه الحاليه',
        'عدد سنين الخدمه',
        'الوظيفه',
        'الحاله الاجتماعيه',
        'ايميل اللقاء',
        'اهتم - الكتاب المقدس',
        'اهتم - العقيده',
        'اهتم - اللاهوت المقارن',
        'اهتم - الدفاعيات',
        'اهتم - التاريخ',
        'اهتم - ابائيات',
        'الدورات السابقة',
        'أريد أن أعرف',
        'أريد امتحان',
        'مرحلة الفصل',
      ];
      final headers = [
        'الترتيب',
        'الاسم',
        'البريد الإلكتروني',
        'رقم الهاتف',
        'الدور',
        'الفصل',
        'تاريخ الميلاد',
        'العنوان',
        'هاتف الأب',
        'هاتف الأم',
        'تاريخ الإنشاء',
        ...popeAthanasiusHeaders,
      ];

      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

      // Style header row
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.lightBlue,
        fontColorHex: ExcelColor.white,
      );
      for (int i = 0; i < headers.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .cellStyle = headerStyle;
      }

      // Data rows
      int rowNum = 1;
      for (int i = 0; i < members.length; i++) {
        final member = members[i];
        // Get class name from map if available, otherwise use single className or member's class
        String memberClassName = className ?? '';
        if (classNamesMap != null && member.classes.isNotEmpty) {
          final memberClassId = member.classes.first.classId;
          memberClassName = classNamesMap[memberClassId] ?? memberClassName;
        } else if (member.classId != null && classNamesMap != null) {
          memberClassName = classNamesMap[member.classId] ?? memberClassName;
        }

        // Use full Pope Athanasius data for export (additionalData + classPhase)
        final popeData = member.popeAthnasiusMeetingData;
        final additionalData = popeData?.exportMap ?? popeData?.additionalData;
        final baseRow = [
          TextCellValue('$rowNum'),
          TextCellValue(member.name ?? ''),
          TextCellValue(member.email ?? ''),
          TextCellValue(member.phoneNumber ?? ''),
          TextCellValue(_getRoleName(member.role)),
          TextCellValue(memberClassName),
          TextCellValue(member.birthdate != null
              ? _dateFormat.format(member.birthdate!)
              : ''),
          TextCellValue(member.address ?? ''),
          TextCellValue(member.fathersPhoneNumber ?? ''),
          TextCellValue(member.mothersPhoneNumber ?? ''),
          TextCellValue(member.createdAt != null
              ? _dateFormat.format(member.createdAt!)
              : ''),
        ];
        final popeCells = _popeAthanasiusRowCells(additionalData);
        sheet.appendRow([...baseRow, ...popeCells]);
        rowNum++;
      }

      // Auto-size columns
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20);
      }

      final timestamp = _getTimestamp();
      return await _saveAndShareExcel(
        excel,
        _getExportFileName(timestamp, 'أعضاء', className),
      );
    } catch (e) {
      print('Error exporting members: $e');
      return null;
    }
  }

  /// Export attendance records to Excel
  static Future<String?> exportAttendance(
    List<AttendanceRecord> records,
    String? className, {
    Map<String, String>? classNamesMap,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['الحضور'];

      // Header row
      final headers = [
        'الترتيب',
        'الاسم',
        'الفصل',
        'التاريخ',
        'النوع',
        'ملاحظات',
        'إضافة نقاط',
        'تاريخ الإنشاء',
      ];

      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

      // Style header row
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.lightBlue,
        fontColorHex: ExcelColor.white,
      );
      for (int i = 0; i < headers.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .cellStyle = headerStyle;
      }

      // Data rows
      for (int i = 0; i < records.length; i++) {
        final record = records[i];
        // Get class name - use className if single class, or try to get from map
        String recordClassName = className ?? '';
        // Note: AttendanceRecord doesn't have classId, so we use the provided className
        // If multiple classes, className will be 'عدة_فصول' and we can't determine per record
        final row = [
          TextCellValue('${i + 1}'),
          TextCellValue(record.userName ?? ''),
          TextCellValue(recordClassName),
          TextCellValue(record.date ?? ''),
          TextCellValue(_getAttendanceTypeName(record.type)),
          TextCellValue(record.notes ?? ''),
          TextCellValue(record.shouldAddScore == true ? 'نعم' : 'لا'),
          TextCellValue(''), // createdAt not in model
        ];
        sheet.appendRow(row);
      }

      // Auto-size columns
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20);
      }

      final timestamp = _getTimestamp();
      return await _saveAndShareExcel(
        excel,
        _getExportFileName(timestamp, 'حضور', className),
      );
    } catch (e) {
      print('Error exporting attendance: $e');
      return null;
    }
  }

  /// Export eftekad records to Excel
  static Future<String?> exportEftekad(
    List<AftekadModel> records,
    String? className, {
    Map<String, String>? classNamesMap,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['الأفتقاد'];

      // Header row
      final headers = [
        'الترتيب',
        'الخادم',
        'المخدوم',
        'الفصل',
        'النوع',
        'الحالة',
        'تاريخ الجدولة',
        'تاريخ الإتمام',
        'المدة (دقيقة)',
        'الأولوية',
        'ملاحظات',
        'يحتاج متابعة',
        'تاريخ المتابعة',
      ];

      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

      // Style header row
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.lightBlue,
        fontColorHex: ExcelColor.white,
      );
      for (int i = 0; i < headers.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .cellStyle = headerStyle;
      }

      // Data rows
      for (int i = 0; i < records.length; i++) {
        final record = records[i];
        // Get class name from map if available, otherwise use className
        String recordClassName = className ?? '';
        if (classNamesMap != null && record.classId != null) {
          recordClassName = classNamesMap[record.classId] ?? recordClassName;
        }
        final row = [
          TextCellValue('${i + 1}'),
          TextCellValue(record.khadem?.name ?? ''),
          TextCellValue(record.makhdoum?.name ?? ''),
          TextCellValue(recordClassName),
          TextCellValue(_getEftekadTypeName(record.type)),
          TextCellValue(record.status == true ? 'مكتمل' : 'غير مكتمل'),
          TextCellValue(record.scheduledDate ?? ''),
          TextCellValue(record.completedDate?.toString() ?? ''),
          TextCellValue(record.duration?.toString() ?? ''),
          TextCellValue(record.priority ?? ''),
          TextCellValue(record.notes ?? ''),
          TextCellValue(record.followUpRequired == true ? 'نعم' : 'لا'),
          TextCellValue(record.followUpDate?.toString() ?? ''),
        ];
        sheet.appendRow(row);
      }

      // Auto-size columns
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20);
      }

      final timestamp = _getTimestamp();
      return await _saveAndShareExcel(
        excel,
        _getExportFileName(timestamp, 'أفتقاد', className),
      );
    } catch (e) {
      print('Error exporting eftekad: $e');
      return null;
    }
  }

  /// Export leaderboard/scoring to Excel
  static Future<String?> exportScoring(
    List<LeaderboardEntryModel> leaderboard,
    String? className, {
    Map<String, String>? userClassNamesMap, // userId -> className
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['التايو'];

      // Header row
      final headers = [
        'الترتيب',
        'الاسم',
        'الفصل',
        'إجمالي النقاط',
        'المستوى',
        'آخر تحديث',
      ];

      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

      // Style header row
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.lightBlue,
        fontColorHex: ExcelColor.white,
      );
      for (int i = 0; i < headers.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .cellStyle = headerStyle;
      }

      // Data rows
      for (final entry in leaderboard) {
        // Get class name - use userClassNamesMap if available, otherwise use className
        String entryClassName = className ?? '';
        if (userClassNamesMap != null && entry.userId.isNotEmpty) {
          entryClassName = userClassNamesMap[entry.userId] ?? entryClassName;
        }
        final row = [
          TextCellValue('${entry.rank}'),
          TextCellValue(entry.user?.name ?? ''),
          TextCellValue(entryClassName),
          TextCellValue('${entry.totalPoints}'),
          TextCellValue(entry.tier?.name ?? ''),
          TextCellValue(_dateTimeFormat.format(entry.lastUpdated)),
        ];
        sheet.appendRow(row);
      }

      // Auto-size columns
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20);
      }

      final timestamp = _getTimestamp();
      return await _saveAndShareExcel(
        excel,
        _getExportFileName(timestamp, 'التايو', className),
      );
    } catch (e) {
      print('Error exporting scoring: $e');
      return null;
    }
  }

  /// Save Excel file and share it
  static Future<String?> _saveAndShareExcel(
      Excel excel, String fileName) async {
    try {
      final bytes = excel.save();
      if (bytes != null) {
        final uint8List = Uint8List.fromList(bytes);

        if (kIsWeb) {
          // On web use a single download path to avoid two files (Share can trigger
          // a download and then throw, causing fallback to download again).
          web_download.downloadFileOnWeb(uint8List, fileName);
          return fileName;
        } else {
          // For mobile/desktop, save to file system
          final directory = await getApplicationDocumentsDirectory();
          final filePath = '${directory.path}/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(uint8List);
          // Share the file
          final xfile = XFile(filePath);
          await Share.shareXFiles([xfile], text: fileName);
          return filePath;
        }
      }
      return null;
    } catch (e) {
      print('Error saving Excel file: $e');
      return null;
    }
  }

  static String _getTimestamp() {
    return DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  }

  /// Build export filename: date and time first, then suitable name for the export.
  static String _getExportFileName(
      String timestamp, String exportTypeLabel, String? className) {
    final safeClass =
        (className ?? 'الفصل').replaceAll(' ', '_').replaceAll('/', '-');
    return '${timestamp}_${exportTypeLabel}_$safeClass.xlsx';
  }

  static String _getRoleName(UserRole? role) {
    switch (role) {
      case UserRole.khadem:
        return 'خادم';
      case UserRole.makhdoum:
        return 'مخدوم';
      case UserRole.superAdmin:
        return 'مدير عام';
      default:
        return '';
    }
  }

  /// Pope Athanasius additional data columns in same order as popeAthanasiusHeaders.
  static List<TextCellValue> _popeAthanasiusRowCells(
      Map<String, dynamic>? additionalData) {
    if (additionalData == null) {
      return List.filled(18, TextCellValue(''));
    }
    String str(dynamic v) {
      if (v == null) return '';
      if (v is bool) return v ? 'نعم' : 'لا';
      return v.toString();
    }

    return [
      TextCellValue(str(additionalData['registrationDate'])),
      TextCellValue(str(additionalData['regularChurch'])),
      TextCellValue(str(additionalData['previousServices'])),
      TextCellValue(str(additionalData['currentService'])),
      TextCellValue(str(additionalData['yearsOfService'])),
      TextCellValue(str(additionalData['profession'])),
      TextCellValue(str(additionalData['maritalStatus'])),
      TextCellValue(str(additionalData['meetingEmail'])),
      TextCellValue(str(additionalData['interestedBible'])),
      TextCellValue(str(additionalData['interestedTheology'])),
      TextCellValue(str(additionalData['interestedComparativeTheology'])),
      TextCellValue(str(additionalData['interestedApologetics'])),
      TextCellValue(str(additionalData['interestedHistory'])),
      TextCellValue(str(additionalData['interestedPatristics'])),
      TextCellValue(str(additionalData['previousCourses'])),
      TextCellValue(str(additionalData['needToKnow'])),
      TextCellValue(str(additionalData['wantExam'])),
      TextCellValue(str(additionalData['classPhase'])),
    ];
  }

  static String _getAttendanceTypeName(String? type) {
    switch (type) {
      case 'mass':
        return 'قداس';
      case 'specialMeeting':
        return 'اجتماع خاص';
      case 'generalMeeting':
        return 'اجتماع عام';
      case 'praise':
        return 'تسبحة';
      default:
        return type ?? '';
    }
  }

  static String _getEftekadTypeName(AftekadType? type) {
    switch (type) {
      case AftekadType.phone_call:
        return 'مكالمة هاتفية';
      case AftekadType.whatsapp_message:
        return 'رسالة واتساب';
      case AftekadType.home_visit:
        return 'زيارة منزلية';
      default:
        return '';
    }
  }
}
