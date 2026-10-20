import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/client_entity.dart';
import '../../domain/repositories/clients_repository.dart';

class ClientsRepositoryImpl implements ClientsRepository {
  ClientsRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<ClientEntity>> getAll() async {
    final response = await _client
        .from('clients')
        .select()
        .eq('is_active', true)
        .order('name', ascending: true);

    return (response as List)
        .map((json) => ClientEntity.fromJson(json))
        .toList();
  }

  @override
  Future<List<ClientEntity>> getByPropertyId(String propertyId) async {
    final response = await _client
        .from('clients')
        .select()
        .eq('property_id', propertyId)
        .eq('is_active', true)
        .order('name', ascending: true);

    return (response as List)
        .map((json) => ClientEntity.fromJson(json))
        .toList();
  }

  @override
  Future<ClientEntity?> getById(String id) async {
    final response = await _client
        .from('clients')
        .select()
        .eq('id', id)
        .maybeSingle();

    return response != null ? ClientEntity.fromJson(response) : null;
  }

  @override
  Future<ClientEntity?> findByNif(String nif) async {
    final response = await _client
        .from('clients')
        .select()
        .eq('nif', nif)
        .eq('is_active', true)
        .maybeSingle();

    return response != null ? ClientEntity.fromJson(response) : null;
  }

  @override
  Future<List<ClientEntity>> search(String query) async {
    final response = await _client
        .from('clients')
        .select()
        .eq('is_active', true)
        .or('name.ilike.%$query%,nif.ilike.%$query%,email.ilike.%$query%')
        .order('name', ascending: true)
        .limit(20);

    return (response as List)
        .map((json) => ClientEntity.fromJson(json))
        .toList();
  }

  @override
  Future<ClientEntity> create(ClientEntity client) async {
    final response = await _client
        .from('clients')
        .insert(client.toJson())
        .select()
        .single();

    return ClientEntity.fromJson(response);
  }

  @override
  Future<ClientEntity> update(ClientEntity client) async {
    final response = await _client
        .from('clients')
        .update(client.toJson())
        .eq('id', client.id)
        .select()
        .single();

    return ClientEntity.fromJson(response);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('clients').update({'is_active': false}).eq('id', id);
  }
}
