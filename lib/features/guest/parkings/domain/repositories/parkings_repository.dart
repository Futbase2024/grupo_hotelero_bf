import '../entities/parking_entity.dart';
import '../entities/unit_parking_entity.dart';

/// Contrato del repositorio de parkings
abstract class ParkingsRepository {
  /// Obtiene todos los parkings activos
  Future<List<ParkingEntity>> getAllParkings();

  /// Obtiene un parking por su ID
  Future<ParkingEntity?> getParkingById(String id);

  /// Obtiene los parkings asociados a una unidad específica
  /// Incluye la información del parking y la relación
  Future<List<UnitParkingEntity>> getParkingsByUnitId(String unitId);

  /// Obtiene todos los parkings con su relación a unidades
  Future<List<UnitParkingEntity>> getAllUnitParkings();
}
