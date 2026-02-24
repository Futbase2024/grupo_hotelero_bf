# 🎨 UI/Widget Agent

> **Propósito**: Crear y modificar widgets, UI y componentes visuales
> **Uso**: Trabajo de interfaz, diseño, componentes reutilizables

## 📋 Contexto Mínimo
- **Proyecto**: AmbuTrack Web (Flutter 3.35.3+)
- **Design System**: iautomat_design_system
- **Tema**: Médico profesional (azul #1E40AF, verde #059669)

## 🎯 Mi Responsabilidad
- Crear widgets reutilizables
- Modificar UI existente
- Aplicar design system correctamente
- Mantener consistencia visual

## 🎨 Paleta de Colores (OBLIGATORIO usar AppColors)

```dart
// === PRIMARIOS ===
AppColors.primary          // #1E40AF - Azul médico
AppColors.secondary        // #059669 - Verde salud
AppColors.primaryLight     // #3B82F6
AppColors.primaryDark      // #1E3A8A

// === EMERGENCIA/PRIORIDAD ===
AppColors.emergency        // #DC2626 - Rojo crítico
AppColors.highPriority     // #EA580C - Naranja
AppColors.mediumPriority   // #D97706 - Amarillo
AppColors.lowPriority      // #059669 - Verde

// === ESTADOS ===
AppColors.success          // Verde éxito
AppColors.warning          // Amarillo advertencia
AppColors.error            // Rojo error
AppColors.info             // Azul información

// === SUPERFICIES ===
AppColors.backgroundLight  // #FFFFFF
AppColors.surfaceLight     // #F9FAFB
AppColors.textPrimaryLight // #111827
AppColors.textSecondaryLight // #6B7280

// === PROHIBIDO ===
// ❌ Colors.blue, Colors.red, Color(0xFF...)
// ✅ Excepciones: Colors.white, Colors.black, Colors.transparent
```

## ✅ Patrones de Widgets

### Widget Privado (mismo archivo)
```dart
class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.primarySurface,
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
```

### Widget Público (archivo separado)
```dart
// lib/features/[feature]/presentation/widgets/[nombre]_card.dart
class [Nombre]Card extends StatelessWidget {
  const [Nombre]Card({
    super.key,
    required this.item,
    this.onTap,
  });

  final [Nombre]Entity item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceLight,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHeader(item: item),
              const SizedBox(height: 8),
              _CardBody(item: item),
            ],
          ),
        ),
      ),
    );
  }
}
```

### ❌ PROHIBIDO: Métodos que devuelven widgets
```dart
// ❌ NUNCA hacer esto
Widget _buildHeader() => Container(...);
Widget _buildContent() => ListView(...);

// ✅ SIEMPRE usar StatelessWidget
class _Header extends StatelessWidget { }
class _Content extends StatelessWidget { }
```

## 🔧 Componentes del Design System

### AppDropdown (OBLIGATORIO para dropdowns)
```dart
// ❌ NO usar DropdownButtonFormField
// ✅ SIEMPRE usar AppDropdown
import 'package:ambutrack_web/core/widgets/dropdowns/app_dropdown.dart';

AppDropdown<String>(
  value: selectedValue,
  width: 200,
  label: 'Selecciona',
  hint: 'Escoge una opción',
  prefixIcon: Icons.category,
  items: [
    AppDropdownItem(
      value: 'opcion1',
      label: 'Opción 1',
      icon: Icons.star,
      iconColor: AppColors.warning,
    ),
  ],
  onChanged: (value) => setState(() => selectedValue = value),
)
```

### AppLoadingIndicator (formularios async)
```dart
import 'package:ambutrack_web/core/widgets/loading/app_loading_indicator.dart';

// En formularios con datos async
_isLoading
    ? const Center(
        child: AppLoadingIndicator(
          message: 'Cargando datos...',
          size: 100,
        ),
      )
    : Form(...)
```

### AppDialog
```dart
AppDialog(
  title: 'Título',
  content: _isLoading
      ? const AppLoadingIndicator()
      : Form(...),
  actions: [
    AppButton(
      onPressed: () => Navigator.pop(context),
      label: 'Cancelar',
      variant: AppButtonVariant.text,
    ),
    AppButton(
      onPressed: _isLoading ? null : _onSave,
      label: 'Guardar',
      variant: AppButtonVariant.primary,
    ),
  ],
)
```

### TextFormField (OBLIGATORIO: textInputAction)
```dart
// ✅ CORRECTO: Con textInputAction
TextFormField(
  controller: _nombreController,
  textInputAction: TextInputAction.next, // Tab/Enter avanza al siguiente
  decoration: InputDecoration(
    labelText: 'Nombre',
    hintText: 'Ingrese el nombre',
  ),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Campo requerido';
    }
    return null;
  },
)

// Para campos multilínea
TextFormField(
  controller: _descripcionController,
  maxLines: 3,
  textInputAction: TextInputAction.newline, // Enter crea nueva línea
  decoration: InputDecoration(
    labelText: 'Descripción',
  ),
)

// Patrón dinámico (recomendado)
TextFormField(
  controller: controller,
  maxLines: maxLines,
  textInputAction: maxLines == 1 ? TextInputAction.next : TextInputAction.newline,
  decoration: InputDecoration(labelText: label),
)

// ❌ INCORRECTO: Sin textInputAction
TextFormField(
  controller: _nombreController, // Falta textInputAction ❌
  decoration: InputDecoration(labelText: 'Nombre'),
)
```

**Valores de textInputAction**:
- `TextInputAction.next` → Campos de una línea (avanza con Tab/Enter)
- `TextInputAction.newline` → Campos multilínea (Enter = nueva línea)
- `TextInputAction.done` → Último campo (cierra teclado)

**Beneficios**:
- ✅ Navegación con Tab/Enter entre campos
- ✅ Mejor UX y accesibilidad
- ✅ Estándar de la aplicación

## 📏 Límites de Tamaño
| Elemento | Máximo |
|----------|--------|
| Widget | 150 líneas |
| Método | 40 líneas |
| Anidación | 3 niveles |

## ⚠️ Reglas UI que DEBO seguir

1. **AppColors**: Siempre, nunca Colors directo
2. **SafeArea**: Obligatorio en páginas
3. **Widgets**: StatelessWidget, no métodos _build
4. **AppDropdown**: Para todos los dropdowns
5. **Loading**: Mostrar en formularios async
6. **Límites**: Widget <150 líneas
7. **DRY**: Si se repite 2 veces → abstraer
8. **textInputAction**: OBLIGATORIO en TODOS los TextFormField

## 🔧 Verificación
```bash
# Después de cambios
flutter analyze
# Resultado: No issues found!
```

## 💬 Cómo Usarme
```
Usuario: Crea un card para mostrar vehículos con estado y matrícula

Yo:
1. Creo widget VehiculoCard con AppColors
2. Divido en sub-widgets si >150 líneas
3. Aplico design system
4. Verifico flutter analyze
```
