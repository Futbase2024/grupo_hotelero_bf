import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../auth/domain/bloc/auth_bloc.dart';
import '../../../../guest/chat/domain/repositories/chat_repository.dart';
import '../../domain/bloc/conversations_bloc.dart';
import '../widgets/conversation_tile.dart';

// ignore: avoid_classes_with_only_static_members
class _Debug {
  static void log(String message) {
    debugPrint('🔵 [ConversationsScreen] $message');
  }
}

/// Pantalla de lista de conversaciones para admin/staff
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  late final ConversationsBloc _conversationsBloc;
  late final AuthBloc _authBloc;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _Debug.log('initState');
    _conversationsBloc = ConversationsBloc(
      chatRepository: getIt<ChatRepository>(),
    );
    _authBloc = context.read<AuthBloc>();
  }

  @override
  void dispose() {
    _Debug.log('dispose');
    _conversationsBloc.close();
    super.dispose();
  }

  void _initializeConversations(AuthState authState) {
    if (_initialized) return;

    _Debug.log('_initializeConversations - authState: ${authState.runtimeType}');

    if (authState is AuthAuthenticated) {
      final user = authState.user;
      _Debug.log('User: ${user.id}, role: ${user.role}, propertyId: ${user.propertyId}');

      // Validar que propertyId no sea null, vacío ni solo espacios
      final propertyId = user.propertyId?.trim();
      if (propertyId != null && propertyId.isNotEmpty) {
        // Si tiene propertyId válido, cargar conversaciones de la propiedad
        _Debug.log('Cargando conversaciones por propertyId: $propertyId');
        _conversationsBloc.add(
          ConversationsStarted(propertyId: propertyId),
        );
      } else {
        // Sin propertyId válido, cargar conversaciones donde el usuario es participante
        _Debug.log('Sin propertyId - cargando conversaciones por userId: ${user.id}');
        _conversationsBloc.add(
          ConversationsLoadForUser(userId: user.id),
        );
      }
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _conversationsBloc,
      child: BlocBuilder<AuthBloc, AuthState>(
        bloc: _authBloc,
        builder: (context, authState) {
          // Inicializar conversaciones cuando tengamos el estado de auth
          _initializeConversations(authState);

          return Scaffold(
            appBar: _buildAppBar(context),
            body: BlocBuilder<ConversationsBloc, ConversationsState>(
              builder: (context, state) {
                return _buildBody(context, state);
              },
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/admin'),
      ),
      title: Row(
        children: [
          const Text('Mensajes'),
          const SizedBox(width: AppTheme.spacing8),
          BlocBuilder<ConversationsBloc, ConversationsState>(
            builder: (context, state) {
              if (state is ConversationsLoaded && state.totalUnread > 0) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    state.totalUnread > 99 ? '99+' : state.totalUnread.toString(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.black,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ConversationsState state) {
    if (state is ConversationsLoading || state is ConversationsInitial) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.gold,
        ),
      );
    }

    if (state is ConversationsError) {
      return _buildErrorState(context, state);
    }

    if (state is ConversationsLoaded) {
      if (state.hasConversations) {
        return _buildConversationsList(context, state);
      }
      return _buildEmptyState(context);
    }

    return const SizedBox.shrink();
  }

  Widget _buildConversationsList(BuildContext context, ConversationsLoaded state) {
    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: () async {
        _conversationsBloc.add(const ConversationsRefreshRequested());
      },
      child: ListView.builder(
        itemCount: state.sortedConversations.length,
        itemBuilder: (context, index) {
          final conversation = state.sortedConversations[index];
          return ConversationTile(
            conversation: conversation,
            onTap: () => _openConversation(context, conversation.id),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.goldWithAlpha20,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),
          Text(
            'Sin conversaciones',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Las conversaciones con huéspedes\naparecerán aquí',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.gray500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ConversationsError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            state.message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacing16),
          ElevatedButton(
            onPressed: () {
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated) {
                final user = authState.user;
                // Validar que propertyId no sea null, vacío ni solo espacios
                final propertyId = user.propertyId?.trim();
                if (propertyId != null && propertyId.isNotEmpty) {
                  _conversationsBloc.add(
                    ConversationsStarted(propertyId: propertyId),
                  );
                } else {
                  // Sin propertyId válido, cargar por userId
                  _conversationsBloc.add(
                    ConversationsLoadForUser(userId: user.id),
                  );
                }
              }
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  void _openConversation(BuildContext context, String conversationId) {
    context.go('/admin/chat/$conversationId');
  }
}
