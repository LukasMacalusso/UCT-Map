import '../../../../domain/entities/campus.dart';
import 'campus_map_area.dart';
import 'san_francisco_map.dart';
import 'san_juan_pablo_ii_map.dart';
import 'luis_rivas_map.dart';
import 'menchaca_lira_map.dart';
import 'sergio_contreras_map.dart';

/// El orquestador sigue recibiendo campus desde el backend.
/// Estos archivos solo definen la zona navegable de cada uno.
CampusMapArea areaForCampus(Campus campus) {
  final name = campus.name.toLowerCase();
  if (campus.id == '855f802e-311d-418e-b1a3-80cc2c360625' || name.contains('juan pablo')) {
    return sanJuanPabloIIArea;
  }
  if (name.contains('san francisco')) return sanFranciscoArea;
  if (name.contains('rivas')) return luisRivasArea;
  if (name.contains('menchaca')) return menchacaLiraArea;
  if (name.contains('contreras')) return sergioContrerasArea;
  return const CampusMapArea(latitudeSpan: 0.006, longitudeSpan: 0.006);
}
