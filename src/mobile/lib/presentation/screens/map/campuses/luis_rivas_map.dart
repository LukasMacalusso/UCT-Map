import 'campus_map_area.dart';

/// Encuadre provisional basado en las capturas del campus.
/// Los limites son rectangulares alrededor del centro del backend,
/// NO el perimetro real marcado en rojo.
const luisRivasArea = CampusMapArea(
  latitudeSpan: 0.0032,
  longitudeSpan: 0.0058,
  minZoom: 17.1,
  maxZoom: 20,
  initialZoom: 17.4,
  pitch: 50,
  bearing: -20,
);
