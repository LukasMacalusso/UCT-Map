import 'campus_map_area.dart';

/// Encuadre provisional basado en las capturas del campus.
/// Los limites son rectangulares alrededor del centro del backend,
/// NO el perimetro real marcado en rojo.
const sanJuanPabloIIArea = CampusMapArea(
  latitudeSpan: 0.0030,
  longitudeSpan: 0.0046,
  minZoom: 17.2,
  maxZoom: 20,
  initialZoom: 17.5,
  pitch: 50,
  bearing: -20,
);
