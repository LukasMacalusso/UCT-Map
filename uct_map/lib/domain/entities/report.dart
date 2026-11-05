// Entidad Report: modelo de datos de reportes de incidencias del campus UCT.

enum ReportStatus { reportado, enRevision, enProceso, resuelto }

extension ReportStatusExt on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.reportado:
        return 'Reportado';
      case ReportStatus.enRevision:
        return 'En Revision';
      case ReportStatus.enProceso:
        return 'En Proceso';
      case ReportStatus.resuelto:
        return 'Resuelto';
    }
  }

  static ReportStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'enrevision':
      case 'en_revision':
      case 'en revision':
        return ReportStatus.enRevision;
      case 'enproceso':
      case 'en_proceso':
      case 'en proceso':
        return ReportStatus.enProceso;
      case 'resuelto':
        return ReportStatus.resuelto;
      case 'reportado':
      default:
        return ReportStatus.reportado;
    }
  }
}

class ReportStatusEvent {
  final ReportStatus status;
  final DateTime at;
  final String by;

  const ReportStatusEvent({
    required this.status,
    required this.at,
    required this.by,
  });

  factory ReportStatusEvent.fromJson(Map<String, dynamic> json) {
    final rawAt = json['at'] ?? json['At'];
    final parsedAt = rawAt is String
        ? (DateTime.tryParse(rawAt) ?? DateTime.now())
        : DateTime.now();

    return ReportStatusEvent(
      status: ReportStatusExt.fromString(
        (json['status'] ?? json['Status'])?.toString(),
      ),
      at: parsedAt,
      by: (json['by'] ?? json['By'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'at': at.toIso8601String(),
    'by': by,
  };
}

class Report {
  final String id;
  final String title;
  final String description;
  final String location;
  final String campus;
  final String reportedBy;
  final DateTime reportedAt;
  final ReportStatus currentStatus;
  final List<ReportStatusEvent> statusHistory;
  final String? imageUrl; // URL de la foto adjunta al reporte (null = sin foto)

  const Report({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.campus,
    required this.reportedBy,
    required this.reportedAt,
    required this.currentStatus,
    required this.statusHistory,
    this.imageUrl,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    final rawAt =
        json['reportedAt'] ??
        json['ReportedAt'] ??
        json['dateReport'] ??
        json['createdAt'];
    final parsedAt = rawAt is String
        ? (DateTime.tryParse(rawAt) ?? DateTime.now())
        : DateTime.now();

    final rawHistory =
        (json['statusHistory'] ?? json['StatusHistory']) as List<dynamic>? ??
        [];
    final historyList = rawHistory
        .whereType<Map<String, dynamic>>()
        .map<ReportStatusEvent>((e) => ReportStatusEvent.fromJson(e))
        .toList();

    return Report(
      id: (json['id'] ?? json['Id'] ?? json['idTicket'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      description: (json['description'] ?? json['Description'] ?? '')
          .toString(),
      location:
          (json['location'] ?? json['Location'] ?? json['idStructure'] ?? '')
              .toString(),
      campus: (json['campus'] ?? json['Campus'] ?? 'Campus San Francisco')
          .toString(),
      reportedBy:
          (json['reportedBy'] ?? json['ReportedBy'] ?? json['idUsuario'] ?? '')
              .toString(),
      reportedAt: parsedAt,
      currentStatus: ReportStatusExt.fromString(
        (json['currentStatus'] ?? json['CurrentStatus'] ?? json['status'])
            ?.toString(),
      ),
      statusHistory: historyList,
      imageUrl:
          json['imageUrl']?.toString() ??
          json['pictureUri']?.toString() ??
          json['PictureUri']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'location': location,
    'campus': campus,
    'reportedBy': reportedBy,
    'reportedAt': reportedAt.toIso8601String(),
    'currentStatus': currentStatus.name,
    'statusHistory': statusHistory.map((e) => e.toJson()).toList(),
    if (imageUrl != null) 'imageUrl': imageUrl,
  };
}

final List<Report> mockReports = [
  Report(
    id: '1',
    title: 'Bano con cadena rota',
    description: 'Se rompio la cadena del bano del primer piso. El inodoro no para de botar agua, lo que genera una perdida constante de agua. Se solicita revision urgente.',
    location: 'Bano Primer Piso',
    campus: 'Campus San Francisco',
    reportedBy: 'Juan Perez',
    reportedAt: DateTime(2026, 9, 14, 9, 30),
    currentStatus: ReportStatus.enRevision,
    statusHistory: [
      ReportStatusEvent(
        status: ReportStatus.reportado,
        at: DateTime(2026, 9, 14, 9, 30),
        by: 'Juan Perez',
      ),
      ReportStatusEvent(
        status: ReportStatus.enRevision,
        at: DateTime(2026, 9, 14, 11, 15),
        by: 'Depto. Infraestructura',
      ),
    ],
  ),
  Report(
    id: '2',
    title: 'Proyector con falla tecnica',
    description: 'El proyector de la Sala C-201 no enciende. Se probo con distintos cables HDMI y el problema persiste. Afecta las clases de la manana.',
    location: 'Sala C-201, Edificio C',
    campus: 'Campus San Francisco',
    reportedBy: 'Prof. Ana Morales',
    reportedAt: DateTime(2026, 9, 12, 8, 0),
    currentStatus: ReportStatus.enProceso,
    statusHistory: [
      ReportStatusEvent(
        status: ReportStatus.reportado,
        at: DateTime(2026, 9, 12, 8, 0),
        by: 'Prof. Ana Morales',
      ),
      ReportStatusEvent(
        status: ReportStatus.enRevision,
        at: DateTime(2026, 9, 12, 10, 30),
        by: 'Soporte TI',
      ),
      ReportStatusEvent(
        status: ReportStatus.enProceso,
        at: DateTime(2026, 9, 13, 9, 0),
        by: 'Soporte TI',
      ),
    ],
  ),
  Report(
    id: '3',
    title: 'Luz intermitente en pasillo',
    description: 'Las luces del pasillo del segundo piso parpadean constantemente desde hace una semana. Genera molestias visuales y posible riesgo electrico.',
    location: 'Pasillo Piso 2',
    campus: 'Campus San Francisco',
    reportedBy: 'Carlos Fernandez',
    reportedAt: DateTime(2026, 9, 8, 14, 45),
    currentStatus: ReportStatus.resuelto,
    statusHistory: [
      ReportStatusEvent(
        status: ReportStatus.reportado,
        at: DateTime(2026, 9, 8, 14, 45),
        by: 'Carlos Fernandez',
      ),
      ReportStatusEvent(
        status: ReportStatus.enRevision,
        at: DateTime(2026, 9, 9, 9, 0),
        by: 'Mantencion',
      ),
      ReportStatusEvent(
        status: ReportStatus.enProceso,
        at: DateTime(2026, 9, 10, 11, 0),
        by: 'Mantencion',
      ),
      ReportStatusEvent(
        status: ReportStatus.resuelto,
        at: DateTime(2026, 9, 11, 16, 0),
        by: 'Mantencion',
      ),
    ],
  ),
  Report(
    id: '4',
    title: 'Ascensor fuera de servicio',
    description: 'El ascensor del Edificio D se queda trabado entre pisos. Ya ocurrio 3 veces esta semana. Afecta a estudiantes con movilidad reducida.',
    location: 'Ascensor, Edificio D',
    campus: 'Campus San Francisco',
    reportedBy: 'Maria Gonzalez',
    reportedAt: DateTime(2026, 9, 15, 10, 0),
    currentStatus: ReportStatus.reportado,
    statusHistory: [
      ReportStatusEvent(
        status: ReportStatus.reportado,
        at: DateTime(2026, 9, 15, 10, 0),
        by: 'Maria Gonzalez',
      ),
    ],
  ),
  Report(
    id: '5',
    title: 'Filtracion de agua en techo',
    description: 'Hay una filtracion de agua en el techo de la biblioteca, sector de mesas grupales. Cuando llueve cae agua sobre las mesas y los enchufes.',
    location: 'Biblioteca, Sector Grupal',
    campus: 'Campus Norte',
    reportedBy: 'Diego Rojas',
    reportedAt: DateTime(2026, 9, 11, 16, 20),
    currentStatus: ReportStatus.enProceso,
    statusHistory: [
      ReportStatusEvent(
        status: ReportStatus.reportado,
        at: DateTime(2026, 9, 11, 16, 20),
        by: 'Diego Rojas',
      ),
      ReportStatusEvent(
        status: ReportStatus.enRevision,
        at: DateTime(2026, 9, 12, 8, 30),
        by: 'Depto. Infraestructura',
      ),
      ReportStatusEvent(
        status: ReportStatus.enProceso,
        at: DateTime(2026, 9, 13, 13, 0),
        by: 'Depto. Infraestructura',
      ),
    ],
  ),
  Report(
    id: '6',
    title: 'Puerta de acceso sin seguro',
    description: 'La puerta principal del laboratorio de computacion no cierra con llave. Se puede abrir desde afuera sin tarjeta de acceso, lo que representa un riesgo para los equipos.',
    location: 'Laboratorio Computacion, Piso 3',
    campus: 'Campus Norte',
    reportedBy: 'Sofia Castro',
    reportedAt: DateTime(2026, 9, 5, 8, 0),
    currentStatus: ReportStatus.resuelto,
    statusHistory: [
      ReportStatusEvent(
        status: ReportStatus.reportado,
        at: DateTime(2026, 9, 5, 8, 0),
        by: 'Sofia Castro',
      ),
      ReportStatusEvent(
        status: ReportStatus.enRevision,
        at: DateTime(2026, 9, 5, 11, 0),
        by: 'Seguridad Campus',
      ),
      ReportStatusEvent(
        status: ReportStatus.enProceso,
        at: DateTime(2026, 9, 6, 9, 0),
        by: 'Seguridad Campus',
      ),
      ReportStatusEvent(
        status: ReportStatus.resuelto,
        at: DateTime(2026, 9, 7, 14, 0),
        by: 'Seguridad Campus',
      ),
    ],
  ),
];

const List<String> campusList = [
  'Todos',
  'Campus San Francisco',
  'Campus Norte',
];
