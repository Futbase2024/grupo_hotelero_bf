/// Mapeo de nombres de unidades a imágenes locales
class UnitImageHelper {
  /// Imagen del hotel para habitaciones
  static const String _hotelImagePath = 'assets/alojamientos/HotelBoutique.jpeg';

  /// Mapeo de nombres de unidades a imágenes locales
  static const Map<String, String> _unitImageMap = {
    'Apartamento Bandera': 'assets/alojamientos/ApartamentoBanferra.jpeg',
    'Apartamento BF Jerez': 'assets/alojamientos/ApartamentoBFJerez.jpeg',
    'Ático Jerez': 'assets/alojamientos/ApartamentoAticoJerez.jpeg',
    'BF Jacuzzi Jerez': 'assets/alojamientos/ApartamentoBFJacuzzi.jpeg',
    'Jacuzzi Jerez': 'assets/alojamientos/EstudioBFJacuzzi.jpeg',
    'Estudio Bf Jacuzzi Jerez': 'assets/alojamientos/EstudioBFJacuzzi.jpeg',
  };

  /// Obtiene la ruta de la imagen local para una unidad
  static String? getLocalImagePath(String? unitName) {
    if (unitName == null || unitName.isEmpty) return null;

    // Si es una habitación del hotel (empieza por "HAB"), usar imagen del hotel
    if (unitName.toUpperCase().startsWith('HAB')) {
      return _hotelImagePath;
    }

    return _unitImageMap[unitName];
  }
}
