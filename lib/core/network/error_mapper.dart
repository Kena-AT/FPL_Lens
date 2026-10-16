import 'package:dio/dio.dart';

enum AppErrorKind {
  offline,
  timeout,
  fplUnavailable,
  teamNotFound,
  teamLinked,
  codeWrong,
  codeExpired,
  rateLimited,
  unauthenticated,
  notFound,
  projectionsUnavailable,
  keyRejected,
  screenshotUnreadable,
  server,
  unknown,
}

class AppError implements Exception {
  final AppErrorKind kind;
  final String message;
  final bool retryable;
  final int? retryAfterMinutes;
  final int? attemptsLeft;

  const AppError({
    required this.kind,
    required this.message,
    required this.retryable,
    this.retryAfterMinutes,
    this.attemptsLeft,
  });

  @override
  String toString() => 'AppError(kind: $kind, message: $message, retryable: $retryable)';
}

abstract final class ErrorMapper {
  static AppError fromDioException(DioException exception) {
    if (exception.type == DioExceptionType.connectionError ||
        exception.type == DioExceptionType.connectionTimeout) {
      return const AppError(
        kind: AppErrorKind.offline,
        message: "You're offline. Connect to continue.",
        retryable: true,
      );
    }

    if (exception.type == DioExceptionType.sendTimeout ||
        exception.type == DioExceptionType.receiveTimeout) {
      return const AppError(
        kind: AppErrorKind.timeout,
        message: "Request timed out. Try again.",
        retryable: true,
      );
    }

    final response = exception.response;
    if (response == null) {
      return const AppError(
        kind: AppErrorKind.unknown,
        message: "Something went wrong. Try again.",
        retryable: true,
      );
    }

    final statusCode = response.statusCode ?? 500;
    final data = response.data;
    String? detail;
    if (data is Map<String, dynamic>) {
      detail = data['detail']?.toString() ?? data['message']?.toString();
    }

    if (statusCode == 401) {
      return const AppError(
        kind: AppErrorKind.unauthenticated,
        message: "Please sign in again.",
        retryable: false,
      );
    }

    if (statusCode == 404) {
      if (detail != null && detail.contains("team")) {
        return const AppError(
          kind: AppErrorKind.teamNotFound,
          message: "We couldn't find a team with that ID. Check it on the FPL website and try again.",
          retryable: false,
        );
      }
      return const AppError(
        kind: AppErrorKind.notFound,
        message: "We couldn't find that.",
        retryable: false,
      );
    }

    if (statusCode == 409) {
      return const AppError(
        kind: AppErrorKind.teamLinked,
        message: "This FPL team is already linked to an FPL Lens account.",
        retryable: false,
      );
    }

    if (statusCode == 400) {
      if (detail != null && detail.toLowerCase().contains("expired")) {
        return const AppError(
          kind: AppErrorKind.codeExpired,
          message: "This code has expired. Request a new code.",
          retryable: true,
        );
      }
      if (detail != null && (detail.toLowerCase().contains("code") || detail.toLowerCase().contains("invalid"))) {
        return const AppError(
          kind: AppErrorKind.codeWrong,
          message: "That code doesn't match.",
          retryable: true,
        );
      }
    }

    if (statusCode == 429) {
      return const AppError(
        kind: AppErrorKind.rateLimited,
        message: "Too many attempts. Try again in 15 minutes.",
        retryable: true,
        retryAfterMinutes: 15,
      );
    }

    if (statusCode == 503) {
      return const AppError(
        kind: AppErrorKind.fplUnavailable,
        message: "FPL is temporarily unavailable. Try again shortly.",
        retryable: true,
      );
    }

    if (statusCode >= 500) {
      return const AppError(
        kind: AppErrorKind.server,
        message: "Something went wrong on our side. Try again.",
        retryable: true,
      );
    }

    return AppError(
      kind: AppErrorKind.unknown,
      message: detail ?? "Something went wrong. Try again.",
      retryable: true,
    );
  }

  static AppError fromException(Object exception) {
    if (exception is AppError) return exception;
    if (exception is DioException) return fromDioException(exception);
    return const AppError(
      kind: AppErrorKind.unknown,
      message: "Something went wrong. Try again.",
      retryable: true,
    );
  }
}
