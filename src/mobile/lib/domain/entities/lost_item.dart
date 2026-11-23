// Entidad LostItem: modelo de datos de objetos perdidos/encontrados UCT.

enum LostItemStatus { publicado, enCustodia, entregado, cerrado }

extension LostItemStatusExt on LostItemStatus {
  String get label {
    switch (this) {
      case LostItemStatus.publicado:
        return 'Publicado';
      case LostItemStatus.enCustodia:
        return 'En Custodia';
      case LostItemStatus.entregado:
        return 'Entregado';
      case LostItemStatus.cerrado:
        return 'Cerrado';
    }
  }

  static LostItemStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'encustodia':
      case 'en_custodia':
      case 'en custodia':
        return LostItemStatus.enCustodia;
      case 'entregado':
        return LostItemStatus.entregado;
      case 'cerrado':
        return LostItemStatus.cerrado;
      case 'publicado':
      default:
        return LostItemStatus.publicado;
    }
  }
}

class LostItemStatusEvent {
  final LostItemStatus status;
  final DateTime at;
  final String by;
  final String? note;

  const LostItemStatusEvent({
    required this.status,
    required this.at,
    required this.by,
    this.note,
  });

  factory LostItemStatusEvent.fromJson(Map<String, dynamic> json) {
    final rawAt = json['at'] ?? json['At'];
    final parsedAt = rawAt is String
        ? (DateTime.tryParse(rawAt) ?? DateTime.now())
        : DateTime.now();

    return LostItemStatusEvent(
      status: LostItemStatusExt.fromString(
        (json['status'] ?? json['Status'])?.toString(),
      ),
      at: parsedAt,
      by: (json['by'] ?? json['By'] ?? '').toString(),
      note: json['note']?.toString() ?? json['Note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'at': at.toIso8601String(),
    'by': by,
    if (note != null) 'note': note,
  };
}

class LostItem {
  final String id;
  final String ticketNumber;
  final String title;
  final String description;
  final String category;
  final String campus;
  final String building;
  final String reportedBy;
  final DateTime reportedAt;
  final LostItemStatus currentStatus;
  final List<LostItemStatusEvent> statusHistory;
  final String? imageUrl;
  final String? contactInfo;

  const LostItem({
    required this.id,
    required this.ticketNumber,
    required this.title,
    required this.description,
    required this.category,
    required this.campus,
    required this.building,
    required this.reportedBy,
    required this.reportedAt,
    required this.currentStatus,
    required this.statusHistory,
    this.imageUrl,
    this.contactInfo,
  });

  factory LostItem.fromJson(Map<String, dynamic> json) {
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
        .map<LostItemStatusEvent>((e) => LostItemStatusEvent.fromJson(e))
        .toList();

    return LostItem(
      id: (json['id'] ?? json['Id'] ?? json['idTicket'] ?? '').toString(),
      ticketNumber:
          (json['ticketNumber'] ??
                  json['TicketNumber'] ??
                  'TK-${json['id'] ?? '001'}')
              .toString(),
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      description: (json['description'] ?? json['Description'] ?? '')
          .toString(),
      category: (json['category'] ?? json['Category'] ?? 'General').toString(),
      campus: (json['campus'] ?? json['Campus'] ?? 'Campus San Francisco')
          .toString(),
      building:
          (json['building'] ??
                  json['Building'] ??
                  json['idStructure'] ??
                  'Edificio Central')
              .toString(),
      reportedBy:
          (json['reportedBy'] ?? json['ReportedBy'] ?? json['idUsuario'] ?? '')
              .toString(),
      reportedAt: parsedAt,
      currentStatus: LostItemStatusExt.fromString(
        (json['currentStatus'] ?? json['CurrentStatus'] ?? json['status'])
            ?.toString(),
      ),
      statusHistory: historyList,
      imageUrl:
          json['imageUrl']?.toString() ??
          json['pictureUri']?.toString() ??
          json['PictureUri']?.toString(),
      contactInfo:
          json['contactInfo']?.toString() ?? json['ContactInfo']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ticketNumber': ticketNumber,
    'title': title,
    'description': description,
    'category': category,
    'campus': campus,
    'building': building,
    'reportedBy': reportedBy,
    'reportedAt': reportedAt.toIso8601String(),
    'currentStatus': currentStatus.name,
    'statusHistory': statusHistory.map((e) => e.toJson()).toList(),
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (contactInfo != null) 'contactInfo': contactInfo,
  };
}

// ---------------------------------------------------------------------------
// Datos de prueba (mock)
// ---------------------------------------------------------------------------
final List<LostItem> mockLostItems = [
  LostItem(
    id: '1',
    ticketNumber: '#TKT-UCT-0842',
    title: 'Billetera de cuero con carnet y TNE',
    description: 'Billetera de cuero color cafe oscuro. Contiene carnet de identidad, tarjeta TNE, tarjeta de debito y alrededor de \$5.000 en efectivo. Se encontro debajo de la silla del aula C-204.',
    category: 'Documentos',
    campus: 'Campus San Juan Pablo II',
    building: 'Edificio C - Aula C-204',
    reportedBy: 'Camila Rojas (Estudiante)',
    reportedAt: DateTime(2026, 9, 16, 8, 15),
    currentStatus: LostItemStatus.publicado,
    contactInfo: 'Dirigirse a porteria Edificio C',
    statusHistory: [
      LostItemStatusEvent(
        status: LostItemStatus.publicado,
        at: DateTime(2026, 9, 16, 8, 15),
        by: 'Camila Rojas',
        note: 'Objeto encontrado y registrado en el sistema.',
      ),
    ],
  ),
  LostItem(
    id: '2',
    ticketNumber: '#TKT-UCT-0839',
    title: 'Llavero con 4 llaves y cinta azul UCT',
    description: 'Llavero con anilla metalica, 4 llaves de distintos tamanos y una cinta de tela azul con el logo UCT. Encontrado en la mesa del casino central.',
    category: 'Llaves',
    campus: 'Campus San Juan Pablo II',
    building: 'Edificio Central - Casino',
    reportedBy: 'Guardia de Seguridad',
    reportedAt: DateTime(2026, 9, 16, 5, 0),
    currentStatus: LostItemStatus.enCustodia,
    contactInfo: 'Seguridad Campus, Edificio Central',
    statusHistory: [
      LostItemStatusEvent(
        status: LostItemStatus.publicado,
        at: DateTime(2026, 9, 16, 5, 0),
        by: 'Guardia de Seguridad',
        note: 'Encontrado y registrado en turno de manana.',
      ),
      LostItemStatusEvent(
        status: LostItemStatus.enCustodia,
        at: DateTime(2026, 9, 16, 9, 30),
        by: 'Jefatura Seguridad',
        note: 'Trasladado a bodega de custodia de seguridad.',
      ),
    ],
  ),
  LostItem(
    id: '3',
    ticketNumber: '#TKT-UCT-0820',
    title: 'Calculadora Cientifica Casio fx-991LA',
    description: 'Calculadora cientifica Casio fx-991LA PLUS color negro. Tiene el nombre "R. Alarcon" escrito en la parte trasera con marcador. Se encontro en el laboratorio 2 del Edificio A.',
    category: 'Tecnologia',
    campus: 'Campus San Francisco',
    building: 'Edificio A - Laboratorio 2',
    reportedBy: 'Prof. Rodrigo Alarcon',
    reportedAt: DateTime(2026, 9, 15, 17, 0),
    currentStatus: LostItemStatus.publicado,
    contactInfo: 'Secretaria Facultad de Ingenieria',
    statusHistory: [
      LostItemStatusEvent(
        status: LostItemStatus.publicado,
        at: DateTime(2026, 9, 15, 17, 0),
        by: 'Prof. Rodrigo Alarcon',
        note: 'Encontrada al termino de la clase de calculo.',
      ),
    ],
  ),
  LostItem(
    id: '4',
    ticketNumber: '#TKT-UCT-0811',
    title: 'Poleron azul marino UCT Talla L',
    description: 'Poleron azul marino con el logo UCT bordado en el pecho. Talla L. Se encontro colgado en una silla del gimnasio despues del turno de la tarde.',
    category: 'Ropa',
    campus: 'Campus San Juan Pablo II',
    building: 'Gimnasio / Canchas Deportivas',
    reportedBy: 'Matias Soto (Estudiante)',
    reportedAt: DateTime(2026, 9, 14, 19, 30),
    currentStatus: LostItemStatus.entregado,
    contactInfo: 'Entregado al dueno',
    statusHistory: [
      LostItemStatusEvent(
        status: LostItemStatus.publicado,
        at: DateTime(2026, 9, 14, 19, 30),
        by: 'Matias Soto',
        note: 'Encontrado al cierre del gimnasio.',
      ),
      LostItemStatusEvent(
        status: LostItemStatus.enCustodia,
        at: DateTime(2026, 9, 15, 8, 0),
        by: 'Encargado Deportes',
        note: 'En custodia en oficina de deportes.',
      ),
      LostItemStatusEvent(
        status: LostItemStatus.entregado,
        at: DateTime(2026, 9, 15, 11, 45),
        by: 'Encargado Deportes',
        note: 'Dueno se presento con identificacion y retiró el objeto.',
      ),
    ],
  ),
];

const List<String> lostItemCampusList = [
  'Todos los campus',
  'Campus San Juan Pablo II',
  'Campus San Francisco',
  'Campus Dr. Luis Rivas del Canto',
];

const List<String> lostItemCategories = [
  'Todos',
  'Documentos',
  'Llaves',
  'Tecnologia',
  'Ropa',
  'Mochilas',
];
