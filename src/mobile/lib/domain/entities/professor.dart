import 'office_hour.dart';

/// Entidad Profesor del directorio académico (ms.svg - Schedule Service).
class Professor {
  final String id;
  final String name;
  final String department;
  final String office;
  final String email;
  final String? structureRefId;
  final List<OfficeHour> officeHours;

  const Professor({
    required this.id,
    required this.name,
    required this.department,
    required this.office,
    required this.email,
    this.structureRefId,
    this.officeHours = const [],
  });

  factory Professor.fromJson(Map<String, dynamic> json) {
    final rawHours =
        (json['officeHours'] ?? json['OfficeHours']) as List<dynamic>? ?? [];
    final hoursList = rawHours
        .whereType<Map<String, dynamic>>()
        .map<OfficeHour>((h) => OfficeHour.fromJson(h))
        .toList();

    return Professor(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      department: (json['department'] ?? json['Department'] ?? '').toString(),
      office: (json['office'] ?? json['Office'] ?? '').toString(),
      email: (json['email'] ?? json['Email'] ?? '').toString(),
      structureRefId:
          json['structureRefId']?.toString() ??
          json['StructureRefId']?.toString(),
      officeHours: hoursList,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'department': department,
    'office': office,
    'email': email,
    if (structureRefId != null) 'structureRefId': structureRefId,
    'officeHours': officeHours.map((h) => h.toJson()).toList(),
  };
}
