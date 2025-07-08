import 'package:dio/dio.dart';

String parseDioError(DioException e) {
  String errorMessage = 'An unexpected error occurred';

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
      errorMessage =
          'Connection timeout (2 minutes). Server may be slow or unreachable. Please check your internet connection and try again.';
      break;
    case DioExceptionType.sendTimeout:
      errorMessage = 'Request timeout (2 minutes). Please try again.';
      break;
    case DioExceptionType.receiveTimeout:
      errorMessage =
          'Server response timeout (3 minutes). The server may be processing your request. Please try again.';
      break;
    case DioExceptionType.badResponse:
      errorMessage = _parseResponseError(e);
      break;
    case DioExceptionType.cancel:
      errorMessage = 'Request was cancelled';
      break;
    case DioExceptionType.connectionError:
      errorMessage =
          'Connection error. Please check your internet connection and server availability.';
      break;
    case DioExceptionType.unknown:
      errorMessage =
          'Network error. Please check your connection and server status.';
      break;
    case DioExceptionType.badCertificate:
      errorMessage =
          'Certificate verification failed. Please check your connection.';
      break;
  }

  // Add the actual error details for debugging
  print('DioException details: ${e.toString()}');
  if (e.response != null) {
    print('Response status: ${e.response?.statusCode}');
    print('Response data: ${e.response?.data}');
  }

  return errorMessage;
}

String _parseResponseError(DioException e) {
  final statusCode = e.response?.statusCode;
  final errorData = e.response?.data;

  String errorMessage = 'Request failed with status $statusCode';

  // Extract error message from NestJS response format
  if (errorData != null) {
    // NestJS typically returns errors in this format:
    // { "message": "User not found", "error": "Not Found", "statusCode": 404 }
    // or { "message": ["field1 error", "field2 error"], "error": "Bad Request", "statusCode": 400 }

    if (errorData is Map<String, dynamic>) {
      final message = errorData['message'];

      if (message != null) {
        if (message is String) {
          errorMessage = message;
        } else if (message is List && message.isNotEmpty) {
          // Handle validation errors (array of messages)
          errorMessage = message.first?.toString() ?? errorMessage;
        }
      }
    } else if (errorData is String) {
      errorMessage = errorData;
    }
  }

  // Fallback to status-specific messages if no custom message found
  if (errorMessage == 'Request failed with status $statusCode') {
    switch (statusCode) {
      case 400:
        errorMessage = 'Bad request. Please check your input.';
        break;
      case 401:
        errorMessage = 'Invalid credentials or unauthorized access.';
        break;
      case 403:
        errorMessage = 'Access forbidden. You don\'t have permission.';
        break;
      case 404:
        errorMessage = 'Resource not found.';
        break;
      case 409:
        errorMessage = 'Conflict. Resource already exists.';
        break;
      case 422:
        errorMessage = 'Invalid input data. Please check your information.';
        break;
      case 500:
        errorMessage = 'Server error. Please try again later.';
        break;
      default:
        errorMessage = 'Request failed with status $statusCode';
    }
  }

  return errorMessage;
}
