import '../../domain/entities/app_permission.dart';
import '../../domain/entities/lost_object.dart';
import '../session/session_controller.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/lost_object_dto.dart';
import '../../data/models/report_dto.dart';
import '../../data/storage/pending_object_storage.dart';
import '../../domain/repositories/lost_objects_repository.dart';
import '../../domain/repositories/reports_repository.dart';

class PendingObjectPublication implements Exception {
  const PendingObjectPublication(this.item);
  final PendingObject item;
}

class ObjectPublication {
  ObjectPublication({
    required this.objects,
    required this.reports,
    required this.session,
    required this.storage,
  });
  final LostObjectsRepository objects;
  final ReportsRepository reports;
  final SessionController session;
  final PendingObjectStorage storage;
  PendingObject? _known;
  String? _ownerId;

  Future<String> publish(CreateLostObjectDto dto) async {
    dto.validate();
    await session.ready;
    final token = session.token;
    final userId = session.currentUser?.id;
    if (token == null ||
        userId == null ||
        !AppPermission.common.allows(session.currentUser?.role))
      throw const UnauthorizedException();
    if (_ownerId != userId) {
      _known = null;
      _ownerId = userId;
    }
    if (!AppPermission.manageObjects.allows(session.currentUser?.role) &&
        dto.status != LostObjectStatus.pending)
      throw const ForbiddenException();
    final pending = _known ?? await storage.read(userId);
    if (pending != null) throw PendingObjectPublication(pending);
    if (session.token != token)
      throw const UnauthorizedException('La sesión cambió.');
    // Guardar antes del POST evita repetir una creación cuyo resultado se perdió.
    var item = PendingObject(title: dto.title, structureId: dto.structureId);
    await storage.save(userId, item);
    try {
      final result = await objects.createLostObject(dto);
      if (result.id.isEmpty)
        throw const FormatException('Falta el ID del objeto creado.');
      item = PendingObject(
        title: dto.title,
        structureId: dto.structureId,
        id: result.id,
      );
      _known = item;
      await storage.save(userId, item);
    } on ApiException catch (error) {
      // Un rechazo explícito no creó el objeto; los fallos de red/5xx son ambiguos.
      if (error.statusCode != null &&
          error.statusCode! >= 400 &&
          error.statusCode! < 500) {
        await storage.clear(userId);
        rethrow;
      }
      throw PendingObjectPublication(item);
    } catch (_) {
      _known = item;
      throw PendingObjectPublication(item);
    }
    if (session.token != token)
      throw const UnauthorizedException('La sesión cambió.');
    return resume(item);
  }

  Future<String> resume(PendingObject item) async {
    final token = session.token;
    final userId = session.currentUser?.id;
    if (token == null ||
        userId == null ||
        !AppPermission.common.allows(session.currentUser?.role))
      throw const UnauthorizedException();
    if (_ownerId != userId) {
      _known = null;
      _ownerId = userId;
    }
    void check() {
      if (session.token != token || session.currentUser?.id != userId)
        throw const UnauthorizedException('La sesión cambió.');
    }

    final stored = _known ?? await storage.read(userId);
    check();
    if (item.id == null || stored?.id != item.id)
      throw PendingObjectPublication(item);
    try {
      final object = await objects.getLostObjectById(item.id!);
      check();
      if (object.structureId != item.structureId)
        throw const FormatException('La ubicación del objeto cambió.');
      final existing = await reports.getReports(
        filter: ReportFilterParams(userRefId: userId, lostObjectId: item.id),
      );
      check();
      if (existing.items.any(
        (r) => r.userRefId != userId || r.lostObjectId != item.id,
      ))
        throw const FormatException(
          'La respuesta de vinculación no corresponde a tu cuenta.',
        );
      if (existing.items.isEmpty) {
        await reports.createReport(
          CreateReportDto(
            structureRefId: item.structureId,
            lostObjectId: item.id,
          ),
        );
        check();
      }
      await storage.clear(userId);
      _known = null;
      return item.id!;
    } on UnauthorizedException {
      rethrow;
    } catch (_) {
      throw PendingObjectPublication(item);
    }
  }
}
