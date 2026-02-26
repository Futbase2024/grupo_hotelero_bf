import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/config/supabase_config.dart';
import '../../domain/entities/house_rule_entity.dart';
import '../../domain/repositories/house_rules_repository.dart';

/// Implementación del repositorio de normas de la casa
class HouseRulesRepositoryImpl implements HouseRulesRepository {
  HouseRulesRepositoryImpl({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  @override
  Future<List<HouseRuleEntity>> getAll() async {
    try {
      final response = await _supabase
          .from(SupabaseTables.houseRules)
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true);

      return response
          .map<HouseRuleEntity>(
              (json) => HouseRuleEntity.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar las normas de la casa: $e');
    }
  }

  @override
  Future<List<HouseRuleEntity>> getByPropertyId(String propertyId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.houseRules)
          .select()
          .eq('property_id', propertyId)
          .eq('is_active', true)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true);

      return response
          .map<HouseRuleEntity>(
              (json) => HouseRuleEntity.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar las normas de la casa: $e');
    }
  }

  @override
  Future<HouseRuleEntity?> getById(String id) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.houseRules)
          .select()
          .eq('id', id)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;

      return HouseRuleEntity.fromJson(response);
    } catch (e) {
      throw Exception('Error al cargar la norma: $e');
    }
  }

  @override
  Future<Map<String, List<HouseRuleEntity>>> getAllGrouped() async {
    final rules = await getAll();

    final grouped = <String, List<HouseRuleEntity>>{};

    for (final rule in rules) {
      final category = rule.category;
      grouped.putIfAbsent(category, () => []).add(rule);
    }

    return grouped;
  }

  @override
  Future<Map<String, List<HouseRuleEntity>>> getByPropertyIdGrouped(
    String propertyId,
  ) async {
    final rules = await getByPropertyId(propertyId);

    final grouped = <String, List<HouseRuleEntity>>{};

    for (final rule in rules) {
      final category = rule.category;
      grouped.putIfAbsent(category, () => []).add(rule);
    }

    return grouped;
  }

  @override
  Stream<List<HouseRuleEntity>> watchByPropertyId(String propertyId) {
    return _supabase
        .from(SupabaseTables.houseRules)
        .stream(primaryKey: ['id'])
        .order('sort_order', ascending: true)
        .asyncMap((rules) async {
      // Filtrar por property_id y is_active
      final filteredRules = rules.where((rule) {
        final rulePropertyId = rule['property_id'] as String?;
        final isActive = rule['is_active'] as bool? ?? true;
        return rulePropertyId == propertyId && isActive;
      }).toList();

      return filteredRules
          .map((json) => HouseRuleEntity.fromJson(json))
          .toList();
    });
  }
}
