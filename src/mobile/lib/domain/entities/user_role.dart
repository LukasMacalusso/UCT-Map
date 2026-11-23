enum UserRole {
  estudiante,
  profesor,
  administrador,
  funcionarioObjetos,
  funcionarioQuejas,
  invitado,
  desconocido;

  static UserRole fromString(dynamic value) {
    if (value is Map) {
      value = value['nombre'] ?? value['name'] ?? value['rol'];
    }
    final v = value.toString().trim().toLowerCase();
    final n = v.replaceAll(RegExp(r'[\s_\-]+'), '');
    return switch (n) {
      'estudiante' || 'student' => UserRole.estudiante,
      'docente' || 'profesor' || 'teacher' => UserRole.profesor,
      'administrador' || 'admin' => UserRole.administrador,
      'funcionarioobjetos' || 'objectsofficer' => UserRole.funcionarioObjetos,
      'funcionarioquejas' || 'complaintsofficer' => UserRole.funcionarioQuejas,
      'invitado' => UserRole.invitado,
      _ => UserRole.desconocido,
    };
  }

  String toShortString() {
    switch (this) {
      case UserRole.estudiante:
        return 'estudiante';
      case UserRole.profesor:
        return 'profesor';
      case UserRole.administrador:
        return 'administrador';
      case UserRole.funcionarioObjetos:
        return 'funcionario_objetos';
      case UserRole.funcionarioQuejas:
        return 'funcionario_quejas';
      case UserRole.invitado:
        return 'invitado';
      case UserRole.desconocido:
        return 'desconocido';
    }
  }
}
