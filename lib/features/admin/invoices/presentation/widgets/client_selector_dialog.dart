import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/client_entity.dart';
import '../bloc/invoices_bloc.dart';
import '../bloc/invoices_event.dart';
import '../bloc/invoices_state.dart';

Future<ClientEntity?> showClientSelectorDialog(
  BuildContext context,
) async {
  final bloc = context.read<InvoicesBloc>();
  return showDialog<ClientEntity>(
    context: context,
    builder: (_) => BlocProvider<InvoicesBloc>.value(
      value: bloc,
      child: const _ClientSelectorDialog(),
    ),
  );
}

class _ClientSelectorDialog extends StatefulWidget {
  const _ClientSelectorDialog();

  @override
  State<_ClientSelectorDialog> createState() => _ClientSelectorDialogState();
}

class _ClientSelectorDialogState extends State<_ClientSelectorDialog> {
  final _searchController = TextEditingController();
  String _lastQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    final state = context.read<InvoicesBloc>().state;
    if (state.clients.isEmpty && !state.isLoadingClients) {
      context.read<InvoicesBloc>().add(const InvoicesLoadClientsRequested());
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() => _lastQuery = query);

    // Debounce: evita disparar una query a Supabase por cada pulsación.
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (query.isEmpty) {
        // Mostrar todos
        context.read<InvoicesBloc>().add(const InvoicesLoadClientsRequested());
      } else if (query.length >= 2) {
        // Buscar en servidor
        context.read<InvoicesBloc>().add(InvoicesSearchClients(query));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: AppColors.darkBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),
            const Divider(color: AppColors.darkBorder, height: 1),

            // Barra de busqueda
            _buildSearchBar(),

            // Lista de clientes
            Flexible(child: _buildClientsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.goldWithAlpha10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.person_search_outlined,
              color: AppColors.gold,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Seleccionar cliente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppColors.gray400),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppColors.white, fontSize: 15),
        onChanged: _onSearchChanged,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, NIF o email...',
          hintStyle: const TextStyle(color: AppColors.gray500, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppColors.gray500, size: 20),
          filled: true,
          fillColor: AppColors.darkSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildClientsList() {
    return BlocBuilder<InvoicesBloc, InvoicesState>(
      builder: (context, state) {
        final clients = state.clients;

        if (state.isLoadingClients) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2),
            ),
          );
        }

        if (clients.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_off_outlined,
                  size: 48,
                  color: AppColors.gray600,
                ),
                const SizedBox(height: 12),
                Text(
                  _lastQuery.isEmpty
                      ? 'No hay clientes guardados'
                      : 'No se encontraron clientes',
                  style: const TextStyle(
                    color: AppColors.gray400,
                    fontSize: 14,
                  ),
                ),
                if (_lastQuery.isEmpty) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Los clientes se guardan automaticamente al crear facturas',
                    style: TextStyle(
                      color: AppColors.gray600,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
          itemCount: clients.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final client = clients[index];
            return _buildClientTile(client);
          },
        );
      },
    );
  }

  Widget _buildClientTile(ClientEntity client) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(client),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          children: [
            // Avatar con inicial
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.goldWithAlpha10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info del cliente
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.name,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (client.nif != null && client.nif!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'NIF: ${client.nif}',
                      style: const TextStyle(
                        color: AppColors.gray400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (client.email != null && client.email!.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      client.email!,
                      style: const TextStyle(
                        color: AppColors.gray500,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Icono de seleccion
            const Icon(
              Icons.chevron_right,
              color: AppColors.gray500,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
