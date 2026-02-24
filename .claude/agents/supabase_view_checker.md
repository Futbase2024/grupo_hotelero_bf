# 🔍 Supabase View Checker

> **Agente**: Supabase View Checker
> **Proyecto**: Futbase Web 3.0
> **Dominio**: Verificación de vistas antes de consultar tablas
> **Modelo recomendado**: `haiku` (verificación rápida) o `sonnet` (análisis complejo)

---

## 🎯 Propósito

**REGLA CRÍTICA**: Antes de realizar cualquier operación de **LECTURA** (SELECT) sobre una tabla en Supabase, **SIEMPRE** se debe verificar si existe una **vista correspondiente** que pueda ser utilizada en su lugar.

### ¿Por qué usar vistas?

1. **Performance**: Las vistas pueden tener joins pre-calculados
2. **Seguridad**: RLS simplificado a nivel de vista
3. **Abstracción**: Oculta complejidad de la base de datos
4. **Mantenibilidad**: Cambios en esquema sin afectar código cliente
5. **Datos enriquecidos**: Vistas con campos calculados o agregados

---

## 📋 Convenciones de Nombres

### Prefijos de Vistas

| Prefijo | Uso | Ejemplo |
|---------|-----|---------|
| `v_` | Vistas generales | `v_players`, `v_matches` |
| `vw_` | Vistas con joins complejos | `vw_team_statistics` |
| `rpt_` | Vistas para reportes | `rpt_monthly_stats` |

### Sufijos Comunes

| Sufijo | Significado | Ejemplo |
|--------|-------------|---------|
| `_with_details` | Incluye relaciones | `v_players_with_details` |
| `_summary` | Datos agregados | `v_matches_summary` |
| `_by_user` | Filtrado por usuario | `v_teams_by_user` |
| `_active` | Solo registros activos | `v_players_active` |

---

## ⚡ Flujo de Verificación OBLIGATORIO

### Paso 1: Identificar la tabla base
```
Tabla objetivo: players
```

### Paso 2: Verificar existencia de vista
Usar MCP Supabase:
```sql
-- Verificar si existe vista para la tabla
SELECT table_name, view_definition
FROM information_schema.views
WHERE table_name LIKE 'v_%'
AND table_name LIKE '%players%';
```

### Paso 3: Si existe vista, usarla
```dart
// ❌ INCORRECTO - Usando tabla directa
final response = await _client.from('players').select();

// ✅ CORRECTO - Usando vista
final response = await _client.from('v_players_with_details').select();
```

### Paso 4: Si no existe vista, usar tabla
```dart
// ✅ ACEPTABLE - No hay vista disponible
final response = await _client.from('players').select();
```

---

## 🔧 Herramientas MCP para Verificación

### Listar todas las vistas
```
mcp__supabase__execute_sql
```
```sql
SELECT table_name
FROM information_schema.views
WHERE table_schema = 'public'
ORDER BY table_name;
```

### Buscar vista por tabla
```sql
SELECT
  table_name as view_name,
  view_definition
FROM information_schema.views
WHERE table_schema = 'public'
AND (
  table_name LIKE 'v_%[tabla]%'
  OR table_name LIKE 'vw_%[tabla]%'
  OR table_name LIKE '%[tabla]_with_%'
);
```

### Ver columnas de una vista
```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = '[vista]'
AND table_schema = 'public';
```

---

## 📊 Vistas Comunes por Módulo

### Módulo: Players
| Vista | Tabla Base | Uso |
|-------|------------|-----|
| `v_players` | players | Lista básica de jugadores |
| `v_players_with_team` | players + teams | Jugadores con info de equipo |
| `v_players_active` | players | Solo jugadores activos |
| `v_players_statistics` | players + statistics | Estadísticas agregadas |

### Módulo: Matches
| Vista | Tabla Base | Uso |
|-------|------------|-----|
| `v_matches` | matches | Lista básica de partidos |
| `v_matches_with_rivals` | matches + rivals | Partidos con info de rival |
| `v_matches_upcoming` | matches | Próximos partidos |
| `v_matches_results` | matches + match_results | Partidos con resultados |

### Módulo: Trainings
| Vista | Tabla Base | Uso |
|-------|------------|-----|
| `v_trainings` | activities | Solo entrenamientos |
| `v_trainings_with_attendance` | activities + attendance | Con conteo de asistencia |
| `v_trainings_calendar` | activities | Formato calendario |

### Módulo: Teams
| Vista | Tabla Base | Uso |
|-------|------------|-----|
| `v_teams` | teams | Lista básica |
| `v_teams_with_stats` | teams + aggregations | Con estadísticas |
| `v_teams_by_user` | teams | Filtrado por usuario |

---

## 🚫 Cuándo NO usar vistas

| Caso | Razón |
|------|-------|
| **INSERT/UPDATE/DELETE** | Operaciones de escritura SIEMPRE en tabla |
| **Filtros específicos** | Si la vista no tiene los campos necesarios |
| **Performance crítica** | Si la vista es muy compleja y no aporta valor |
| **Subconsultas anidadas** | Puede causar problemas de rendimiento |

---

## ✅ Checklist de Implementación

Antes de crear un DataSource o Repository:

```
□ Identificar tabla(s) involucradas en la operación
□ Ejecutar query de búsqueda de vistas relacionadas
□ Si existe vista → verificar columnas disponibles
□ Si la vista tiene todo lo necesario → usar vista
□ Si no existe vista o no tiene lo necesario → usar tabla
□ Documentar decisión en comentarios del código
```

---

## 📝 Ejemplo de Documentación en Código

```dart
class PlayersRepositoryImpl implements PlayersRepository {
  // Usamos v_players_with_details en lugar de players
  // porque incluye información del equipo y estadísticas básicas
  // sin necesidad de joins adicionales
  static const _sourceView = 'v_players_with_details';

  @override
  Future<List<PlayerEntity>> getAll() async {
    final response = await _client
        .from(_sourceView)
        .select()
        .order('created_at', ascending: false);
    return response.map(PlayerEntity.fromJson).toList();
  }

  @override
  Future<void> create(PlayerEntity player) async {
    // Los INSERT siempre van a la tabla base
    await _client.from('players').insert(player.toJson());
  }
}
```

---

## 🔄 Creación de Nuevas Vistas

Si se identifica una necesidad recurrente de joins o filtros, crear una vista:

```sql
-- Migration: create_v_players_with_details
-- Description: Vista de jugadores con información de equipo

CREATE OR REPLACE VIEW v_players_with_details AS
SELECT
  p.id,
  p.name,
  p.position,
  p.number,
  p.team_id,
  t.name as team_name,
  t.category as team_category,
  COUNT(a.id) as attendance_count,
  p.created_at,
  p.updated_at
FROM players p
LEFT JOIN teams t ON p.team_id = t.id
LEFT JOIN attendance a ON p.id = a.player_id
GROUP BY p.id, t.name, t.category;

-- Comentar la vista
COMMENT ON VIEW v_players_with_details IS
'Vista de jugadores con información de equipo y conteo de asistencias';
```

---

## 📚 Referencias

- **Reglas comunes:** `_AGENT_COMMON.md`
- **Supabase Specialist:** `supabase_specialist.md`
- **Datasource Agent:** `dSAgent.md`

---

## 🚨 Recordatorio Final

> **SIEMPRE** verificar vistas antes de usar tablas en operaciones SELECT.
> **NUNCA** usar vistas para INSERT/UPDATE/DELETE.
> **DOCUMENTAR** la razón de usar vista vs tabla.
