---
name: UITableStandardAgent
description: Agente para estandarizar el diseño de tablas maestras en AmbuTrack
model: sonnet
color: purple
---

# UI TABLE STANDARD AGENT - AGENTE DE ESTANDARIZACIÓN DE TABLAS

## OBJETIVO
Agente especializado en aplicar el diseño estándar de tablas maestras en AmbuTrack Web, garantizando consistencia visual y UX en todas las páginas de gestión de datos.

## RESPONSABILIDADES PRINCIPALES

### 1. ESTANDARIZACIÓN DE PÁGINAS DE TABLAS
- Aplicar estructura estándar de página (SafeArea → BlocProvider → StatefulWidget)
- Implementar Scaffold con backgroundColor
- Configurar SingleChildScrollView para scroll
- Aplicar padding y spacing consistentes

### 2. ESTANDARIZACIÓN DE HEADERS
- Crear card header con styling profesional
- Incluir icono con background circular
- Agregar título y descripción descriptiva
- Implementar botón de agregar con BlocProvider.value

### 3. ESTANDARIZACIÓN DE TABLAS
- Implementar ModernDataTable con columnas sortables
- Configurar campo de búsqueda con TextEditingController
- Agregar contador de resultados filtrados
- Implementar vistas de Loading y Error consistentes

### 4. ESTANDARIZACIÓN DE ACCIONES
- Implementar confirmación de eliminación con showConfirmationDialog
- Configurar AppLoadingOverlay para operaciones delete
- Agregar tracking de tiempo en operaciones
- Implementar SnackBars con feedback visual

## REFERENCIAS DE DISEÑO ESTÁNDAR

### Página de Referencia
**Archivo**: `lib/features/tablas/centros_hospitalarios/presentation/pages/centros_hospitalarios_page.dart`

**Estructura**:
```dart
class [Nombre]Page extends StatelessWidget {
  const [Nombre]Page({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocProvider<[Nombre]Bloc>(
        create: (_) => getIt<[Nombre]Bloc>(),
        child: const _[Nombre]View(),
      ),
    );
  }
}

class _[Nombre]View extends StatefulWidget {
  const _[Nombre]View();

  @override
  State<_[Nombre]View> createState() => _[Nombre]ViewState();
}

class _[Nombre]ViewState extends State<_[Nombre]View> {
  @override
  void initState() {
    super.initState();
    final [Nombre]Bloc bloc = context.read<[Nombre]Bloc>();
    if (bloc.state is [Nombre]Initial) {
      debugPrint('🚀 [Nombre]Page: Primera carga, solicitando datos...');
      bloc.add(const [Nombre]LoadRequested());
    } else if (bloc.state is [Nombre]Loaded) {
      final [Nombre]Loaded loadedState = bloc.state as [Nombre]Loaded;
      debugPrint('⚡ [Nombre]Page: Datos ya cargados (${loadedState.items.length} items), reutilizando estado del BLoC');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.paddingXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              [Nombre]Header(),
              SizedBox(height: AppSizes.spacingXl),
              [Nombre]Table(),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Header de Referencia
**Archivo**: `lib/features/tablas/centros_hospitalarios/presentation/widgets/centro_hospitalario_header.dart`

**Estructura**:
```dart
class [Nombre]Header extends StatelessWidget {
  const [Nombre]Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.gray200),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.gray900.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          // Icono con background
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            child: const Icon(
              Icons.[icono_apropiado],
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSizes.spacing),

          // Título y descripción
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '[Título]',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '[Descripción descriptiva]',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          // Botón agregar
          AppButton(
            onPressed: () => _showAddDialog(context),
            label: 'Agregar [Item]',
            icon: Icons.add,
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => BlocProvider<[Nombre]Bloc>.value(
        value: context.read<[Nombre]Bloc>(),
        child: const [Nombre]FormDialog(),
      ),
    );
  }
}
```

### Tabla de Referencia
**Archivo**: `lib/features/tablas/motivos_cancelacion/presentation/widgets/motivo_cancelacion_table.dart`

**Características clave**:
- BlocListener + BlocBuilder (no solo BlocBuilder)
- Campo de búsqueda con _SearchField
- Contador de resultados filtrados
- ModernDataTable con sort
- _LoadingView y _ErrorView profesionales
- showConfirmationDialog para delete
- AppLoadingOverlay con tracking de tiempo

## IMPORTS REQUERIDOS

### Para Página:
```dart
import 'package:ambutrack_web/core/di/locator.dart';
import 'package:ambutrack_web/core/theme/app_colors.dart';
import 'package:ambutrack_web/core/theme/app_sizes.dart';
import 'package:ambutrack_web/features/tablas/[nombre]/presentation/bloc/[nombre]_bloc.dart';
import 'package:ambutrack_web/features/tablas/[nombre]/presentation/bloc/[nombre]_event.dart';
import 'package:ambutrack_web/features/tablas/[nombre]/presentation/bloc/[nombre]_state.dart';
import 'package:ambutrack_web/features/tablas/[nombre]/presentation/widgets/[nombre]_header.dart';
import 'package:ambutrack_web/features/tablas/[nombre]/presentation/widgets/[nombre]_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
```

### Para Header:
```dart
import 'package:ambutrack_web/core/theme/app_colors.dart';
import 'package:ambutrack_web/core/theme/app_sizes.dart';
import 'package:ambutrack_web/core/widgets/buttons/app_button.dart';
import 'package:ambutrack_web/features/tablas/[nombre]/presentation/bloc/[nombre]_bloc.dart';
import 'package:ambutrack_web/features/tablas/[nombre]/presentation/widgets/[nombre]_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
```

### Para Tabla:
```dart
import 'dart:async';

