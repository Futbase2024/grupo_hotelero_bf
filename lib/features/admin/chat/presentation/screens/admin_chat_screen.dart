import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../auth/domain/bloc/auth_bloc.dart';
import '../../../../guest/chat/data/services/chat_media_service.dart';
import '../../../../guest/chat/domain/bloc/chat_bloc.dart';
import '../../../../guest/chat/domain/repositories/chat_repository.dart';
import '../../../../guest/chat/presentation/widgets/attachment_uploading_bubble.dart';
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

  @override
  void initState() {
    super.initState();
    _chatBloc = ChatBloc(
      chatRepository: getIt<ChatRepository>(),
      mediaService: getIt<ChatMediaService>(),
    );
    final authState = context.read<AuthBloc>().state;
    _tryInitChat(authState);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // `close()` ya cancela la suscripción de mensajes y libera el repositorio
    // (mismo trabajo que el evento ChatDisposed), así que no hace falta
    // encolar ChatDisposed justo antes de cerrar el bloc.
    _chatBloc.close();
    super.dispose();
  }

  void _tryInitChat(AuthState authState) {
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      _chatBloc.add(ChatStarted(
        propertyId: user.propertyId ?? '',
        userId: user.id,
        userName: user.name ?? user.displayName,
        conversationId: widget.conversationId,
      ));
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

  void _onSendAttachment(List<ChatAttachmentDraft> drafts) {
    _chatBloc.add(ChatSendAttachment(drafts: drafts));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _confirmDeleteMessage(
    BuildContext context,
    String messageId,
  ) async {
    final s = S.of(context);
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: s.chat_delete_message,
      body: s.chat_delete_message_confirm_body,
      confirmText: s.common_delete,
      cancelText: s.common_cancel,
      isDestructive: true,
    );
    if (confirmed) {
      _chatBloc.add(ChatDeleteMessage(messageId: messageId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatBloc,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, authState) {
          if (_chatBloc.state is ChatInitial) {
            _tryInitChat(authState);
          }
        },
        child: Scaffold(
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
                    onSendAttachment: _onSendAttachment,
                    enabled: state.isConversationReady,
                    isUploading: state.isUploadingAttachment,
                  ),
                ],
              );
            },
          ),
        ),
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
          final title = state is ChatLoaded ? state.otherParticipantName : S.of(context).admin_chat_title;
          final bookingId = state is ChatLoaded ? state.conversation.bookingId : null;

          return GestureDetector(
            onTap: bookingId != null
                ? () => context.push(
                      AppRoutes.adminBookingDetail.replaceFirst(':bookingId', bookingId),
                    )
                : null,
            child: Row(
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (bookingId != null) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.open_in_new_rounded,
                              size: 14,
                              color: AppColors.gold,
                            ),
                          ],
                        ],
                      ),
                      if (state is ChatLoaded)
                        Text(
                          S.of(context).admin_chat_online,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.success,
                              ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
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
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, color: AppColors.error),
                      const SizedBox(width: 12),
                      Text(S.of(context).admin_chat_delete_conversation),
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
      title: S.of(context).admin_chat_delete_conversation,
      body: S.of(context).admin_chat_delete_confirm_body,
      confirmText: S.of(context).common_delete,
      cancelText: S.of(context).common_cancel,
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
          SnackBar(
            content: Text(S.of(context).admin_chat_deleted_success),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }).catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).admin_chat_error_deleting('$error')),
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
                final authState = context.read<AuthBloc>().state;
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
              child: Text(S.of(context).common_retry),
            ),
          ],
        ),
      );
    }

    final messages = state.messagesOrNull;
    final currentUserId = state.currentUserIdOrNull;

    if (messages != null && currentUserId != null) {
      final uploading = state is ChatUploadingAttachment ? state : null;

      if (messages.isEmpty && uploading == null) {
        return _buildEmptyState(context);
      }

      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppTheme.spacing16),
        itemCount: messages.length + (uploading != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == messages.length) {
            return AttachmentUploadingBubble(
              fileName: uploading!.fileName,
              currentIndex: uploading.currentIndex,
              total: uploading.total,
            );
          }

          final message = messages[index];
          final isFromMe = message.isFromMe(currentUserId);

          return MessageBubble(
            message: message,
            isFromMe: isFromMe,
            onDelete: isFromMe
                ? () => _confirmDeleteMessage(context, message.id)
                : null,
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
            S.of(context).admin_chat_empty_title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            S.of(context).admin_chat_empty_subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.gray500,
                ),
          ),
        ],
      ),
    );
  }
}
