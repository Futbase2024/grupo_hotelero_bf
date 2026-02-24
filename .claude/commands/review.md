# Review Command

Revisa el código contra los estándares del proyecto.

## Uso
```
/review [path]
```

## Ejemplo
```
/review lib/presentation/features/ideas/
```

## Checklist de Revisión

### 🔴 Crítico (BLOQUEA)

```
□ ¿Hay métodos que devuelven Widget? (_buildX)
  → grep -rn "Widget _build" [path]

□ ¿Hay imports de Material?
  → grep -r "import 'package:flutter/material" [path]

□ ¿Hay StatefulWidget donde debería haber BLoC?
  → Revisar manualmente
```

### 🟡 Importante

```
□ ¿Widgets extraídos a clases separadas?
□ ¿BLoC usa Freezed para Events/States?
□ ¿Repository tiene contrato en domain/?
□ ¿Routes usan GoRouteData pattern?
□ ¿Hay tests con 85%+ coverage?
```

### 🟢 Recomendado

```
□ ¿Nombres descriptivos?
□ ¿Comentarios en código complejo?
□ ¿Imports organizados?
□ ¿Archivos <= 300 líneas?
```

## Proceso

1. **AG-05 (QA)** ejecuta verificaciones automáticas
2. Reporta issues encontrados
3. Sugiere correcciones
4. Ejecuta `dart fix --apply` si hay fixes disponibles

## Output

```
✅ PASA: No hay métodos _buildX
✅ PASA: No hay imports Material  
❌ FALLA: Falta test para ideas_bloc
⚠️ WARN: Archivo ideas_page.dart tiene 350 líneas
```
