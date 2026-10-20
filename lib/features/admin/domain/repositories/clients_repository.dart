import '../entities/client_entity.dart';

abstract class ClientsRepository {
  Future<List<ClientEntity>> getAll();
  Future<List<ClientEntity>> getByPropertyId(String propertyId);
  Future<ClientEntity?> getById(String id);
  Future<ClientEntity?> findByNif(String nif);
  Future<List<ClientEntity>> search(String query);
  Future<ClientEntity> create(ClientEntity client);
  Future<ClientEntity> update(ClientEntity client);
  Future<void> delete(String id);
}
