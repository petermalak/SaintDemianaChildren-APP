import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/date_filter_state.dart';

/// Cubit for managing date filter state
/// Follows Single Responsibility Principle - only manages date filtering logic
class DateFilterCubit extends Cubit<DateFilterState> {
  DateFilterCubit() : super(DateFilterState.initial());

  /// Initialize with available dates
  void initializeDates(List<DateTime> dates) {
    final sorted = dates.toList()..sort((a, b) => b.compareTo(a));
    final mostRecentYear = sorted.isNotEmpty ? sorted.first.year : null;

    // Select 4 most recent dates by default
    final defaultSelection = sorted.take(4).map((d) => _dateToIso(d)).toSet();

    emit(DateFilterState(
      availableDates: sorted,
      selectedDates: defaultSelection,
      selectedYear: mostRecentYear,
      filterMode: DateFilterMode.recent,
    ));
  }

  /// Toggle date picker visibility
  void toggleDatePicker() {
    emit(state.copyWith(
      isDatePickerVisible: !state.isDatePickerVisible,
    ));
  }

  /// Select a specific date
  void toggleDate(String dateIso) {
    final newSelection = Set<String>.from(state.selectedDates);
    if (newSelection.contains(dateIso)) {
      newSelection.remove(dateIso);
    } else {
      newSelection.add(dateIso);
    }
    emit(state.copyWith(
      selectedDates: newSelection,
      filterMode: DateFilterMode.custom,
    ));
  }

  /// Select recent N dates
  void selectRecentDates(int count) {
    final dates = state.selectedYear != null
        ? state.getDatesForYear(state.selectedYear!)
        : state.availableDates;

    final selected = dates.take(count).map((d) => _dateToIso(d)).toSet();

    emit(state.copyWith(
      selectedDates: selected,
      filterMode: count <= 4 ? DateFilterMode.recent : DateFilterMode.month,
    ));
  }

  /// Select all dates in current year
  void selectAllInYear() {
    if (state.selectedYear == null) return;

    final yearDates = state.getDatesForYear(state.selectedYear!);
    final selected = yearDates.map((d) => _dateToIso(d)).toSet();

    emit(state.copyWith(
      selectedDates: selected,
      filterMode: DateFilterMode.all,
    ));
  }

  /// Clear all selections
  void clearSelection() {
    emit(state.copyWith(
      selectedDates: {},
      filterMode: DateFilterMode.custom,
    ));
  }

  /// Change selected year
  void changeYear(int year) {
    final yearDates = state.getDatesForYear(year);
    final defaultSelection =
        yearDates.take(4).map((d) => _dateToIso(d)).toSet();

    emit(state.copyWith(
      selectedYear: year,
      selectedDates: defaultSelection,
      filterMode: DateFilterMode.recent,
    ));
  }

  String _dateToIso(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
