import 'user_role.dart';

/// Permisos de las pantallas y acciones disponibles en el móvil.
enum AppPermission {
  common,
  bookConsultation;

  bool allows(UserRole? role) => switch (this) {
    common => const {
      UserRole.estudiante,
      UserRole.profesor,
      UserRole.administrador,
      UserRole.funcionarioObjetos,
      UserRole.funcionarioQuejas,
    }.contains(role),
    bookConsultation => role == UserRole.estudiante,
  };
}
