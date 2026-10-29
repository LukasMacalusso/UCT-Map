import 'package:flutter/material.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../../../domain/entities/building.dart';

// Panel extraído sin cambios visuales del MapScreen original.
void showBuildingDetailSheet(BuildContext context, int number, Building building) {
  final roomsFuture = ApiClientProvider.apiClient.getJson<List<dynamic>>(
  '/api/campus/buildings/${building.id}/rooms',
);

  const blue = Color(0xFF003865);
  const yellow = Color(0xFFEAA221);
  const surface = Color(0xFFF4F6F8);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
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
                        // Encabezado
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'EDIFICIO $number',
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

                        // Fotografía: pendiente de agregar
                        Container(
                          height: 170,
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.apartment_rounded,
                                  size: 52,
                                  color: blue,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Fotografía próximamente',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Horario
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: blue,
                                child: Icon(
                                  Icons.access_time,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Horario de apertura',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Pendiente de información',
                                      style: TextStyle(
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
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No fue posible cargar las salas.',
                              style: TextStyle(color: Colors.red),
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
                ],
              );
            },
          ),
        ),
      );
    },
  );
}
