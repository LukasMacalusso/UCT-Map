import 'package:flutter/material.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../../../domain/entities/building.dart';

void showBuildingDetailSheet(
  BuildContext context,
  int number,
  Building building, {
  required VoidCallback onDirections,
}) {
  Future<List<dynamic>> loadRooms() => ApiClientProvider.apiClient
      .getJson<List<dynamic>>('/api/campus/buildings/${building.id}/rooms');
  var roomsFuture = loadRooms();

  const blue = Color(0xFF003865);
  const yellow = Color(0xFFEAA221);
  const surface = Color(0xFFF4F6F8);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(sheetContext).size.height * 0.83,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            top: false,
            child: FutureBuilder<List<dynamic>>(
              future: roomsFuture,
              builder: (context, snapshot) {
                final rooms = (snapshot.data ?? [])
                    .whereType<Map<String, dynamic>>()
                    .toList();

                final roomsByFloor = <int, List<Map<String, dynamic>>>{};

                for (final room in rooms) {
                  final floor = int.tryParse('${room['floor']}') ?? 0;
                  roomsByFloor.putIfAbsent(floor, () => []);
                  roomsByFloor[floor]!.add(room);
                }

                for (final floorRooms in roomsByFloor.values) {
                  floorRooms.sort(
                    (a, b) => '${a['name']}'.compareTo('${b['name']}'),
                  );
                }

                final floorNumbers = roomsByFloor.keys.toList()..sort();

                return Column(
                  children: [
                    // Barra superior para arrastrar
                    const SizedBox(height: 10),
                    Container(
                      width: 38,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                        children: [
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCE6EF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.apartment_rounded,
                                size: 76,
                                color: blue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Encabezado
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Edificio $number',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: blue,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      building.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(sheetContext),
                                icon: const Icon(Icons.close),
                                style: IconButton.styleFrom(
                                  backgroundColor: surface,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Horario
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: blue,
                                  child: Icon(
                                    Icons.access_time,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Horario de apertura',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        building.schedule.isEmpty
                                            ? 'Horario no disponible'
                                            : building.schedule,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          if (building.services.isNotEmpty) ...[
                            const Text(
                              'Servicios disponibles',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: blue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                for (final service in building.services)
                                  Chip(
                                    label: Text(service),
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Resumen del edificio
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: yellow,
                                  child: Icon(
                                    Icons.layers_outlined,
                                    color: blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Distribución del edificio',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${building.floorsCount} pisos',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (snapshot.hasData)
                                  Text(
                                    '${rooms.length} salas',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: blue,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          const Text(
                            'SALAS DEL EDIFICIO',
                            style: TextStyle(
                              fontSize: 16,
                              color: blue,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 5),

                          const Text(
                            'Selecciona un piso para ver sus salas',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),

                          const SizedBox(height: 14),

                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                child: CircularProgressIndicator(color: blue),
                              ),
                            )
                          else if (snapshot.hasError)
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Text(
                                    'No fue posible cargar las salas. Revisa tu sesión y conexión.',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  TextButton(
                                    onPressed: () => setSheetState(
                                      () => roomsFuture = loadRooms(),
                                    ),
                                    child: const Text('Reintentar'),
                                  ),
                                ],
                              ),
                            )
                          else if (rooms.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Este edificio aún no tiene salas registradas.',
                              ),
                            )
                          else
                            ...floorNumbers.map((floor) {
                              final floorRooms = roomsByFloor[floor]!;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: surface,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Theme(
                                  data: Theme.of(
                                    context,
                                  ).copyWith(dividerColor: Colors.transparent),
                                  child: ExpansionTile(
                                    initiallyExpanded:
                                        floor == floorNumbers.first,
                                    leading: const Icon(
                                      Icons.layers_outlined,
                                      color: blue,
                                    ),
                                    title: Text(
                                      'Piso $floor',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: blue,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${floorRooms.length} salas',
                                    ),
                                    iconColor: blue,
                                    collapsedIconColor: blue,
                                    children: floorRooms.map((room) {
                                      return ListTile(
                                        onTap: () => showRoomDetail(
                                          sheetContext,
                                          building,
                                          room,
                                          onDirections,
                                          closeBuildingSheet: true,
                                        ),
                                        leading: const Icon(
                                          Icons.meeting_room_outlined,
                                          color: blue,
                                        ),
                                        title: Text(
                                          '${room['name']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Sala ${room['number'] ?? ''}',
                                        ),
                                        trailing: const Icon(
                                          Icons.chevron_right,
                                          color: yellow,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            }),

                          const SizedBox(height: 12),

                          // Información adicional
                          Center(
                            child: Text(
                              'UCT MAP · Campus y edificios',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: blue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            onDirections();
                          },
                          icon: const Icon(Icons.directions_walk),
                          label: const Text('CÓMO LLEGAR'),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

void showRoomDetail(
  BuildContext buildingContext,
  Building building,
  Map<String, dynamic> room,
  VoidCallback onDirections, {
  bool closeBuildingSheet = false,
}) {
  const blue = Color(0xFF003865);
  final name = (room['name'] ?? room['Name'] ?? room['number'] ?? 'Sala')
      .toString();
  final floor = room['floor'] ?? room['Floor'];
  showModalBottomSheet<void>(
    context: buildingContext,
    isScrollControlled: true,
    builder: (roomContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFDCE6EF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.meeting_room_outlined,
                size: 64,
                color: blue,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.apartment, size: 18),
                  label: Text(building.name),
                ),
                if (floor != null)
                  Chip(
                    avatar: const Icon(Icons.layers_outlined, size: 18),
                    label: Text('Piso $floor'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'La ruta termina en el edificio donde se encuentra esta sala.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: blue),
                onPressed: () {
                  Navigator.pop(roomContext);
                  if (closeBuildingSheet) Navigator.pop(buildingContext);
                  onDirections();
                },
                icon: const Icon(Icons.directions_walk),
                label: const Text('Cómo llegar'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
