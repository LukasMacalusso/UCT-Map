import 'dart:convert';
import 'api_exception.dart';

/// Representación del estándar RFC 7807 (Problem Details for HTTP APIs).
/// Utilizado ampliamente por ASP.NET Core para respuestas de error (4xx y 5xx).
class ProblemDetails {
  final String? type;
  final String? title;
  final int? status;
  final String? detail;
  final String? instance;
  final Map<String, List<String>>? errors;
  final Map<String, dynamic> extensions;

  const ProblemDetails({
    this.type,
    this.title,
    this.status,
    this.detail,
    this.instance,
    this.errors,
    this.extensions = const {},
  });

  /// Parsea un mapa JSON devuelto por ASP.NET Core a [ProblemDetails].
  factory ProblemDetails.fromJson(Map<String, dynamic> json) {
    Map<String, List<String>>? parsedErrors;
    final rawErrors = json['errors'];
    if (rawErrors is Map<String, dynamic>) {
      parsedErrors = {};
      rawErrors.forEach((key, value) {
        if (value is List) {
          parsedErrors![key] = value.map((e) => e.toString()).toList();
        } else if (value != null) {
          parsedErrors![key] = [value.toString()];
        }
      });
    }

    final extensions = <String, dynamic>{};
    const standardKeys = {'type', 'title', 'status', 'detail', 'instance', 'errors'};
    json.forEach((key, value) {
      if (!standardKeys.contains(key.toLowerCase())) {
        extensions[key] = value;
      }
    });

    final statusVal = json['status'];
    final parsedStatus = statusVal is int
        ? statusVal
        : (statusVal != null ? int.tryParse(statusVal.toString()) : null);

    return ProblemDetails(
      type: json['type']?.toString(),
      title: json['title']?.toString(),
      status: parsedStatus,
      detail: json['detail']?.toString(),
      instance: json['instance']?.toString(),
      errors: parsedErrors,
      extensions: extensions,
    );
  }

  /// Intenta parsear una respuesta HTTP cruda a [ProblemDetails].
  static ProblemDetails? tryParse(int statusCode, String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('title') ||
            decoded.containsKey('detail') ||
            decoded.containsKey('type') ||
            decoded.containsKey('errors') ||
            decoded.containsKey('status')) {
          final res = ProblemDetails.fromJson(decoded);
          return ProblemDetails(
            type: res.type,
            title: res.title,
            status: res.status ?? statusCode,
            detail: res.detail,
            instance: res.instance,
            errors: res.errors,
            extensions: res.extensions,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  /// Mensaje formateado para presentar al usuario en UI (prioriza detail -> title -> errores).
  String get userMessage {
    if (errors != null && errors!.isNotEmpty) {
      final buffer = StringBuffer();
      if (detail != null && detail!.trim().isNotEmpty) {
        buffer.writeln(detail!.trim());
      } else if (title != null && title!.trim().isNotEmpty) {
        buffer.writeln(title!.trim());
      }
      errors!.forEach((key, messages) {
        for (final msg in messages) {
          buffer.writeln('• $key: $msg');
        }
      });
      return buffer.toString().trim();
    }

    if (detail != null && detail!.trim().isNotEmpty) {
      return detail!.trim();
    }
    if (title != null && title!.trim().isNotEmpty) {
      return title!.trim();
    }
    return 'Error del servicio (${status ?? "desconocido"}).';
  }

  Map<String, dynamic> toJson() => {
        if (type != null) 'type': type,
        if (title != null) 'title': title,
        if (status != null) 'status': status,
        if (detail != null) 'detail': detail,
        if (instance != null) 'instance': instance,
        if (errors != null) 'errors': errors,
        ...extensions,
      };

  @override
  String toString() =>
      'ProblemDetails(title: $title, status: $status, type: $type, detail: $detail, errors: $errors)';
}

/// Excepción especializada para errores RFC 7807.
class ProblemDetailsException extends ApiException {
  final ProblemDetails problemDetails;

  ProblemDetailsException(this.problemDetails)
      : super(
          problemDetails.userMessage,
          problemDetails.status,
          problemDetails.toJson(),
        );

  String? get errorTitle => problemDetails.title;
  String? get errorType => problemDetails.type;
  String? get errorDetail => problemDetails.detail;
  Map<String, List<String>>? get validationErrors => problemDetails.errors;

  @override
  String toString() =>
      'ProblemDetailsException(${problemDetails.status}): ${problemDetails.title} - ${problemDetails.detail ?? ""}';
}
