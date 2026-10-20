# Plan: Adjuntos (imágenes y documentos) en el chat

> **Feature**: Envío de imágenes y documentos desde el chat huésped ↔ staff
> **Fecha**: 2026-08-06
> **Rama**: feature/novedades

---

## 1. Contexto

El chat ya tiene el esqueleto para imágenes pero **nunca se usó**:

| Pieza | Estado previo |
|---|---|
| `MessageType.image` | ✅ existe |
| `sendImageMessage()` datasource/repo/contrato | ✅ existe, sin llamadas |
| `_buildImageContent()` en `MessageBubble` | ✅ existe (`CachedNetworkImage` sobre `content`) |
| CHECK `msg_type IN ('text','image')` | ✅ en BD |
| `notify_chat_message` con rama `image` | ✅ "📷 Imagen" |
| `lastMessagePreview` con rama `isImage` | ✅ "📷 Imagen" |
| Botón adjuntar en `ChatInput` | ❌ no existe |
| Bucket de Storage para chat | ❌ no existe |
| Soporte de documentos (PDF, etc.) | ❌ no existe |

Como no hay ni un solo mensaje `image` en producción, **no hay retrocompatibilidad que preservar**
en el formato de `content`.

---

## 2. Decisiones de diseño

### 2.1 Qué se guarda en `content`

Se guarda el **storage path** (`{conversation_id}/{uuid}.{ext}`), **no la URL**.

Motivo: el bucket es privado; las URLs firmadas caducan. Guardar la URL en BD la dejaría
muerta al expirar. El cliente resuelve la signed URL bajo demanda y la cachea en memoria.

`MessageBubble` usa `cacheKey: storagePath` en `CachedNetworkImage` para que el caché de disco
no se invalide cuando cambie la signed URL.

Fallback: si `content` empieza por `http`, se usa tal cual (tolerancia a datos antiguos/externos).

### 2.2 Ruta en el bucket

```
chat-media/{conversation_id}/{uuid}.{ext}
```

El primer segmento es el `conversation_id` para que las policies de `storage.objects` puedan
autorizar con `(storage.foldername(name))[1]::uuid` contra `conversation_participants`.

### 2.3 Metadatos de archivo

Se añaden 3 columnas nullable a `messages` en lugar de serializar JSON en `content`:
`file_name`, `file_size`, `mime_type`. Solo se rellenan para `msg_type = 'file'`
(y `mime_type` también para `image`).

### 2.4 Abrir documentos

Se usa `url_launcher` (ya en pubspec) sobre la signed URL en modo `externalApplication`,
en lugar de añadir `open_filex` + descarga a disco. Menos dependencias y menos superficie de fallo.

Única dependencia nueva: **`file_picker`** (no hay alternativa para elegir documentos).

### 2.5 Límites

| Concepto | Valor |
|---|---|
| Tamaño máximo por archivo | 10 MB (igual que `guest-documents`) |
| Compresión de imágenes | maxWidth/Height 1600, quality 80 (vía `image_picker`) |
| MIME permitidos | jpeg, png, webp, heic, gif, pdf, doc(x), xls(x), txt |
| Caducidad signed URL | 1 año (31.536.000 s), cacheada en memoria |

---

## 3. Fase 0 — Base de datos y Storage

**Migración `chat_attachments_support`:**

1. `messages`: drop + recreate CHECK → `msg_type IN ('text','image','file')`
2. `messages`: `ALTER TABLE ADD COLUMN file_name TEXT, file_size BIGINT, mime_type TEXT`
3. Crear bucket `chat-media` (privado, 10 MB, MIME whitelist)
4. Policies sobre `storage.objects` para `bucket_id = 'chat-media'`:
   - **SELECT**: participante de la conversación (carpeta) **o** admin/staff
   - **INSERT**: participante de la conversación
   - **DELETE**: `owner = auth.uid()` **o** admin/staff
5. `notify_chat_message`: añadir rama `msg_type = 'file'` → "📎 Documento"

---

## 4. Fase 1 — Imágenes

| # | Archivo | Cambio |
|---|---|---|
| 1 | `pubspec.yaml` | + `file_picker` |
| 2 | `chat/data/services/chat_media_service.dart` | **NUEVO**: pick/compress/upload/signedUrl/delete |
| 3 | `chat/domain/entities/message_entity.dart` | + `MessageType.file`, `fileName`, `fileSize`, `mimeType`, getters |
| 4 | `chat/data/datasources/chat_datasource.dart` | `sendImageMessage` con mime; + `sendFileMessage`; + `getMessageAttachmentPaths` |
| 5 | `chat/domain/repositories/chat_repository.dart` | + `sendFileMessage`, firma extendida |
| 6 | `chat/data/repositories/chat_repository_impl.dart` | pass-through |
| 7 | `chat/domain/bloc/chat_bloc.dart` | + `ChatSendAttachment`, estado `ChatAttachmentUploading`; borrado limpia storage |
| 8 | `chat/presentation/widgets/chat_input.dart` | + botón 📎 + bottom sheet (Cámara/Galería/Documento) |
| 9 | `chat/presentation/widgets/attachment_source_sheet.dart` | **NUEVO** (SafeArea top:false) |
| 10 | `chat/presentation/widgets/message_bubble.dart` | imagen con signed URL + tap → visor; burbuja de documento |
| 11 | `chat/presentation/screens/chat_image_viewer.dart` | **NUEVO**: visor fullscreen con `InteractiveViewer` |
| 12 | `chat_screen.dart` / `admin_chat_screen.dart` | conectar `onSendAttachment` |
| 13 | `core/di/injection.dart` | registrar `ChatMediaService` |
| 14 | `lib/l10n/app_*.arb` (7) + generados (8) | claves nuevas |

