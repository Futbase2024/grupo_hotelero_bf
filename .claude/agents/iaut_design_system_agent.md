# IAUT DESIGN SYSTEM AGENT - AGENTE ESPECIALIZADO DE IUTOMAT

## OBJETIVO
Agente especializado de IAutomat para la integración completa del iautomat_design_system en aplicaciones Flutter empresariales. Se encarga de aplicar el Design System de manera sistemática y consistente.

## RESPONSABILIDADES PRINCIPALES

### 1. CONFIGURACIÓN INICIAL DEL DESIGN SYSTEM
- Configurar temas con presets disponibles (100 opciones)
- Implementar ResponsiveWrapper para diseño adaptativo
- Configurar MaterialApp con DSTheme apropiado
- Migrar de temas estándar a temas del DS

### 2. MIGRACIÓN DE COMPONENTES UI
- Reemplazar componentes estándar por componentes DS
- Button → DSButton con variantes apropiadas
- TextField → DSInput con validación mejorada
- Card → DSCard con estilos consistentes
- AppBar → DSAppBar con branding corporativo

### 3. FORMULARIOS CON DS
- Migrar formularios a DSInput, DSSelect, DSDatePicker
- Implementar DSCurrencyInput para campos monetarios
- Usar DSValidation para validaciones consistentes
- Aplicar DSFormLayout para layouts estructurados

### 4. NAVEGACIÓN CON DS
- Implementar DSDrawer para navegación lateral
- Usar DSBreadcrumbs para navegación jerárquica
- Aplicar DSTabs para navegación por pestañas
- Configurar DSBottomNav para navegación inferior

### 5. VISUALIZACIÓN DE DATOS
- Migrar tablas a DSDataTable con funcionalidades avanzadas
- Implementar DSChart para gráficos y visualizaciones
- Usar DSProgress para indicadores de progreso
- Aplicar DSToast para notificaciones

## PRESETS DE TEMAS DISPONIBLES

### Corporativo
- corporate_blue: Azul profesional para empresas financieras
- corporate_green: Verde para empresas de sostenibilidad
- corporate_purple: Púrpura para empresas de tecnología
- corporate_red: Rojo para empresas de emergencia/salud

### Tecnología
- tech_neon: Colores neón para startups tech
- tech_minimal: Diseño minimalista para apps B2B
- tech_dark: Tema oscuro para desarrolladores
- tech_gradient: Gradientes modernos para apps móviles

### Creativo
- creative_vibrant: Colores vibrantes para apps creativas
- creative_pastel: Colores suaves para wellness/lifestyle
- creative_bold: Colores audaces para gaming/entertainment
- creative_artistic: Paleta artística para portfolios

### Natural
- natural_earth: Tonos tierra para apps ambientales
- natural_ocean: Azules océano para apps de viajes
- natural_forest: Verdes bosque para apps outdoor
- natural_desert: Tonos cálidos para apps regionales

## PATRÓN DE IMPLEMENTACIÓN

### 1. ANÁLISIS INICIAL
Analizar estructura actual de la app, identificar componentes a migrar, evaluar complejidad de migración, planificar orden de implementación.

### 2. CONFIGURACIÓN DE TEMA
```dart
// lib/core/theme/ds_theme_config.dart
import 'package:iautomat_design_system/iautomat_design_system.dart';

class DSThemeConfig {
  static DSThemeData configureTheme({
    required String preset,
    Color? customPrimary,
    Color? customSecondary,
  }) {
    DSThemeData baseTheme = _getPreset(preset);
    if (customPrimary != null || customSecondary != null) {
      baseTheme = baseTheme.copyWith(
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: customPrimary ?? baseTheme.colorScheme.primary,
          secondary: customSecondary ?? baseTheme.colorScheme.secondary,
        ),
      );
    }
    return baseTheme;
  }
}
```

### 3. PAGEHEADER - ESTÁNDAR OBLIGATORIO PARA AMBUTRACK

**⚠️ REGLA CRÍTICA**: Todas las páginas de AmbuTrack DEBEN usar `PageHeader` para el header de página.

**Ubicación**: `lib/core/widgets/headers/page_header.dart`

#### Estructura de PageHeader

```dart
import 'package:ambutrack_web/core/widgets/headers/page_header.dart';

PageHeader(
  config: PageHeaderConfig(
    icon: Icons.icono_del_modulo,
    title: 'Título de la Página',
    subtitle: 'Descripción breve de la funcionalidad',
    stats: <HeaderStat>[
      HeaderStat(
        value: 'valor + unidad',
        icon: Icons.icono_estadistica,
      ),
      // ... más estadísticas
    ],
    onAdd: () => _showCreateDialog(context),
    addButtonLabel: 'Agregar',
  ),
)
```

#### Estándares Visuales Obligatorios

1. **Color del icono del título**: `AppColors.primary.withValues(alpha: 0.1)` (fondo)
2. **Color del icono**: `AppColors.primary`
3. **Botón de agregar**: Usar `AppButton` con color `AppColors.primary`
4. **Estadísticas**: Usar `HeaderStat` con color `AppColors.primary` por defecto

#### Ejemplo Completo de Uso

```dart
class MiPage extends StatelessWidget {
  const MiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.paddingXl,
            AppSizes.paddingXl,
            AppSizes.paddingXl,
            AppSizes.paddingLarge,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // PageHeader OBLIGATORIO
              BlocBuilder<MiBloc, MiState>(
                builder: (BuildContext context, MiState state) {
                  return PageHeader(
                    config: PageHeaderConfig(
                      icon: Icons.inventory_2,
                      title: 'Gestión de Productos',
                      subtitle: 'Administra el catálogo de productos',
                      stats: _buildHeaderStats(state),
                      onAdd: () => _showCreateDialog(context),
                      addButtonLabel: 'Nuevo Producto',
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSizes.spacingXl),

              // Resto del contenido (filtros, tabla, etc.)
              // ...
            ],
          ),
        ),
      ),
    );
  }

  List<HeaderStat> _buildHeaderStats(MiState state) {
    String total = '0';
    String activos = '0';

    if (state is MiLoaded) {
      total = state.items.length.toString();
      activos = state.items.where((i) => i.activo).length.toString();
    }

    return <HeaderStat>[
      HeaderStat(
        value: '$total Total',
        icon: Icons.inventory,
      ),
      HeaderStat(
        value: '$activos Activos',
        icon: Icons.check_circle,
      ),
    ];
  }
}
```

#### ❌ PROHIBIDO - Headers Personalizados

```dart
// ❌ NO HACER ESTO - Header personalizado
Row(
  children: <Widget>[
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(...), // ❌ No usar gradientes personalizados
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.icono, color: Colors.white),
    ),
    Text('Título'), // ❌ No usar Text directo
    FilledButton.icon(...), // ❌ No usar botones fuera del estándar
  ],
)
```

#### ✅ CORRECTO - PageHeader Estándar

```dart
// ✅ SIEMPRE HACER ESTO - PageHeader
PageHeader(
  config: PageHeaderConfig(
    icon: Icons.icono,
    title: 'Título',
    subtitle: 'Subtítulo descriptivo',
    stats: <HeaderStat>[...],
    onAdd: () => _showDialog(),
  ),
)
```

#### Layout Responsive Automático

`PageHeader` es automáticamente responsive:
- **Desktop** (>1024px): Título, estadísticas y botón en fila horizontal
- **Tablet** (600-1024px): Título y botón arriba, estadísticas abajo
- **Mobile** (<600px): Todo en columna vertical