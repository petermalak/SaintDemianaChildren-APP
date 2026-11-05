import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../authentication/model/user_model.dart';

@immutable
sealed class QrAttendanceState extends Equatable {
  const QrAttendanceState();

  @override
  List<Object?> get props => [];
}

final class QrAttendanceLoadingRoster extends QrAttendanceState {
  const QrAttendanceLoadingRoster();
}

final class QrAttendanceRosterError extends QrAttendanceState {
  const QrAttendanceRosterError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class QrAttendanceReady extends QrAttendanceState {
  const QrAttendanceReady({
    required this.rosterById,
    required this.scannedMembers,
    this.selectedEvent,
    required this.selectedDate,
    this.shouldAddScore = false,
    this.isSubmitting = false,
    this.feedback,
    this.feedbackIsError = true,
    this.lastSuccessName,
    this.successTick = 0,
  });

  /// All class members keyed by user id (makhdoum + khadem from API).
  final Map<String, UserModel> rosterById;

  /// Scanned members in scan order.
  final List<UserModel> scannedMembers;

  final String? selectedEvent;
  final DateTime selectedDate;
  final bool shouldAddScore;
  final bool isSubmitting;

  /// One-shot message for SnackBar (duplicate, not in roster, etc.).
  final String? feedback;

  /// When false, [feedback] is a success/info tone.
  final bool feedbackIsError;

  /// Name of the last successful scan (for overlay).
  final String? lastSuccessName;

  /// Bumps on each successful scan so UI can animate even for same name.
  final int successTick;

  QrAttendanceReady copyWith({
    Map<String, UserModel>? rosterById,
    List<UserModel>? scannedMembers,
    String? selectedEvent,
    bool clearSelectedEvent = false,
    DateTime? selectedDate,
    bool? shouldAddScore,
    bool? isSubmitting,
    String? feedback,
    bool clearFeedback = false,
    bool? feedbackIsError,
    String? lastSuccessName,
    bool clearLastSuccessName = false,
    int? successTick,
  }) {
    return QrAttendanceReady(
      rosterById: rosterById ?? this.rosterById,
      scannedMembers: scannedMembers ?? this.scannedMembers,
      selectedEvent:
          clearSelectedEvent ? null : (selectedEvent ?? this.selectedEvent),
      selectedDate: selectedDate ?? this.selectedDate,
      shouldAddScore: shouldAddScore ?? this.shouldAddScore,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      feedback: clearFeedback ? null : (feedback ?? this.feedback),
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
      lastSuccessName: clearLastSuccessName
          ? null
          : (lastSuccessName ?? this.lastSuccessName),
      successTick: successTick ?? this.successTick,
    );
  }

  @override
  List<Object?> get props => [
        rosterById,
        scannedMembers,
        selectedEvent,
        selectedDate,
        shouldAddScore,
        isSubmitting,
        feedback,
        feedbackIsError,
        lastSuccessName,
        successTick,
      ];
}

final class QrAttendanceSubmitSuccess extends QrAttendanceState {
  const QrAttendanceSubmitSuccess();
}
