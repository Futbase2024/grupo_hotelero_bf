import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../auth/domain/bloc/auth_bloc.dart';
import '../../../../guest/chat/domain/bloc/chat_bloc.dart';
import '../../../../guest/chat/domain/repositories/chat_repository.dart';
import '../../../../guest/chat/presentation/widgets/chat_input.dart';
import '../../../../guest/chat/presentation/widgets/message_bubble.dart';
import '../../../shared/widgets/confirmation_dialog.dart';

/// Pantalla de Chat para Admin/Staff
class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({
    super.key,
    required this.conversationId,
  });

  final String conversationId;

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final _scrollController = ScrollController();
  late final ChatBloc _chatBloc;
  late final AuthBloc _authBloc;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _chatBloc = ChatBloc(chatRepository: getIt<ChatRepository>());
    _authBloc = context.read<AuthBloc>();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chatBloc.add(const ChatDisposed());
    _chatBloc.close();
    super.dispose();
  }

  void _initializeChat(AuthState authState) {
    if (_initialized) return;

    if (authState is AuthAuthenticated) {
      final user = authState.user;
      // Cargar conversación específica usando el conversationId
      _chatBloc.add(ChatStarted(
        propertyId: user.propertyId ?? '',
        userId: user.id,
        userName: user.name ?? user.displayName,
        conversationId: widget.conversationId,
      ));
      _initialized = true;
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onSendMessage(String message) {
    _chatBloc.add(ChatSendMessage(content: message));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatBloc,
      child: BlocBuilder<AuthBloc, AuthState>(
        bloc: _authBloc,
        builder: (context, authState) {
          // Inicializar chat cuando tengamos el estado de auth
          _initializeChat(authState);

          return Scaffold(
            appBar: _buildAppBar(context),
            body: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state is ChatLoaded) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                }
              },
              builder: (context, state) {
                return Column(
                  children: [
                    Expanded(
                      child: _buildMessagesList(context, state),
                    ),
                    ChatInput(
                      onSend: _onSendMessage,
                      enabled: state is ChatLoaded || state is ChatSending,
                    ),
                  ],
                );
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
        onPressed: () => context.go('/admin/chat'),
      ),
      title: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          final title = state is ChatLoaded ? state.otherParticipantName : 'Chat';

          return Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (state is ChatLoaded)
                      Text(
                        'En línea',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.success,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            if (state is! ChatLoaded) return const SizedBox.shrink();

            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteConfirmation(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: AppColors.error),
                      SizedBox(width: 12),
                      Text('Eliminar conversación'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    ConfirmationDialog.show(
      context: context,
      title: 'Eliminar conversación',
      body: '¿Estás seguro de que quieres eliminar esta conversación? '
          'Se eliminarán todos los mensajes y no se podrá recuperar.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      isDestructive: true,
    ).then((confirmed) {
      if (confirmed && mounted) {
        _deleteConversation();
      }
    });
  }

  void _deleteConversation() {
    // Navegar hacia atrás antes de eliminar para evitar errores
    context.go('/admin/chat');

    // Usar el ChatRepository directamente para eliminar
    getIt<ChatRepository>().deleteConversation(
      conversationId: widget.conversationId,
    ).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversación eliminada'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }).catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });
  }

  Widget _buildMessagesList(BuildContext context, ChatState state) {
    if (state is ChatLoading || state is ChatInitial) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.gold,
        ),
      );
    }

    if (state is ChatError) {
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
                final authState = _authBloc.state;
                if (authState is AuthAuthenticated) {
                  final user = authState.user;
                  _chatBloc.add(ChatStarted(
                    propertyId: user.propertyId ?? '',
                    userId: user.id,
                    userName: user.name ?? user.displayName,
                    conversationId: widget.conversationId,
                  ));
                }
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state is ChatLoaded || state is ChatSending) {
      final messages = state is ChatLoaded
          ? state.messages
          : (state as ChatSending).messages;
      final currentUserId = state is ChatLoaded
          ? state.currentUserId
          : (state as ChatSending).currentUserId;

      if (messages.isEmpty) {
        return _buildEmptyState(context);
      }

      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppTheme.spacing16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          final isFromMe = message.isFromMe(currentUserId);

          return MessageBubble(
            message: message,
            isFromMe: isFromMe,
          );
        },
      );
    }

    return const SizedBox.shrink();
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
            'Conversación vacía',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Escribe un mensaje para comenzar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.gray500,
                ),
          ),
        ],
      ),
    );
  }
}
