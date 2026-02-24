# 📏 Límites de Archivos AmbuTrack - REGLAS CRÍTICAS

> **⚠️ ESTAS REGLAS SON IRROMPIBLES E INQUEBRANTABLES**

---

## 🚨 Límites Máximos ABSOLUTOS

### Tamaños por Tipo de Archivo

| Tipo | Soft Limit | Hard Limit | Acción si se excede |
|------|------------|------------|---------------------|
| **Archivo general** | 300 líneas | **400 LÍNEAS MÁXIMO** | ⛔ DETENER + Dividir |
| **Widget** | 120 líneas | 150 líneas | Extraer subwidgets |
| **Método/Función** | 30 líneas | 40 líneas | Refactorizar |
| **Profundidad anidación** | 2 niveles | 3 niveles | Extraer métodos |

---

## ⚠️ Protocolo de Exceso de Líneas

### Si un archivo supera 350 líneas:
1. **ALERTAR** al usuario inmediatamente
2. **PROPONER** división en múltiples archivos
3. **ESPERAR** aprobación antes de continuar
4. **DIVIDIR** siguiendo Single Responsibility Principle

### Si un archivo supera 400 líneas:
1. ⛔ **DETENER** inmediatamente
2. 🚫 **NO CONTINUAR** bajo ninguna circunstancia
3. 📋 **GENERAR** plan de división obligatorio
4. ✅ **IMPLEMENTAR** solo después de aprobación

---

## ✂️ Ejemplos de División Correcta

### ❌ INCORRECTO: Archivo Monolítico

```
planificar_servicios_page.dart (650 líneas)
├─ Imports (20 líneas)
├─ Page (50 líneas)
├─ Header (150 líneas)
├─ Table (200 líneas)
├─ Filters (120 líneas)
└─ Form Dialog (110 líneas)
```

### ✅ CORRECTO: Archivos Divididos

```
planificar_servicios_page.dart (200 líneas)
├─ Solo página principal
└─ Orquestación de widgets

servicios_header.dart (150 líneas)
├─ Header con búsqueda
└─ Botón agregar

servicios_table.dart (320 líneas)
├─ AppDataGridV5
├─ Paginación
└─ Acciones (Ver/Editar/Eliminar)

servicios_filters.dart (180 líneas)
├─ Filtros por fecha
├─ Filtros por estado
└─ Filtros por centro

servicio_form_dialog.dart (350 líneas)
├─ Formulario completo
├─ Validaciones
└─ Submit
```

---

## 📦 Estructura de Carpetas Recomendada

### Para feature trafico_diario:

```
lib/features/trafico_diario/
├── presentation/
│   ├── pages/
│   │   └── planificar_servicios_page.dart      (200 líneas)
│   │
│   ├── widgets/
│   │   ├── servicios_table.dart                (320 líneas)
│   │   ├── servicios_header.dart               (150 líneas)
│   │   ├── servicios_filters.dart              (180 líneas)
│   │   ├── servicio_form_dialog.dart           (350 líneas)
│   │   ├── servicio_detail_dialog.dart         (250 líneas)
│   │   └── servicio_card.dart                  (120 líneas)
│   │
│   └── bloc/
│       ├── servicios_bloc.dart                 (280 líneas)
│       ├── servicios_event.dart                (80 líneas)
│       └── servicios_state.dart                (60 líneas)
│
├── domain/
│   └── repositories/
│       └── servicio_repository.dart            (100 líneas)
│
└── data/
    └── repositories/
        └── servicio_repository_impl.dart       (300 líneas)
```

**Total**: ~2,390 líneas distribuidas en 13 archivos
**Promedio**: ~183 líneas por archivo
**Máximo**: 350 líneas (servicio_form_dialog.dart)
**✅ Todos los archivos bajo el límite**

---

## 🔍 Checklist de Validación

Antes de dar por terminado un archivo:

- [ ] **¿Tiene menos de 350 líneas?** (preferido)
- [ ] **¿Tiene menos de 400 líneas?** (OBLIGATORIO)
- [ ] **¿Widgets separados en clases propias?** (NO métodos `_buildX()`)
- [ ] **¿Métodos menores de 40 líneas?**
- [ ] **¿Profundidad de anidación menor de 3 niveles?**
- [ ] **¿Sigue Single Responsibility Principle?**

Si alguna respuesta es **NO** → **REFACTORIZAR**

---

## 🚀 Comandos de Verificación

### Contar líneas de un archivo:
```bash
wc -l lib/features/trafico_diario/presentation/widgets/servicios_table.dart
```

### Contar líneas de todos los archivos de un feature:
```bash
find lib/features/trafico_diario -name "*.dart" -exec wc -l {} + | sort -n
```

### Alertar si algún archivo supera 350 líneas:
```bash
find lib/features/trafico_diario -name "*.dart" -exec sh -c 'lines=$(wc -l < "$1"); if [ "$lines" -gt 350 ]; then echo "⚠️  $1: $lines líneas (SUPERA LÍMITE)"; fi' _ {} \;
```

---

## 📋 Casos Especiales

### Formularios complejos (máx 350 líneas)
Si un formulario necesita más de 350 líneas:
- **Dividir en steps** (wizard multi-paso)
- **Extraer secciones** a widgets dedicados
- **Usar builders** para secciones repetitivas

### Tablas complejas (máx 350 líneas)
Si una tabla necesita más de 350 líneas:
- **Separar buildCells** en archivo dedicado
- **Extraer filtros** a archivo propio
- **Mover paginación** a widget reutilizable

### BLoCs complejos (máx 300 líneas)
Si un BLoC necesita más de 300 líneas:
- **Dividir eventos** por categoría (Load, Create, Update, Delete)
- **Extraer lógica** a servicios/helpers
- **Usar múltiples BLoCs** si hay responsabilidades distintas

---

## ⚖️ Prioridad de Reglas

En caso de conflicto entre mantenibilidad y límites:

```
Límites de Archivos > Mantenibilidad > Otras reglas
```

**Los límites de archivos tienen prioridad ABSOLUTA.**

---

## 🎯 Objetivo

**Mantener TODOS los archivos bajo 350 líneas (400 máximo absoluto)** para:
- ✅ Mejor legibilidad
- ✅ Fácil mantenimiento
- ✅ Testing más simple
- ✅ Menos conflictos en git
- ✅ Mejor organización
- ✅ Código más modular

---

**Última actualización**: 2025-01-07
**Aplicable a**: Todos los features de AmbuTrack Web
