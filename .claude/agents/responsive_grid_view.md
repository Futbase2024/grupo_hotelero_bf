# Agente: Responsive GridView Pattern

## Descripción
Este agente asegura que todos los GridViews del proyecto sean responsivos y se adapten al contenido y tamaño de pantalla.

## Patron Obligatorio

### Widget Reutilizable
Usar siempre `ResponsiveGridView` o `SliverResponsiveGridView` desde:
```
lib/shared/widgets/responsive_grid_view.dart
```

### Ejemplo de Uso

#### GridView Normal
```dart
import 'package:bf_stay/shared/widgets/responsive_grid_view.dart';

ResponsiveGridView<MyItem>(
  items: myItems,
  itemBuilder: (context, item) => MyCard(item: item),
  minItemWidth: 160,      // Ancho minimo de cada item
  maxItemWidth: 220,      // Ancho maximo de cada item
  minItemsPerRow: 2,      // Minimo 2 columnas
  maxItemsPerRow: 3,      // Maximo 3 columnas
  itemSpacing: 12,        // Espacio horizontal entre items
  rowSpacing: 12,         // Espacio vertical entre filas
  padding: const EdgeInsets.symmetric(horizontal: 16),
  emptyWidget: const EmptyState(), // Opcional
)
```

#### Sliver para CustomScrollView
```dart
SliverResponsiveGridView<MyItem>(
  items: myItems,
  itemBuilder: (context, item) => MyCard(item: item),
  minItemWidth: 160,
  maxItemWidth: 220,
  minItemsPerRow: 2,
  maxItemsPerRow: 3,
  itemSpacing: 12,
  rowSpacing: 12,
  padding: const EdgeInsets.symmetric(horizontal: 16),
)
```

### Tarjetas Responsivas
Las tarjetas dentro del grid DEBEN usar:
```dart
class MyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,  // IMPORTANTE
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen con AspectRatio
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Image(...),
          ),
          // Contenido flexible
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,  // IMPORTANTE
                children: [
                  Text(...),
                  Text(...),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

## Reglas

1. **NUNCA usar `SliverGridDelegateWithFixedCrossAxisCount` con `childAspectRatio` fijo**
   - ❌ `SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.72)`
   - ✅ Usar `SliverResponsiveGridView`

2. **Las tarjetas DEBEN adaptarse al contenido**
   - Usar `mainAxisSize: MainAxisSize.min` en Columns
   - Usar `Flexible` para contenido variable
   - NO usar alturas fijas en el contenido

3. **Usar `LayoutBuilder` o `SliverLayoutBuilder` para responsividad**
   - El widget `ResponsiveGridView` ya lo hace internamente

4. **Padding consistente**
   - Usar `padding: const EdgeInsets.symmetric(horizontal: 16)`
   - Espaciado entre items: 12px

## Parametros por Defecto

| Parametro | Valor | Descripcion |
|-----------|-------|-------------|
| minItemWidth | 160 | Ancho minimo de cada item |
| maxItemWidth | 220 | Ancho maximo de cada item |
| minItemsPerRow | 2 | Minimo de columnas |
| maxItemsPerRow | 3 | Maximo de columnas |
| itemSpacing | 12 | Espacio horizontal |
| rowSpacing | 12 | Espacio vertical |

## Checklist para Nuevos GridViews

- [ ] Usar `ResponsiveGridView` o `SliverResponsiveGridView`
- [ ] Tarjetas con `mainAxisSize: MainAxisSize.min`
- [ ] Contenido variable envuelto en `Flexible`
- [ ] Imagenes con `AspectRatio`
- [ ] Padding consistente (16px horizontal)
- [ ] Sin `childAspectRatio` fijo
- [ ] Sin alturas fijas en tarjetas
