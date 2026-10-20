# Plan: Buscador en la lista de conversaciones (admin)

> **Feature**: Buscar conversaciones en la pantalla «Mensajes» del panel de admin
> **Fecha**: 2026-08-06
> **Rama**: feature/novedades

---

## 1. Problema

La pantalla lista **todas** las conversaciones de la propiedad ordenadas por fecha del
último mensaje. Con decenas de reservas activas, localizar a un huésped concreto obliga a
hacer scroll hasta encontrarlo. El título de cada fila es
`displayNameForAdmin` = `«Nombre del huésped - #BF-XXXX-XXXX»`, así que hay dos criterios
naturales de búsqueda: **nombre** y **código de reserva**.

---

## 2. Decisiones de diseño

### 2.1 Filtrado local, no en servidor

Las conversaciones ya están **todas en memoria** (`ConversationsLoaded.conversations`) y se
mantienen al día por realtime. Ir al servidor por cada pulsación añadiría latencia y
complejidad sin ganar nada. Consecuencia: no hace falta debounce, el filtro es instantáneo.

### 2.2 Qué se indexa

| Campo | Se busca | Motivo |
|---|---|---|
| `guestName` | ✅ | Criterio principal |
| `guestParticipant.displayName` | ✅ | Respaldo cuando la reserva no trae nombre |
| `bookingCode` | ✅ | Tal cual: `BF-9KGF-9NYN` |
| `bookingCode` sin guiones | ✅ | Para que `9kgf9nyn` también encuentre |
| Último mensaje **de texto** | ✅ | Recordar por lo último que se habló |
| Último mensaje imagen/documento | ❌ | Su `content` es un **storage path**: buscar por UUID no sirve a nadie |

### 2.3 Normalización

Minúsculas + sin acentos, en ambos sentidos: `jesus` encuentra «Jesús García» y
`Domínguez` encuentra «Lidia Domínguez». Tabla de traducción explícita en
`ConversationsLoaded._normalize`, sin dependencias extra.

### 2.4 El filtro debe sobrevivir al realtime

Riesgo principal: escribes en el buscador, llega un mensaje de otro huésped y la lista se
repinta **perdiendo el filtro**. Por eso `searchQuery` se propaga en **todas** las
emisiones de `ConversationsLoaded` (realtime, refresh, select, delete, recarga).
Cubierto por test específico.

---

## 3. Cambios

| # | Archivo | Cambio |
|---|---|---|
| 1 | `conversations_bloc.dart` | + evento `ConversationsSearchChanged`; `ConversationsLoaded` gana `searchQuery` y `visibleConversations`; constructor pasa a factory + constructor privado para no ordenar dos veces |
| 2 | `conversations_search_field.dart` | **NUEVO**: campo de búsqueda con icono y botón de limpiar |
| 3 | `conversations_screen.dart` | Buscador sobre la lista; la lista pinta `visibleConversations`; estado «sin resultados» |
| 4 | `lib/l10n/app_*.arb` (6) | `admin_chat_search_hint`, `admin_chat_search_no_results` (con placeholder) |
| 5 | `conversations_search_test.dart` | **NUEVO**: 8 tests |

### Detalle: `hasNoSearchResults`

Se distingue «no hay conversaciones» (estado vacío de siempre) de «la búsqueda no encuentra
nada» (icono `search_off` + el término buscado). El buscador **sigue visible** cuando no hay
resultados; si se ocultara, no habría forma de corregir el término.

---

## 4. Verificación

- [x] `dart analyze` — 0 errores nuevos (3 issues preexistentes ajenos)
- [x] `flutter test` — 28/28 pasan (8 nuevos)
- [x] Casos cubiertos: mayúsculas, acentos en ambos sentidos, código con y sin guiones,
      texto del último mensaje, sin resultados, **filtro que sobrevive a realtime**,
      y que no se busque dentro de los storage paths
- [ ] **Pendiente**: prueba visual en dispositivo

---

## 5. Fuera de alcance

- Buscador en el chat del **huésped**: solo tiene una conversación, no aporta nada
- Búsqueda dentro de los mensajes de una conversación (buscar en el histórico): es otra
  feature, y esa sí necesitaría ir al servidor
- Filtros por estado (no leídos, archivados): no se pidió
