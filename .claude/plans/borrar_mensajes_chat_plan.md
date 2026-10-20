# Plan: Borrado real de mensajes en el chat (huésped + admin)

> **Objetivo**: Permitir que cada usuario (huésped y admin/staff) borre de forma
> permanente **cualquier mensaje que él mismo haya enviado**, en caso de error.
> Borrado real (hard delete), con confirmación, y reflejo en tiempo real en el
> dispositivo del otro participante.

## Decisiones de producto
- ✅ **Confirmación** antes de borrar (diálogo).
- ✅ Cada uno borra **solo sus propios mensajes** (simétrico huésped ↔ admin).
- ✅ **Borrado real** (no soft delete). El mensaje desaparece; no se muestra
  "mensaje eliminado".

## Hallazgos técnicos (verificados)
- La tabla `messages` **no tiene política DELETE** en RLS (solo SELECT/INSERT/UPDATE),
  por lo que hoy un `.delete()` del cliente no borra nada.
- `message_translations` tiene FK `ON DELETE CASCADE` → al borrar un mensaje se
  borran sus traducciones automáticamente.
- El stream `watchMessages` actual **solo emite mensajes nuevos** (trackea
  `emittedMessageIds` y hace `.expand()`), por lo que **no detecta borrados**.
  Hay que añadir detección de eliminaciones para que se refleje al otro lado.
- Los guests anónimos tienen rol `authenticated`, así que la policy con
  `auth.uid()` funciona para ambos.

---

## 1. Backend — Migración Supabase
Archivo nuevo: `supabase/migrations/<timestamp>_add_messages_delete_policy.sql`

```sql
-- Permite a cada usuario borrar ÚNICAMENTE los mensajes que él mismo envió.
DROP POLICY IF EXISTS "messages_delete_own" ON public.messages;
CREATE POLICY "messages_delete_own" ON public.messages
FOR DELETE
USING (sender_user_id = (SELECT auth.uid()));
```

- Replica identity por PK es suficiente para que el evento DELETE de Realtime
  llegue (borrado por primary key). La tabla ya está en la publicación de
  realtime (los INSERT ya funcionan).

## 2. Data layer

### 2.1 `ChatDatasource` (`.../chat/data/datasources/chat_datasource.dart`)
Nuevo método:
```dart
Future<void> deleteMessage({required String messageId}) async {
  await _client.from(SupabaseTables.messages).delete().eq('id', messageId);
}
```

### 2.2 Realtime — detectar borrados en `watchMessages`
Cambiar el contrato del stream de `Stream<MessageEntity>` a
`Stream<MessageChange>`, donde `MessageChange` es un pequeño sealed/clase:
- `MessageAdded(MessageEntity message)`
- `MessageDeleted(String messageId)`

Dentro del `asyncMap`, además de calcular los mensajes nuevos (no emitidos),
calcular `deletedIds = emittedMessageIds - idsActuales` y emitir un
`MessageDeleted` por cada uno (y quitarlos de `emittedMessageIds`).
`supabase_flutter.stream()` ya mantiene la lista completa actualizada y elimina
por PK, así que la lista recibida ya viene sin el mensaje borrado.

### 2.3 Contrato repositorio (`domain/repositories/chat_repository.dart`)
- Añadir `Future<void> deleteMessage({required String messageId});`
- Cambiar la firma de `watchMessages` a `Stream<MessageChange>`.

### 2.4 Impl repositorio (`data/repositories/chat_repository_impl.dart`)
- Pass-through de `deleteMessage` y `watchMessages`.

## 3. BLoC (`domain/bloc/chat_bloc.dart`)
- Nuevo evento `ChatDeleteMessage(String messageId)`:
  - Optimista: quita el mensaje de la lista y emite `ChatLoaded`.
  - Llama `_chatRepository.deleteMessage(...)`; si falla, restaura la lista y
    emite error temporal (mismo patrón que envío).
- Nuevo evento `ChatMessageDeleted(String messageId)` (desde realtime):
  - Si el mensaje está en la lista, lo elimina y emite `ChatLoaded`.
- Adaptar la suscripción: enrutar `MessageAdded` → `ChatMessageReceived`,
  `MessageDeleted` → `ChatMessageDeleted`.

## 4. UI

### 4.1 `MessageBubble` (`.../presentation/widgets/message_bubble.dart`)
- Añadir callback opcional `VoidCallback? onDelete`.
- Envolver la burbuja en `GestureDetector` con `onLongPress` **solo cuando
  `isFromMe && onDelete != null`**, que dispara el flujo de borrado.

### 4.2 Pantallas (huésped y admin)
`chat_screen.dart` y `admin_chat_screen.dart`:
- Pasar `onDelete` al `MessageBubble` que:
  1. Muestra `ConfirmationDialog` (destructivo) con textos i18n.
  2. Si confirma, añade `ChatDeleteMessage(message.id)` al `ChatBloc`.
- Reutilizar el `ConfirmationDialog` que ya usa el admin para borrar conversación.

## 5. i18n (`l10n/*.arb`)
Añadir claves (ES/EN/… según idiomas del proyecto):
- `chat_delete_message` — "Eliminar mensaje"
- `chat_delete_message_confirm_body` — "¿Seguro que quieres eliminar este mensaje? Esta acción no se puede deshacer."
- `chat_delete_message_error` — "No se pudo eliminar el mensaje"

## 6. Tests
- `chat_bloc_test.dart`: casos para `ChatDeleteMessage` (éxito, error/restauración)
  y `ChatMessageDeleted` (elimina si existe, no-op si no).
- Mantener cobertura 85%+.

---

## Notas / límites conocidos
- El preview de "último mensaje" en la lista de conversaciones del admin
  (`watchUserConversations`, basado en `conversation_participants`) puede tardar
  en refrescarse si se borra el último mensaje, ya que ese stream no se dispara
  por cambios en `messages`. Es cosmético; se puede abordar aparte si molesta.
- Solo se implementa borrado de mensajes propios; sin moderación cruzada.

## Orden de ejecución
1. Migración RLS (requiere autorización).
2. Datasource + `MessageChange` + repositorio (contrato/impl).
3. BLoC (eventos).
4. UI (MessageBubble + ambas pantallas + i18n).
5. `dart fix --apply && dart analyze` (requiere autorización).
6. Tests + `flutter test` (requiere autorización).
```