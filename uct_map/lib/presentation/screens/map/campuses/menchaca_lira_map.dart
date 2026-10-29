import 'campus_map_area.dart';

/// Encuadre provisional basado en las capturas del campus.
/// Los limites son rectangulares alrededor del centro del backend,
/// NO el perimetro real marcado en rojo.
const menchacaLiraArea = CampusMapArea(
  latitudeSpan: 0.0015,
  longitudeSpan: 0.0018,
  minZoom: 18.0,
  maxZoom: 20,
  initialZoom: 18.3,
  pitch: 50,
  bearing: -20,
);
