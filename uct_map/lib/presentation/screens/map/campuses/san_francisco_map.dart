import 'campus_map_area.dart';

/// Encuadre provisional basado en las capturas del campus.
/// Los limites son rectangulares alrededor del centro del backend,
/// NO el perimetro real marcado en rojo.
const sanFranciscoArea = CampusMapArea(
  latitudeSpan: 0.0024,
  longitudeSpan: 0.0030,
  minZoom: 17.5,
  maxZoom: 20,
  initialZoom: 17.8,
  pitch: 50,
  bearing: -20,
);
