# 🤖 Agentes de Claude para AmbuTrack

Esta carpeta contiene agentes especializados para automatizar tareas específicas en el proyecto AmbuTrack Web.

## 📋 Agentes Disponibles

### 1. **UITableStandardAgent** 🎨
**Propósito**: Estandarizar el diseño de tablas maestras

**Cuándo usar**:
- Al crear una nueva tabla maestra
- Al actualizar tablas existentes que no siguen el estándar
- Al detectar inconsistencias visuales en páginas de gestión

**Ejemplo de uso**:
```
Usuario: "Estandariza la página de Tipos de Paciente"
Claude: [Usa UITableStandardAgent automáticamente]
```

**Qué hace**:
- ✅ Aplica estructura estándar de página (SafeArea → BlocProvider → StatefulWidget)
- ✅ Crea header con card profesional (icono + título + descripción + botón)
- ✅ Configura tabla con búsqueda, sort y vistas de loading/error
- ✅ Verifica que no haya warnings con `flutter analyze`

**Resultado**: Página 100% consistente con el diseño de Centros Hospitalarios

---

### 2. **dSAgent** 🎯
**Propósito**: Integración del iautomat_design_system

**Cuándo usar**:
- Al configurar el design system en la app
- Al migrar componentes estándar a componentes DS
- Al implementar temas corporativos

**Ejemplo de uso**:
```
Usuario: "Migra el formulario de vehículos al design system"
Claude: [Usa dSAgent]
```

**Qué hace**:
- Configura temas con presets disponibles
- Migra componentes (Button → DSButton, TextField → DSInput, etc.)
- Implementa navegación con DSDrawer, DSTabs, etc.
- Aplica DSDataTable para visualización de datos

---

### 3. **DataSourceAgent** 📡
**Propósito**: Configuración de datasources en AmbuTrack

**Cuándo usar**:
- Al crear nuevos datasources
- Al configurar integración con Supabase
- Al implementar cache de datos

**Ejemplo de uso**:
```
Usuario: "Crea el datasource para Tipos de Paciente"
Claude: [Usa DataSourceAgent]
```

**Qué hace**:
- Crea datasources Simple/Complex/RealTime según el caso
- Configura integración con Supabase
- Implementa cache inteligente
- Genera modelos en ambutrack_core_datasource

---

## 🚀 Cómo Usar los Agentes

### Opción 1: Automático (Recomendado)
Claude detecta automáticamente qué agente usar según tu solicitud:

```
Usuario: "Estandariza la UI de Facultativos"
→ Claude usa UITableStandardAgent automáticamente
```

### Opción 2: Explícito
Puedes solicitar un agente específico:

```
Usuario: "Usa UITableStandardAgent para actualizar la página de Motivos de Traslado"
→ Claude usa el agente especificado
```

### Opción 3: Task Tool
Para tareas complejas, Claude puede lanzar agentes en paralelo:

```dart
Usuario: "Estandariza todas las tablas maestras"
→ Claude lanza múltiples UITableStandardAgent en paralelo
```

## 📚 Referencias de Diseño Estándar

### Página de Referencia
- **Archivo**: `lib/features/tablas/centros_hospitalarios/presentation/pages/centros_hospitalarios_page.dart`
- **Características**: StatefulWidget, Scaffold, SingleChildScrollView, initState con logs

### Header de Referencia
- **Archivo**: `lib/features/tablas/centros_hospitalarios/presentation/widgets/centro_hospitalario_header.dart`
- **Características**: Card con shadow, icono circular, título + descripción, botón agregar

### Tabla de Referencia
- **Archivo**: `lib/features/tablas/motivos_cancelacion/presentation/widgets/motivo_cancelacion_table.dart`
- **Características**: BlocListener + BlocBuilder, búsqueda, sort, confirmación delete

## ✅ Validaciones que Hacen los Agentes

Todos los agentes ejecutan estas validaciones antes de terminar:

1. **Imports correctos**: Verifican que todos los imports necesarios estén presentes
2. **Estructura estándar**: Comparan con archivos de referencia
3. **AppSizes y AppColors**: Validan uso correcto de constantes
4. **Flutter Analyze**: Ejecutan `flutter analyze` y corrigen todos los warnings
5. **Documentación**: Agregan comentarios descriptivos

## 🎨 Paleta de Iconos por Módulo

Los agentes seleccionan automáticamente iconos apropiados:

- **Centros Hospitalarios**: `Icons.local_hospital`
- **Tipos de Paciente**: `Icons.personal_injury`
- **Motivos de Traslado**: `Icons.transfer_within_a_station`
- **Facultativos**: `Icons.medical_services`
- **Personal**: `Icons.people`
- **Vehículos**: `Icons.directions_car`

## 🛠️ Crear un Nuevo Agente

Para crear un agente personalizado:

1. Crea un archivo `.md` en esta carpeta
2. Usa la estructura YAML al inicio:
```yaml
---
name: NombreAgente
description: Descripción breve de qué hace
model: sonnet
color: blue|purple|green|red
---
```

3. Documenta:
   - Objetivo del agente
   - Responsabilidades principales
   - Referencias de código
   - Ejemplos de uso
   - Validaciones pre-commit

## 📞 Soporte

Si tienes dudas sobre qué agente usar, simplemente pregunta:

```
Usuario: "¿Qué agente uso para mejorar el diseño de una tabla?"
Claude: "Te recomiendo UITableStandardAgent, que estandariza..."
```

---

**Última actualización**: 2025-12-19
**Proyecto**: AmbuTrack Web
**Framework**: Flutter 3.35.3+
