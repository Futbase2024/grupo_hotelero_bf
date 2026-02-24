# Plan: Feature de Informes (Reports)

> **Fecha**: 2026-02-23
> **Proyecto**: Futbase 3.0
> **Estado**: Pendiente de aprobación

---

## 1. Resumen

Implementar un sistema completo de informes con diferenciación por roles (Entrenador, Coordinador, Club) que permita visualizar y exportar datos estadísticos.

---

## 2. Alcance

### 2.1 Tipos de Informes

| Informe | Descripción | Datos Fuente |
|---------|-------------|--------------|
| **Informe de Jugador** | Estadísticas individuales: goles, asistencias, minutos, tarjetas, asistencia a entrenamientos | `testadisticasjugador`, `tentrenojugador`, `veventos` |
| **Informe de Partido** | Resumen del partido: alineación, eventos, estadísticas, resultado | `vpartido`, `vpartidosjugadores`, `veventos` |
| **Informe de Convocatoria** | Jugadores convocados, titulares, suplentes, bajas | `vpartidosjugadores`, `tconvpartidos` |
| **Asistencia Mensual Entrenamientos** | Porcentaje asistencia por jugador, días entrenados, motivos ausencia | `ventrenojugador`, `tentrenamientos` |
| **Estadísticas Equipo** | Agregadas: goles, victorias/derrotas, rachas | `vpartido`, `testadisticaspartido` |

### 2.2 Diferenciación por Rol

| Rol | Alcance | Informes Disponibles |
|-----|---------|---------------------|
| **Entrenador** | Solo su equipo | Todos (filtrados a su equipo) |
| **Coordinador** | Categorías que coordina | Todos (filtrados a sus categorías) |
| **Club** | Todos los equipos del club | Todos (acceso completo) |

### 2.3 Filtros

- **Períodos predefinidos**: Última semana, Último mes, Último trimestre, Temporada actual
- **Rango personalizado**: DatePicker con fecha inicio y fin
- **Filtro por equipo**: Dropdown con equipos según rol
- **Filtro por categoría**: Dropdown con categorías según rol

### 2.4 Exportación

- **PDF**: Documento formateado con gráficos y tablas
- **Excel/CSV**: Datos tabulares para análisis externo

---

## 3. Arquitectura

### 3.1 Estructura de Carpetas

```
lib/features/reports/
├── bloc/
│   ├── reports_bloc.dart
│   ├── reports_event.dart
│   ├── reports_state.dart
│   └── report_filter.dart
├── domain/
│   ├── report_types.dart          # Enum tipos de informe
│   └── report_data.dart           # Clases de datos de informe
├── presentation/
│   ├── pages/
│   │   ├── reports_page.dart      # Página principal
│   │   ├── player_report_page.dart
│   │   ├── match_report_page.dart
│   │   ├── convocatoria_report_page.dart
│   │   └── attendance_report_page.dart
│   └── widgets/
│       ├── report_filter_bar.dart
│       ├── report_card.dart
│       ├── player_stats_card.dart
│       ├── match_summary_card.dart
│       ├── attendance_chart.dart
│       └── export_button.dart
├── services/
│   ├── reports_datasource.dart    # Consultas Supabase
│   ├── pdf_export_service.dart    # Generación PDF
│   └── excel_export_service.dart  # Generación Excel
└── routes/
    └── reports_route.dart
```

### 3.2 Modelos de Datos

```dart
// report_types.dart
enum ReportType {
  player,
  match,
  convocatoria,
  attendanceMonthly,
  teamStats,
}

// report_filter.dart
class ReportFilter {
  final ReportType type;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int? teamId;
  final int? categoryId;
  final int? playerId;
  final int? matchId;
  final String period; // 'week', 'month', 'quarter', 'season', 'custom'
}

// report_data.dart
class PlayerReportData {
  final PlayerModel player;
  final int totalMatches;
  final int totalMinutes;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
  final double attendancePercentage;
  final List<MatchEvent> events;
}

class MatchReportData {
  final MatchModel match;
  final List<ConvocadoPlayer> convocatoria;
  final List<MatchEvent> events;
  final MatchStatistics? statistics;
}

class AttendanceReportData {
  final int teamId;
  final String teamName;
  final DateTime month;
  final int totalTrainings;
  final List<PlayerAttendance> playersAttendance;
}
```

### 3.3 Estados BLoC

