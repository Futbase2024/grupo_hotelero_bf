import 'message_entity.dart';

/// Representa un cambio en tiempo real sobre los mensajes de una conversación.
///
/// Permite distinguir entre un mensaje nuevo ([MessageAdded]) y la eliminación
/// de uno existente ([MessageDeleted]), para que el stream de realtime pueda
/// reflejar ambos casos en la UI.
sealed class MessageChange {
  const MessageChange();
}

/// Se ha recibido un mensaje nuevo.
class MessageAdded extends MessageChange {
  const MessageAdded(this.message);

  final MessageEntity message;
}

/// Un mensaje existente ha sido eliminado.
class MessageDeleted extends MessageChange {
  const MessageDeleted(this.messageId);

  final String messageId;
}
