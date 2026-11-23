/// Contenido autenticado para Inicio. null significa que la fuente aún no existe;
/// una lista vacía significa que la fuente real confirmó que no hay contenido.
class DashboardAcademicContent {
  const DashboardAcademicContent({
    required this.userId,
    this.classes,
    this.notices,
  });
  final String userId;
  final List<DashboardClass>? classes;
  final List<DashboardNotice>? notices;
}

class DashboardClass {
  DashboardClass({
    required this.title,
    required this.location,
    required this.startsAt,
    required this.endsAt,
  }) {
    if (title.trim().isEmpty ||
        location.trim().isEmpty ||
        !endsAt.isAfter(startsAt)) {
      throw ArgumentError('Clase sin título, lugar o intervalo válido.');
    }
  }
  final String title;
  final String location;
  final DateTime startsAt;
  final DateTime endsAt;
}

class DashboardNotice {
  DashboardNotice({required this.title, required this.message}) {
    if (title.trim().isEmpty || message.trim().isEmpty) {
      throw ArgumentError('Aviso sin título o contenido.');
    }
  }
  final String title;
  final String message;
}