```dart
// reports_state.dart
abstract class ReportsState extends Equatable {}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

class ReportTypeSelected extends ReportsState {
  final ReportType type;
  final ReportFilter filter;
  final List<TeamModel> availableTeams;
  final List<CategoryModel> availableCategories;
}

class PlayerReportLoaded extends ReportsState {
  final PlayerReportData data;
  final ReportFilter filter;
}

class MatchReportLoaded extends ReportsState {
  final MatchReportData data;
  final ReportFilter filter;
}

class AttendanceReportLoaded extends ReportsState {
  final AttendanceReportData data;
  final ReportFilter filter;
}

class ConvocatoriaReportLoaded extends ReportsState {
  final ConvocatoriaReportData data;
  final ReportFilter filter;
}

class ReportsError extends ReportsState {
  final String message;
}

class ReportExporting extends ReportsState {
  final double progress;
}

class ReportExported extends ReportsState {
  final String filePath;
  final String format; // 'pdf' | 'excel'
}
```

### 3.4 Eventos BLoC

```dart
// reports_event.dart
abstract class ReportsEvent extends Equatable {}

class SelectReportType extends ReportsEvent {
  final ReportType type;
}

class UpdateFilter extends ReportsEvent {
  final ReportFilter filter;
}

class LoadPlayerReport extends ReportsEvent {
  final int playerId;
  final ReportFilter filter;
}

class LoadMatchReport extends ReportsEvent {
  final int matchId;
}

class LoadAttendanceReport extends ReportsEvent {
  final int teamId;
  final DateTime month;
}

class LoadConvocatoriaReport extends ReportsEvent {
  final int matchId;
}

class ExportToPdf extends ReportsEvent {
  final dynamic reportData;
  final ReportType type;
}

class ExportToExcel extends ReportsEvent {
  final dynamic reportData;
  final ReportType type;
}
```

---

## 4. Consultas Supabase

### 4.1 Informe de Jugador

```sql
-- Estadísticas del jugador en la temporada
SELECT
  j.id,
  j.nombre,
  j.apellidos,
  j.dorsal,
  COUNT(DISTINCT p.id) as total_partidos,
  SUM(e.minutosjugados) as total_minutos,
  COUNT(CASE WHEN ev.tipo = 'gol' THEN 1 END) as goles,
  COUNT(CASE WHEN ev.tipo = 'asistencia' THEN 1 END) as asistencias,
  COUNT(CASE WHEN ev.tipo = 'amarilla' THEN 1 END) as tarjetas_amarillas,
  COUNT(CASE WHEN ev.tipo = 'roja' THEN 1 END) as tarjetas_rojas
FROM tjugadores j
LEFT JOIN vpartidosjugadores cp ON cp.idjugador = j.id
LEFT JOIN tpartidos p ON p.id = cp.idpartido
LEFT JOIN testadisticaspartido e ON e.idjugador = j.id AND e.idpartido = p.id
LEFT JOIN teventospartido ev ON ev.idjugador = j.id AND ev.idpartido = p.id
WHERE j.id = :playerId
  AND p.idtemporada = :seasonId
GROUP BY j.id;

-- Asistencia a entrenamientos
SELECT
  COUNT(CASE WHEN ea.asiste = 1 THEN 1 END) as presentes,
  COUNT(*) as total_entrenamientos,
  ROUND(COUNT(CASE WHEN ea.asiste = 1 THEN 1 END) * 100.0 / COUNT(*), 1) as porcentaje
FROM tentrenojugador ea
JOIN tentrenamientos ent ON ent.id = ea.identrenamiento
WHERE ea.idjugador = :playerId
  AND ent.fecha BETWEEN :fromDate AND :toDate;
```

### 4.2 Informe de Asistencia Mensual

```sql
SELECT
  j.id,
  j.nombre,
  j.apellidos,
  COUNT(DISTINCT ent.id) as total_entrenamientos,
  COUNT(CASE WHEN ea.asiste = 1 THEN 1 END) as asistencias,
  COUNT(CASE WHEN ea.asiste = 0 THEN 1 END) as faltas,
  ROUND(COUNT(CASE WHEN ea.asiste = 1 THEN 1 END) * 100.0 / COUNT(DISTINCT ent.id), 1) as porcentaje
FROM tjugadores j
LEFT JOIN tentrenojugador ea ON ea.idjugador = j.id
LEFT JOIN tentrenamientos ent ON ent.id = ea.identrenamiento
  AND ent.fecha >= :monthStart
  AND ent.fecha < :monthEnd
  AND ent.idequipo = :teamId
WHERE j.idequipo = :teamId
  AND j.activo = 1
GROUP BY j.id
ORDER BY porcentaje DESC;
```

### 4.3 Informe de Convocatoria

```sql
SELECT
  j.id,
  j.nombre,
  j.apellidos,
  j.dorsal,
  pos.posicion,
  cp.titular,
  cp.convocado
FROM vpartidosjugadores cp
JOIN vjugadores j ON j.id = cp.idjugador
LEFT JOIN tposiciones pos ON pos.id = j.idposicion
WHERE cp.idpartido = :matchId
ORDER BY cp.titular DESC, j.dorsal;
```

