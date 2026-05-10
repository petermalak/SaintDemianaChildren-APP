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
  static const Map<String, String> _attendanceCategoryNames = {
    'praise': 'تسبحة',
    'mass': 'قداس',
    'generalMeeting': 'عام',
    'specialMeeting': 'خاص',
  };
  static const List<String> _attendanceCategories = [
    'praise',
    'mass',
    'generalMeeting',
    'specialMeeting',
  ];

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

      final cleanRecords = records
          .where((r) =>
              (r.userName != null && r.userName!.isNotEmpty) &&
              (r.date != null && r.date!.isNotEmpty) &&
              (r.type != null && r.type!.isNotEmpty))
          .toList();

      // Build ordered members list (same behavior as UI: first-seen order).
      final memberSet = <String>{};
      for (final r in cleanRecords) {
        memberSet.add(r.userName!);
      }
      final members = memberSet.toList();

      // Build unique dates list, sorted ascending.
      final dateSet = <String>{};
      for (final r in cleanRecords) {
        dateSet.add(r.date!);
      }
      final dates = dateSet.toList()
        ..sort((a, b) {
          try {
            return DateTime.parse(a).compareTo(DateTime.parse(b));
          } catch (_) {
            return a.compareTo(b);
          }
        });

      // Build attendance matrix: member -> date -> type -> present
      final attendance =
          <String, Map<String, Map<String, bool>>>{}; // same shape as UI
      for (final r in cleanRecords) {
        final member = r.userName!;
        final date = r.date!;
        final type = r.type!;
        final memberMap =
            attendance.putIfAbsent(member, () => <String, Map<String, bool>>{});
        final dateMap = memberMap.putIfAbsent(date, () => <String, bool>{});
        dateMap[type] = true;
      }

      // Two-row header like the UI (date row + category row).
      final headerRow1 = <TextCellValue>[TextCellValue('الاسم')];
      for (final date in dates) {
        for (int i = 0; i < _attendanceCategories.length; i++) {
          headerRow1.add(TextCellValue(date));
        }
      }
      // Totals columns (same for all rows)
      for (final _ in _attendanceCategories) {
        headerRow1.add(TextCellValue('الإجمالي'));
        headerRow1.add(TextCellValue('النسبة'));
      }
      headerRow1.add(TextCellValue('الإجمالي'));
      headerRow1.add(TextCellValue('النسبة'));

      final headerRow2 = <TextCellValue>[TextCellValue('')];
      for (final _ in dates) {
        for (final cat in _attendanceCategories) {
          headerRow2.add(TextCellValue(_attendanceCategoryNames[cat] ?? cat));
        }
      }
      for (final cat in _attendanceCategories) {
        headerRow2.add(TextCellValue('${_attendanceCategoryNames[cat] ?? cat}'));
        headerRow2.add(TextCellValue('${_attendanceCategoryNames[cat] ?? cat}'));
      }
      headerRow2.add(TextCellValue('كل الاجتماعات'));
      headerRow2.add(TextCellValue('كل الاجتماعات'));

      sheet.appendRow(headerRow1);
      sheet.appendRow(headerRow2);

      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.lightBlue,
        fontColorHex: ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        textWrapping: TextWrapping.WrapText,
      );
      final subHeaderStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.lightBlue,
        fontColorHex: ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        textWrapping: TextWrapping.WrapText,
      );
      final cellCenterStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final totalColumns = 1 +
          (dates.length * _attendanceCategories.length) +
          (_attendanceCategories.length * 2) +
          2;

      // Make header rows taller for readability.
      sheet.setRowHeight(0, 28);
      sheet.setRowHeight(1, 24);

      for (int col = 0; col < totalColumns; col++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
            .cellStyle = headerStyle;
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 1))
            .cellStyle = subHeaderStyle;
      }

      // Merge the first header row groups (each date spans 4 columns).
      // Also merge each totals group (الإجمالي/النسبة) and the final overall totals.
      int colCursor = 1; // 0 is "الاسم"
      for (final _ in dates) {
        final start = colCursor;
        final end = colCursor + _attendanceCategories.length - 1;
        if (start < end) {
          sheet.merge(
            CellIndex.indexByColumnRow(columnIndex: start, rowIndex: 0),
            CellIndex.indexByColumnRow(columnIndex: end, rowIndex: 0),
          );
        }
        colCursor += _attendanceCategories.length;
      }
      // Totals per category (each spans 2 columns)
      for (final cat in _attendanceCategories) {
        final start = colCursor;
        final end = colCursor + 1;
        if (start < end) {
          sheet.merge(
            CellIndex.indexByColumnRow(columnIndex: start, rowIndex: 0),
            CellIndex.indexByColumnRow(columnIndex: end, rowIndex: 0),
          );
        }
        // Put the category name in the merged cell for clarity
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: start, rowIndex: 0))
            .value = TextCellValue(_attendanceCategoryNames[cat] ?? cat);
        colCursor += 2;
      }
      // Overall totals (2 columns)
      final overallStart = colCursor;
      final overallEnd = colCursor + 1;
      if (overallStart < overallEnd) {
        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: overallStart, rowIndex: 0),
          CellIndex.indexByColumnRow(columnIndex: overallEnd, rowIndex: 0),
        );
      }
      sheet
          .cell(CellIndex.indexByColumnRow(
              columnIndex: overallStart, rowIndex: 0))
          .value = TextCellValue('كل الاجتماعات');

      // Data rows: one row per member, one cell per (date, category)
      for (int memberIndex = 0; memberIndex < members.length; memberIndex++) {
        final member = members[memberIndex];
        final row = <TextCellValue>[TextCellValue(member)];

        final totalsByCat = <String, int>{
          for (final cat in _attendanceCategories) cat: 0,
        };
        int totalAttendedAll = 0;

        for (final date in dates) {
          for (final cat in _attendanceCategories) {
            final present = attendance[member]?[date]?[cat] == true;
            if (present) {
              totalsByCat[cat] = (totalsByCat[cat] ?? 0) + 1;
              totalAttendedAll += 1;
            }
            // Absent cells should be blank (no ✗)
            row.add(TextCellValue(present ? '✓' : ''));
          }
        }

        final possiblePerCat = dates.length;
        final possibleAll = dates.length * _attendanceCategories.length;

        for (final cat in _attendanceCategories) {
          final attended = totalsByCat[cat] ?? 0;
          final pct = possiblePerCat == 0
              ? 0.0
              : (attended / possiblePerCat) * 100.0;
          row.add(TextCellValue(attended.toString()));
          row.add(TextCellValue('${pct.toStringAsFixed(0)}%'));
        }

        final pctAll =
            possibleAll == 0 ? 0.0 : (totalAttendedAll / possibleAll) * 100.0;
        row.add(TextCellValue(totalAttendedAll.toString()));
        row.add(TextCellValue('${pctAll.toStringAsFixed(0)}%'));

        sheet.appendRow(row);

        // Center-align all cells in this data row.
        final rowIndex = 2 + memberIndex;
        for (int col = 0; col < totalColumns; col++) {
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: col, rowIndex: rowIndex))
              .cellStyle = cellCenterStyle;
        }
      }

      // Set column widths: name wider, attendance columns compact
      sheet.setColumnWidth(0, 28);
      final attendanceCols = dates.length * _attendanceCategories.length;
      for (int i = 1; i <= attendanceCols; i++) {
        sheet.setColumnWidth(i, 10);
      }
      for (int i = attendanceCols + 1; i < totalColumns; i++) {
        sheet.setColumnWidth(i, 14);
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
      TextCellValue(str(
          additionalData['registrationDate'] ?? additionalData['تاريخ التسجيل'])),
      TextCellValue(str(additionalData['regularChurch'] ??
          additionalData['الكنيسه المواظب عليها'])),
      TextCellValue(str(additionalData['previousServices'] ??
          additionalData['خدمات سابقه'])),
      TextCellValue(str(
          additionalData['currentService'] ?? additionalData['الخدمه الحاليه'])),
      TextCellValue(str(additionalData['yearsOfService'] ??
          additionalData['عدد سنين الخدمه'])),
      TextCellValue(
          str(additionalData['profession'] ?? additionalData['الوظيفه'])),
      TextCellValue(str(additionalData['maritalStatus'] ??
          additionalData['الحاله الاجتماعيه'])),
      TextCellValue(
          str(additionalData['meetingEmail'] ?? additionalData['الايميل'])),
      TextCellValue(str(additionalData['interestedBible'] ??
          additionalData['اهتم بدارسه - الكتاب المقدس'])),
      TextCellValue(str(additionalData['interestedTheology'] ??
          additionalData['اهتم بدارسه - العقيده'])),
      TextCellValue(str(additionalData['interestedComparativeTheology'] ??
          additionalData['اهتم بدارسه - اللاهوت المقارن'])),
      TextCellValue(str(additionalData['interestedApologetics'] ??
          additionalData['اهتم بدارسه - الدفاعيات'])),
      TextCellValue(str(additionalData['interestedHistory'] ??
          additionalData['اهتم بدارسه - التاريخ'])),
      TextCellValue(str(additionalData['interestedPatristics'] ??
          additionalData['اهتم بدارسه - ابائيات'])),
      TextCellValue(str(
          additionalData['previousCourses'] ?? additionalData['كورسات سابقه'])),
      TextCellValue(
          str(additionalData['needToKnow'] ?? additionalData['محتاج اعرف'])),
      TextCellValue(str(
          additionalData['wantExam'] ?? additionalData['ارغب في الامتحان'])),
      TextCellValue(str(additionalData['classPhase'] ??
          additionalData['Class Phase'] ??
          additionalData['class_phase'])),
    ];
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