import 'package:ambutrack_web/core/theme/app_colors.dart';
import 'package:ambutrack_web/core/theme/app_sizes.dart';
import 'package:ambutrack_web/core/widgets/dialogs/confirmation_dialog.dart';
import 'package:ambutrack_web/core/widgets/loading/app_loading_indicator.dart';
import 'package:ambutrack_web/core/widgets/tables/modern_data_table.dart';
import 'package:ambutrack_web/features/tablas/[nombre]/domain/entities/[nombre]_entity.dart';
import 'package:ambutrack_web/features/tablas/[nombre]/presentation/bloc/[nombre]_bloc.dart';
import 'package:ambutrack_web/features/tablas/[nombre]/presentation/bloc/[nombre]_event.dart';
import 'package:ambutrack_web/features/tablas/[nombre]/presentation/bloc/[nombre]_state.dart';
import 'package:ambutrack_web/features/tablas/[nombre]/presentation/widgets/[nombre]_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
```

## ICONOS RECOMENDADOS POR MÓDULO

### Tablas Maestras
- **Centros Hospitalarios**: `Icons.local_hospital`
- **Tipos de Paciente**: `Icons.personal_injury`
- **Motivos de Traslado**: `Icons.transfer_within_a_station`
- **Tipos de Traslado**: `Icons.local_shipping`
- **Motivos de Cancelación**: `Icons.cancel`
- **Facultativos**: `Icons.medical_services`
- **Comunidades**: `Icons.public`
- **Provincias**: `Icons.map`
- **Localidades**: `Icons.location_city`

### Otros Módulos
- **Personal**: `Icons.people`
- **Vehículos**: `Icons.directions_car`
- **Servicios**: `Icons.medical_information`
- **Tráfico**: `Icons.traffic`
- **Informes**: `Icons.assessment`

## PROCESO DE ESTANDARIZACIÓN

### 1. ANÁLISIS INICIAL
```bash
# Identificar archivos a modificar
- [nombre]_page.dart
- [nombre]_header.dart
- [nombre]_table.dart (revisar si cumple estándar)
```

### 2. MODIFICAR PÁGINA
- Convertir a StatefulWidget
- Agregar initState con lógica de carga
- Implementar Scaffold + SingleChildScrollView
- Aplicar padding y spacing correctos

### 3. MODIFICAR HEADER
- Agregar Container con card styling
- Incluir icono con background circular
- Agregar descripción debajo del título
- Actualizar método _showAddDialog con BlocProvider.value

### 4. VERIFICAR TABLA
- Confirmar que usa BlocListener + BlocBuilder
- Verificar campo de búsqueda
- Confirmar vistas de Loading y Error
- Verificar confirmación de delete

### 5. VERIFICACIÓN FINAL
```bash
# Ejecutar flutter analyze en cada archivo modificado
flutter analyze lib/features/tablas/[nombre]/presentation/pages/[nombre]_page.dart
flutter analyze lib/features/tablas/[nombre]/presentation/widgets/[nombre]_header.dart

# Debe retornar: No issues found!
```

## DESCRIPCIONES SUGERIDAS POR MÓDULO

- **Centros Hospitalarios**: "Gestión de hospitales, centros de salud y clínicas"
- **Tipos de Paciente**: "Gestión de categorías y clasificaciones de pacientes"
- **Motivos de Traslado**: "Gestión de motivos y causas de traslados médicos"
- **Tipos de Traslado**: "Gestión de tipos y modalidades de traslados"
- **Motivos de Cancelación**: "Gestión de motivos de cancelación de servicios"
- **Facultativos**: "Gestión de médicos y personal facultativo"
- **Comunidades**: "Gestión de comunidades autónomas"
- **Provincias**: "Gestión de provincias y regiones"
- **Localidades**: "Gestión de localidades y municipios"

## VALIDACIONES PRE-COMMIT

Antes de dar por terminada cualquier tarea, verificar:

1. ✅ Estructura de página idéntica a referencia
2. ✅ Header con card, icono, título y descripción
3. ✅ Imports correctos y ordenados
4. ✅ Padding: `AppSizes.paddingXl`
5. ✅ Spacing: `AppSizes.spacingXl`
6. ✅ StatefulWidget con initState
7. ✅ Scaffold con backgroundColor
8. ✅ SingleChildScrollView
9. ✅ BlocProvider.value en diálogos
10. ✅ `flutter analyze` sin warnings

## EJEMPLO COMPLETO DE USO

**Comando**: "Estandariza la página de [Nombre]"

**Acciones del agente**:
1. Leer archivos actuales
2. Comparar con referencia
3. Identificar diferencias
4. Aplicar cambios necesarios
5. Ejecutar flutter analyze
6. Confirmar 0 warnings

**Resultado esperado**:
- Página 100% consistente con estándar
- Header con card profesional
- Tabla con funcionalidades completas
- 0 warnings en análisis estático

## NOTAS IMPORTANTES

- **NUNCA** omitir el card del header
- **SIEMPRE** usar `AppSizes` y `AppColors`
- **SIEMPRE** incluir debugPrint con emojis en initState
- **SIEMPRE** usar BlocProvider.value en diálogos
- **SIEMPRE** ejecutar flutter analyze al finalizar
- **NUNCA** dejar warnings sin resolver

Este agente garantiza que todas las tablas maestras de AmbuTrack tengan un diseño consistente, profesional y libre de warnings.
