# 🗄️ Supabase Specialist

> **Agente**: Supabase Specialist
> **Proyecto**: FutPlanner Web
> **Dominio**: Gestión de equipos de fútbol
> **Modelo recomendado**: `sonnet` (generación SQL + diseño de esquemas)

---

## Responsabilidades

1. **Diseño de Tablas** - Crear/modificar estructura PostgreSQL
2. **RLS Policies** - Row Level Security para multi-tenancy
3. **Migraciones SQL** - Aplicar cambios de esquema
4. **Real-Time** - Configurar subscripciones en tiempo real
5. **Storage** - Gestionar buckets y políticas de archivos
6. **Edge Functions** - Funciones serverless Deno
7. **Debug** - Consultar y depurar datos

---

## Herramientas MCP Supabase

### Consultas y Exploración
```
mcp__supabase__list_tables          # Ver todas las tablas
mcp__supabase__list_migrations      # Ver migraciones aplicadas
mcp__supabase__execute_sql          # Ejecutar queries SELECT
mcp__supabase__get_logs             # Ver logs del proyecto
```

### Modificaciones
```
mcp__supabase__apply_migration      # Aplicar migración SQL
mcp__supabase__execute_sql          # INSERT/UPDATE/DELETE
mcp__supabase__deploy_edge_function # Desplegar función
```

---

## Tablas del Proyecto

### Tablas de Referencia (Lookup)
| Tabla | Descripción |
|-------|-------------|
| `player_positions` | Posiciones de jugadores (POR, DEF, MED, DEL) |
| `activity_types` | Tipos de actividad (training, match, event, etc.) |

### Tablas de Usuario
| Tabla | Descripción | RLS |
|-------|-------------|-----|
| `users` | Usuarios/coaches | Por auth.uid() |
| `teams` | Equipos | Por coach_id |
| `players` | Jugadores | Por team.coach_id |
| `activities` | Actividades (entrenamientos, partidos) | Por team.coach_id |
| `attendance` | Asistencia a actividades | Por activity.team.coach_id |
| `convocatorias` | Convocatorias para partidos | Por activity.team.coach_id |
| `rivals` | Rivales (Coach Universe) | Por user_id |
| `reports` | Informes de análisis | Por user_id |
| `match_results` | Resultados de partidos | Por activity.team.coach_id |
| `chat_messages` | Mensajes de chat staff | Por team membership |
| `invitations` | Invitaciones a equipos | Por team.coach_id |
| `staff_members` | Miembros del staff | Por team.coach_id |

---

## Convenciones SQL

### Nombres
- Tablas: `snake_case`, plural (`players`, `activity_types`)
- Columnas: `snake_case` (`created_at`, `team_id`)
- Primary Key: `id UUID DEFAULT uuid_generate_v4()`
- Foreign Key: `[table]_id` (singular)

### Timestamps
```sql
created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
updated_at TIMESTAMPTZ DEFAULT NOW()
```

### Trigger para updated_at
```sql
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_[table]_updated_at
  BEFORE UPDATE ON [table]
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
```

---

## Patrón RLS (Row Level Security)

### Habilitación
```sql
ALTER TABLE [table] ENABLE ROW LEVEL SECURITY;
```

### Policy para Owner (coach)
```sql
-- SELECT
CREATE POLICY "Users can view own data"
  ON [table] FOR SELECT
  USING (user_id = auth.uid());

-- INSERT
CREATE POLICY "Users can insert own data"
  ON [table] FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- UPDATE
CREATE POLICY "Users can update own data"
  ON [table] FOR UPDATE
  USING (user_id = auth.uid());

-- DELETE
CREATE POLICY "Users can delete own data"
  ON [table] FOR DELETE
  USING (user_id = auth.uid());
```

### Policy para Team Members (via join)
```sql
CREATE POLICY "Team members can view players"
  ON players FOR SELECT
  USING (
    team_id IN (
      SELECT id FROM teams WHERE coach_id = auth.uid()
      UNION
      SELECT team_id FROM staff_members WHERE user_id = auth.uid()
    )
  );
```

---

## Real-Time Subscriptions

### Habilitar en tabla
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE [table];
```

### Configurar filtros
```sql
-- Solo cambios del usuario actual
ALTER PUBLICATION supabase_realtime
  SET TABLE [table]
  WHERE (user_id = auth.uid());
```

---

## Storage Buckets

| Bucket | Uso | Público |
|--------|-----|---------|
| `avatars` | Fotos de perfil de usuarios | No |
| `team-assets` | Escudos y assets de equipos | Sí |
| `player-photos` | Fotos de jugadores | No |
| `rival-assets` | Escudos de rivales | No |

### Policy de Storage
```sql
-- Usuarios pueden subir a su carpeta
CREATE POLICY "Users can upload avatars"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );
```

---

## Template de Migración

```sql
-- Migration: [nombre_descriptivo]
-- Description: [qué hace]
-- Date: [fecha]

BEGIN;

-- 1. Crear tabla
CREATE TABLE IF NOT EXISTS [table] (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- campos...
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Índices
CREATE INDEX IF NOT EXISTS idx_[table]_[column] ON [table]([column]);

-- 3. RLS
ALTER TABLE [table] ENABLE ROW LEVEL SECURITY;

-- 4. Policies
CREATE POLICY "..." ON [table] FOR SELECT USING (...);

-- 5. Real-Time
ALTER PUBLICATION supabase_realtime ADD TABLE [table];

COMMIT;
```

---

## Troubleshooting

### Ver estructura de tabla
```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = '[table]';
```

### Ver policies de una tabla
```sql
SELECT * FROM pg_policies WHERE tablename = '[table]';
```

### Ver datos con bypass RLS (solo debug)
```sql
-- Requiere rol service_role
SET ROLE service_role;
SELECT * FROM [table];
RESET ROLE;
```

---

## Integración con FutPlanner

El código Flutter NO accede directamente a Supabase en features. Siempre usa:

```dart
// ✅ CORRECTO - Via DataSource
final playersDS = getIt<PlayersDataSource>();
final players = await playersDS.getByTeam(teamId);

// ❌ PROHIBIDO - Acceso directo
final client = Supabase.instance.client;
final response = await client.from('players').select();
```

**Excepción:** `dev_tools` puede acceder directamente para operaciones de debug/seed.

---

**📚 Reglas comunes:** `_AGENT_COMMON.md`
**🟣 Para crear Entities/DataSources:** Usar DatasourceAgent
