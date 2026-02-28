import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/di/injection.dart';
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
      if (user.propertyId != null && user.propertyId!.isNotEmpty) {
        _chatBloc.add(ChatStarted(
          propertyId: user.propertyId!,
          bookingId: user.bookingId,
          userId: user.id,
          userName: user.name ?? user.displayName,
        ));
        _initialized = true;
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatBloc,
      child: BlocBuilder<AuthBloc, AuthState>(
        bloc: _authBloc,
        builder: (context, authState) {
          // Inicializar chat cuando el usuario esté autenticado
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
        onPressed: () => context.go('/guest'),
      ),
      title: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          final title = state is ChatLoaded ? state.otherParticipantName : 'Recepción';
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
                      'En línea',
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
            '¡Hola! ¿En qué podemos ayudarte?',
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
