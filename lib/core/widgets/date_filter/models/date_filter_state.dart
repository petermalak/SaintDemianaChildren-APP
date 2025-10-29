import 'package:equatable/equatable.dart';

/// Represents the configuration and state of date filtering
class DateFilterState extends Equatable {
  final List<DateTime> availableDates;
  final Set<String> selectedDates; // ISO format dates
  final int? selectedYear;
  final bool isDatePickerVisible;
  final DateFilterMode filterMode;

  const DateFilterState({
    required this.availableDates,
    required this.selectedDates,
    this.selectedYear,
    this.isDatePickerVisible = false,
    this.filterMode = DateFilterMode.recent,
  });

  factory DateFilterState.initial() {
    return const DateFilterState(
      availableDates: [],
      selectedDates: {},
      isDatePickerVisible: false,
      filterMode: DateFilterMode.recent,
    );
  }

  /// Get filtered dates based on current selection
  List<String> get filteredDatesIso {
    if (selectedDates.isEmpty) {
      // Default: show 4 most recent dates
      final sorted = availableDates.toList()
        ..sort((a, b) => b.compareTo(a)); // Most recent first
      return sorted.take(4).map((d) => _dateToIso(d)).toList();
    }
    return selectedDates.toList()..sort((a, b) => b.compareTo(a));
  }

  /// Get available years from dates
  List<int> get availableYears {
    final years = availableDates.map((d) => d.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a)); // Most recent first
    return years;
  }

  /// Get dates for a specific year
  List<DateTime> getDatesForYear(int year) {
    return availableDates.where((d) => d.year == year).toList()
      ..sort((a, b) => b.compareTo(a));
  }

  DateFilterState copyWith({
    List<DateTime>? availableDates,
    Set<String>? selectedDates,
    int? selectedYear,
    bool? isDatePickerVisible,
    DateFilterMode? filterMode,
  }) {
    return DateFilterState(
      availableDates: availableDates ?? this.availableDates,
      selectedDates: selectedDates ?? this.selectedDates,
      selectedYear: selectedYear ?? this.selectedYear,
      isDatePickerVisible: isDatePickerVisible ?? this.isDatePickerVisible,
      filterMode: filterMode ?? this.filterMode,
    );
  }

  String _dateToIso(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        availableDates,
        selectedDates,
        selectedYear,
        isDatePickerVisible,
        filterMode,
      ];
}

/// Filter mode enum for quick selection options
enum DateFilterMode {
  recent, // Recent dates
  month, // Last month
  all, // All in year
  custom, // Custom selection
}