---

## 5. Fase 2 — Documentos

Se integra en los mismos archivos de la Fase 1 (por eso van juntos):
- `MessageType.file` + columnas ya cubiertas en Fase 0
- `_buildFileContent()` en `MessageBubble`: icono por MIME + nombre + tamaño + acción abrir
- Opción "Documento" en el bottom sheet vía `file_picker`
- `lastMessagePreview` → "📎 {nombre}"

---

## 6. Limpieza de Storage

| Evento | Acción |
|---|---|
| Borrar mensaje con adjunto | `ChatBloc` conoce el mensaje → borra su objeto del bucket antes del DELETE en BD |
| Borrar conversación (admin) | `ChatDatasource.deleteConversation` lista `chat-media/{id}/` y hace `remove()` |

Sin esto quedarían archivos huérfanos (mismo problema que resolvió `guest_documents_cleaner.dart`).

---

## 7. Claves l10n nuevas

```
chat_attach_title, chat_attach_camera, chat_attach_gallery, chat_attach_document,
chat_attachment_uploading, chat_attachment_too_large, chat_attachment_upload_error,
chat_attachment_open_error, chat_attachment_file_preview
```

En los 7 idiomas: es (plantilla), en, de, fr, it, pt.

---

## 8. Checklist

- [x] Migración BD aplicada (`chat_attachments_support`, `chat_notification_file_preview`)
- [x] Bucket `chat-media` + 3 policies creados
- [x] `file_picker 8.1.7` resuelto en `pubspec.lock`
- [x] Código Fase 1 + 2
- [x] l10n en 6 idiomas (es/en/de/fr/it/pt) + regenerados con `flutter gen-l10n`
- [x] `dart fix --apply && dart analyze` — 0 errores nuevos
- [x] `flutter test` — 18/18 pasan (4 tests nuevos de adjuntos)
- [ ] **Pendiente**: prueba manual en dispositivo — huésped envía foto → staff la ve;
      staff envía PDF → huésped lo abre

---

## 9. Desviaciones respecto al plan inicial

| Punto | Decisión final | Motivo |
|---|---|---|
| 6 idiomas, no 7 | El proyecto tiene es/en/de/fr/it/pt | `app_localizations_pt.dart` existe pero no hay un 7º locale |
| `chat_attachment_uploading` sin placeholder | Texto fijo "Enviando archivo…" + nombre en línea aparte | Evita ICU placeholders y simplifica la burbuja |
| Extensión `ChatStateX` | Añadida en `chat_bloc.dart` | Las pantallas encadenaban `is ChatLoaded ? ... : (state as ChatSending)`; con 3 estados eso se volvía ilegible |
| `AttachmentUploadingBubble` | Widget nuevo no previsto | La subida tarda segundos; sin feedback en la lista parecía que no pasaba nada |

`flutter_image_compress` aparece en `pubspec.yaml` pero **no lo usa esta feature**:
la compresión se hace con los parámetros de `image_picker` (1600 px, calidad 80).

---

## 10. Fase 3 — Mejoras posteriores

Añadidas tras la primera entrega (todo menos vídeos/audios, descartados por el usuario).

| Mejora | Implementación |
|---|---|
| **Varios archivos a la vez** | `pickImages()` / `pickDocuments()` con multi-selección. El evento pasa a `ChatSendAttachment(drafts: [...])` y el BLoC los sube **en orden**, un mensaje por archivo. La cámara sigue siendo de una foto. |
| **Progreso de subida** | `ChatUploadingAttachment` lleva `currentIndex` / `total` → burbuja "Enviando 2 de 5…". |
| **Guardar en galería** | Botón de descarga en `ChatImageViewer` → `ChatMediaService.saveImageToGallery()` con `gal`. Descarga el **original** del bucket, no el thumbnail cacheado. |
| **Miniatura en la lista** | `ConversationPreviewThumbnail` (28×28) junto al "📷 Imagen" en `ConversationTile`. |

### Límite conocido: no hay progreso por bytes

`storage_client 2.4.1` **no expone ningún callback de progreso** en `uploadBinary`
(verificado en el fuente del paquete: no existe `onProgress` ni equivalente). Una barra
de porcentaje sería inventada. El progreso mostrado —"archivo N de M"— es real. Para tener
porcentaje de bytes habría que reimplementar la subida con `http.MultipartRequest`,
perdiendo el reintento y la gestión de auth del SDK: no compensa.

### Política ante fallo parcial de un lote

Si un archivo del lote falla, **se detiene el resto**: los ya enviados se conservan y los
pendientes no se suben. La alternativa (seguir y reportar los fallidos al final) deja al
usuario sin saber qué llegó. Cubierto por test.

### Permisos nativos añadidos

- **iOS**: `NSPhotoLibraryAddUsageDescription` en `Info.plist` (lo exige `gal` para escribir)
- **Android**: ya existía `WRITE_EXTERNAL_STORAGE` con `maxSdkVersion="28"`, que es
  justo lo que `gal` necesita en Android ≤ 9

### Verificación Fase 3

- [x] `dart analyze` — 0 errores nuevos (3 issues preexistentes ajenos a esta feature)
- [x] `flutter test` — 20/20 pasan (2 tests nuevos: lote en orden con progreso, y corte ante fallo)
- [x] `flutter build apk --debug` — OK
- [x] `flutter build ios --no-codesign --debug` — OK (pod install incluido)
