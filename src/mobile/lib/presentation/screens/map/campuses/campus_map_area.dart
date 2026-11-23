/// Configuración de cámara por campus. Los tamaños son PROVISIONALES:
/// rectángulos alrededor de la coordenada central almacenada en Campus Service.
/// No representan los límites catastrales reales del recinto.
class CampusMapArea {
  const CampusMapArea({
    required this.latitudeSpan,
    required this.longitudeSpan,
    this.minZoom = 15.5,
    this.maxZoom = 19.5,
    this.initialZoom = 16.5,
    this.pitch = 50,
    this.bearing = -20,
  });

  final double latitudeSpan;
  final double longitudeSpan;
  final double minZoom;
  final double maxZoom;
  final double initialZoom;
  final double pitch;
  final double bearing;
}
