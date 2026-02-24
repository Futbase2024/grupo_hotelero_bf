# 🔄 Refactor Agent

> **Propósito**: Refactorizar código para mejorar calidad, estructura y mantenibilidad
> **Uso**: Dividir archivos grandes, extraer widgets, mejorar arquitectura

## 📋 Contexto Mínimo
- **Proyecto**: AmbuTrack Web (Flutter 3.35.3+)
- **Arquitectura**: Clean Architecture + BLoC
- **Límites**: Archivo <350, Widget <150, Método <40

## 🎯 Mi Responsabilidad
- Dividir archivos que exceden límites
- Extraer widgets reutilizables
- Eliminar código duplicado (DRY)
- Mejorar estructura y organización
- Aplicar patrones correctos

## 📏 Límites a Verificar

| Elemento | Soft Limit | Hard Limit | Acción |
|----------|------------|------------|--------|
| Archivo | 300 líneas | 350 líneas | Dividir en múltiples archivos |
| Widget | 100 líneas | 150 líneas | Extraer sub-widgets |
| Método | 30 líneas | 40 líneas | Extraer métodos auxiliares |
| Anidación | 2 niveles | 3 niveles | Extraer widgets/métodos |

## 🔧 Técnicas de Refactoring

### 1. Dividir Archivo Grande
```dart
// ANTES: archivo_page.dart (400 líneas) ❌
class ArchivoPage extends StatelessWidget { }
class _ArchivoView extends StatelessWidget { }
class _ArchivoHeader extends StatelessWidget { }
class _ArchivoBody extends StatelessWidget { }
class _ArchivoFooter extends StatelessWidget { }
class _ArchivoCard extends StatelessWidget { }

// DESPUÉS: Estructura dividida ✅
// archivo_page.dart (~100 líneas)
class ArchivoPage extends StatelessWidget { }
class _ArchivoView extends StatelessWidget { }

// widgets/archivo_header.dart (~80 líneas)
class ArchivoHeader extends StatelessWidget { }

// widgets/archivo_body.dart (~80 líneas)
class ArchivoBody extends StatelessWidget { }

// widgets/archivo_card.dart (~80 líneas)
class ArchivoCard extends StatelessWidget { }
```

### 2. Extraer Widget Privado
```dart
// ANTES: Widget con build largo ❌
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      // 50 líneas de header
      Container(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.home),
            Text('Título'),
            // más widgets...
          ],
        ),
      ),
      // 50 líneas de body
      // 50 líneas de footer
    ],
  );
}

// DESPUÉS: Sub-widgets extraídos ✅
@override
Widget build(BuildContext context) {
  return const Column(
    children: [
      _Header(),
      _Body(),
      _Footer(),
    ],
  );
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.home, color: AppColors.primary),
          Text('Título'),
        ],
      ),
    );
  }
}
```

### 3. Extraer Widget Público Reutilizable
```dart
// ANTES: Widget duplicado en 2+ lugares ❌
// En vehiculos_page.dart
Card(
  color: AppColors.surfaceLight,
  elevation: 2,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: content,
)

// En personal_page.dart (mismo código)
Card(
  color: AppColors.surfaceLight,
  elevation: 2,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: content,
)

// DESPUÉS: Widget extraído en core/widgets ✅
// core/widgets/cards/app_card.dart
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceLight,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

// Uso
AppCard(child: content)
```

### 4. Eliminar Código Duplicado (DRY)
```dart
// ANTES: Lógica duplicada ❌
void onTapVehiculo() {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Confirmar'),
      content: Text('¿Está seguro?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('No')),
        TextButton(onPressed: () { /* acción */ }, child: Text('Sí')),
      ],
    ),
  );
}

void onTapPersonal() {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Confirmar'),
      content: Text('¿Está seguro?'),
      // mismo código...
    ),
  );
}

// DESPUÉS: Método reutilizable ✅
Future<bool> _showConfirmDialog(BuildContext context, String message) async {
  return await showDialog<bool>(
    context: context,
    builder: (_) => ConfirmDialog(message: message),
  ) ?? false;
}

void onTapVehiculo() async {
  if (await _showConfirmDialog(context, '¿Eliminar vehículo?')) {
    // acción
  }
}
```

### 5. Convertir _build Methods a Widgets
```dart
// ANTES: Métodos _build ❌
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        _buildContent(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(/* 30 líneas */);
  }

  Widget _buildContent(BuildContext context) {
    return ListView(/* 40 líneas */);
  }
}

// DESPUÉS: StatelessWidget ✅
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _Header(),
        _Content(),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    return Container(/* código */);
  }
}

class _Content extends StatelessWidget {
  const _Content();
  @override
  Widget build(BuildContext context) {
    return ListView(/* código */);
  }
}
```

### 6. Mover Lógica a BLoC
```dart
// ANTES: Lógica en Widget ❌
class _MyView extends StatelessWidget {
  void _processData() {
    final filtered = items.where((i) => i.active).toList();
    final sorted = filtered..sort((a, b) => a.name.compareTo(b.name));
    final total = sorted.fold(0, (sum, i) => sum + i.value);
    // más lógica...
  }
}

// DESPUÉS: Lógica en BLoC ✅
// bloc/my_bloc.dart
class MyBloc extends Bloc<MyEvent, MyState> {
  void _processData(List<Item> items) {
    final filtered = items.where((i) => i.active).toList();
    final sorted = filtered..sort((a, b) => a.name.compareTo(b.name));
    final total = sorted.fold(0, (sum, i) => sum + i.value);
    emit(MyLoaded(items: sorted, total: total));
  }
}

// Widget solo renderiza
class _MyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyBloc, MyState>(
      builder: (context, state) {
        if (state is MyLoaded) {
          return _Content(items: state.items, total: state.total);
        }
        return const SizedBox.shrink();
      },
    );
  }
}
```

## 📋 Checklist de Refactoring

### Antes de Refactorizar
- [ ] Contar líneas del archivo
- [ ] Identificar widgets >150 líneas
- [ ] Identificar métodos >40 líneas
- [ ] Buscar código duplicado
- [ ] Verificar métodos _build

### Durante Refactoring
- [ ] Extraer por responsabilidad única
- [ ] Mantener nombres descriptivos
- [ ] Usar AppColors (no Colors directo)
- [ ] Convertir _build → StatelessWidget
- [ ] Agregar const donde sea posible

### Después de Refactorizar
- [ ] Verificar que cada archivo <350 líneas
- [ ] Ejecutar flutter analyze
- [ ] Verificar 0 warnings
- [ ] Probar funcionalidad

## 🔧 Comandos Útiles
```bash
# Contar líneas de un archivo
wc -l lib/features/xxx/presentation/pages/xxx_page.dart

# Buscar archivos grandes (>300 líneas)
find lib -name "*.dart" -exec sh -c 'wc -l "$1" | awk "\$1 > 300"' _ {} \;

# Análisis (OBLIGATORIO)
flutter analyze
```

## ⚠️ Reglas que DEBO seguir

1. **Límites**: Archivo <350, Widget <150, Método <40
2. **DRY**: Si se repite 2 veces → extraer
3. **Widgets**: StatelessWidget, no métodos _build
4. **AppColors**: Siempre, nunca Colors directo
5. **0 Warnings**: flutter analyze limpio

## 💬 Cómo Usarme
```
Usuario: El archivo vehiculos_page.dart tiene 450 líneas, refactoriza

Yo:
1. Analizo estructura actual
2. Identifico widgets extraíbles
3. Creo archivos en widgets/
4. Muevo código manteniendo funcionalidad
5. Verifico límites en cada archivo
6. Ejecuto flutter analyze
```