---

## 5. Dependencias Necesarias

Añadir al `pubspec.yaml`:

```yaml
dependencies:
  # Exportación PDF
  pdf: ^3.10.7
  printing: ^5.12.0

  # Exportación Excel
  excel: ^4.0.3

  # Gráficos para informes
  fl_chart: ^0.67.0

dev_dependencies:
  # Ya existentes...
```

---

## 6. Flujo de Usuario

### 6.1 Seleccionar Tipo de Informe

1. Usuario navega a sección "Informes"
2. Ve tarjetas con tipos de informes disponibles
3. Selecciona el tipo deseado

### 6.2 Configurar Filtros

1. Se muestra barra de filtros según tipo de informe
2. Usuario puede seleccionar:
   - Período (predefinido o personalizado)
   - Equipo (según su rol)
   - Categoría (si aplica)

### 3.3 Generar Informe

1. Al aplicar filtros, se cargan datos
2. Se muestra visualización del informe
3. Opciones de exportación disponibles

### 6.4 Exportar

1. Usuario hace clic en botón "Exportar"
2. Elige formato (PDF o Excel)
3. Se genera archivo y se descarga

---

## 7. Vistas por Rol

### 7.1 Entrenador

- Selector de informe
- Su equipo preseleccionado (no editable)
- Filtros de período
- Botones de exportación

### 7.2 Coordinador

- Selector de informe
- Dropdown de categorías que coordina
- Dropdown de equipos dentro de la categoría
- Filtros de período
- Botones de exportación

### 7.3 Club

- Selector de informe
- Dropdown de todas las categorías
- Dropdown de todos los equipos
- Vista agregada del club disponible
- Filtros de período
- Botones de exportación

---

## 8. Archivos a Crear/Modificar

### Nuevos (Crear)

| Archivo | Descripción |
|---------|-------------|
| `lib/features/reports/bloc/reports_bloc.dart` | BLoC principal |
| `lib/features/reports/bloc/reports_event.dart` | Eventos |
| `lib/features/reports/bloc/reports_state.dart` | Estados |
| `lib/features/reports/bloc/report_filter.dart` | Modelo de filtros |
| `lib/features/reports/domain/report_types.dart` | Enums y tipos |
| `lib/features/reports/domain/report_data.dart` | Modelos de datos |
| `lib/features/reports/presentation/pages/reports_page.dart` | Página principal |
| `lib/features/reports/presentation/pages/player_report_page.dart` | Informe jugador |
| `lib/features/reports/presentation/pages/match_report_page.dart` | Informe partido |
| `lib/features/reports/presentation/pages/attendance_report_page.dart` | Informe asistencia |
| `lib/features/reports/presentation/widgets/report_filter_bar.dart` | Barra filtros |
| `lib/features/reports/presentation/widgets/report_card.dart` | Tarjeta informe |
| `lib/features/reports/presentation/widgets/player_stats_card.dart` | Stats jugador |
| `lib/features/reports/presentation/widgets/attendance_chart.dart` | Gráfico asistencia |
| `lib/features/reports/presentation/widgets/export_button.dart` | Botón exportar |
| `lib/features/reports/services/reports_datasource.dart` | Consultas |
| `lib/features/reports/services/pdf_export_service.dart` | Exportar PDF |
| `lib/features/reports/services/excel_export_service.dart` | Exportar Excel |
| `lib/features/reports/routes/reports_route.dart` | Rutas |

### Modificar (Existentes)

| Archivo | Cambio |
|---------|--------|
| `pubspec.yaml` | Añadir dependencias pdf, printing, excel, fl_chart |
| `lib/core/config/router_config.dart` | Añadir ruta de informes |
| `lib/injection.dart` | Registrar servicios de exportación |

---

## 9. Estimación

| Fase | Tareas |
|------|--------|
| **Fase 1: Estructura base** | BLoC, estados, eventos, modelos, datasource |
| **Fase 2: UI Principal** | Página principal, selector de informes, filtros |
| **Fase 3: Informes específicos** | Cada tipo de informe con su visualización |
| **Fase 4: Exportación** | Servicios PDF y Excel |
| **Fase 5: Integración** | Rutas, DI, navegación |

---

## 10. Notas Adicionales

- Usar `AppColors` para consistencia visual
- Widget `CELoading` para estados de carga
- Widget `CeInfoDialog` para errores/confirmaciones
- SafeArea obligatorio en todas las páginas
- Filtrar siempre por `activeSeasonId` del `AppConfigCubit`
