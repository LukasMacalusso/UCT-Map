import 'package:flutter/material.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../../../domain/entities/building.dart';

/// Resultado de busqueda: la ubicacion de una sala es la de su edificio.
class CampusSearchResult {
  const CampusSearchResult({required this.building, this.roomCode});

  final Building building;
  final String? roomCode;
}

/// Busca salas en Campus Service y edificios entre los ya cargados.
/// Se limita a los edificios del campus actualmente seleccionado.
class CampusSearchSheet extends StatefulWidget {
  const CampusSearchSheet({super.key, required this.buildings});

  final List<Building> buildings;

  @override
  State<CampusSearchSheet> createState() => _CampusSearchSheetState();
}

class _CampusSearchSheetState extends State<CampusSearchSheet> {
  static const _blue = Color(0xFF003865);
  static const _yellow = Color(0xFFEAA221);

  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  List<CampusSearchResult> _results = [];
  int _requestId = 0;

  @override
  void dispose() {
    _requestId++;
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final term = _controller.text.trim();
    final request = ++_requestId;
    if (term.isEmpty) {
      setState(() {
        _error = null;
        _results = [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });

    try {
      final matches = widget.buildings
          .where(
            (building) =>
                building.name.toLowerCase().contains(term.toLowerCase()),
          )
          .map((building) => CampusSearchResult(building: building))
          .toList();

      final response = await ApiClientProvider.apiClient.getJson<List<dynamic>>(
        '/api/campus/rooms/search',
        queryParameters: {'term': term},
      );

      final byId = {
        for (final building in widget.buildings)
          building.id.toLowerCase(): building,
      };
      final seen = <String>{};
      for (final item in response) {
        if (item is! Map) continue;
        final room = item.cast<String, dynamic>();
        final buildingId = (room['buildingId'] ?? room['BuildingId'] ?? '')
            .toString()
            .toLowerCase();
        final building = byId[buildingId];
        if (building == null) continue; // Ignora salas de otros campus.
        final roomCode = (room['name'] ?? room['Name'] ?? '').toString();
        final roomNumber = (room['number'] ?? room['Number'] ?? '').toString();
        if (!roomCode.toLowerCase().contains(term.toLowerCase()) &&
            !roomNumber.toLowerCase().contains(term.toLowerCase()))
          continue;
        if (seen.add('$buildingId:$roomCode')) {
          matches.add(
            CampusSearchResult(building: building, roomCode: roomCode),
          );
        }
      }
      if (!mounted || request != _requestId) return;
      setState(() => _results = matches);
    } catch (error) {
      if (!mounted || request != _requestId) return;
      setState(
        () => _error =
            'No se pudo consultar Campus Service. Revisa tu sesión y conexión.',
      );
      debugPrint('[UCT Search] $error');
    } finally {
      if (mounted && request == _requestId) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.64,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  'Buscar edificio o sala',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _blue,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'Ej.: CJP07_301 o Ricardo Ferrando',
                    prefixIcon: const Icon(Icons.search, color: _blue),
                    suffixIcon: IconButton(
                      tooltip: 'Buscar',
                      icon: const Icon(Icons.arrow_forward, color: _blue),
                      onPressed: _search,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_loading) const LinearProgressIndicator(color: _yellow),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              Expanded(
                child: _results.isEmpty && !_loading && _error == null
                    ? const Center(
                        child: Text(
                          'Escribe un código o nombre y pulsa buscar.',
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final result = _results[index];
                          return ListTile(
                            leading: Icon(
                              result.roomCode == null
                                  ? Icons.apartment
                                  : Icons.meeting_room,
                              color: _blue,
                            ),
                            title: Text(
                              result.roomCode ?? result.building.name,
                            ),
                            subtitle: Text(
                              result.roomCode == null
                                  ? 'Edificio'
                                  : 'Edificio: ${result.building.name}',
                            ),
                            trailing: const Icon(
                              Icons.location_on,
                              color: _yellow,
                            ),
                            onTap: () => Navigator.of(context).pop(result),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
