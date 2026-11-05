import '../../domain/entities/professor.dart';

List<Professor> filterProfessors(
  Iterable<Professor> professors, {
  String query = '',
  String? campusId,
  String? locationId,
  int? weekday,
  bool? hasOfficeHours,
  Map<String, String> campusByLocation = const {},
}) {
  final text = query.trim().toLowerCase();
  return professors.where((p) {
    if (text.isNotEmpty &&
        ![
          p.name,
          p.email,
          p.department,
          p.office,
        ].any((v) => v.toLowerCase().contains(text)))
      return false;
    if (hasOfficeHours != null && p.officeHours.isNotEmpty != hasOfficeHours)
      return false;
    if (campusId == null && locationId == null && weekday == null) return true;
    return p.officeHours.any(
      (h) =>
          (weekday == null || h.dayOfWeek == weekday) &&
          (locationId == null || h.structureRefId == locationId) &&
          (campusId == null || campusByLocation[h.structureRefId] == campusId),
    );
  }).toList();
}
