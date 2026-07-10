import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bf_stay/l10n/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/di/injection.dart';
import '../../../../admin/shared/widgets/confirmation_dialog.dart';
import '../../../../auth/domain/bloc/auth_bloc.dart';
import '../../domain/bloc/chat_bloc.dart';
import '../../domain/repositories/chat_repository.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';

/// Pantalla de Chat con el personal
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();
  late final ChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    _chatBloc = ChatBloc(chatRepository: getIt<ChatRepository>());
    // Inicializar con el estado actual de auth (sin esperar un rebuild)
    final authState = context.read<AuthBloc>().state;
    _tryInitChat(authState);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chatBloc.add(const ChatDisposed());
    _chatBloc.close();
    super.dispose();
  }

  void _tryInitChat(AuthState authState) {
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      if (user.propertyId != null && user.propertyId!.isNotEmpty) {
        _chatBloc.add(ChatStarted(
          propertyId: user.propertyId!,
          bookingId: user.bookingId,
          userId: user.id,
          userName: user.name ?? user.displayName,
        ));
      }
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
          // Solo inicializar si el chat aún no arrancó (auth tardó más que el build)
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
                    enabled: state is ChatLoaded || state is ChatSending,
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
    final s = S.of(context);
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/guest'),
      ),
      title: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          final title = state is ChatLoaded ? state.otherParticipantName : s.guest_chat_default_title;
          final isOnline = state is ChatLoaded;

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
                    Icons.support_agent,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  if (isOnline)
                    Text(
                      s.guest_chat_online,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                          ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context, ChatState state) {
    final s = S.of(context);
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
                  if (user.propertyId != null) {
                    _chatBloc.add(ChatStarted(
                      propertyId: user.propertyId!,
                      bookingId: user.bookingId,
                      userId: user.id,
                      userName: user.name ?? user.displayName,
                    ));
                  }
                }
              },
              child: Text(s.common_retry),
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
    final s = S.of(context);
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
            s.guest_chat_welcome_message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            s.guest_chat_start_conversation,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.gray500,
                ),
          ),
        ],
      ),
    );
  }
}
