import '../../../widgets/report_location_actions.dart';

import 'package:flutter/material.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/campus_map_target.dart';
import 'building_detail_sheet.dart';
import 'campus_search_sheet.dart';

void showCampusResultDetail(BuildContext context, CampusSearchResult result) {
  void openMap(CampusMapTarget target) =>
      Navigator.pushNamed(context, AppRoutes.mapLocation, arguments: target);
  final building = result.building;
  if (building != null) {
    if (result.roomCode != null) {
      showRoomDetail(
        context,
        building,
        {
          'id': result.roomId,
          'name': result.roomCode,
          if (result.roomFloor != null) 'floor': result.roomFloor,
        },
        null,
        onShowMap: () => openMap(
          CampusMapTarget.building(building.id, roomId: result.roomId),
        ),
      );
    } else {
      showBuildingDetailSheet(
        context,
        null,
        building,
        onShowMap: (room) => openMap(
          CampusMapTarget.building(
            building.id,
            roomId: room?['id']?.toString(),
          ),
        ),
      );
    }
    return;
  }
  final structure = result.structure;
  if (structure == null) return;
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              structure.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.uctBlue,
              ),
            ),
            const SizedBox(height: 12),
            if (structure.categoryName.isNotEmpty) Text(structure.categoryName),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => openMap(CampusMapTarget.structure(structure.id)),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Ver en mapa'),
            ),
            const SizedBox(height: 12),
            ReportLocationActions(
              locationId: structure.id,
              campusId: structure.campusId,
            ),
          ],
        ),
      ),
    ),
  );
}
