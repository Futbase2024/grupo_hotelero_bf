import '../entities/house_rule_entity.dart';

/// Contrato del repositorio de normas de la casa
abstract class HouseRulesRepository {
  /// Obtiene todas las normas (generales)
  Future<List<HouseRuleEntity>> getAll();

  /// Obtiene todas las normas de una propiedad
  Future<List<HouseRuleEntity>> getByPropertyId(String propertyId);

  /// Obtiene una norma por ID
  Future<HouseRuleEntity?> getById(String id);

  /// Obtiene todas las normas agrupadas por categoría (generales)
  Future<Map<String, List<HouseRuleEntity>>> getAllGrouped();

  /// Obtiene normas agrupadas por categoría para una propiedad
  Future<Map<String, List<HouseRuleEntity>>> getByPropertyIdGrouped(
    String propertyId,
  );

  /// Stream de normas en tiempo real para una propiedad
  Stream<List<HouseRuleEntity>> watchByPropertyId(String propertyId);
}
