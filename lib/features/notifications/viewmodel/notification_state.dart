part of 'notification_cubit.dart';

/// NotificationState
///
/// Represents the state of notifications in the application.
/// Follows Immutability principle for state management.
@immutable
sealed class NotificationState {
  const NotificationState();
}

/// Initial state when notifications are not initialized
final class NotificationInitial extends NotificationState {}

/// Loading state when fetching notifications
final class NotificationLoading extends NotificationState {}

/// State when notifications are initialized and ready
final class NotificationInitialized extends NotificationState {}

/// State when notifications are loaded successfully
final class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;

  const NotificationLoaded({
    required this.notifications,
    required this.unreadCount,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationLoaded &&
        other.notifications == notifications &&
        other.unreadCount == unreadCount;
  }

  @override
  int get hashCode => notifications.hashCode ^ unreadCount.hashCode;
}

/// Error state when something goes wrong
final class NotificationError extends NotificationState {
  final String errorMessage;

  const NotificationError(this.errorMessage);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationError && other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => errorMessage.hashCode;
}
