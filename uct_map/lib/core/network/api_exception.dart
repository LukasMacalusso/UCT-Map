import 'dart:convert';
import 'problem_details.dart';

/// Jerarquía de excepciones de red y API para la aplicación UCT Map.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;
  final ProblemDetails? problemDetails;

  const ApiException(
    this.message, [
    this.statusCode,
    this.details,
    this.problemDetails,
  ]);

  /// Parsea la respuesta del backend (incluyendo ProblemDetails RFC 7807 de ASP.NET Core)
  /// para extraer el mensaje de error más específico y tipar la excepción adecuadamente.
  factory ApiException.fromResponse(int statusCode, String body) {
    String message = 'Error en la petición ($statusCode).';
    dynamic details;
    ProblemDetails? problem;

    final trimmed = body.trim();
    if (trimmed.isNotEmpty) {
      problem = ProblemDetails.tryParse(statusCode, trimmed);
      if (problem != null) {
        message = problem.userMessage;
        details = problem.toJson();
      } else {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is Map<String, dynamic>) {
            details = decoded;
            final errors = decoded['errors'];
            if (errors is Map<String, dynamic> && errors.isNotEmpty) {
              final errorMessages = <String>[];
              for (final entry in errors.entries) {
                if (entry.value is List) {
                  errorMessages.addAll((entry.value as List).map((e) => e.toString()));
                } else if (entry.value != null) {
                  errorMessages.add('${entry.key}: ${entry.value}');
                }
              }
              if (errorMessages.isNotEmpty) {
                message = errorMessages.join('\n');
              }
            } else if (decoded['detail'] != null && decoded['detail'].toString().trim().isNotEmpty) {
              message = decoded['detail'].toString().trim();
            } else if (decoded['title'] != null && decoded['title'].toString().trim().isNotEmpty) {
              message = decoded['title'].toString().trim();
            } else if (decoded['message'] != null && decoded['message'].toString().trim().isNotEmpty) {
              message = decoded['message'].toString().trim();
            }
          } else if (decoded is String && decoded.trim().isNotEmpty) {
            message = decoded.trim();
          }
        } catch (_) {
          if (!trimmed.startsWith('<') && trimmed.length < 300) {
            message = trimmed;
          }
        }
      }
    }

    switch (statusCode) {
      case 400:
        return BadRequestException(message, details, problem);
      case 401:
        return UnauthorizedException(message, problem);
      case 403:
        return ForbiddenException(message, problem);
      case 404:
        return NotFoundException(message, problem);
      case 409:
        return ConflictException(message, problem);
      default:
        if (statusCode >= 500) {
          return ServerException(message, problem);
        }
        return ApiException(message, statusCode, details, problem);
    }
  }

  @override
  String toString() =>
      statusCode != null ? 'ApiException($statusCode): $message' : 'ApiException: $message';
}

/// Error 400 Bad Request: parámetros o cuerpo inválido.
class BadRequestException extends ApiException {
  const BadRequestException([
    String message = 'Solicitud inválida.',
    dynamic details,
    ProblemDetails? problemDetails,
  ]) : super(message, 400, details, problemDetails);
}

/// Error 401 Unauthorized: token expirado o credenciales inválidas.
class UnauthorizedException extends ApiException {
  const UnauthorizedException([
    String message = 'Sesión expirada o no autorizada.',
    ProblemDetails? problemDetails,
  ]) : super(message, 401, null, problemDetails);
}

/// Error 403 Forbidden: permisos insuficientes para el recurso.
class ForbiddenException extends ApiException {
  const ForbiddenException([
    String message = 'Acceso no permitido para este rol.',
    ProblemDetails? problemDetails,
  ]) : super(message, 403, null, problemDetails);
}

/// Error 404 Not Found: recurso no encontrado.
class NotFoundException extends ApiException {
  const NotFoundException([
    String message = 'Recurso no encontrado.',
    ProblemDetails? problemDetails,
  ]) : super(message, 404, null, problemDetails);
}

/// Error 409 Conflict: conflicto en el estado del recurso.
class ConflictException extends ApiException {
  const ConflictException([
    String message = 'Conflicto al procesar la solicitud.',
    ProblemDetails? problemDetails,
  ]) : super(message, 409, null, problemDetails);
}

/// Error de conectividad de red o timeout.
class NetworkException extends ApiException {
  const NetworkException([super.message = 'Sin conexión con el servidor. Revisa tu red.']);
}

/// Error 500+ Internal Server Error.
class ServerException extends ApiException {
  const ServerException([
    String message = 'Error interno del servidor.',
    ProblemDetails? problemDetails,
  ]) : super(message, 500, null, problemDetails);
}
