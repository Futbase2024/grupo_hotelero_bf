import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bf_stay/core/theme/app_colors.dart';
import 'package:bf_stay/core/theme/app_theme.dart';

/// Pantalla de Chat con el personal
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: '¡Bienvenido a BF Stay! ¿En qué podemos ayudarte?',
      isFromStaff: true,
      time: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    _ChatMessage(
      text: 'Gracias! ¿A qué hora es el desayuno?',
      isFromStaff: false,
      time: DateTime.now().subtract(const Duration(hours: 1, minutes: 50)),
    ),
    _ChatMessage(
      text: 'El desayuno se sirve de 7:30 a 10:30 en el comedor principal.',
      isFromStaff: true,
      time: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isFromStaff: false,
        time: DateTime.now(),
      ));
      _messageController.clear();
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/guest'),
        ),
        title: Row(
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
                const Text('Recepción'),
                Text(
                  'En línea',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppTheme.spacing16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _MessageBubble(message: _messages[index]);
              },
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: AppColors.background,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        filled: true,
                        fillColor: AppColors.backgroundInput,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing20,
                          vertical: AppTheme.spacing12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isFromStaff,
    required this.time,
  });

  final String text;
  final bool isFromStaff;
  final DateTime time;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final alignment =
        message.isFromStaff ? Alignment.centerLeft : Alignment.centerRight;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
        padding: const EdgeInsets.all(AppTheme.spacing12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isFromStaff
              ? AppColors.gray100
              : AppColors.gold,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppTheme.radiusMedium),
            topRight: const Radius.circular(AppTheme.radiusMedium),
            bottomLeft: message.isFromStaff
                ? const Radius.circular(0)
                : const Radius.circular(AppTheme.radiusMedium),
            bottomRight: message.isFromStaff
                ? const Radius.circular(AppTheme.radiusMedium)
                : const Radius.circular(0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: message.isFromStaff
                        ? AppColors.textPrimary
                        : Colors.white,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.time),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: message.isFromStaff
                        ? AppColors.textSecondary
                        : Colors.white.withValues(alpha: 0.8),
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
