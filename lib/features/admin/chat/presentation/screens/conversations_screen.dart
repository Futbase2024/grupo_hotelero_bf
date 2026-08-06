import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../auth/domain/bloc/auth_bloc.dart';
import '../../domain/bloc/conversations_bloc.dart';
import '../widgets/conversation_tile.dart';
import '../widgets/conversations_search_field.dart';

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
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inicializar solo si el BLoC aún no ha cargado datos
    // (evita recargar al volver desde una conversación)
    final bloc = context.read<ConversationsBloc>();
    if (bloc.state is ConversationsInitial) {
      final authState = context.read<AuthBloc>().state;
      _initializeConversations(bloc, authState);
    }
  }

  void _initializeConversations(ConversationsBloc bloc, AuthState authState) {
    if (authState is! AuthAuthenticated) return;

    final user = authState.user;
    _Debug.log('User: ${user.id}, role: ${user.role}, propertyId: ${user.propertyId}');

    final propertyId = user.propertyId?.trim();
    if (propertyId != null && propertyId.isNotEmpty) {
      _Debug.log('Cargando conversaciones por propertyId: $propertyId');
      bloc.add(ConversationsStarted(propertyId: propertyId));
    } else {
      _Debug.log('Sin propertyId - cargando conversaciones por userId: ${user.id}');
      bloc.add(ConversationsLoadForUser(userId: user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        final bloc = context.read<ConversationsBloc>();
        if (bloc.state is ConversationsInitial) {
          _initializeConversations(bloc, authState);
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: BlocBuilder<ConversationsBloc, ConversationsState>(
          builder: (context, state) {
            return _buildBody(context, state);
          },
        ),
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
          Text(S.of(context).admin_chat_messages),
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
      if (!state.hasConversations) {
        return _buildEmptyState(context);
      }

      // El buscador se mantiene visible aunque el filtro no devuelva nada, o
      // no habría forma de corregir la búsqueda.
      return Column(
        children: [
          ConversationsSearchField(
            initialValue: state.searchQuery,
            onChanged: (query) => context
                .read<ConversationsBloc>()
                .add(ConversationsSearchChanged(query: query)),
          ),
          Expanded(
            child: state.hasNoSearchResults
                ? _buildNoResultsState(context, state.searchQuery)
                : _buildConversationsList(context, state),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildConversationsList(BuildContext context, ConversationsLoaded state) {
    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: () async {
        context.read<ConversationsBloc>().add(const ConversationsRefreshRequested());
      },
      child: ListView.builder(
        itemCount: state.visibleConversations.length,
        itemBuilder: (context, index) {
          final conversation = state.visibleConversations[index];
          return ConversationTile(
            conversation: conversation,
            onTap: () => _openConversation(context, conversation.id),
            onDelete: () => _deleteConversation(context, conversation.id),
          );
        },
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.goldWithAlpha20,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off,
                size: 32,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              S.of(context).admin_chat_search_no_results(query),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.gray500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteConversation(BuildContext context, String conversationId) {
    context.read<ConversationsBloc>().add(ConversationsDeleteRequested(conversationId: conversationId));

    // Mostrar feedback al usuario
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(S.of(context).admin_chat_conversation_deleted),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
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
            S.of(context).admin_chat_empty_title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            S.of(context).admin_chat_empty_subtitle,
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
                  context.read<ConversationsBloc>().add(
                    ConversationsStarted(propertyId: propertyId),
                  );
                } else {
                  context.read<ConversationsBloc>().add(
                    ConversationsLoadForUser(userId: user.id),
                  );
                }
              }
            },
            child: Text(S.of(context).common_retry),
          ),
        ],
      ),
    );
  }

  void _openConversation(BuildContext context, String conversationId) {
    context.go('/admin/chat/$conversationId');
  }
}
